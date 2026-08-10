# Find-LargeFiles.ps1

Read-only PowerShell 5.1 script for DWP engineers to locate and report large files on a Windows endpoint. The script never modifies, moves, or deletes any file.

> **v1.1 changes:** Script is now saved as ASCII to prevent PowerShell 5.1 encoding errors on systems using the default Windows code page. The `Owner` field lookup (`Get-Acl`) was moved outside the hashtable literal, which is required for PS 5.1 compatibility. `-ReportPath` now accepts a bare directory path and auto-appends a timestamped filename; parent directories are created automatically if they do not exist.

---

## Requirements

- PowerShell 5.1 or later
- Read access to the folder being scanned
- Write access to the report output path (only needed when not using `-DryRun`)

---

## Parameters

| Parameter | Type | Default | Description |
|---|---|---|---|
| `-ScanPath` | String | `C:\` (system drive root) | The root folder to scan recursively. Must be a valid, accessible directory. |
| `-ThresholdMB` | Integer | `100` | Minimum file size in megabytes to include in the report. Accepted range: 1 – 1,048,576 MB. |
| `-ReportPath` | String | `%USERPROFILE%\Desktop\LargeFiles_Report_<timestamp>.csv` | Full file path **or directory path** where the CSV report will be saved. If a directory is supplied (path ends with `\`), a timestamped filename is appended automatically. The directory is created if it does not exist. |
| `-DryRun` | Switch | Off | When specified, results are printed to the console only. No CSV file is created. Use this to preview results safely before committing to a saved report. |

---

## Usage Examples

### Preview only (no file written)
```powershell
.\Find-LargeFiles.ps1 -DryRun
```

### Scan a specific folder with the default 100 MB threshold
```powershell
.\Find-LargeFiles.ps1 -ScanPath "C:\Users" -DryRun
```

### Change the threshold to 50 MB, dry run
```powershell
.\Find-LargeFiles.ps1 -ScanPath "C:\Users" -ThresholdMB 50 -DryRun
```

### Full scan and save report to a custom location
```powershell
.\Find-LargeFiles.ps1 -ThresholdMB 200 -ReportPath "C:\Temp\LargeFiles.csv"
```

### Scan a single user's profile and save report to the desktop
```powershell
.\Find-LargeFiles.ps1 -ScanPath "C:\Users\jsmith" -ThresholdMB 100
```

---

## Output

### Console
Results are always printed to the console, sorted largest file first, showing:
- File name
- Size in MB
- Last modified date
- Full path

### CSV Report (when `-DryRun` is not used)
A UTF-8 encoded CSV is written to `-ReportPath` containing:

| Column | Description |
|---|---|
| File Name | Name of the file including extension |
| Size (MB) | File size rounded to 2 decimal places |
| Size (GB) | File size rounded to 3 decimal places |
| Last Modified | Date and time the file was last written (yyyy-MM-dd HH:mm:ss) |
| Owner | Windows ACL owner of the file, or `N/A` if unreadable |
| Full Path | Absolute path to the file |

### Summary
After the scan completes, a summary is printed showing total files scanned, large files found, access-denied path count, and whether a report was saved.

---

## Safety Notes

- **Read-only**: The script uses `Get-ChildItem` and `Get-Acl` only - no write operations are performed on scanned files.
- **Access-denied paths**: Folders the script cannot access (e.g. protected system directories) are silently skipped. The count of skipped paths is shown in the summary.
- **Hidden and system files**: Included in the scan via the `-Force` flag, giving a complete picture of disk usage.
- **No elevation required**: The script runs under the current user's permissions. Running as Administrator will provide broader access to protected paths.
- **Encoding**: The script is saved as ASCII. Do not re-save it as UTF-8 without BOM, as PowerShell 5.1 will misread non-ASCII characters and fail to parse the file.
