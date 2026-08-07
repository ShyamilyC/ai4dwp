Title: AVD POOL-FIN-01 Black Screen After Login - L2/L3 Knowledge Base
Version: v 1.0
Date: 07/08/2026
Status: Draft

## Background
Azure Virtual Desktop (AVD) delivers finance user desktops from pooled compute. Users in `POOL-FIN-01` and `POOL-FIN-02` rely on this service for daily ERP, mail, and shared-drive access. If post-login desktop rendering fails, users cannot reach business applications even when identity and profile sign-in succeed.

Why this matters:
- Finance operations are time-sensitive and interruption impacts payroll, approvals, and period-close tasks.
- A pool-specific failure can be contained quickly if identified correctly.
- Fast differentiation between sign-in success and post-login render failure prevents incorrect fixes.

## Symptom
What users report:
- "I can sign in but only see a black screen."
- "It disconnects, then reconnects, then black screen again."

What engineer observes:
- Incident starts after overnight update window (in this case 02:00 update, user impact around 07:00).
- Affected scope is `POOL-FIN-01`; `POOL-FIN-02` remains healthy.
- Repeating pattern on affected hosts: logon success event, then app crash event, then desktop manager exit, then session disconnect.

## Root Cause
A graphics stack regression was introduced in the updated `POOL-FIN-01` baseline. During user sign-in, `dwm.exe` crashed in Intel module `igdumd64.dll`, causing Desktop Window Manager termination and user session disconnect/reconnect loops.

Evidence that confirms root cause:
- Affected host (`SHFIN-01-A`) shows repeated:
  - Event ID 21 (TerminalServices-LocalSessionManager): logon succeeded.
  - Event ID 1000 (Application Error): `dwm.exe` faulting module `igdumd64.dll`, exception `0xc0000005`.
  - Event ID 9009 (Desktop Window Manager): DWM exited.
  - Event ID 40 (TerminalServices-LocalSessionManager): session disconnected.
- Repetition appears for multiple users on same updated pool.
- Control host in `POOL-FIN-02` shows normal Event ID 21 plus Event ID 9011 (DWM started successfully) and no Event ID 1000 signature.
- Kernel-General Event ID 1 confirms reboot after overnight update, aligning change timing with failure onset.

## Detection
Use this 3-minute command-first check before taking action.

1. Open Azure portal path: `Virtual machines > <AFFECTED_HOST_IN_POOL-FIN-01> > Run command > RunPowerShellScript`.
Expected result: `RunPowerShellScript` panel is open for one affected `POOL-FIN-01` VM.

2. Run this command against the exact log location `Windows Logs > Application`:
```powershell
Get-WinEvent -FilterHashtable @{LogName='Application'; Id=1000; StartTime=(Get-Date).AddHours(-4)} |
Where-Object { $_.Message -match 'dwm.exe' -and $_.Message -match 'igdumd64.dll' } |
Select-Object -First 20 TimeCreated, Id, ProviderName, Message
```
Required event and field check:
- Event ID: `1000`
- Faulting module text in `Message`: `igdumd64.dll`
Expected result: One or more Event ID `1000` rows with `dwm.exe` and `igdumd64.dll` in `Message`.

3. In the same `RunPowerShellScript` panel, run this command against `Windows Logs > Application`:
```powershell
Get-WinEvent -FilterHashtable @{LogName='Application'; Id=9009; StartTime=(Get-Date).AddHours(-4)} |
Select-Object -First 20 TimeCreated, Id, ProviderName, Message
```
Required event and field check:
- Event ID: `9009`
- Field to inspect: `Message`
Expected result: Event ID `9009` appears in the same time window as Event ID `1000`.

4. Open Azure portal path: `Virtual machines > <CONTROL_HOST_IN_POOL-FIN-02> > Run command > RunPowerShellScript`.
Expected result: `RunPowerShellScript` panel is open for one unaffected control VM in `POOL-FIN-02`.

5. Run this baseline command against `Windows Logs > Application`:
```powershell
Get-WinEvent -FilterHashtable @{LogName='Application'; StartTime=(Get-Date).AddHours(-4)} |
Where-Object {
  $_.Id -in 9011,1000,9009 -and
  ($_.Message -match 'dwm.exe' -or $_.Message -match 'igdumd64.dll' -or $_.Id -eq 9011)
} |
Select-Object -First 30 TimeCreated, Id, ProviderName, Message
```
Required healthy comparison:
- Unaffected control: `POOL-FIN-02`
- Healthy baseline event: `9011`
- Absence check: no Event ID `1000` with `igdumd64.dll`
Expected result: Event ID `9011` is present on control host and Event ID `1000` with `igdumd64.dll` is absent.

