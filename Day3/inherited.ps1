# Purpose: Collect quick local system health details (computer info, disk free space, top memory processes, recent system errors, stale user profiles).
# Author: Refactored by GitHub Copilot.
# How to run: Open PowerShell and execute `./inherited.ps1` from this folder, or run with a full path.
# Notes: This refactor improves readability only and keeps the original script behavior and output intent unchanged.

# Get computer system details such as machine name and total physical memory.
$computerSystem = Get-CimInstance Win32_ComputerSystem
# Get free space (bytes) from the C: drive.
$cDriveFreeBytes = Get-PSDrive C | Select-Object -ExpandProperty Free
# Get the top 5 running processes by working set memory usage.
$topMemoryProcesses = Get-Process | Sort-Object WS -Descending | Select-Object -First 5
# Get the most recent 10 system log events and keep only error-level events (Level 2).
$recentSystemErrors = Get-WinEvent -LogName System -MaxEvents 10 | Where-Object {$_.Level -eq 2}
# Get all user profiles and filter to non-special profiles not used in the last 90 days.
$staleUserProfiles = Get-CimInstance Win32_UserProfile | Where-Object {
     # Exclude system/special profiles and keep profiles older than 90 days since last use.
     -not $_.Special -and $_.LastUseTime -lt (Get-Date).AddDays(-90)}
# Output the computer name and total physical memory.
Write-Host $computerSystem.Name $computerSystem.TotalPhysicalMemory
# Output C: free space converted to GB and rounded to 2 decimal places.
Write-Host ([math]::Round($cDriveFreeBytes/1GB,2)) 'GB free'
# Output each of the top memory-consuming processes with process name and working set value.
$topMemoryProcesses | ForEach-Object { Write-Host $_.Name $_.WS }
# Output each recent system error with timestamp and message text.
$recentSystemErrors | ForEach-Object { Write-Host $_.TimeCreated $_.Message }
# If stale user profiles exist, output a summary count.
if ($staleUserProfiles.Count -gt 0) { Write-Host 'Stale profiles:' $staleUserProfiles.Count }
