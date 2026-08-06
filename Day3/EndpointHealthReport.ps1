<#
.SYNOPSIS
Safely cleans temp files on Windows endpoints with dry-run, logging, and rollback.

.DESCRIPTION
This PowerShell 5.1 script removes temp files older than a configurable number of days.
For safety, files are moved to a rollback store (quarantine) rather than permanently deleted,
which allows restoration later by using the rollback mode.

Key features:
- Dry run mode to preview files.
- Configurable age filter via parameter (default 0 days).
- Locked files are skipped and logged.
- Per-file try/catch handling.
- Timestamped log file for every action.
- End-of-run summary.
- Rollback support per transaction.
- Idempotent behavior for cleanup and rollback.
#>

[CmdletBinding()]
param(
    # Dry run mode: list files that would be removed from temp paths.
    [switch]$DryRun,

    # Cleanup mode: only files older than this many days are targeted.
    [ValidateRange(0, 36500)]
    [int]$OlderThanDays = 0,

    # Paths to clean. Defaults to user temp and Windows temp.
    [string[]]$TargetPaths = @(
        $env:TEMP,
        "$env:WINDIR\Temp"
    ),

    # Root directory for timestamped action logs.
    [string]$LogDirectory = (Join-Path -Path $PSScriptRoot -ChildPath 'Logs'),

    # Root directory where files are staged for rollback.
    [string]$RollbackDirectory = (Join-Path -Path $PSScriptRoot -ChildPath 'RollbackStore'),

    # Rollback mode: restore files from a previous cleanup transaction.
    [switch]$Rollback,

    # Optional transaction ID to rollback; newest transaction is used when omitted.
    [string]$TransactionId
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Section 1: Initialize runtime metadata, folders, and logging.
# This section creates required directories and defines the centralized logger.
$script:RunTimestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$script:RunId = '{0}_{1}' -f $script:RunTimestamp, ([guid]::NewGuid().ToString('N').Substring(0, 8))

if (-not (Test-Path -LiteralPath $LogDirectory)) {
    New-Item -Path $LogDirectory -ItemType Directory -Force | Out-Null
}

if (-not (Test-Path -LiteralPath $RollbackDirectory)) {
    New-Item -Path $RollbackDirectory -ItemType Directory -Force | Out-Null
}

$script:LogFile = Join-Path -Path $LogDirectory -ChildPath ("TempCleanup_{0}.log" -f $script:RunTimestamp)

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
    Add-Content -Path $script:LogFile -Value $line
    Write-Host $line
}

# Section 2: Helper functions for file lock detection and path mapping.
# Test-FileLocked prevents deleting files currently in use, while Convert-ToSafeRelativePath
# preserves a deterministic path under rollback storage.
function Test-FileLocked {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    try {
        $stream = [System.IO.File]::Open($Path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None)
        $stream.Close()
        return $false
    }
    catch [System.IO.IOException] {
        return $true
    }
}

function Convert-ToSafeRelativePath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FullPath
    )

    $safe = $FullPath -replace ':', ''
    $safe = $safe.TrimStart('\\')
    return $safe
}

