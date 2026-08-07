# Finance Shared Drives Access Issue - Analysis and Hypothesis

Date: 2026-08-06
Issue: Finance team cannot access shared drives
Affected users: 45

## Scope Facts
- Drive mapping script migrated from GPO logon script (runs as USER) to Intune PowerShell script (runs as SYSTEM).
- Script was not updated for SYSTEM context.
- UNC network paths require Workstation service and mapped credentials that are not available to SYSTEM at login time.

## Ranked Most Likely Causes (Most Probable First)

### 1) Script runs in SYSTEM context instead of USER context
Why this fits the scope facts:
- The change note explicitly confirms context changed from USER to SYSTEM.
- Drive mappings for user access are typically user-session scoped and rely on user credentials.
- A wide impact (45 users) aligns with a centrally deployed context error.

Single fastest check:
- On one affected endpoint, verify script execution identity in Intune Management Extension logs/transcript and confirm it ran as `NT AUTHORITY\\SYSTEM`.

### 2) SYSTEM context cannot authenticate to UNC shares with user-mapped credentials
Why this fits the scope facts:
- SYSTEM does not carry the signed-in user's network token/credential mapping at login.
- UNC path access in mapping logic can fail or behave differently under SYSTEM.
- This directly matches the documented migration risk.

Single fastest check:
- On one affected endpoint, compare `Test-Path \\fileserver\\share` run as SYSTEM versus run as an affected user.

### 3) Mapped drives created under SYSTEM are invisible in user session
Why this fits the scope facts:
- Even if mapping succeeds under SYSTEM, mappings are tied to that account/session.
- Users can still report drive access failure because they do not see SYSTEM-scoped mappings.

Single fastest check:
- Compare `net use` output in SYSTEM context and in the logged-in user context on the same device.

### 4) Workstation service/network readiness timing at script execution causes failures
Why this fits the scope facts:
- Scope facts call out dependency on Workstation service for UNC.
- Intune/system startup timing can run before network stack/services are fully ready.
- That can cause mapping failures during login window.

Single fastest check:
- Check `LanmanWorkstation` state and startup/script execution timing in Event Viewer on an affected machine.

### 5) Intune script configuration mode mismatch (device/system deployment for user-intent mapping)
Why this fits the scope facts:
- Migration from GPO user logon to Intune system script introduces execution-mode risk.
- Policy-level misconfiguration explains broad, simultaneous impact.

Single fastest check:
- In Intune script settings, verify run context (`Run this script using the logged on credentials`) and assignment scope.

## Note
- This is a ranked hypothesis list based only on scope facts.
- No single cause is confirmed yet; checks above are intended to quickly confirm or eliminate each possibility.

## Evidence-Based Elimination (Using Provided Event Logs)

Evidence set:
- Source: Intune Management Extension Log + System Log
- Affected: All Finance users (DESKTOP-FB* devices, OU=Finance)

### Hypothesis 1) Script runs in SYSTEM context instead of USER context
Judgement: Supports

Determining evidence:
- [08:00:02] ScriptRunner Info: Script context: SYSTEM account
- [08:00:07] Ntfs Event 98 Warning: Drive letter S: has not been assigned

Why:
- Execution identity is explicitly SYSTEM, matching the hypothesis.
- Drive mapping failure symptom is observed afterward.

### Hypothesis 2) SYSTEM context cannot authenticate/access UNC with user-mapped credentials
Judgement: Supports

Determining evidence:
- [08:00:03] ScriptRunner Warning: Network path \\finbridge-fs01\Finance not accessible from SYSTEM context at execution time
- [08:00:03] ScriptRunner Error: Exit code 1. Error: Network name cannot be found.
- [08:00:05] Service Control Manager Event 7036: Workstation service entered running state

Why:
- Direct log message states UNC access failure from SYSTEM context.
- Workstation service readiness occurs after failure timestamp.

### Hypothesis 3) Mapped drives created under SYSTEM are invisible in user session
Judgement: Contradicts

Determining evidence:
- [08:00:03] ScriptRunner Error: Script failed (Exit code 1)
- [08:00:07] Ntfs Event 98 Warning: Drive letter S: has not been assigned

Why:
- Evidence indicates mapping did not succeed at all, rather than succeeding only in SYSTEM scope.

### Hypothesis 4) Workstation service/network readiness timing at script execution causes failure
Judgement: Supports

Determining evidence:
- [08:00:03] ScriptRunner Warning/Error: UNC path inaccessible; script failed
- [08:00:05] Service Control Manager Event 7036: Workstation service entered running state
- [08:00:04] ScriptRunner Info: No retry configured

Why:
- Failure precedes Workstation running state.
- Lack of retry means transient startup timing issue is not recovered.

### Hypothesis 5) Intune script execution-mode mismatch for user-intent drive mapping
Judgement: Supports

Determining evidence:
- [08:00:02] ScriptRunner Info: Script context: SYSTEM account
- [08:00:06] GroupPolicy Event 1500: Group Policy settings processed successfully
- Prior change note (2024-03-14 23:30): migration from USER GPO logon script to SYSTEM Intune script without context adaptation

Why:
- Evidence confirms SYSTEM-context execution and rules out GP processing as the fault domain.
- Change note aligns exactly with observed behavior.

## Surviving Hypothesis

The surviving hypothesis is:
- Intune execution-mode mismatch after migration (script runs as SYSTEM instead of USER), causing UNC mapping failure at login due to missing user credential context and startup timing dependencies.

## Detailed Resolution Steps

### 1) Immediate containment
1. Pause/disable the failing Intune SYSTEM-context script assignment for Finance scope.
2. Restore temporary user access via prior USER-context mapping method (for example, temporary GPO/user-targeted policy).
3. Send short incident communication: mitigation in place, permanent fix in progress.

### 2) Correct deployment mode
1. Re-deploy mapping logic in USER context.
2. In Intune script configuration, run using logged-on user credentials.
3. Prefer user-group targeting (Finance users) for user-mapped resources.
4. Trigger at user sign-in rather than device startup-only execution.

### 3) Harden script behavior
1. Add pre-check for Workstation service state and network availability.
2. Validate UNC path reachability before mapping.
3. Add retry logic (example: 3 retries with short delay).
4. Add explicit logging and exit codes for pre-check, map, verify, retry, fail stages.
5. Make mapping idempotent (repair/remove stale mapping then map cleanly).

### 4) Pilot validation
1. Deploy to a small Finance pilot ring (3-5 users/devices).
2. Validate first-logon mapping success and access.
3. Confirm logs show USER context and successful UNC pre-check.
4. Check for absence of new drive-letter mapping warnings.

### 5) Controlled rollout
1. Roll out in phased batches to remaining Finance users.
2. Monitor failure rate after each batch before broadening scope.
3. Keep rollback path available until stability criteria are met.

### 6) Closure and prevention
1. Define success criteria: no mapping failures across Finance for two business days.
2. Publish known-error and closure documentation with root cause and fix.
3. Update change checklist to require execution-context validation (USER vs SYSTEM) for future migrations.
4. Add post-change validation step for login timing and UNC dependency checks.