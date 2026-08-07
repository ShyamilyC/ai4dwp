# Finance Shared Drives Access Failure - L2/L3 Knowledge Base

Version: v1.0  
Date: 07/08/2026  
Status: Draft

## Background
Finance users rely on mapped drive S: to reach shared business data on \\finbridge-fs01\Finance. If mapping fails at sign-in, users cannot access files needed for daily processing, approvals, and reporting. This incident pattern is high impact because assignment scope is usually group-based and can affect many users at once.

## Symptom
Engineer observes:
- Multiple Finance endpoints report missing S: drive after sign-in.
- Intune script status shows repeated failures for Map-FinBridgeDrives.ps1.
- System log timing shows mapping failure near startup.

Users report:
- "My Finance drive is gone"
- "I cannot open shared folders"
- "Network path cannot be found" or similar access error

## Root Cause
Drive mapping logic designed for signed-in user context was executed as SYSTEM context after migration from user logon GPO to Intune script deployment. At execution time, UNC access was attempted before required user context and before Workstation service readiness, then script exited with no retry.

Evidence that confirms root cause:
- Intune log shows script context as SYSTEM and UNC failure with exit code 1.
- Event ID 7036 shows Workstation service entered Running after script failure time.
- Event ID 98 shows drive letter mapping failure for S:.
- Change record confirms migration from USER-context GPO logon script to SYSTEM-context Intune script without redesign.

## Detection
Complete these checks in order. Target completion time is under 3 minutes.

1. Pull the required Application log events with one command.
Path: PowerShell (Run as Administrator) on an impacted endpoint.
Command:
```powershell
Get-WinEvent -FilterHashtable @{LogName='Application'; Id=1000,9009; StartTime=(Get-Date).AddHours(-4)} |
Sort-Object TimeCreated -Descending |
Select-Object -First 20 TimeCreated, Id, ProviderName, LevelDisplayName, MachineName, Message | Format-Table -AutoSize
```
Field(s): `TimeCreated`, `Id`, `ProviderName`, `LevelDisplayName`, `Message`.
Look for: Both `Id 1000` and `Id 9009` present in recent time window, with message text aligned to script/process failure near user sign-in window.

2. Validate the same events in Event Viewer Application log.
Path: Event Viewer -> Windows Logs -> Application -> Filter Current Log...
Filter: `<All Event IDs>` = `1000,9009`; `Logged` = `Last 4 hours`.
Field(s): `Date and Time`, `Source`, `Event ID`, `Task Category`, `General`.
Look for: Event 1000 and Event 9009 timestamps close to the reported failure period.

3. Check Intune status for the mapping script.
Path: Azure portal -> https://portal.azure.com -> Microsoft Intune -> Devices -> Scripts and remediations -> Platform scripts -> Map-FinBridgeDrives.ps1 -> Device status.
Field(s): `Status`, `Error code`, `Last check-in`, `User`.
Look for: Finance devices with `Failed` results in the same timeframe as Application events 1000/9009.

4. Check assignment scope for accidental broad targeting.
Path: Azure portal -> https://portal.azure.com -> Microsoft Intune -> Devices -> Scripts and remediations -> Platform scripts -> Map-FinBridgeDrives.ps1 -> Assignments.
Field(s): `Included groups`, `Excluded groups`.
Look for: Finance group included for SYSTEM-context execution.

5. Confirm script-context evidence in Intune Management Extension log.
Path: C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log.
Field(s): `Timestamp`, `Component`, `Message`.
Look for exact strings: `Executing Map-FinBridgeDrives.ps1`, `Script context: SYSTEM account`, `Network path \\finbridge-fs01\Finance not accessible`, `Exit code: 1`, `No retry configured`.

Diagnosis confirmation criteria:
- Application log contains Event ID 1000 and Event ID 9009 in failure window.
- Intune status shows failed script runs for affected Finance scope in the same period.
- IntuneManagementExtension.log confirms SYSTEM-context execution and UNC failure for `\\finbridge-fs01\Finance`.

## Resolution
Perform in order. This path is designed for 5-10 minute execution.

