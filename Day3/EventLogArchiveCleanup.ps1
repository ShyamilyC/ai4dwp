<#
.SYNOPSIS
Archives and cleans Windows Event Logs with dry-run, logging, summary, and rollback support.

.DESCRIPTION
This PowerShell 5.1 script is designed for endpoint-safe event log maintenance.
It targets only logs where all records are older than the cutoff date, exports each
log to an EVTX archive, and then clears the source log.

Safety and control features:
- Dry-run mode prints how many records would be deleted.
- Configurable age threshold via -OlderThanDays (default: 3).
- Per-operation try/catch handling with detailed log output.
- Timestamped action log for auditing.
- End-of-run summary.
- Rollback mode based on archived EVTX files and transaction manifests.
- Idempotency: if today's archive exists for a log, that log is skipped.

Note on rollback:
Windows does not provide a supported API to write archived events back into the live
built-in channels (Application/System/Security). Rollback in this script restores
and preserves archived EVTX artifacts from a transaction for investigation/replay.
#>

[CmdletBinding()]
param(
    # Preview mode: no export/clear actions, only counts what would be deleted.
    [switch]$DryRun,

    # Cleanup mode: process only logs where events are older than this many days.
    [ValidateRange(1, 36500)]
    [int]$OlderThanDays = 3,

    # Optional explicit log names. If omitted, all enabled classic/admin logs are evaluated.
    [string[]]$LogNames,

    # Root directory where script logs are written.
    [string]$LogDirectory = (Join-Path -Path $PSScriptRoot -ChildPath 'Logs'),

    # Root directory where exported archives are written.
    [string]$ArchiveDirectory = (Join-Path -Path $PSScriptRoot -ChildPath 'EventLogArchives'),

    # Root directory where rollback manifests and recovered artifacts are stored.
    [string]$RollbackDirectory = (Join-Path -Path $PSScriptRoot -ChildPath 'RollbackStore'),

    # Rollback mode: use latest or specified transaction manifest.
    [switch]$Rollback,

    # Optional transaction ID for rollback mode.
    [string]$TransactionId
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Section 1: Initialize run metadata, folder layout, and centralized logging.
# Creates required directories and prepares a timestamped run log file.
$script:RunTimestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$script:RunDate = Get-Date -Format 'yyyyMMdd'
$script:RunId = '{0}_{1}' -f $script:RunTimestamp, ([guid]::NewGuid().ToString('N').Substring(0, 8))
$script:LogFile = $null

function Write-Log {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('INFO', 'WARN', 'ERROR')]
        [string]$Level,

        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    $stamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $line = '{0} [{1}] {2}' -f $stamp, $Level, $Message

    try {
        if ($script:LogFile) {
            Add-Content -Path $script:LogFile -Value $line -ErrorAction Stop
        }
        Write-Host $line
    }
    catch {
        Write-Host ('{0} [ERROR] Failed to write log entry: {1}' -f $stamp, $_.Exception.Message)
        Write-Host $line
    }
}

# Section 2: Helpers for safe naming and transaction discovery.
# Sanitizes log names for file paths and resolves rollback manifests.
function Convert-ToSafeName {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    try {
        $safe = $Name -replace '[\\/:*?"<>|]', '_'
        return $safe
    }
    catch {
        Write-Log -Level ERROR -Message ("Safe name conversion failed for '{0}': {1}" -f $Name, $_.Exception.Message)
        throw
    }
}

function Get-RollbackManifestPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$RollbackRoot,

        [string]$TxnId
    )

    try {
        if ($TxnId) {
            $candidate = Join-Path -Path (Join-Path -Path $RollbackRoot -ChildPath $TxnId) -ChildPath 'manifest.json'
            if (Test-Path -LiteralPath $candidate) {
                return $candidate
            }
            return $null
        }

        $all = Get-ChildItem -Path $RollbackRoot -Filter 'manifest.json' -File -Recurse -ErrorAction SilentlyContinue |
            Sort-Object -Property LastWriteTime -Descending

        if ($all -and $all.Count -gt 0) {
            return $all[0].FullName
        }

        return $null
    }
    catch {
        Write-Log -Level ERROR -Message ("Failed to discover rollback manifest: {0}" -f $_.Exception.Message)
        throw
    }
}

