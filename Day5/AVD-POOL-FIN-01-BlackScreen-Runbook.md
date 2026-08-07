Title: AVD POOL-FIN-01 Black Screen Post-Login Runbook
Version: 1.0
Date: 07/08/2026
Author: Shyamily
Reviewed: self
Status: draft
Change: initial version from RCA

# Runbook: AVD POOL-FIN-01 Black Screen Post-Login

## Purpose and Scope
Use this runbook when users report black screen immediately after AVD logon in `POOL-FIN-01`, especially after an image update. This procedure restores the known-good graphics stack baseline and validates service recovery.

## 1. Prerequisites
Complete every prerequisite before starting the procedure.

1. Confirm the incident matches this signature: black screen after logon, disconnect/reconnect loop, and impact limited to `POOL-FIN-01`.
Expected result: Incident symptoms and scope match this runbook.

2. Obtain `Contributor` access to the Azure resource group that contains AVD host pool `POOL-FIN-01`. **[ELEVATED]**
Expected result: You can open host pool settings and save changes in Azure portal.

3. Obtain `Virtual Machine Contributor` access on all `POOL-FIN-01` session host VMs. **[ELEVATED]**
Expected result: You can restart hosts and run commands on the VMs.

4. Obtain local administrator rights on each affected session host VM. **[ELEVATED]**
Expected result: You can modify driver packages and reboot from the host OS.

5. Obtain read access to Log Analytics workspace connected to AVD diagnostics.
Expected result: You can query event telemetry for Event IDs 21, 40, 1000, 9009, and 9011.

6. Confirm access to Azure portal and one remote management method (`Run command`, PowerShell remoting, or Bastion).
Expected result: You can execute host-level changes without user interaction on the VM console.

7. Retrieve the approved known-good graphics rollback package from change record for this incident (driver package path, version, and checksum). **[ELEVATED]**
Expected result: You have exact package file(s), version, and checksum values to deploy.

8. Retrieve the approved host list for `POOL-FIN-01` from Azure Virtual Desktop host pool.
Expected result: You have a complete list of target session hosts.

9. Capture current host pool settings and current image/driver versions into incident notes.
Expected result: You have a timestamped pre-change baseline for rollback and audit.

## 2. Procedure
Perform each step in order.

1. In Azure portal, go to `Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts`. **[ELEVATED]**
Expected result: You can see the full list of `POOL-FIN-01` session hosts and their `Allow new sessions` status.

2. For each session host shown in `POOL-FIN-01`, set `Allow new sessions` to `No` (drain mode). **[ELEVATED]**
Expected result: Every host in the list shows `Allow new sessions = No`.

3. In Azure portal, go to `Azure Virtual Desktop > Host pools > POOL-FIN-02 > Session hosts`. **[ELEVATED]**
Expected result: You can see the `POOL-FIN-02` session host list and availability.

4. For each healthy host shown in `POOL-FIN-02`, set `Allow new sessions` to `Yes`. **[ELEVATED]**
Expected result: Healthy `POOL-FIN-02` hosts show `Allow new sessions = Yes`.

5. In Azure portal, go to `Azure Virtual Desktop > Host pools > POOL-FIN-01 > User sessions`.
Expected result: You can see all active and disconnected sessions for `POOL-FIN-01`.

6. In Cloud Shell (PowerShell), run `Get-AzWvdUserSession -ResourceGroupName <RG_NAME> -HostPoolName POOL-FIN-01 | Export-Csv .\POOL-FIN-01-UserSessions-PreChange.csv -NoTypeInformation`.
Expected result: File `POOL-FIN-01-UserSessions-PreChange.csv` is created and contains session rows.

7. In the `User sessions` view for `POOL-FIN-01`, select all sessions and click `Send message` with text `Maintenance in 10 minutes. You will be signed out.`.
Expected result: Portal displays message delivery success for selected sessions.

8. Wait 10 minutes by checking the timestamp before and after in incident notes.
Expected result: At least 10 minutes have elapsed since user warning was sent.

9. In the same `User sessions` view, select all remaining sessions and click `Sign out user`.
Expected result: `User sessions` count becomes `0` for `POOL-FIN-01`.

10. In Azure portal, open the first target VM (`Virtual machines > <HOSTNAME> > Run command > RunPowerShellScript`) and run `Get-WinEvent -FilterHashtable @{LogName='Application'; StartTime=(Get-Date).AddHours(-2)} | Where-Object { $_.Id -in 1000,9009 } | Select-Object TimeCreated, Id, ProviderName, Message | Out-File C:\Windows\Temp\PreFix-AppEvents.txt`.
Expected result: Command returns `Provisioning succeeded` and file `C:\Windows\Temp\PreFix-AppEvents.txt` is created on the VM.