6. Confirm diagnosis as this incident only when both conditions are true.
Expected result: Condition A: affected `POOL-FIN-01` host has Event ID `1000` (`dwm.exe` + `igdumd64.dll`) and Event ID `9009`; Condition B: unaffected `POOL-FIN-02` control host shows Event ID `9011` and no matching Event ID `1000` signature.

## Resolution
Follow steps in order. Use either Portal Path or CLI Fast Path for each action.

1. Open `Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts` and confirm you can see columns `Name`, `Status`, `Allow new sessions`, `Sessions`. **[ELEVATED]**
CLI fast path:
```powershell
az desktopvirtualization session-host list --resource-group <RG_NAME> --host-pool-name POOL-FIN-01 --query "[].{Name:name,Status:status,AllowNewSessions:allowNewSession,Sessions:sessions}" -o table
```
Expected result: Host list is visible and manageable for `POOL-FIN-01`.

2. Set drain mode on all `POOL-FIN-01` hosts (`Allow new sessions = No`). **[ELEVATED]**
Portal path and option: `Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts > select host > Allow new sessions = No > Save`.
CLI fast path:
```powershell
$hosts = az desktopvirtualization session-host list --resource-group <RG_NAME> --host-pool-name POOL-FIN-01 --query "[].name" -o tsv
foreach ($h in $hosts) {
  $n = ($h -split '/sessionHosts/')[1]
  az desktopvirtualization session-host update --resource-group <RG_NAME> --host-pool-name POOL-FIN-01 --name $n --allow-new-session false
}
```
Expected result: Every `POOL-FIN-01` host shows `Allow new sessions = No`.

3. Open `Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-02 > Session hosts` and set approved healthy hosts to `Allow new sessions = Yes`. **[ELEVATED]**
CLI fast path:
```powershell
$hosts2 = az desktopvirtualization session-host list --resource-group <RG_NAME> --host-pool-name POOL-FIN-02 --query "[].name" -o tsv
foreach ($h in $hosts2) {
  $n = ($h -split '/sessionHosts/')[1]
  az desktopvirtualization session-host update --resource-group <RG_NAME> --host-pool-name POOL-FIN-02 --name $n --allow-new-session true
}
```
Expected result: Healthy `POOL-FIN-02` capacity accepts new sessions.

4. Open `Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > User sessions` and send message `Maintenance in progress. You will be signed out.` to all active users. **[ELEVATED]**
CLI fast path:
```powershell
$sessions = az desktopvirtualization user-session list --resource-group <RG_NAME> --host-pool-name POOL-FIN-01 | ConvertFrom-Json
foreach ($s in $sessions) {
  $sn = ($s.name -split '/sessionHosts/')[1].Split('/')[0]
  az desktopvirtualization user-session send-message --resource-group <RG_NAME> --host-pool-name POOL-FIN-01 --session-host-name $sn --user-session-id $s.id --message-title "Maintenance" --message-body "Maintenance in progress. You will be signed out."
}
```
Expected result: Users receive warning message and are prepared for sign-out.

5. In the same `User sessions` blade, sign out all remaining sessions. **[ELEVATED]**
CLI fast path:
```powershell
$sessions = az desktopvirtualization user-session list --resource-group <RG_NAME> --host-pool-name POOL-FIN-01 | ConvertFrom-Json
foreach ($s in $sessions) {
  $sn = ($s.name -split '/sessionHosts/')[1].Split('/')[0]
  az desktopvirtualization user-session delete --resource-group <RG_NAME> --host-pool-name POOL-FIN-01 --session-host-name $sn --user-session-id $s.id --yes
}
```
Expected result: `POOL-FIN-01` user session count is `0`.

6. Open `Azure portal > Virtual machines > <PILOT_HOST> > Run command > RunPowerShellScript` and validate package checksum. **[ELEVATED]**
Command:
```powershell
Get-FileHash -Path '<PACKAGE_PATH>' -Algorithm SHA256
```
Expected result: SHA256 matches approved checksum exactly.

7. On same pilot host path, install the approved known-good package. **[ELEVATED]**
Command:
```powershell
pnputil /add-driver "<INF_FOLDER_PATH>\*.inf" /install
```
Expected result: Output shows successful add/install and no failures.