1. Run pre-check to identify whether users are on Azure Virtual Desktop host pool `AVD-POOL-FIN-01`.
Path: Azure portal -> Azure Virtual Desktop -> Host pools -> AVD-POOL-FIN-01 -> Session hosts.
Azure CLI:
```bash
az desktopvirtualization session-host list \
	--resource-group <avd-resource-group> \
	--host-pool-name AVD-POOL-FIN-01 \
	--query "[].{name:name,status:status,allowNewSession:allowNewSession,sessions:sessions}" -o table
```
Expected result: Host pool and session hosts are visible; if host pool is healthy, continue with Intune/GPO fix below.

2. Get the Intune script object ID for `Map-FinBridgeDrives.ps1`.
Path: Azure portal -> Microsoft Intune -> Devices -> Scripts and remediations -> Platform scripts -> Map-FinBridgeDrives.ps1.
Azure CLI:
```bash
az rest --method GET \
	--url "https://graph.microsoft.com/beta/deviceManagement/deviceManagementScripts?$filter=displayName eq 'Map-FinBridgeDrives.ps1'" \
	--query "value[0].{id:id,displayName:displayName}" -o table
```
Expected result: Command returns one script with non-empty `id`.

3. Export current script assignments (backup before change).
Path: N/A (CLI-only fast path).
Azure CLI:
```bash
az rest --method GET \
	--url "https://graph.microsoft.com/beta/deviceManagement/deviceManagementScripts/<scriptId>/assignments" \
	-o json > prechange-Map-FinBridgeDrives-assignments.json
```
Expected result: Backup JSON file is created with current assignment objects.

4. Update assignment so Finance group is excluded from SYSTEM-context script.
Path: Azure portal option reference -> Microsoft Intune -> Devices -> Scripts and remediations -> Platform scripts -> Map-FinBridgeDrives.ps1 -> Assignments -> Edit.
Azure CLI:
```bash
az rest --method POST \
	--url "https://graph.microsoft.com/beta/deviceManagement/deviceManagementScripts/<scriptId>/assign" \
	--headers "Content-Type=application/json" \
	--body @assign-exclude-finance.json
```
Expected result: Command returns HTTP success and Finance target is no longer in Included groups for this script.

5. Re-link or enable approved USER-context Finance mapping policy.
Path: Group Policy Management -> Forest -> Domains -> <domain> -> OU=Finance -> Linked Group Policy Objects.
Command:
```powershell
Set-GPLink -Name "<Finance-User-Drive-Mapping-GPO>" -Target "OU=Finance,DC=<domain>,DC=<tld>" -LinkEnabled Yes
```
Expected result: GPO link status is `Enabled` on `OU=Finance`.

6. Force policy on one pilot endpoint and reload session.
Path: Pilot endpoint -> Command Prompt.
Command:
```cmd
gpupdate /force
```
Expected result: Output includes `User Policy update has completed successfully`.

7. Confirm mapped drive access on pilot endpoint.
Path: Pilot endpoint -> File Explorer -> This PC -> S:.
PowerShell quick check:
```powershell
Get-PSDrive -Name S -ErrorAction SilentlyContinue | Select-Object Name,Root,Used,Free
```
Expected result: `S` drive exists and root points to `\\finbridge-fs01\Finance`.

## Verification
1. Verify host pool is not the active fault domain before closure.
Path: Azure portal -> Azure Virtual Desktop -> Host pools -> AVD-POOL-FIN-01 -> Session hosts.
Azure CLI:
```bash
az desktopvirtualization session-host list \
	--resource-group <avd-resource-group> \
	--host-pool-name AVD-POOL-FIN-01 \
	--query "[].{name:name,status:status,sessions:sessions}" -o table
```
Success looks like: Session hosts are `Available` (or expected operational state) and no abnormal pool-wide outage is present.

2. Verify script assignment change is active in Intune.
Path: Azure portal -> Microsoft Intune -> Devices -> Scripts and remediations -> Platform scripts -> Map-FinBridgeDrives.ps1 -> Assignments.
Azure CLI:
```bash
az rest --method GET \
	--url "https://graph.microsoft.com/beta/deviceManagement/deviceManagementScripts/<scriptId>/assignments" \
	--query "value[].target" -o json
```
Success looks like: Finance group is absent from Included target set for this script.