11. On the same VM Run command blade, run `Get-WinEvent -FilterHashtable @{LogName='Microsoft-Windows-TerminalServices-LocalSessionManager/Operational'; StartTime=(Get-Date).AddHours(-2)} | Where-Object { $_.Id -in 21,40 } | Select-Object TimeCreated, Id, Message | Out-File C:\Windows\Temp\PreFix-LSMEvents.txt`.
Expected result: Command returns `Provisioning succeeded` and file `C:\Windows\Temp\PreFix-LSMEvents.txt` is created on the VM.

12. In Azure portal, open the pilot VM (`Virtual machines > <PILOT_HOST> > Run command > RunPowerShellScript`) and run `Get-FileHash -Path '<PACKAGE_PATH>' -Algorithm SHA256`.
Expected result: Output `Hash` exactly matches the approved checksum from the change record.

13. On the pilot VM Run command blade, run `pnputil /add-driver "<INF_FOLDER_PATH>\*.inf" /install`.
Expected result: Output includes `Driver package added successfully` or `Driver package installed on matching devices` with no failure lines.

14. In Azure portal, click `Virtual machines > <PILOT_HOST> > Restart`.
Expected result: VM power state returns to `Running`.

15. In Azure portal, go to `Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts` and check `<PILOT_HOST>`.
Expected result: Pilot host shows `Status = Available` and `Health check = Available`.

16. In Log Analytics (`Log Analytics workspaces > <WORKSPACE> > Logs`), run this query:
`Event | where TimeGenerated >= ago(10m) | where Computer =~ '<PILOT_HOST>' | where EventID in (1000,9009) | where RenderedDescription has_any ('dwm.exe','igdumd64.dll')`.
Expected result: Query returns `0` rows.

17. Launch Remote Desktop client, subscribe to workspace feed, and sign in once with the validation account to a desktop assigned to `<PILOT_HOST>`.
Expected result: Full desktop renders in under 30 seconds with no black screen and no forced disconnect.

18. For each remaining `POOL-FIN-01` host, run `pnputil /add-driver "<INF_FOLDER_PATH>\*.inf" /install` using `Virtual machines > <HOSTNAME> > Run command > RunPowerShellScript`. **[ELEVATED]**
Expected result: Each host command output shows successful driver add/install and no failure lines.

19. For each remaining `POOL-FIN-01` host, click `Virtual machines > <HOSTNAME> > Restart`. **[ELEVATED]**
Expected result: Each host returns to `Running`, then to AVD `Status = Available`.

20. In `Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts`, set `Allow new sessions = Yes` for remediated hosts. **[ELEVATED]**
Expected result: All remediated hosts show `Allow new sessions = Yes`.

21. In `Azure Virtual Desktop > Host pools > POOL-FIN-02 > Session hosts`, return non-required burst hosts to their normal `Allow new sessions` state per standard operations profile. **[ELEVATED]**
Expected result: Session distribution policy is back to documented production state.

22. In the incident ticket timeline, enter UTC timestamps for containment start, pilot fix start, pilot validation pass, full rollout complete, and service restored.
Expected result: Ticket timeline contains complete, ordered, auditable times.

## 3. Verification
Complete all checks before closure.

1. In `Log Analytics workspaces > <WORKSPACE> > Logs`, run `Event | where TimeGenerated >= ago(30m) | where Computer has 'SHFIN-' | where EventID == 1000 | where RenderedDescription has 'dwm.exe' and RenderedDescription has 'igdumd64.dll'`.
Expected result: `0` rows are returned.

2. In the same Logs window, run `Event | where TimeGenerated >= ago(30m) | where Computer has 'SHFIN-' | where EventID == 9009 | summarize Count=count() by Computer`.
Expected result: Each host count is `0`; any host with count `>=1` fails verification.

3. In the same Logs window, run `let logons = Event | where TimeGenerated >= ago(30m) | where EventID == 21 | project Computer, LogonTime=TimeGenerated; let disconnects = Event | where TimeGenerated >= ago(30m) | where EventID == 40 | project Computer, DisconnectTime=TimeGenerated; logons | join kind=inner disconnects on Computer | where DisconnectTime between (LogonTime .. LogonTime + 60s)`.
Expected result: `0` rows are returned.

4. From three separate test accounts, start one AVD session each to `POOL-FIN-01`.
Expected result: All 3 sessions reach usable desktop in under 30 seconds with no black screen.

5. In `Azure Virtual Desktop > Host pools > POOL-FIN-01 > User sessions`, watch active sessions for 10 minutes.
Expected result: No abnormal session churn (no repeated immediate drop/reconnect pattern for the same user).

6. In the service desk tool queue filter for `POOL-FIN-01`, check new incidents created during the last 30 minutes.
Expected result: `0` new tickets with black-screen symptom.

7. In the closure note, attach the exact query text, query result screenshots, test account IDs, hostnames tested, and UTC timestamps.
Expected result: Another engineer can replay evidence and reach the same pass/fail conclusion.

## 4. Rollback (Immediate Actions if Condition Worsens)
Trigger this rollback immediately if any black-screen or reconnect-loop symptom appears after remediation.