# Section 3: Rollback implementation.
# Reads a transaction manifest and restores files back to original locations.
# Designed to be idempotent: already restored/missing staged files are skipped safely.
function Invoke-TempFileRollback {
    [CmdletBinding()]
    param(
        [string]$RollbackDirectory,
        [string]$TransactionId
    )

    $manifestPath = $null

    if ($TransactionId) {
        $candidate = Join-Path -Path (Join-Path -Path $RollbackDirectory -ChildPath $TransactionId) -ChildPath 'manifest.json'
        if (Test-Path -LiteralPath $candidate) {
            $manifestPath = $candidate
        }
    }
    else {
        $allManifests = Get-ChildItem -Path $RollbackDirectory -Filter 'manifest.json' -File -Recurse -ErrorAction SilentlyContinue |
            Sort-Object -Property LastWriteTime -Descending
        if ($allManifests) {
            $manifestPath = $allManifests[0].FullName
        }
    }

    if (-not $manifestPath) {
        Write-Log -Level WARN -Message 'No rollback manifest was found. Nothing to restore.'
        return
    }

    Write-Log -Level INFO -Message ("Rollback manifest: {0}" -f $manifestPath)

    $manifest = Get-Content -Path $manifestPath -Raw | ConvertFrom-Json
    $entries = @($manifest.Entries)

    $stats = [pscustomobject]@{
        TotalEntries      = $entries.Count
        Restored          = 0
        AlreadyRestored   = 0
        MissingStagedFile = 0
        Failed            = 0
    }

    foreach ($entry in $entries) {
        if ($entry.Restored -eq $true) {
            $stats.AlreadyRestored++
            Write-Log -Level INFO -Message ("SKIP already restored: {0}" -f $entry.OriginalPath)
            continue
        }

        try {
            if (-not (Test-Path -LiteralPath $entry.StagedPath)) {
                $stats.MissingStagedFile++
                Write-Log -Level WARN -Message ("SKIP missing staged file: {0}" -f $entry.StagedPath)
                continue
            }

            $parent = Split-Path -Path $entry.OriginalPath -Parent
            if (-not (Test-Path -LiteralPath $parent)) {
                New-Item -Path $parent -ItemType Directory -Force | Out-Null
            }

            if (Test-Path -LiteralPath $entry.OriginalPath) {
                $stats.Failed++
                Write-Log -Level ERROR -Message ("RESTORE conflict, target exists: {0}" -f $entry.OriginalPath)
                continue
            }

            Move-Item -LiteralPath $entry.StagedPath -Destination $entry.OriginalPath -Force -ErrorAction Stop
            $entry.Restored = $true
            $entry.RestoredAt = (Get-Date).ToString('s')
            $stats.Restored++
            Write-Log -Level INFO -Message ("RESTORED: {0}" -f $entry.OriginalPath)
        }
        catch {
            $stats.Failed++
            Write-Log -Level ERROR -Message ("RESTORE failed for {0}: {1}" -f $entry.OriginalPath, $_.Exception.Message)
        }
    }

    $manifest.Entries = $entries
    $manifest | ConvertTo-Json -Depth 8 | Set-Content -Path $manifestPath -Encoding UTF8

    Write-Host "`n=== Rollback Summary ===" -ForegroundColor Cyan
    [pscustomobject]$stats | Format-List
    Write-Log -Level INFO -Message ("Rollback summary: Total={0}; Restored={1}; AlreadyRestored={2}; MissingStaged={3}; Failed={4}" -f $stats.TotalEntries, $stats.Restored, $stats.AlreadyRestored, $stats.MissingStagedFile, $stats.Failed)
}

# Section 4: Handle rollback mode early and exit.
# Cleanup logic is skipped when -Rollback is provided.
Write-Log -Level INFO -Message ("Script started. Mode={0}; DryRun={1}; OlderThanDays={2}" -f ($(if ($Rollback) { 'Rollback' } else { 'Cleanup' }), $DryRun.IsPresent, $OlderThanDays))

if ($Rollback) {
    Invoke-TempFileRollback -RollbackDirectory $RollbackDirectory -TransactionId $TransactionId
    Write-Log -Level INFO -Message 'Script completed (rollback mode).'
    return
}

# Section 5: Build candidate file list by age and target paths.
# This keeps discovery separate from action for predictable dry-run and summary output.
$cutoff = (Get-Date).AddDays(-$OlderThanDays)
$candidateFiles = New-Object System.Collections.Generic.List[System.IO.FileInfo]

foreach ($path in $TargetPaths) {
    if ([string]::IsNullOrWhiteSpace($path)) {
        continue
    }

    if (-not (Test-Path -LiteralPath $path)) {
        Write-Log -Level WARN -Message ("Target path does not exist: {0}" -f $path)
        continue
    }

    Write-Log -Level INFO -Message ("Scanning: {0}" -f $path)

    try {
        $files = Get-ChildItem -LiteralPath $path -File -Recurse -Force -ErrorAction SilentlyContinue |
            Where-Object { $_.LastWriteTime -lt $cutoff }

        foreach ($file in $files) {
            $candidateFiles.Add($file)
        }
    }
    catch {
        Write-Log -Level ERROR -Message ("Scan failed for {0}: {1}" -f $path, $_.Exception.Message)
    }
}

# Section 6: Dry-run mode.
# Lists files that would be removed without making any changes.
if ($DryRun) {
    Write-Host "`n=== Dry Run: Files That Would Be Removed ===" -ForegroundColor Yellow

    if ($candidateFiles.Count -eq 0) {
        Write-Host 'No files match the criteria.'
        Write-Log -Level INFO -Message 'Dry run found no matching files.'
    }
    else {
        foreach ($file in $candidateFiles) {
            $line = 'DRYRUN delete candidate: {0} | LastWriteTime={1} | SizeBytes={2}' -f $file.FullName, $file.LastWriteTime.ToString('s'), $file.Length
            Write-Host $line
            Write-Log -Level INFO -Message $line
        }
    }

    Write-Host "`n=== Dry Run Summary ===" -ForegroundColor Cyan
    [pscustomobject]@{
        Mode            = 'DryRun'
        OlderThanDays   = $OlderThanDays
        CutoffDate      = $cutoff
        CandidateFiles  = $candidateFiles.Count
        LogFile         = $script:LogFile
    } | Format-List

    Write-Log -Level INFO -Message ("Script completed (dry run). CandidateFiles={0}" -f $candidateFiles.Count)
    return
}

