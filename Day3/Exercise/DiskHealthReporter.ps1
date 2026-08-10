<#
.SYNOPSIS
Read-only disk health reporter for DWP engineers (PowerShell 5.1).

.DESCRIPTION
Collects disk health and capacity information using read-only commands.
No changes are made to the endpoint.

IMPORTANT SAFETY GUARANTEE
- This script is strictly read-only.
- This script does NOT run defragmentation.
- This script does NOT call Optimize-Volume, defrag.exe, chkdsk /f, or any write operation.
#>

[CmdletBinding()]
param(
    # DryRun mode: show what the script would collect, then exit without querying system state.
    [switch]$DryRun
)

# Section: Safety banner and execution mode
# Explains execution mode and confirms that no repair/optimization actions are performed.
Write-Host "=== DWP Disk Health Reporter (Read-Only) ===" -ForegroundColor Cyan
if ($DryRun) {
    Write-Host "Mode: DRY RUN" -ForegroundColor Yellow
} else {
    Write-Host "Mode: LIVE READ-ONLY COLLECTION" -ForegroundColor Green
}
Write-Host "Safety: No write operations. Defragmentation is never executed." -ForegroundColor Green

# Section: DryRun simulation
# Displays exactly what data sources would be queried in live mode, then exits.
if ($DryRun) {
    Write-Host "" 
    Write-Host "The following read-only checks would run:" -ForegroundColor Yellow
    Write-Host "1. Get-CimInstance Win32_OperatingSystem (uptime/context)"
    Write-Host "2. Get-CimInstance Win32_LogicalDisk (drive free space)"
    Write-Host "3. Get-CimInstance Win32_DiskDrive (physical disk model/status)"
    Write-Host "4. Get-CimInstance Win32_DiskPartition (partition layout)"
    Write-Host "5. Get-CimInstance Win32_LogicalDiskToPartition (partition mapping)"
    Write-Host "6. Get-Volume (if available) for file system health and operational status"
    Write-Host "7. Get-PhysicalDisk (if available) for media/health status"
    Write-Host ""
    Write-Host "DryRun complete. No system queries executed." -ForegroundColor Yellow
    return
}

# Section: Initialize report metadata
# Captures context details used at the top of the report.
$reportTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$computerName = $env:COMPUTERNAME

# Section: Gather operating system context
# Retrieves basic OS details and uptime indicators for troubleshooting context.
$os = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction SilentlyContinue

# Section: Gather logical disk information
# Retrieves capacity and free space for local disks (DriveType 3 = local fixed disk).
$logicalDisks = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType = 3" -ErrorAction SilentlyContinue

# Section: Gather physical disk information
# Retrieves disk model/interface/size/status from WMI in a read-only manner.
$physicalDisks = Get-CimInstance -ClassName Win32_DiskDrive -ErrorAction SilentlyContinue

# Section: Gather partition mapping information
# Retrieves partition details and maps logical drives to partitions.
$partitions = Get-CimInstance -ClassName Win32_DiskPartition -ErrorAction SilentlyContinue
$logicalToPartition = Get-CimInstance -ClassName Win32_LogicalDiskToPartition -ErrorAction SilentlyContinue

# Section: Optionally gather modern storage cmdlet data
# Uses Get-Volume/Get-PhysicalDisk when available; safely skips if module/cmdlets are missing.
$volumeData = $null
$physicalDiskData = $null

if (Get-Command -Name Get-Volume -ErrorAction SilentlyContinue) {
    $volumeData = Get-Volume -ErrorAction SilentlyContinue
}

if (Get-Command -Name Get-PhysicalDisk -ErrorAction SilentlyContinue) {
    $physicalDiskData = Get-PhysicalDisk -ErrorAction SilentlyContinue
}

# Section: Print report header
# Displays high-level report context.
Write-Host ""
Write-Host "===== Disk Health Report =====" -ForegroundColor Cyan
Write-Host "Computer Name : $computerName"
Write-Host "Generated At  : $reportTime"
if ($os) {
    Write-Host "OS            : $($os.Caption) ($($os.Version))"
    $lastBootDisplay = $os.LastBootUpTime
    if ($os.LastBootUpTime -is [string]) {
        try {
            $lastBootDisplay = [Management.ManagementDateTimeConverter]::ToDateTime($os.LastBootUpTime)
        } catch {
            $lastBootDisplay = $os.LastBootUpTime
        }
    }
    Write-Host "Last Boot     : $lastBootDisplay"
}