8. Restart pilot host from `Azure portal > Virtual machines > <PILOT_HOST> > Overview > Restart`. **[ELEVATED]**
CLI fast path:
```powershell
az vm restart --resource-group <RG_NAME> --name <PILOT_HOST>
```
Expected result: VM returns to `Running`.

9. Confirm pilot AVD state in `Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts`. **[ELEVATED]**
CLI fast path:
```powershell
az desktopvirtualization session-host show --resource-group <RG_NAME> --host-pool-name POOL-FIN-01 --name <PILOT_HOST> --query "{Status:status,AllowNewSessions:allowNewSession,Sessions:sessions}" -o table
```
Expected result: Pilot host shows `Status = Available` and remains drained until full validation.

10. Apply package and restart all remaining affected hosts. **[ELEVATED]**
CLI fast path:
```powershell
$targets = @('<HOST1>','<HOST2>','<HOST3>')
foreach ($vm in $targets) {
  az vm run-command invoke --resource-group <RG_NAME> --name $vm --command-id RunPowerShellScript --scripts "pnputil /add-driver '<INF_FOLDER_PATH>\\*.inf' /install"
  az vm restart --resource-group <RG_NAME> --name $vm
}
```
Expected result: Every affected VM completes install and returns to `Running`.

11. Re-enable traffic on remediated hosts from `Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts > select host > Allow new sessions = Yes > Save`. **[ELEVATED]**
CLI fast path:
```powershell
$hosts = az desktopvirtualization session-host list --resource-group <RG_NAME> --host-pool-name POOL-FIN-01 --query "[].name" -o tsv
foreach ($h in $hosts) {
  $n = ($h -split '/sessionHosts/')[1]
  az desktopvirtualization session-host update --resource-group <RG_NAME> --host-pool-name POOL-FIN-01 --name $n --allow-new-session true
}
```
Expected result: `POOL-FIN-01` hosts are available and accepting new sessions.

## Verification
1. Open `Azure portal > Log Analytics workspaces > <WORKSPACE_NAME> > Logs` and run this query for Event ID 1000 signature:
```kusto
Event
| where TimeGenerated >= ago(30m)
| where Computer has "SHFIN-01" or Computer has "POOL-FIN-01"
| where EventID == 1000
| where RenderedDescription has "dwm.exe" and RenderedDescription has "igdumd64.dll"
```
CLI fast path:
```powershell
az monitor log-analytics query --workspace <WORKSPACE_ID> --analytics-query "Event | where TimeGenerated >= ago(30m) | where Computer has 'SHFIN-01' or Computer has 'POOL-FIN-01' | where EventID == 1000 | where RenderedDescription has 'dwm.exe' and RenderedDescription has 'igdumd64.dll' | count"
```
Expected result: Query result is `0` matches.

2. In the same Logs blade, run Event ID 9009 count by host:
```kusto
Event
| where TimeGenerated >= ago(30m)
| where Computer has "SHFIN-01" or Computer has "POOL-FIN-01"
| where EventID == 9009
| summarize Count=count() by Computer
```
CLI fast path:
```powershell
az monitor log-analytics query --workspace <WORKSPACE_ID> --analytics-query "Event | where TimeGenerated >= ago(30m) | where Computer has 'SHFIN-01' or Computer has 'POOL-FIN-01' | where EventID == 9009 | summarize Count=count() by Computer"
```
Expected result: No host shows repeat termination pattern (target is zero rows).

3. In the same Logs blade, run 21-to-40 correlation check:
```kusto
let logons = Event | where TimeGenerated >= ago(30m) | where EventID == 21 | where Computer has "SHFIN-01" or Computer has "POOL-FIN-01" | project Computer, LogonTime=TimeGenerated;
let disconnects = Event | where TimeGenerated >= ago(30m) | where EventID == 40 | where Computer has "SHFIN-01" or Computer has "POOL-FIN-01" | project Computer, DisconnectTime=TimeGenerated;
logons | join kind=inner disconnects on Computer | where DisconnectTime between (LogonTime .. LogonTime + 60s)
```
CLI fast path:
```powershell
az monitor log-analytics query --workspace <WORKSPACE_ID> --analytics-query "let logons = Event | where TimeGenerated >= ago(30m) | where EventID == 21 | where Computer has 'SHFIN-01' or Computer has 'POOL-FIN-01' | project Computer, LogonTime=TimeGenerated; let disconnects = Event | where TimeGenerated >= ago(30m) | where EventID == 40 | where Computer has 'SHFIN-01' or Computer has 'POOL-FIN-01' | project Computer, DisconnectTime=TimeGenerated; logons | join kind=inner disconnects on Computer | where DisconnectTime between (LogonTime .. LogonTime + 60s) | count"
```
Expected result: Correlation count is `0`.

