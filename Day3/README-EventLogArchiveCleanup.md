# Event Log Archive and Cleanup (PowerShell 5.1)

This document explains how to use the Day3 script:

- Script: `EventLogArchiveCleanup.ps1`
- Purpose: Safely archive and clean Windows event logs on endpoints
- Safety controls: dry run, age filter, idempotent archive skip, detailed logging, rollback artifacts

## Script Location

- `Day3/EventLogArchiveCleanup.ps1`

## What the Script Does

1. Evaluates event logs and selects only logs whose newest event is older than the cutoff date.
2. Exports candidate logs to EVTX archive files.
3. Clears source logs only after successful archive and archive validation.
4. Writes a transaction manifest for audit and rollback artifact recovery.
5. Prints an end summary.

## Parameters

### `-DryRun` (switch)

- Preview mode.
- No archive or clear is performed.
- Outputs per-log and total record counts that would be deleted.

### `-OlderThanDays` (int, default: `3`)

- Cutoff control for cleanup eligibility.
- Only logs where the newest event is older than this value are candidates.
- Valid range: `1..36500`.

### `-LogNames` (string[])

- Optional list of specific logs to evaluate.
- If omitted, script evaluates enabled administrative/operational/classic logs.

Example:

```powershell
-LogNames Application,System
```

### `-LogDirectory` (string)

- Folder for timestamped run logs.
- Default: `Day3/Logs` (relative to script folder).

### `-ArchiveDirectory` (string)

- Folder root for EVTX archives.
- Default: `Day3/EventLogArchives`.
- Script creates a date subfolder per run date (format `yyyyMMdd`).

### `-RollbackDirectory` (string)

- Folder root for rollback transaction manifests and recovered artifacts.
- Default: `Day3/RollbackStore`.

### `-Rollback` (switch)

- Activates rollback mode.
- Reads latest manifest (or a specific one via `-TransactionId`) and recovers archived EVTX files into a `Recovered` folder under that transaction.

### `-TransactionId` (string)

- Optional transaction identifier for rollback mode.
- If omitted with `-Rollback`, latest manifest is used.

## Idempotency Behavior

To avoid duplicate same-day exports:

- If today’s archive file already exists for a log, that log is skipped.
- Skip is logged and counted in summary (`IdempotentSkipped`).

## Logging and Audit

Each run creates:

1. A timestamped action log in `Day3/Logs`.
2. A transaction manifest (`manifest.json`) in `Day3/RollbackStore/<TransactionId>/`.

Manifest entries include log name, archive path, status, and timestamps.

## Rollback Note (Important)

Windows built-in channels do not support reinserting archived events back into live event logs.

Rollback mode in this script:

- Recovers archived EVTX files from a transaction into a `Recovered` folder.
- Preserves investigation and evidence artifacts.
- Does not write historical entries back into live channels.

## Usage Examples

### 1. Dry run with default age (3 days)

```powershell
powershell -ExecutionPolicy Bypass -File .\Day3\EventLogArchiveCleanup.ps1 -DryRun
```

### 2. Cleanup with default options

```powershell
powershell -ExecutionPolicy Bypass -File .\Day3\EventLogArchiveCleanup.ps1
```

### 3. Cleanup with 7-day threshold

```powershell
powershell -ExecutionPolicy Bypass -File .\Day3\EventLogArchiveCleanup.ps1 -OlderThanDays 7
```

### 4. Target specific logs only

```powershell
powershell -ExecutionPolicy Bypass -File .\Day3\EventLogArchiveCleanup.ps1 -LogNames Application,System
```

### 5. Rollback using latest transaction

```powershell
powershell -ExecutionPolicy Bypass -File .\Day3\EventLogArchiveCleanup.ps1 -Rollback
```

### 6. Rollback using specific transaction

```powershell
powershell -ExecutionPolicy Bypass -File .\Day3\EventLogArchiveCleanup.ps1 -Rollback -TransactionId 20260805_130015_1a2b3c4d
```

## Summary Output Fields

Cleanup mode reports:

- `EvaluatedLogs`
- `CandidateLogs`
- `TotalRecordsToDelete`
- `ArchivedLogs`
- `ClearedLogs`
- `IdempotentSkipped`
- `FailedLogs`
- `TransactionId`
- `ManifestPath`
- `LogFile`

Dry run mode reports:

- `EvaluatedLogs`
- `CandidateLogs`
- `TotalRecordsToDelete`
- `CutoffDate`
- `LogFile`

## Operational Tips

1. Run from elevated PowerShell for best access to all channels.
2. Start with `-DryRun` in production-like environments.
3. Keep archive and rollback folders on storage with adequate capacity.
4. Consider scheduling during low-activity windows.