# Section: Report logical disk utilization
# Calculates percentages and flags low free space thresholds.
Write-Host ""
Write-Host "--- Logical Disk Utilization ---" -ForegroundColor Cyan
if (-not $logicalDisks) {
    Write-Host "No logical disks returned." -ForegroundColor Yellow
} else {
    $logicalDisks |
        Sort-Object DeviceID |
        ForEach-Object {
            $sizeGB = [math]::Round($_.Size / 1GB, 2)
            $freeGB = [math]::Round($_.FreeSpace / 1GB, 2)
            $usedGB = [math]::Round(($sizeGB - $freeGB), 2)

            if ($_.Size -gt 0) {
                $freePct = [math]::Round(($_.FreeSpace / $_.Size) * 100, 1)
            } else {
                $freePct = 0
            }

            $status = "OK"
            if ($freePct -lt 10) {
                $status = "CRITICAL_LOW_FREE_SPACE"
            } elseif ($freePct -lt 20) {
                $status = "WARNING_LOW_FREE_SPACE"
            }

            "Drive {0} | FS: {1} | Size: {2} GB | Used: {3} GB | Free: {4} GB ({5}%) | Status: {6}" -f $_.DeviceID, $_.FileSystem, $sizeGB, $usedGB, $freeGB, $freePct, $status
        }
}

# Section: Report physical disk status from Win32_DiskDrive
# Shows model/serial/interface and current reported status for each physical disk.
Write-Host ""
Write-Host "--- Physical Disk Status (Win32_DiskDrive) ---" -ForegroundColor Cyan
if (-not $physicalDisks) {
    Write-Host "No physical disks returned." -ForegroundColor Yellow
} else {
    $physicalDisks |
        Sort-Object Index |
        ForEach-Object {
            $diskSizeGB = [math]::Round($_.Size / 1GB, 2)
            "Disk {0} | Model: {1} | Interface: {2} | Size: {3} GB | Status: {4}" -f $_.Index, $_.Model, $_.InterfaceType, $diskSizeGB, $_.Status
        }
}

# Section: Report logical-to-partition mapping
# Provides quick mapping from logical drives to physical partition references.
Write-Host ""
Write-Host "--- Logical Drive to Partition Mapping ---" -ForegroundColor Cyan
if (-not $logicalToPartition) {
    Write-Host "No drive-to-partition mapping returned." -ForegroundColor Yellow
} else {
    $logicalToPartition |
        ForEach-Object {
            "Antecedent: {0}" -f $_.Antecedent
            "Dependent : {0}" -f $_.Dependent
            ""
        }
}

# Section: Report volume health when Get-Volume is available
# Shows file system health and operational status from modern storage APIs.
Write-Host ""
Write-Host "--- Volume Health (Get-Volume, if available) ---" -ForegroundColor Cyan
if (-not $volumeData) {
    Write-Host "Get-Volume unavailable or returned no data." -ForegroundColor Yellow
} else {
    $volumeData |
        Sort-Object DriveLetter |
        ForEach-Object {
            $letter = if ($_.DriveLetter) { $_.DriveLetter + ":" } else { "(NoLetter)" }
            "Volume {0} | Label: {1} | FS: {2} | Health: {3} | Operational: {4}" -f $letter, $_.FileSystemLabel, $_.FileSystem, $_.HealthStatus, ($_.OperationalStatus -join ",")
        }
}

# Section: Report physical disk health when Get-PhysicalDisk is available
# Shows media and health status from Storage module when supported by endpoint.
Write-Host ""
Write-Host "--- Physical Disk Health (Get-PhysicalDisk, if available) ---" -ForegroundColor Cyan
if (-not $physicalDiskData) {
    Write-Host "Get-PhysicalDisk unavailable or returned no data." -ForegroundColor Yellow
} else {
    $physicalDiskData |
        Sort-Object FriendlyName |
        ForEach-Object {
            "Disk: {0} | MediaType: {1} | Health: {2} | Operational: {3} | Size: {4} GB" -f $_.FriendlyName, $_.MediaType, $_.HealthStatus, ($_.OperationalStatus -join ","), ([math]::Round($_.Size / 1GB, 2))
        }
}

# Section: Final safety statement
# Reiterates that this script did not attempt remediation, repairs, or optimization.
Write-Host ""
Write-Host "Report complete. This script performed read-only checks only." -ForegroundColor Green
Write-Host "No defragmentation, optimization, or repair action was run." -ForegroundColor Green
