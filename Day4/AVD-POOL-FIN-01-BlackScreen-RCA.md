# Root Cause Analysis (RCA)
## Incident: AVD Black Screen Post-Login on POOL-FIN-01

## 1. Executive Summary
On 2024-03-15, users connecting to AVD hosts in POOL-FIN-01 experienced black screens immediately after logon. Some sessions recovered after about 30 seconds, while others disconnected and required reconnect attempts. The incident started after an overnight image update to POOL-FIN-01 at 02:00. POOL-FIN-02, which was not updated, remained fully healthy.

The issue was resolved by 10:00 AM after applying the remediation plan to restore a known-good graphics stack baseline on POOL-FIN-01 hosts and validating successful user logons.

## 2. Business Impact
- Affected population: approximately 40% of POOL-FIN-01 users.
- User-facing symptom: black screen post-login, intermittent disconnect/reconnect loops.
- Service scope: limited to POOL-FIN-01.
- Unaffected control group: POOL-FIN-02 users had normal service.

## 3. Scope Facts and Change Correlation
- Symptom onset: around 07:00.
- Infrastructure change: overnight image update to POOL-FIN-01 at 02:00.
- Control condition: POOL-FIN-02 was not updated and had no incidents.
- Correlation strength: high, due to strict time and scope alignment.

## 4. Supporting Technical Evidence

### Affected Host Evidence (SHFIN-01-A)
- 07:02:10 - Event 21 (TerminalServices-LocalSessionManager): Session logon succeeded.
- 07:02:14 - Event 1 (Kernel-General): System boot time 02:03:11, confirming restart after overnight update.
- 07:02:16 - Event 1000 (Application Error): dwm.exe faulting module igdumd64.dll, exception 0xc0000005.
- 07:02:17 - Event 40 (TerminalServices-LocalSessionManager): Session disconnected.
- 07:02:18 - Event 9009 (Desktop Window Manager): DWM exited with code 0x40010004.
- 07:02:44 - Event 21: Session logon succeeded (reconnect).
- 07:02:46 - Event 1000: dwm.exe faulting module igdumd64.dll (repeat).
- 07:02:47 - Event 40: Session disconnected (repeat).
- 07:03:01 - Event 9009: DWM exited (repeat).
- 07:03:10 - Event 21: Session logon succeeded (second reconnect).
- 07:08:24 - Event 1000: Same dwm.exe/igdumd64.dll fault for another user.

### Unaffected Control Host Evidence (SHFIN-02-A, POOL-FIN-02)
- 07:01:44 - Event 21: Session logon succeeded.
- 07:01:46 - Event 9011 (Desktop Window Manager): DWM started successfully.
- No Application Error Event 1000 entries in the same incident window.

### Interpretation
The failure pattern is explicit and repeated on updated pool hosts: successful logon followed by DWM crash in Intel graphics module igdumd64.dll and immediate disconnect behavior. The unaffected pre-update pool lacks this error signature.

## 5. Hypothesis Elimination Summary
1. Image-level regression: supported.
2. Startup agent/service change: neutral (not evidenced directly in supplied logs).
3. Graphics stack regression: supported strongly by repeated dwm.exe -> igdumd64.dll crashes.
4. FSLogix/profile attach issue: contradicted by successful logons before display subsystem crash sequence.
5. GPO/logon script latency: contradicted by crash/disconnect loop signatures rather than long-processing signatures.

## 6. Confirmed Root Cause
A graphics stack regression was introduced in the updated POOL-FIN-01 image. During user sign-in, Desktop Window Manager (dwm.exe) repeatedly crashed in Intel graphics driver module igdumd64.dll (Event 1000), causing DWM termination (Event 9009) and session disconnect/reconnect behavior.

## 7. Detailed Incident Timeline
- 02:00 - Overnight image update applied to POOL-FIN-01.
- 02:03:11 - Updated host reboot recorded (Kernel-General Event 1 reported at 07:02:14).
- Around 07:00 - User impact starts; black screen complaints begin.
- 07:02:10 - First observed successful logon on SHFIN-01-A.
- 07:02:16 to 07:03:01 - Repeating crash cycle:
  - Event 1000 (dwm.exe fault in igdumd64.dll)
  - Event 9009 (DWM exit)
  - Event 40 (session disconnect)