# Section 7: Cleanup execution.
# Moves each candidate file to rollback storage with per-file try/catch and lock checks.
$transactionId = '{0}_{1}' -f $script:RunTimestamp, ([guid]::NewGuid().ToString('N').Substring(0, 8))
$transactionRoot = Join-Path -Path $RollbackDirectory -ChildPath $transactionId
New-Item -Path $transactionRoot -ItemType Directory -Force | Out-Null

$manifestPath = Join-Path -Path $transactionRoot -ChildPath 'manifest.json'
$manifestEntries = New-Object System.Collections.Generic.List[object]

$summary = [pscustomobject]@{
    Mode             = 'Cleanup'
    OlderThanDays    = $OlderThanDays
    CutoffDate       = $cutoff
    CandidateFiles   = $candidateFiles.Count
    MovedToRollback  = 0
    LockedSkipped    = 0
    Failed           = 0
    TransactionId    = $transactionId
    RollbackManifest = $manifestPath
    LogFile          = $script:LogFile
}

foreach ($file in $candidateFiles) {
    try {
        if (-not (Test-Path -LiteralPath $file.FullName)) {
            Write-Log -Level INFO -Message ("SKIP already absent (idempotent): {0}" -f $file.FullName)
            continue
        }

        if (Test-FileLocked -Path $file.FullName) {
            $summary.LockedSkipped++
            Write-Log -Level WARN -Message ("SKIP locked file: {0}" -f $file.FullName)
            continue
        }

        $safeRelative = Convert-ToSafeRelativePath -FullPath $file.FullName
        $stagedPath = Join-Path -Path $transactionRoot -ChildPath $safeRelative
        $stagedDir = Split-Path -Path $stagedPath -Parent

        if (-not (Test-Path -LiteralPath $stagedDir)) {
            New-Item -Path $stagedDir -ItemType Directory -Force | Out-Null
        }

        if (Test-Path -LiteralPath $stagedPath) {
            $baseName = [System.IO.Path]::GetFileNameWithoutExtension($stagedPath)
            $ext = [System.IO.Path]::GetExtension($stagedPath)
            $dir = Split-Path -Path $stagedPath -Parent
            $stagedPath = Join-Path -Path $dir -ChildPath ("{0}_{1}{2}" -f $baseName, ([guid]::NewGuid().ToString('N').Substring(0, 6)), $ext)
        }

        Move-Item -LiteralPath $file.FullName -Destination $stagedPath -Force -ErrorAction Stop
        $summary.MovedToRollback++

        $manifestEntries.Add([pscustomobject]@{
            OriginalPath = $file.FullName
            StagedPath   = $stagedPath
            LastWriteTime = $file.LastWriteTime.ToString('s')
            SizeBytes    = $file.Length
            MovedAt      = (Get-Date).ToString('s')
            Restored     = $false
            RestoredAt   = $null
        }) | Out-Null

        Write-Log -Level INFO -Message ("MOVED to rollback: {0} -> {1}" -f $file.FullName, $stagedPath)
    }
    catch {
        $summary.Failed++
        Write-Log -Level ERROR -Message ("FAILED for {0}: {1}" -f $file.FullName, $_.Exception.Message)
    }
}

$manifest = [pscustomobject]@{
    TransactionId = $transactionId
    CreatedAt     = (Get-Date).ToString('s')
    OlderThanDays = $OlderThanDays
    CutoffDate    = $cutoff.ToString('s')
    Entries       = @($manifestEntries)
}

$manifest | ConvertTo-Json -Depth 8 | Set-Content -Path $manifestPath -Encoding UTF8
Write-Log -Level INFO -Message ("Manifest written: {0}" -f $manifestPath)

# Section 8: End-of-run summary output.
# Provides totals required for engineering reporting and auditability.
Write-Host "`n=== Cleanup Summary ===" -ForegroundColor Cyan
$summary | Format-List
Write-Log -Level INFO -Message ("Summary: Candidate={0}; Moved={1}; Locked={2}; Failed={3}; Transaction={4}" -f $summary.CandidateFiles, $summary.MovedToRollback, $summary.LockedSkipped, $summary.Failed, $summary.TransactionId)
Write-Log -Level INFO -Message 'Script completed (cleanup mode).'
