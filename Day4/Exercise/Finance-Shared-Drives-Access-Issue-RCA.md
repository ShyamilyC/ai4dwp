# Root Cause Analysis (RCA)

## Incident Title
Finance Team Unable to Access Shared Drives

## Document Control
- Date: 2026-08-07
- Incident date: 2026-08-06
- Service area: End User Compute / Endpoint Configuration / File Share Access
- Affected group: Finance users (DESKTOP-FB* devices, OU=Finance)
- Affected users count: 45
- Incident status: Resolved
- Service restored: 10:00 AM

## Executive Summary
At approximately 08:00, Finance users lost access to mapped shared drives. Evidence from Intune Management Extension and System logs showed that the drive mapping script executed under SYSTEM context after a prior migration from a USER-context GPO logon script to an Intune PowerShell deployment. The script attempted UNC access before required user credential context and before Workstation service readiness at that execution point, then failed with no retry. The issue was resolved by applying the approved resolution approach and restoring user-context mapping behavior; confirmation was received at 10:00 AM that all Finance users could access shared drives.

## Impact Assessment
- Business impact: Finance users unable to access required shared drives for normal operations.
- User impact: 45 users affected.
- Scope impact: Broad, policy-level impact across Finance-managed endpoints, not isolated to a single machine.
- Duration: Approximately 2 hours (from first observed failures around 08:00 to confirmed restoration at 10:00).

## Supporting Evidence

### A) Intune Management Extension / ScriptRunner Evidence
- [08:00:01] ScriptRunner Info: Executing Map-FinBridgeDrives.ps1
- [08:00:02] ScriptRunner Info: Script context: SYSTEM account
- [08:00:03] ScriptRunner Warning: Network path \\finbridge-fs01\Finance not accessible from SYSTEM context at execution time
- [08:00:03] ScriptRunner Error: Script failed. Exit code: 1. Error: Network name cannot be found.
- [08:00:04] ScriptRunner Info: No retry configured

### B) System Log Evidence (DESKTOP-FB041)
- [08:00:05] Service Control Manager Event ID 7036: Workstation service entered running state
- [08:00:06] GroupPolicy Event ID 1500: Group Policy settings processed successfully
- [08:00:07] Ntfs Event ID 98 Warning: Could not map drive letter S: drive letter not assigned

### C) Prior Change Record Evidence
- [2024-03-14 23:30] Change note: Drive mapping script migrated from GPO logon script (runs as USER) to Intune PowerShell script (runs as SYSTEM).
- Change note also states script was not updated for SYSTEM context and UNC dependencies at login time.

### D) Resolution Confirmation Evidence
- [10:00] Operational update received: All Finance team users can access shared drives.

## Timeline (All times local)
- 08:00:01: Intune script execution begins (Map-FinBridgeDrives.ps1).
- 08:00:02: Script confirms SYSTEM execution context.
- 08:00:03: UNC path access fails from SYSTEM context; script exits with code 1.
- 08:00:04: Log confirms no retry mechanism configured.
- 08:00:05: Workstation service reaches running state (after script failure).
- 08:00:06: Group Policy processing success logged (rules out GP processing fault).
- 08:00:07: NTFS warning indicates drive letter S: not assigned.
- 10:00:00: Post-fix confirmation received that all Finance users can access shared drives.

## Root Cause Statement
The primary root cause was an execution-context design mismatch introduced during script migration: a user-intent drive mapping process was moved from USER-context GPO execution to SYSTEM-context Intune execution without updating logic for context, service timing, and authentication dependencies. As a result, UNC access failed at execution time and drive mapping did not complete for users.

## Contributing Factors
- Script executed under SYSTEM account rather than signed-in user.
- Workstation service became ready only after the script had already failed.
- No retry logic present to recover from transient startup readiness conditions.
- Broad assignment scope caused simultaneous impact to all Finance users.
- Change validation gaps for context-sensitive login mappings.

## 5 Whys Analysis
1. Why could Finance users not access shared drives?
Because the drive mapping to shared UNC paths failed and the drive letter was not assigned.

2. Why did drive mapping fail?
Because Map-FinBridgeDrives.ps1 ran in SYSTEM context and could not access the UNC path at execution time.

3. Why did it run in SYSTEM context?
Because the mapping solution was migrated from USER-context GPO logon script to Intune PowerShell script configured to run as SYSTEM.

4. Why was this not handled safely during migration?
Because the script and deployment model were not adapted for context-specific dependencies (user credentials, Workstation/network readiness, retry behavior).

5. Why was the issue not prevented before broad rollout?
Because change controls lacked mandatory checks for execution context suitability and first-logon dependency testing for mapped drive scenarios.

## Corrective Actions Implemented
- Removed/paused failing SYSTEM-context behavior for affected scope.
- Applied user-appropriate mapping execution model per approved resolution path.
- Re-established access for Finance users.
- Confirmed service restoration at 10:00 with all affected users able to access shared drives.

## Preventive Actions

### A) Technical Controls
1. Standardize mapped drive deployments to run in USER context for user resources.
2. Add pre-check for Workstation service and network readiness before mapping.
3. Add UNC reachability validation before attempting map operations.
4. Add bounded retry logic with clear logging and exit codes.
5. Ensure mapping scripts are idempotent and can remediate stale mappings safely.

### B) Change and Release Controls
1. Add mandatory execution-context review (USER vs SYSTEM) to change template.
2. Require pilot validation on representative users/devices before full deployment.
3. Require first-logon timing tests for scripts dependent on network/service readiness.
4. Add rollback criteria and rollback playbook to all endpoint script migrations.

### C) Monitoring and Operations
1. Create alerting for repeated script exit code 1 on drive mapping packages.
2. Add dashboard checks for finance endpoint mapping success rate.
3. Track Event IDs 7036, 98, and script failure signatures during deployment windows.
4. Add post-change verification checkpoint at 30 and 120 minutes.

## Verification of Recovery
- Functional verification: Finance users confirmed successful access to shared drives.
- Scope verification: Applies to all impacted users in Finance group.
- Time of confirmed recovery: 10:00 AM.

## Residual Risk
- Low residual risk after correction, provided preventive controls are enforced.
- Moderate process risk remains if future migrations bypass context and startup-dependency validation.

## Lessons Learned
- User-resource mappings are context-sensitive and should not be moved to SYSTEM execution without explicit redesign.
- Startup timing dependencies must be treated as first-class requirements for login-time automation.
- Broad-scope policy changes require pilot gates and telemetry-backed go/no-go criteria.
