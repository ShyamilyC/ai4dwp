#Requires -Version 5.1
<#
.SYNOPSIS
    Read-only script to find and report large files on a Windows endpoint.

.DESCRIPTION
    Scans a specified path for files exceeding a configurable size threshold and
    produces a console report. This script is strictly read-only - it does not
    modify, move, or delete any files. A DryRun switch is provided to preview
    what would be reported before writing the CSV output file.

.PARAMETER ScanPath
    The root folder to scan. Defaults to the system drive (e.g. C:\).

.PARAMETER ThresholdMB
    File size threshold in megabytes. Files at or above this size are included
    in the report. Defaults to 100 MB.

.PARAMETER ReportPath
    Full path for the CSV output report. Defaults to the user's desktop.

.PARAMETER DryRun
    When specified, results are displayed on screen only - no CSV file is written.

.EXAMPLE
    .\Find-LargeFiles.ps1 -ScanPath "C:\Users" -ThresholdMB 50 -DryRun
    Scans C:\Users for files >= 50 MB and displays results without saving a report.

.EXAMPLE
    .\Find-LargeFiles.ps1 -ThresholdMB 200 -ReportPath "C:\Temp\LargeFiles.csv"
    Scans the system drive for files >= 200 MB and saves results to C:\Temp\LargeFiles.csv.

.NOTES
    - READ-ONLY: This script does not modify any files or system settings.
    - Requires read access to the folders being scanned.
    - Access-denied errors on protected folders are silently skipped and counted.
    - Compatible with PowerShell 5.1.
#>

[CmdletBinding(SupportsShouldProcess = $false)]
param (
    # Root path to scan; defaults to the system drive root
    [Parameter()]
    [ValidateScript({ Test-Path $_ -PathType Container })]
    [string]$ScanPath = "$env:SystemDrive\",

    # Minimum file size in MB to include in results
    [Parameter()]
    [ValidateRange(1, 1048576)]
    [int]$ThresholdMB = 100,

    # Output CSV path; defaults to the current user's Desktop
    [Parameter()]
    [string]$ReportPath = "$env:USERPROFILE\Desktop\LargeFiles_Report_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv",

    # When set, only display results on screen - do not write the CSV
    [Parameter()]
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'SilentlyContinue'   # Skip inaccessible paths without terminating

# ---------------------------------------------------------------------------
# Normalise ReportPath: if the caller supplied a directory instead of a file
# path, append a timestamped filename so Export-Csv has a valid target.
# ---------------------------------------------------------------------------
if ($ReportPath -match '[/\\]$' -or (Test-Path $ReportPath -PathType Container)) {
    $ReportPath = Join-Path $ReportPath ("LargeFiles_Report_" + (Get-Date -Format 'yyyyMMdd_HHmmss') + ".csv")
}

# Create the parent directory if it does not already exist
$reportDir = Split-Path $ReportPath -Parent
if ($reportDir -and -not (Test-Path $reportDir)) {
    New-Item -ItemType Directory -Path $reportDir -Force | Out-Null
}

# ---------------------------------------------------------------------------
# Banner - display run parameters so the engineer knows what is being scanned
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Large File Finder  (READ-ONLY)"        -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Scan path    : $ScanPath"
Write-Host "  Threshold    : $ThresholdMB MB ($([math]::Round($ThresholdMB * 1MB / 1GB, 3)) GB)"
if ($DryRun) {
    Write-Host "  Mode         : DRY RUN - no report file will be saved" -ForegroundColor Yellow
} else {
    Write-Host "  Report output: $ReportPath"
}
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# ---------------------------------------------------------------------------
# Convert the MB threshold to bytes once for efficient per-file comparison
# ---------------------------------------------------------------------------
$ThresholdBytes = $ThresholdMB * 1MB

# ---------------------------------------------------------------------------
# Counters for the summary section printed at the end of the run
# ---------------------------------------------------------------------------
$totalScanned   = 0
$accessDenied   = 0
$largeFileCount = 0

# ---------------------------------------------------------------------------
# Recursively enumerate all files under ScanPath.
# -Force includes hidden/system files. -ErrorVariable captures access errors.
# The results are filtered immediately to files >= threshold to keep memory use low.
# ---------------------------------------------------------------------------
Write-Host "Scanning '$ScanPath' - this may take a few minutes on large drives..." -ForegroundColor Gray
Write-Host ""

$largeFiles = Get-ChildItem -Path $ScanPath -Recurse -Force -File `
                -ErrorVariable accessErrors `
    | ForEach-Object {
        $totalScanned++

        # Only pass through files that meet or exceed the size threshold
        if ($_.Length -ge $ThresholdBytes) {
            $largeFileCount++
            # Inline try/catch is not valid inside a hashtable in PS 5.1; resolve owner first
            $owner = try { (Get-Acl $_.FullName).Owner } catch { 'N/A' }
            [PSCustomObject]@{
                'File Name'      = $_.Name
                'Size (MB)'      = [math]::Round($_.Length / 1MB, 2)
                'Size (GB)'      = [math]::Round($_.Length / 1GB, 3)
                'Last Modified'  = $_.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss')
                'Owner'          = $owner
                'Full Path'      = $_.FullName
            }
        }
    }

# Count access-denied errors recorded during enumeration
$accessDenied = $accessErrors.Count

# ---------------------------------------------------------------------------
# Sort results largest-first so the most impactful files appear at the top
# ---------------------------------------------------------------------------
$largeFiles = $largeFiles | Sort-Object 'Size (MB)' -Descending

# ---------------------------------------------------------------------------
# Display results to the console regardless of DryRun mode
# ---------------------------------------------------------------------------
if ($largeFiles.Count -eq 0) {
    Write-Host "No files found at or above $ThresholdMB MB." -ForegroundColor Green
} else {
    Write-Host "Files found at or above $ThresholdMB MB (sorted largest first):" -ForegroundColor Green
    Write-Host ""

    # Format-Table with AutoSize keeps columns readable in the console
    $largeFiles | Format-Table -AutoSize -Property 'File Name', 'Size (MB)', 'Last Modified', 'Full Path'
}

# ---------------------------------------------------------------------------
# Save report to CSV unless DryRun is active
# ---------------------------------------------------------------------------
if (-not $DryRun) {
    if ($largeFiles.Count -gt 0) {
        try {
            # Export-Csv only writes the report file - no scanned files are modified
            $largeFiles | Export-Csv -Path $ReportPath -NoTypeInformation -Encoding UTF8
            Write-Host "Report saved : $ReportPath" -ForegroundColor Green
        } catch {
            Write-Warning "Could not write report to '$ReportPath'. Error: $_"
        }
    } else {
        Write-Host "No large files found - report file not created." -ForegroundColor Yellow
    }
} else {
    Write-Host "[DRY RUN] Report file was NOT saved. Remove -DryRun to generate the CSV." -ForegroundColor Yellow
}

# ---------------------------------------------------------------------------
# Summary - print a compact run summary for the engineer's records
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Scan Summary"                           -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Files scanned          : $totalScanned"
Write-Host "  Large files found      : $largeFileCount"
Write-Host "  Access-denied paths    : $accessDenied"
Write-Host "  Threshold applied      : $ThresholdMB MB"
Write-Host "  Scan root              : $ScanPath"
if ($DryRun) {
    Write-Host "  Report saved           : No (Dry Run)" -ForegroundColor Yellow
} elseif ($largeFileCount -gt 0) {
    Write-Host "  Report saved           : $ReportPath" -ForegroundColor Green
} else {
    Write-Host "  Report saved           : No (no large files found)"
}
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