# Section 3: Rollback workflow.
# Restores archived EVTX files for a chosen transaction into a rollback output folder.
# This is endpoint-safe and idempotent (existing restored artifacts are skipped).
function Invoke-EventLogRollback {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$RollbackRoot,

        [string]$TxnId
    )

    $manifestPath = $null
    $manifest = $null
    $entries = @()

    try {
        $manifestPath = Get-RollbackManifestPath -RollbackRoot $RollbackRoot -TxnId $TxnId
    }
    catch {
        Write-Log -Level ERROR -Message ("Rollback setup failed: {0}" -f $_.Exception.Message)
        return
    }

    if (-not $manifestPath) {
        Write-Log -Level WARN -Message 'No rollback manifest found. Nothing to rollback.'
        return
    }

    try {
        Write-Log -Level INFO -Message ("Using rollback manifest: {0}" -f $manifestPath)
        $manifest = Get-Content -Path $manifestPath -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
        $entries = @($manifest.Entries)
    }
    catch {
        Write-Log -Level ERROR -Message ("Failed to read rollback manifest: {0}" -f $_.Exception.Message)
        return
    }

    $restoreRoot = Join-Path -Path (Split-Path -Path $manifestPath -Parent) -ChildPath 'Recovered'

    try {
        if (-not (Test-Path -LiteralPath $restoreRoot)) {
            New-Item -Path $restoreRoot -ItemType Directory -Force -ErrorAction Stop | Out-Null
        }
    }
    catch {
        Write-Log -Level ERROR -Message ("Failed to create rollback output folder '{0}': {1}" -f $restoreRoot, $_.Exception.Message)
        return
    }

    $stats = [pscustomobject]@{
        TotalEntries      = $entries.Count
        RecoveredArtifacts = 0
        AlreadyRecovered  = 0
        MissingArchive    = 0
        Failed            = 0
    }

    foreach ($entry in $entries) {
        try {
            $sourceArchive = $entry.ArchivePath
            $targetName = [System.IO.Path]::GetFileName($sourceArchive)
            $targetPath = Join-Path -Path $restoreRoot -ChildPath $targetName

            if ($entry.RolledBack -eq $true -or (Test-Path -LiteralPath $targetPath)) {
                $stats.AlreadyRecovered++
                Write-Log -Level INFO -Message ("SKIP already recovered: {0}" -f $entry.LogName)
                continue
            }

            if (-not (Test-Path -LiteralPath $sourceArchive)) {
                $stats.MissingArchive++
                Write-Log -Level WARN -Message ("SKIP missing archive for log '{0}': {1}" -f $entry.LogName, $sourceArchive)
                continue
            }

            Copy-Item -LiteralPath $sourceArchive -Destination $targetPath -Force -ErrorAction Stop
            $entry.RolledBack = $true
            $entry.RolledBackAt = (Get-Date).ToString('s')
            $stats.RecoveredArtifacts++
            Write-Log -Level INFO -Message ("RECOVERED archive artifact: {0} -> {1}" -f $sourceArchive, $targetPath)
        }
        catch {
            $stats.Failed++
            Write-Log -Level ERROR -Message ("Rollback failed for log '{0}': {1}" -f $entry.LogName, $_.Exception.Message)
        }
    }

    try {
        $manifest.Entries = $entries
        $manifest | ConvertTo-Json -Depth 8 | Set-Content -Path $manifestPath -Encoding UTF8 -ErrorAction Stop
    }
    catch {
        Write-Log -Level ERROR -Message ("Failed to update manifest after rollback: {0}" -f $_.Exception.Message)
    }

    Write-Host "`n=== Rollback Summary ===" -ForegroundColor Cyan
    [pscustomobject]$stats | Format-List
    Write-Log -Level INFO -Message ("Rollback summary: Total={0}; Recovered={1}; AlreadyRecovered={2}; MissingArchive={3}; Failed={4}" -f $stats.TotalEntries, $stats.RecoveredArtifacts, $stats.AlreadyRecovered, $stats.MissingArchive, $stats.Failed)
    Write-Log -Level WARN -Message 'Rollback recovers archived EVTX artifacts only; Windows does not support reinserting events into live built-in channels.'
}

# Section 4: Create directories and start run log.
# Ensures all runtime paths are ready before any data operations begin.
try {
    if (-not (Test-Path -LiteralPath $LogDirectory)) {
        New-Item -Path $LogDirectory -ItemType Directory -Force -ErrorAction Stop | Out-Null
    }
}
catch {
    throw "Failed to create log directory '$LogDirectory': $($_.Exception.Message)"
}

$script:LogFile = Join-Path -Path $LogDirectory -ChildPath ("EventLogArchiveCleanup_{0}.log" -f $script:RunTimestamp)

