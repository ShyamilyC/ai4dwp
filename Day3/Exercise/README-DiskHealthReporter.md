# README - DiskHealthReporter.ps1

## Purpose
`DiskHealthReporter.ps1` is a **read-only** disk health reporting script for DWP engineers.
It collects disk and volume information for diagnostics and capacity checks.

## Safety
- The script is strictly read-only.
- The script never runs defragmentation.
- The script does not run repair/optimization actions.
- The script does not call `Optimize-Volume`, `defrag.exe`, or `chkdsk /f`.

## Script Options

### `-DryRun`
Use this switch to run in simulation mode.

What it does:
- Prints the list of checks the script would perform.
- Exits without querying disk/volume state.

When to use it:
- Before first use on an endpoint.
- When validating safe behavior in change-controlled environments.

Example:
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ".\DiskHealthReporter.ps1" -DryRun
```

## Default Behavior (No Options)
If you run the script with no parameters, it performs a live **read-only** data collection.

It reports:
- OS context and last boot time.
- Logical disk capacity and free-space percentages.
- Physical disk model, interface, size, and status.
- Logical drive to partition mappings.
- Volume health (`Get-Volume`) when available.
- Physical disk health (`Get-PhysicalDisk`) when available.

Example:
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ".\DiskHealthReporter.ps1"
```

## Output Notes
- Output is written to the console.
- Low free-space thresholds in the report:
  - `< 20%` free: warning
  - `< 10%` free: critical

## Requirements
- Windows PowerShell 5.1.
- Standard endpoint permissions that allow read access to WMI/CIM and storage data.

## File Location
- Script: `Day3/Exercise/DiskHealthReporter.ps1`
- This README: `Day3/Exercise/README-DiskHealthReporter.md`
