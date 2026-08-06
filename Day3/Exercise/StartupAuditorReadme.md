# Startup Auditor

PowerShell 5.1 script to audit Windows startup programs, disable selected items, and roll back changes safely.

## Files

- `StartupAuditor.ps1` - Main script
- Rollback state is stored at:
  - `C:\ProgramData\DWP\StartupAuditor\state.json`

## Features

- **Dry run** mode to list startup items
- **Disable** mode to disable a startup program by name
- **Rollback** support for one item or all items
- **Idempotent** behavior:
  - disabling an already-disabled item does nothing
  - rolling back an already-restored item does nothing

## Supported Startup Locations

The script checks:

- `HKCU:\Software\Microsoft\Windows\CurrentVersion\Run`
- `HKLM:\Software\Microsoft\Windows\CurrentVersion\Run`
- `HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Run`
- Current user Startup folder
- All users Startup folder

## Usage

Open PowerShell 5.1.

For machine-wide startup items, run PowerShell as **Administrator**.

### 1. List startup items

````powershell
.\StartupAuditor.ps1 -DryRun
````