- 07:08:24 - Same crash signature observed for additional affected user.
- Incident triage window - Hypothesis ranking and elimination completed using event evidence and unaffected control pool comparison.
- Remediation window - Containment and known-good graphics baseline restoration applied to POOL-FIN-01 hosts.
- 10:00 - Service restored and verified: users can log in to POOL-FIN-01 with no reported issues.

## 8. Resolution Actions Performed
1. Immediate containment
- Drained impacted POOL-FIN-01 hosts to reduce new failed logons.
- Directed new sessions to healthy capacity while remediation proceeded.

2. Technical remediation
- Restored known-good graphics stack baseline on POOL-FIN-01 hosts by applying the approved rollback path from the remediation plan.
- Rebooted remediated hosts and validated event logs post-change.

3. Service recovery validation
- Verified user logons to POOL-FIN-01 hosts after remediation.
- Confirmed no ongoing black-screen reports.
- Confirmed absence of repeated Event 1000 dwm.exe/igdumd64.dll and Event 9009 patterns during verification window.

## 9. 5 Whys Analysis
1. Why did users see a black screen after login?
Because Desktop Window Manager was terminating during session initialization.

2. Why was Desktop Window Manager terminating?
Because dwm.exe crashed with Application Error Event 1000 in module igdumd64.dll with exception 0xc0000005.

3. Why was dwm.exe crashing in igdumd64.dll on these hosts?
Because the updated POOL-FIN-01 image introduced a graphics stack state (driver/version/config combination) that was unstable during AVD logon rendering.

4. Why did this affect only a subset of users and only POOL-FIN-01?
Because only POOL-FIN-01 received the overnight update; the crash triggers occurred when sessions landed on updated hosts and executed the affected render path. POOL-FIN-02 remained on pre-update baseline and stable.

5. Why was this regression not detected before production impact?
Because image promotion controls did not include a mandatory post-deployment synthetic AVD login validation focused on DWM/graphics crash detection and did not use staged canary rollout with automated rollback gating.

## 10. Preventive and Corrective Actions

### A. Image Governance and Release Safety
1. Introduce phased canary deployment for AVD image updates (small subset first, then progressive rollout).
2. Add automatic rollback trigger if canary hosts emit any dwm.exe Event 1000 with igdumd64.dll within validation period.
3. Require formal sign-off checklist before expanding image rollout to full pool.

### B. Validation and Monitoring
1. Implement synthetic logon tests after each image update that validate shell render and desktop readiness.
2. Add alert rules for this failure signature:
   - Application Error Event 1000 where application = dwm.exe and module = igdumd64.dll.
   - Desktop Window Manager Event 9009 spikes.
   - Correlated TerminalServices Event 40 disconnect spikes within 60 seconds of Event 21 logon.
3. Add pool-to-pool health comparison dashboard to quickly isolate update-induced regressions.

### C. Configuration and Dependency Controls
1. Pin approved Intel graphics driver versions for AVD images and track exceptions through change control.
2. Maintain a known-good driver package repository with rapid redeploy instructions.
3. Record image component diffs (driver versions, display settings, startup components) for every release artifact.

### D. Operational Readiness
1. Publish and maintain known error record for black screen with DWM/igdumd64.dll signature.
2. Run incident response drill for image rollback and host draining procedures.
3. Update service desk triage playbook with specific event IDs and escalation trigger thresholds.

## 11. Owners and Target Dates
- AVD Platform Engineering: canary rollout and rollback automation.
- Endpoint Engineering: approved graphics driver baseline and image diff controls.
- Monitoring/SRE: event correlation alerts and dashboard coverage.
- Service Operations: updated triage/known-error documentation and validation checklist.

Target completion: within 2 release cycles, with weekly progress review until all actions are closed.

## 12. Closure Statement
Incident resolved at 10:00 AM. Post-remediation verification confirmed successful user logons to POOL-FIN-01 hosts and no further black-screen reports in the validation window.