try {
    if (-not (Test-Path -LiteralPath $ArchiveDirectory)) {
        New-Item -Path $ArchiveDirectory -ItemType Directory -Force -ErrorAction Stop | Out-Null
    }
}
catch {
    Write-Log -Level ERROR -Message ("Failed to create archive directory '{0}': {1}" -f $ArchiveDirectory, $_.Exception.Message)
    throw
}

try {
    if (-not (Test-Path -LiteralPath $RollbackDirectory)) {
        New-Item -Path $RollbackDirectory -ItemType Directory -Force -ErrorAction Stop | Out-Null
    }
}
catch {
    Write-Log -Level ERROR -Message ("Failed to create rollback directory '{0}': {1}" -f $RollbackDirectory, $_.Exception.Message)
    throw
}

Write-Log -Level INFO -Message ("Script started. Mode={0}; DryRun={1}; OlderThanDays={2}" -f ($(if ($Rollback) { 'Rollback' } else { 'Cleanup' }), $DryRun.IsPresent, $OlderThanDays))

# Section 5: Handle rollback mode and exit early.
# Keeps rollback isolated from cleanup behavior.
if ($Rollback) {
    Invoke-EventLogRollback -RollbackRoot $RollbackDirectory -TxnId $TransactionId
    Write-Log -Level INFO -Message 'Script completed (rollback mode).'
    return
}

# Section 6: Discover candidate logs and compute record counts.
# A log is a candidate only when its newest event is older than cutoff, so clearing is age-safe.
$cutoff = (Get-Date).AddDays(-$OlderThanDays)
$logsToEvaluate = @()

try {
    if ($LogNames -and $LogNames.Count -gt 0) {
        $logsToEvaluate = $LogNames
    }
    else {
        $logObjects = Get-WinEvent -ListLog * -ErrorAction SilentlyContinue |
            Where-Object { $_.IsEnabled -eq $true -and $_.LogType -in @('Administrative', 'Operational', 'Analytical', 'Debug', 'Classic') }
        $logsToEvaluate = @($logObjects | Select-Object -ExpandProperty LogName)
    }
}
catch {
    Write-Log -Level ERROR -Message ("Failed to enumerate logs: {0}" -f $_.Exception.Message)
    throw
}

$evaluationRows = New-Object System.Collections.Generic.List[object]

foreach ($logName in $logsToEvaluate) {
    try {
        Write-Log -Level INFO -Message ("Evaluating log: {0}" -f $logName)

        $recordCount = 0
        $newestEvent = $null

        try {
            $logInfo = Get-WinEvent -ListLog $logName -ErrorAction Stop
            $recordCount = [int64]($logInfo.RecordCount)
        }
        catch {
            Write-Log -Level WARN -Message ("Unable to get metadata for log '{0}': {1}" -f $logName, $_.Exception.Message)
            continue
        }

        if ($recordCount -le 0) {
            $evaluationRows.Add([pscustomobject]@{
                LogName      = $logName
                RecordCount  = 0
                NewestTime   = $null
                IsCandidate  = $false
                Reason       = 'Empty log'
            }) | Out-Null
            Write-Log -Level INFO -Message ("Skipping empty log: {0}" -f $logName)
            continue
        }

        try {
            $newestEvent = Get-WinEvent -LogName $logName -MaxEvents 1 -ErrorAction Stop
        }
        catch {
            Write-Log -Level WARN -Message ("Unable to query newest event for '{0}': {1}" -f $logName, $_.Exception.Message)
            continue
        }

        $isCandidate = $false
        $reason = ''

        if ($null -eq $newestEvent.TimeCreated) {
            $reason = 'No timestamp on newest event'
        }
        elseif ($newestEvent.TimeCreated -lt $cutoff) {
            $isCandidate = $true
            $reason = 'Newest event older than cutoff'
        }
        else {
            $reason = 'Contains recent events'
        }

        $evaluationRows.Add([pscustomobject]@{
            LogName      = $logName
            RecordCount  = $recordCount
            NewestTime   = $newestEvent.TimeCreated
            IsCandidate  = $isCandidate
            Reason       = $reason
        }) | Out-Null

        Write-Log -Level INFO -Message ("Evaluation result: Log={0}; RecordCount={1}; Candidate={2}; Reason={3}" -f $logName, $recordCount, $isCandidate, $reason)
    }
    catch {
        Write-Log -Level ERROR -Message ("Unhandled evaluation error for '{0}': {1}" -f $logName, $_.Exception.Message)
    }
}

$candidates = @($evaluationRows | Where-Object { $_.IsCandidate -eq $true })
$totalDeleteCount = [int64](($candidates | Measure-Object -Property RecordCount -Sum).Sum)
if ($null -eq $totalDeleteCount) { $totalDeleteCount = 0 }