4. Confirm host readiness in `Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts`.
CLI fast path:
```powershell
az desktopvirtualization session-host list --resource-group <RG_NAME> --host-pool-name POOL-FIN-01 --query "[].{Name:name,Status:status,AllowNewSessions:allowNewSession,Sessions:sessions}" -o table
```
Expected result: All remediated hosts show `Status = Available`, `AllowNewSessions = true`, and stable session counts.

5. Perform three test logons and validate no reconnect loop.
Expected result: Each login reaches interactive desktop in under 30 seconds with no black screen.

## Rollback
If symptoms worsen after fix, execute immediately:

1. Open `Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts` and set `Allow new sessions = No` for all remediated hosts. **[ELEVATED]**
CLI fast path:
```powershell
$hosts = az desktopvirtualization session-host list --resource-group <RG_NAME> --host-pool-name POOL-FIN-01 --query "[].name" -o tsv
foreach ($h in $hosts) {
  $n = ($h -split '/sessionHosts/')[1]
  az desktopvirtualization session-host update --resource-group <RG_NAME> --host-pool-name POOL-FIN-01 --name $n --allow-new-session false
}
```
Expected result: New sessions stop landing on `POOL-FIN-01`.

2. Open `Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-02 > Session hosts` and set healthy standby hosts to `Allow new sessions = Yes`. **[ELEVATED]**
CLI fast path:
```powershell
$hosts2 = az desktopvirtualization session-host list --resource-group <RG_NAME> --host-pool-name POOL-FIN-02 --query "[].name" -o tsv
foreach ($h in $hosts2) {
  $n = ($h -split '/sessionHosts/')[1]
  az desktopvirtualization session-host update --resource-group <RG_NAME> --host-pool-name POOL-FIN-02 --name $n --allow-new-session true
}
```
Expected result: New sessions route to stable `POOL-FIN-02` capacity.

3. Reinstall pre-change package on each affected VM from `Azure portal > Virtual machines > <AFFECTED_HOST> > Run command > RunPowerShellScript`. **[ELEVATED]**
Command:
```powershell
pnputil /add-driver "<PRECHANGE_INF_FOLDER>\*.inf" /install
```
CLI fast path:
```powershell
az vm run-command invoke --resource-group <RG_NAME> --name <AFFECTED_HOST> --command-id RunPowerShellScript --scripts "pnputil /add-driver '<PRECHANGE_INF_FOLDER>\\*.inf' /install"
```
Expected result: Pre-change package installs successfully with no failures.

4. Restart each reverted VM from `Azure portal > Virtual machines > <AFFECTED_HOST> > Overview > Restart`. **[ELEVATED]**
CLI fast path:
```powershell
az vm restart --resource-group <RG_NAME> --name <AFFECTED_HOST>
```
Expected result: VM returns to `Running` and AVD status becomes `Available` while still drained.

5. Verify rollback telemetry in `Azure portal > Log Analytics workspaces > <WORKSPACE_NAME> > Logs`.
Query:
```kusto
Event
| where TimeGenerated >= ago(15m)
| where Computer =~ "<AFFECTED_HOST>"
| where EventID in (1000,9009)
| where RenderedDescription has_any ("dwm.exe","igdumd64.dll")
```
CLI fast path:
```powershell
az monitor log-analytics query --workspace <WORKSPACE_ID> --analytics-query "Event | where TimeGenerated >= ago(15m) | where Computer =~ '<AFFECTED_HOST>' | where EventID in (1000,9009) | where RenderedDescription has_any ('dwm.exe','igdumd64.dll') | count"
```
Expected result: Match count is `0` before reintroducing host.

6. Reintroduce one host at a time from `Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts > <HOST> > Allow new sessions = Yes > Save`. **[ELEVATED]**
CLI fast path:
```powershell
az desktopvirtualization session-host update --resource-group <RG_NAME> --host-pool-name POOL-FIN-01 --name <HOST> --allow-new-session true
```
Expected result: Controlled recovery with successful test login per host and no recurrence.

7. Escalate through incident process with evidence bundle.
Expected result: `SEV-2` accepted by AVD Platform Engineering and Endpoint Engineering with command outputs and query results attached.

## Preventive
Strengthened controls below keep the original intent and add owner, timing, pass/fail, and action.