### 3-Minute Emergency Rollback (Containment First)
Complete Steps 1-6 in sequence; these are designed to be launched within 3 minutes.

1. Open `Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts`. **[ELEVATED]**
Expected result: Session host grid for `POOL-FIN-01` is visible.

2. In that grid, select all hosts and set `Allow new sessions = No`. **[ELEVATED]**
Expected result: Every `POOL-FIN-01` host row shows `Allow new sessions` as `No`.

3. Open `Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-02 > Session hosts`. **[ELEVATED]**
Expected result: Session host grid for `POOL-FIN-02` is visible.

4. In that grid, select all approved healthy hosts and set `Allow new sessions = Yes`. **[ELEVATED]**
Expected result: Approved `POOL-FIN-02` host rows show `Allow new sessions` as `Yes`.

5. Open `Azure portal > Cloud Shell (PowerShell)` and run `Get-AzWvdUserSession -ResourceGroupName <RG_NAME> -HostPoolName POOL-FIN-01 | ForEach-Object { Remove-AzWvdUserSession -ResourceGroupName <RG_NAME> -HostPoolName POOL-FIN-01 -SessionHostName $_.Name.Split('/')[0] -Id $_.Id -Force }`. **[ELEVATED]**
Expected result: Command finishes without errors and subsequent `Get-AzWvdUserSession` for `POOL-FIN-01` returns `0` sessions.

6. In the incident bridge/ticket, post `Rollback containment active: POOL-FIN-01 drained, POOL-FIN-02 accepting new sessions, user sessions removed from POOL-FIN-01`.
Expected result: Stakeholders have a timestamped containment confirmation.

### Rollback Technical Reversion (Run Immediately After Containment)
Run these steps after containment is active.

7. Open `Azure portal > Virtual machines > <AFFECTED_HOST> > Run command > RunPowerShellScript` and run `pnputil /add-driver "<PRECHANGE_INF_FOLDER>\*.inf" /install`. **[ELEVATED]**
Expected result: Output includes successful driver add/install and no failure lines.

8. On the same VM blade, click `Restart`. **[ELEVATED]**
Expected result: VM returns to `Running`.

9. Open `Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts` and confirm `<AFFECTED_HOST>` shows `Status = Available`. **[ELEVATED]**
Expected result: Host is healthy but still drained (`Allow new sessions = No`).

10. Open `Log Analytics workspaces > <WORKSPACE> > Logs` and run `Event | where TimeGenerated >= ago(15m) | where Computer =~ '<AFFECTED_HOST>' | where EventID in (1000,9009) | where RenderedDescription has_any ('dwm.exe','igdumd64.dll')`.
Expected result: Query returns `0` rows.

11. Repeat Step 7 for each remaining affected host. **[ELEVATED]**
Expected result: All affected hosts have the pre-change graphics package reinstalled.

12. Repeat Step 8 for each remaining affected host. **[ELEVATED]**
Expected result: All affected hosts return to `Running`.

13. Repeat Step 9 for each remaining affected host. **[ELEVATED]**
Expected result: All affected hosts show `Status = Available` and remain drained.

14. In `Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts`, set `Allow new sessions = Yes` on one validated host only. **[ELEVATED]**
Expected result: Exactly one host in `POOL-FIN-01` is open for new sessions.

15. Perform one validation logon to that opened host.
Expected result: Desktop loads in under 30 seconds with no black screen and no disconnect.

16. Set `Allow new sessions = Yes` for remaining validated hosts. **[ELEVATED]**
Expected result: `POOL-FIN-01` is safely reintroduced to service.

17. Open a `SEV-2` escalation ticket to AVD Platform Engineering and Endpoint Engineering and attach rollback command output and query results.
Expected result: Specialist teams receive complete evidence for root-cause follow-up.

## 5. Notes
- This runbook is specific to `POOL-FIN-01` black-screen pattern linked to `dwm.exe` crashing in `igdumd64.dll`.
- If `POOL-FIN-02` shows similar errors, stop and declare broader platform incident; do not continue pool-specific assumptions.
- If drain mode cannot be enabled due to permission errors, escalate immediately to on-call Azure subscription owner.
- If checksum does not match approved package, do not install the package; request corrected artifact from Endpoint Engineering.
- If the host fails to return after reboot, keep it drained and engage compute operations for VM health recovery.
- Related incident artifacts:
  - `Day4/AVD-POOL-FIN-01-BlackScreen-RCA.md`
  - `Day4/Known-Error-Record-AVD-POOL-FIN-01-BlackScreen.md`
  - `Day4/AVD-POOL-FIN-01-Closure-Note.md`
- Recommended companion controls from RCA:
  - Canary rollout for image updates.
  - Automated rollback trigger on `dwm.exe` + `igdumd64.dll` Event 1000 signature.
  - Synthetic post-deployment AVD logon checks before full rollout.
