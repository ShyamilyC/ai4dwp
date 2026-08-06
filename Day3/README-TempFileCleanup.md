# Temp File Cleanup Script (PowerShell 5.1)

This folder contains a safe temp cleanup script for Windows endpoints:

- Script: `TempFileCleanup.ps1`

The script is designed for DWP engineers and includes:
- Dry run mode
- Age-based filtering
- Per-file error handling
- Locked-file skip behavior
- Timestamped logging
- End-of-run summary
- Rollback support
- Idempotent execution

## Script Parameters

### `-DryRun`
Shows which files would be removed, without moving/deleting anything.

### `-OlderThanDays <int>`
Only targets files older than the specified number of days.
Default: `0`

### `-TargetPaths <string[]>`
One or more folders to scan recursively for files.
Default values:
- `$env:TEMP`
- `$env:WINDIR\Temp`

### `-LogDirectory <string>`
Directory where timestamped log files are written.
Default: `.\Logs` relative to script folder.

### `-RollbackDirectory <string>`
Directory used to stage removed files for rollback.
Default: `.\RollbackStore` relative to script folder.

### `-Rollback`
Runs rollback mode instead of cleanup mode.
When used, the script restores files from a rollback transaction manifest.

### `-TransactionId <string>`
Optional transaction ID to rollback a specific cleanup run.
If omitted with `-Rollback`, the script uses the newest transaction.

## Usage Examples

### 1. Dry run (preview only)
```powershell
powershell -ExecutionPolicy Bypass -File .\TempFileCleanup.ps1 -DryRun -OlderThanDays 7
```

### 2. Cleanup files older than 7 days
```powershell
powershell -ExecutionPolicy Bypass -File .\TempFileCleanup.ps1 -OlderThanDays 7
```

### 3. Cleanup custom paths
```powershell
powershell -ExecutionPolicy Bypass -File .\TempFileCleanup.ps1 -OlderThanDays 14 -TargetPaths "C:\Temp","C:\Windows\Temp"
```

### 4. Roll back latest transaction
```powershell
powershell -ExecutionPolicy Bypass -File .\TempFileCleanup.ps1 -Rollback
```

### 5. Roll back a specific transaction
```powershell
powershell -ExecutionPolicy Bypass -File .\TempFileCleanup.ps1 -Rollback -TransactionId 20260805_120102_ab12cd34
```

## Output and Logging

- Log file format: `TempCleanup_yyyyMMdd_HHmmss.log`
- Log location: `Logs` folder (or custom `-LogDirectory`)
- Rollback manifest location:
  `RollbackStore\<TransactionId>\manifest.json`

Each run logs:
- Start mode and parameters
- Path scans
- Per-file outcomes (moved/skipped/failed)
- Rollback actions
- Final summary

## Safety and Idempotency Notes

- Files are moved into rollback storage, not permanently deleted.
- Locked files are skipped and logged.
- Re-running cleanup safely skips files that are already absent.
- Re-running rollback safely skips already-restored entries.

## Recommended Operational Flow

1. Run with `-DryRun` first.
2. Review candidate files and log output.
3. Run cleanup without `-DryRun`.
4. If needed, restore using `-Rollback`.