# Section 7: Dry-run reporting.
# Prints exact per-log and total record counts that would be deleted.
if ($DryRun) {
    Write-Host "`n=== Dry Run Candidate Logs ===" -ForegroundColor Yellow

    foreach ($row in $candidates) {
        $line = 'DRYRUN candidate: {0} | RecordsToDelete={1} | Newest={2}' -f $row.LogName, $row.RecordCount, ($(if ($row.NewestTime) { $row.NewestTime.ToString('s') } else { 'n/a' }))
        Write-Host $line
        Write-Log -Level INFO -Message $line
    }

    Write-Host "`n=== Dry Run Summary ===" -ForegroundColor Cyan
    [pscustomobject]@{
        Mode                    = 'DryRun'
        OlderThanDays           = $OlderThanDays
        CutoffDate              = $cutoff
        EvaluatedLogs           = $logsToEvaluate.Count
        CandidateLogs           = $candidates.Count
        TotalRecordsToDelete    = $totalDeleteCount
        LogFile                 = $script:LogFile
    } | Format-List

    Write-Log -Level INFO -Message ("Dry run complete. CandidateLogs={0}; TotalRecordsToDelete={1}" -f $candidates.Count, $totalDeleteCount)
    return
}

# Section 8: Archive and clear candidate logs.
# Exports each candidate log to today's archive then clears it if export succeeds.
$transactionId = $script:RunId
$transactionRoot = Join-Path -Path $RollbackDirectory -ChildPath $transactionId
$manifestPath = Join-Path -Path $transactionRoot -ChildPath 'manifest.json'
$archiveDateRoot = Join-Path -Path $ArchiveDirectory -ChildPath $script:RunDate
$manifestEntries = New-Object System.Collections.Generic.List[object]

try {
    if (-not (Test-Path -LiteralPath $transactionRoot)) {
        New-Item -Path $transactionRoot -ItemType Directory -Force -ErrorAction Stop | Out-Null
    }
}
catch {
    Write-Log -Level ERROR -Message ("Failed to create transaction folder '{0}': {1}" -f $transactionRoot, $_.Exception.Message)
    throw
}

try {
    if (-not (Test-Path -LiteralPath $archiveDateRoot)) {
        New-Item -Path $archiveDateRoot -ItemType Directory -Force -ErrorAction Stop | Out-Null
    }
}
catch {
    Write-Log -Level ERROR -Message ("Failed to create archive date folder '{0}': {1}" -f $archiveDateRoot, $_.Exception.Message)
    throw
}

$summary = [pscustomobject]@{
    Mode                  = 'Cleanup'
    OlderThanDays         = $OlderThanDays
    CutoffDate            = $cutoff
    EvaluatedLogs         = $logsToEvaluate.Count
    CandidateLogs         = $candidates.Count
    TotalRecordsToDelete  = $totalDeleteCount
    ArchivedLogs          = 0
    ClearedLogs           = 0
    IdempotentSkipped     = 0
    FailedLogs            = 0
    TransactionId         = $transactionId
    ArchiveFolder         = $archiveDateRoot
    ManifestPath          = $manifestPath
    LogFile               = $script:LogFile
}