1. Staged canary rollout gates (existing control, strengthened).
Owner: Release engineer. Timing: During deployment. Mode: Automated [REQUIRES: release pipeline gates].
Pass/fail: Gate 1 canary is 10% of POOL-FIN-01 only; Gate 2 blocks if Event ID 1000 with dwm.exe and igdumd64.dll count > 0 in 30 minutes; Gate 3 blocks if Event ID 9009 per host > 2 in 30 minutes.
If fail: auto-stop promotion, keep POOL-FIN-01 drained, open SEV-2, and start rollback sequence.

2. In-flight alert correlation in Log Analytics (existing control, strengthened).
Owner: DWP engineer. Timing: During deployment. Mode: Automated [REQUIRES: alert rule + action group].
Pass/fail: Alert A fires on EventID 1000 where RenderedDescription has dwm.exe and igdumd64.dll; Alert B fires if EventID 40 occurs within 60s of EventID 21 more than 3 times in 15 minutes per host.
If fail: action group pages on-call, creates incident automatically, and change manager places rollout on hold.

3. Release artifact checksum gate (existing control, strengthened).
Owner: Image owner. Timing: Before deployment. Mode: Manual now; should be automated in CI by blocking artifact promotion when checksum metadata missing.
Pass/fail: Change record must include package version and SHA256; installer hash must match exactly before any deployment step.
If fail: deployment is rejected by change manager and artifact is returned to image owner for republish.

4. Post-update synthetic login quality test (existing control, strengthened).
Owner: DWP engineer. Timing: After deployment to canary and before full rollout. Mode: Automated [REQUIRES: synthetic login runner].
Pass/fail: Minimum 3 test logins per updated host; fail if any login takes >30s to interactive desktop or any disconnect occurs.
If fail: stop rollout, keep affected hosts drained, and execute rollback on updated hosts.

5. Service desk known-error mapping (existing control, strengthened).
Owner: Service desk lead. Timing: After deployment and during incident intake. Mode: Manual triage aid; can be automated with ticket keyword classifier [REQUIRES: ITSM routing rule].
Pass/fail: Tickets containing black screen + after login in DWP VDI queue auto-suggest this KB and require Event IDs 1000/9009 evidence fields before escalation.
If fail: ticket routes to manual L2 triage and service desk lead updates mapping rules within 1 business day.

6. Pre-deployment smoke gate (added missing layer).
Owner: Image owner. Timing: Before deployment. Mode: Manual now; automate with pre-release validation job [REQUIRES: pre-prod AVD smoke environment].
Pass/fail: One clean login/logout on pre-prod host; Application log has zero EventID 1000 containing igdumd64.dll and zero EventID 9009 in 15-minute window.
If fail: release package is blocked and cannot enter production change window.

7. Post-deployment closure validation gate (added missing layer).
Owner: Change manager. Timing: After deployment, before change closure. Mode: Manual checklist; can be automated from query outputs [REQUIRES: change template integration].
Pass/fail: Last 30 minutes show zero EventID 1000 signature hits, zero EventID 9009 spikes, and zero 21->40 correlations within 60s for POOL-FIN-01.
If fail: change remains open, rollback decision is mandatory, and closure is denied.

8. Explicit rollback trigger policy (added missing layer).
Owner: Release engineer. Timing: During and after deployment watch window. Mode: Automated trigger preferred; manual trigger allowed [REQUIRES: rollout controller webhook].
Pass/fail: Trigger rollback immediately if EventID 1000 signature count >=1 on any updated host or if >3 user disconnect-loop tickets arrive in 15 minutes.
If fail threshold met: rollout auto-pauses and rollback job starts; if automation unavailable, DWP engineer executes runbook rollback within 5 minutes.

9. Knowledge and checklist update control (added missing layer).
Owner: Service desk lead. Timing: After incident closure. Mode: Manual; automate reminders via problem-management workflow [REQUIRES: PIR task template].
Pass/fail: Within 2 business days, update runbook, L2 KB, and change checklist with new detection query and rollback trigger; peer review completed.
If fail: problem record stays open and next similar change cannot be approved by change manager.

## Related
- `Day4/AVD-POOL-FIN-01-BlackScreen-RCA.md`
- `Day4/Known-Error-Record-AVD-POOL-FIN-01-BlackScreen.md`
- `Day4/AVD-POOL-FIN-01-Closure-Note.md`
- `Day5/AVD-POOL-FIN-01-BlackScreen-Runbook.md`
- `Day4/AVD-Incident-Communications-Three-Audiences.md`