3. Verify no new failed runs for affected scope.
Path: Azure portal -> Microsoft Intune -> Devices -> Scripts and remediations -> Platform scripts -> Map-FinBridgeDrives.ps1 -> Device status.
Azure CLI:
```bash
az rest --method GET \
	--url "https://graph.microsoft.com/beta/deviceManagement/deviceManagementScripts/<scriptId>/deviceRunStates" \
	--query "value[?resultMessage!=null].{device:managedDeviceName,state:resultState,msg:resultMessage,last:lastStateUpdateDateTime}" -o table
```
Success looks like: No new Finance endpoint entries show failure after remediation timestamp.

4. Verify mapping on two endpoints by command.
Path: Endpoint PowerShell.
Command:
```powershell
Get-PSDrive -Name S -ErrorAction SilentlyContinue | Select-Object Name,Root
```
Success looks like: `Name` is `S` and `Root` is `\\finbridge-fs01\Finance` on both validated endpoints.

5. Verify no immediate recurrence signal in event logs.
Path: Event Viewer -> Windows Logs -> System (Event ID 98) and Windows Logs -> Application (Event IDs 1000,9009).
PowerShell:
```powershell
Get-WinEvent -FilterHashtable @{LogName='System'; Id=98; StartTime=(Get-Date).AddHours(-1)} | Select-Object TimeCreated, Id, ProviderName, Message
Get-WinEvent -FilterHashtable @{LogName='Application'; Id=1000,9009; StartTime=(Get-Date).AddHours(-1)} | Select-Object TimeCreated, Id, ProviderName, Message
```
Success looks like: No new failure events linked to drive mapping after fix time.

## Rollback
Use if service degrades after remediation.

1. Restore previous Intune assignment payload from backup file.
Path: Azure portal option reference -> Microsoft Intune -> Devices -> Scripts and remediations -> Platform scripts -> Map-FinBridgeDrives.ps1 -> Assignments.
Azure CLI:
```bash
az rest --method POST \
	--url "https://graph.microsoft.com/beta/deviceManagement/deviceManagementScripts/<scriptId>/assign" \
	--headers "Content-Type=application/json" \
	--body @prechange-Map-FinBridgeDrives-assignments.json
```
Expected result: Assignment state returns to pre-change targeting.

2. Disable Finance USER-context mapping GPO link if it was re-enabled during fix.
Path: Group Policy Management -> Forest -> Domains -> <domain> -> OU=Finance -> Linked Group Policy Objects.
PowerShell:
```powershell
Set-GPLink -Name "<Finance-User-Drive-Mapping-GPO>" -Target "OU=Finance,DC=<domain>,DC=<tld>" -LinkEnabled No
```
Expected result: Link state is `Disabled` (or unlinked if your standard requires unlink).

3. Recheck AVD host pool to ensure no parallel platform incident is being masked.
Path: Azure portal -> Azure Virtual Desktop -> Host pools -> AVD-POOL-FIN-01 -> Session hosts.
Azure CLI:
```bash
az desktopvirtualization session-host list \
	--resource-group <avd-resource-group> \
	--host-pool-name AVD-POOL-FIN-01 \
	--query "[].{name:name,status:status,sessions:sessions}" -o table
```
Expected result: Host pool remains stable; rollback impact is isolated to mapping control changes.

4. Force policy refresh on pilot endpoint.
Path: Pilot endpoint -> Command Prompt.
Command:
```cmd
gpupdate /force
```
Expected result: Endpoint receives rollback configuration successfully.

5. Validate pilot behavior and document rollback completion.
Path: Pilot endpoint -> File Explorer -> This PC -> S:; Incident ticket timeline.
Expected result: Pilot returns to last known-good state and ticket includes rollback timestamp, operator, and evidence.