foreach ($candidate in $candidates) {
    $logName = $candidate.LogName
    $recordCount = [int64]$candidate.RecordCount

    try {
        $safeLogName = Convert-ToSafeName -Name $logName
        $archiveFile = Join-Path -Path $archiveDateRoot -ChildPath ('{0}_{1}.evtx' -f $safeLogName, $script:RunDate)

        if (Test-Path -LiteralPath $archiveFile) {
            $summary.IdempotentSkipped++
            $manifestEntries.Add([pscustomobject]@{
                LogName          = $logName
                RecordsDeleted   = 0
                ArchivePath      = $archiveFile
                ArchivedAt       = $null
                ClearedAt        = $null
                Status           = 'SkippedAlreadyArchivedToday'
                RolledBack       = $false
                RolledBackAt     = $null
            }) | Out-Null

            Write-Log -Level INFO -Message ("IDEMPOTENT SKIP: today's archive already exists for '{0}': {1}" -f $logName, $archiveFile)
            continue
        }

        try {
            & wevtutil.exe epl "$logName" "$archiveFile"
            if ($LASTEXITCODE -ne 0) {
                throw "wevtutil epl exit code $LASTEXITCODE"
            }
        }
        catch {
            $summary.FailedLogs++
            $manifestEntries.Add([pscustomobject]@{
                LogName          = $logName
                RecordsDeleted   = 0
                ArchivePath      = $archiveFile
                ArchivedAt       = $null
                ClearedAt        = $null
                Status           = 'ArchiveFailed'
                RolledBack       = $false
                RolledBackAt     = $null
            }) | Out-Null

            Write-Log -Level ERROR -Message ("Archive failed for '{0}': {1}" -f $logName, $_.Exception.Message)
            continue
        }

        try {
            if (-not (Test-Path -LiteralPath $archiveFile)) {
                throw "Archive file missing after export: $archiveFile"
            }
            $archiveInfo = Get-Item -LiteralPath $archiveFile -ErrorAction Stop
            if ($archiveInfo.Length -le 0) {
                throw "Archive file is empty: $archiveFile"
            }
            $summary.ArchivedLogs++
            Write-Log -Level INFO -Message ("Archived log '{0}' to '{1}' (size bytes: {2})" -f $logName, $archiveFile, $archiveInfo.Length)
        }
        catch {
            $summary.FailedLogs++
            $manifestEntries.Add([pscustomobject]@{
                LogName          = $logName
                RecordsDeleted   = 0
                ArchivePath      = $archiveFile
                ArchivedAt       = $null
                ClearedAt        = $null
                Status           = 'ArchiveValidationFailed'
                RolledBack       = $false
                RolledBackAt     = $null
            }) | Out-Null

            Write-Log -Level ERROR -Message ("Archive validation failed for '{0}': {1}" -f $logName, $_.Exception.Message)
            continue
        }

        try {
            & wevtutil.exe cl "$logName"
            if ($LASTEXITCODE -ne 0) {
                throw "wevtutil cl exit code $LASTEXITCODE"
            }
            $summary.ClearedLogs++

            $manifestEntries.Add([pscustomobject]@{
                LogName          = $logName
                RecordsDeleted   = $recordCount
                ArchivePath      = $archiveFile
                ArchivedAt       = (Get-Date).ToString('s')
                ClearedAt        = (Get-Date).ToString('s')
                Status           = 'ArchivedAndCleared'
                RolledBack       = $false
                RolledBackAt     = $null
            }) | Out-Null

            Write-Log -Level INFO -Message ("Cleared log '{0}' after successful archive. RecordsDeleted={1}" -f $logName, $recordCount)
        }
        catch {
            $summary.FailedLogs++

            $manifestEntries.Add([pscustomobject]@{
                LogName          = $logName
                RecordsDeleted   = 0
                ArchivePath      = $archiveFile
                ArchivedAt       = (Get-Date).ToString('s')
                ClearedAt        = $null
                Status           = 'ClearFailedAfterArchive'
                RolledBack       = $false
                RolledBackAt     = $null
            }) | Out-Null

            Write-Log -Level ERROR -Message ("Clear failed for '{0}' after archive. Manual review required. Error: {1}" -f $logName, $_.Exception.Message)
        }
    }
    catch {
        $summary.FailedLogs++
        Write-Log -Level ERROR -Message ("Unhandled cleanup error for '{0}': {1}" -f $logName, $_.Exception.Message)
    }
}

# Section 9: Persist manifest and print final summary.
# Stores transaction data for audit/rollback and reports outcome totals.
try {
    $manifest = [pscustomobject]@{
        TransactionId = $transactionId
        CreatedAt     = (Get-Date).ToString('s')
        RunDate       = $script:RunDate
        OlderThanDays = $OlderThanDays
        CutoffDate    = $cutoff.ToString('s')
        Entries       = @($manifestEntries)
    }

    $manifest | ConvertTo-Json -Depth 8 | Set-Content -Path $manifestPath -Encoding UTF8 -ErrorAction Stop
    Write-Log -Level INFO -Message ("Manifest written: {0}" -f $manifestPath)
}
catch {
    Write-Log -Level ERROR -Message ("Failed to write manifest: {0}" -f $_.Exception.Message)
}

Write-Host "`n=== Cleanup Summary ===" -ForegroundColor Cyan
$summary | Format-List

Write-Log -Level INFO -Message ("Summary: EvaluatedLogs={0}; CandidateLogs={1}; TotalRecordsToDelete={2}; ArchivedLogs={3}; ClearedLogs={4}; IdempotentSkipped={5}; FailedLogs={6}; TransactionId={7}" -f $summary.EvaluatedLogs, $summary.CandidateLogs, $summary.TotalRecordsToDelete, $summary.ArchivedLogs, $summary.ClearedLogs, $summary.IdempotentSkipped, $summary.FailedLogs, $summary.TransactionId)
Write-Log -Level INFO -Message 'Script completed (cleanup mode).'
