# Finance Shared Drives Access Communication

## Audience 1 — Non-technical executive
Your access and data are safe. Finance users could not reach shared drives for a short time after a drive setup change moved from the old sign-in method to a new device-based method. We corrected it and confirmed access was restored at 10:00 AM. No action is needed unless you still cannot open a shared drive, then contact IT.

## Audience 2 — Affected end-user team (10 people, non-technical)
Finance shared drive access stopped for a short time because the drive setup changed from the old sign-in method to a new device-based method. We fixed it and confirmed all Finance users could access the shared drives again at 10:00 AM. If you see the same issue again, try again after a few minutes and contact the Service Desk.

## Audience 3 — Engineer-to-engineer internal note
Incident: Finance shared drive access failure affecting 45 users on DESKTOP-FB* devices in OU=Finance.

Root cause: Drive mapping moved from a USER-context GPO logon script to an Intune PowerShell script running as SYSTEM. The script was not updated for SYSTEM context. UNC access to \\finbridge-fs01\Finance required Workstation service readiness and mapped user credentials, which were not available to SYSTEM at execution time.

Exact action taken: Applied the approved fix by correcting the drive-mapping deployment back to a user-context model for the Finance scope and restoring access for affected users.

Config detail: Intune Management Extension executed Map-FinBridgeDrives.ps1 as SYSTEM at 08:00:02. The script failed at 08:00:03 with exit code 1 and the error "Network name cannot be found." A Workstation service running-state event followed at 08:00:05, and NTFS Event ID 98 recorded that drive letter S: was not assigned. Group Policy processing was successful, so GP was not the fault domain.

Verification step: Operational confirmation was received at 10:00 AM that all Finance users could access the shared drives.

Preventive action needed: Keep user drive mappings in USER context, add pre-checks for Workstation service and UNC reachability, add retry logic for transient startup timing, validate execution context before rollout, and pilot changes on a small Finance ring before broad deployment.