## Preventive
1. Execution-context checkpoint in change template.
Owner: Change manager | Timing: Before deployment | Mode: Manual [REQUIRES: Change template field enforcement].
Pass: Template contains `resource type`, `required context`, and `context proof`; fail if any field missing or USER resource mapped to SYSTEM.
If fail: Change is rejected in CAB and returned to DWP engineer; automation approach: enforce required fields via ServiceNow/Jira workflow rule.

2. Startup dependency pre-check gate for mapping changes.
Owner: DWP engineer | Timing: Before deployment | Mode: Manual (script-assisted).
Pass: On pilot endpoint, Event ID 7036 (Workstation Running) occurs before mapping attempt and UNC `\\finbridge-fs01\Finance` test succeeds 3/3 times.
If fail: Block release and open defect for sequencing/retry redesign; automation approach: preflight script exports pass/fail JSON.

3. Standard retry plus telemetry block in mapping scripts.
Owner: Image owner | Timing: Before deployment | Mode: Automated [REQUIRES: Script standard module/library].
Pass: Script emits structured logs for each attempt and exits with defined codes; success rate >= 99% in pilot run states.
If fail: Pipeline blocks package publication and requires pull request fix with code review by release engineer.

4. Staged rollout with hard go/no-go thresholds.
Owner: Release engineer | Timing: During deployment | Mode: Manual decision with automated metrics.
Pass: Pilot (5 users) and ring-1 (20%) each complete with < 2 failed script runs per 15 minutes and 0 critical incidents.
If fail: Stop progression to next ring and execute rollback plan immediately.

5. In-flight alert for mapping failure burst.
Owner: DWP engineer | Timing: During deployment | Mode: Automated [REQUIRES: Log Analytics/SIEM alert rule].
Pass: Alert triggers when Event ID 98 >= 5 or Application Event IDs 1000/9009 >= 5 on Finance scope within 15 minutes.
If fail: If alert does not fire during synthetic test, deployment is paused until alert rule is corrected and retested.

6. Rollback metadata and drill requirement per change.
Owner: Change manager | Timing: Before deployment | Mode: Manual.
Pass: Change record includes prechange assignment JSON, rollback owner, and rollback SLA <= 10 minutes; drill completed in last 90 days.
If fail: CAB approval is denied and rollout window is not opened.

7. Pre-deployment smoke test gate (missing layer).
Owner: DWP engineer | Timing: Before deployment | Mode: Manual.
Pass: Test account sign-in maps `S:` and opens one known Finance folder in < 10 seconds on 2 pilot devices.
If fail: Freeze deployment and attach failed test evidence to change record.

8. Post-deployment validation gate before change closure (missing layer).
Owner: Service desk lead | Timing: After deployment | Mode: Manual [REQUIRES: Ticket checklist update].
Pass: Two user confirmations plus no new Event ID 98 and no new Intune failed runs for 60 minutes after rollout.
If fail: Keep change open, escalate to DWP engineer, and start incident workflow.

9. Explicit rollback trigger threshold (missing layer).
Owner: Release engineer | Timing: During deployment | Mode: Automated threshold + manual execution.
Pass: Continue rollout only while failure rate stays below 2% of targeted devices per 15 minutes.
If fail: At >= 2% failures or >= 10 affected users, trigger immediate rollback and halt all new assignments.

10. Knowledge update control from incident learnings (missing layer).
Owner: Service desk lead | Timing: After deployment | Mode: Manual [REQUIRES: KB governance process].
Pass: Runbook, L1 KB, and L2/L3 KB updated within 2 business days; version/date changed and peer review logged.
If fail: Raise problem-management action item and block closure of related known-error record.

## Related
- RCA: Day4/Exercise/Finance-Shared-Drives-Access-Issue-RCA.md
- Engineering Runbook: Day5/Exercise/Finance-Shared-Drives-Access-Issue-Runbook.md
- L1 Self-Service KB: Day5/Exercise/Finance-Shared-Drives-Access-Issue-L1-Self-Service-KB.md
- Related incident pattern: Day2/T-1008-VPN-Connected-No-Internal-Access-Triage.md (shared resource reachability triage model)
