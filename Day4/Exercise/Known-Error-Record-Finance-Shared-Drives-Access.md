# Known-Error Record: Finance Shared Drives Access

Symptom: Finance users cannot access shared drives, and mapped drive letters are not assigned during sign-in. Users report they cannot open the Finance shared location.

Cause: The drive mapping process was migrated from a USER-context GPO logon script to an Intune PowerShell script running as SYSTEM. In that context, the script could not access the UNC path at execution time and failed.

Scope: Finance users on DESKTOP-FB* devices in OU=Finance were affected. The incident affected 45 users.

Workaround: Apply the approved user-context mapping approach for the Finance scope to restore drive access. This was used to re-establish service during the incident.

Permanent fix: Keep Finance user drive mapping in USER context and not SYSTEM context. Implement script pre-checks for Workstation/network readiness, UNC reachability validation, and retry behavior before broad rollout.

How to spot it: Intune Management Extension/ScriptRunner shows Map-FinBridgeDrives.ps1 running as SYSTEM with UNC failure and exit code 1 ("Network name cannot be found") around login time. System logs show Event ID 7036 (Workstation service entered running state) after script failure, Event ID 98 for drive letter not assigned, and GroupPolicy Event ID 1500 processed successfully.