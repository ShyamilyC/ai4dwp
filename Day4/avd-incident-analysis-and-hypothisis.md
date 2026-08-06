# AVD Incident Analysis - POOL-FIN-01 Black Screen

## Scope Facts
- Symptom: Black screen post-login; clears after ~30s for some users, persists for others
- Who: ~40% of users on POOL-FIN-01
- Control: POOL-FIN-02 completely unaffected
- Since: ~07:00 today
- Change: Overnight image update to POOL-FIN-01 at 02:00; POOL-FIN-02 not updated

## Timing-Clue Conclusion
The cause most consistent with the clue (only FIN-01 updated, FIN-02 unaffected) is:

1. Image-level regression introduced by the 02:00 update to POOL-FIN-01

## Re-ranked Hypotheses (Most probable first)

1. Image-level regression (OS/base image component)
   - Why it fits: Exact time and scope boundary alignment (post-update, single updated pool impacted).
   - Fastest check: Correlate affected sessions to host/image version; confirm impact is on updated build hosts.

2. Startup agent/service changed in new image (AV/EDR/DLP/monitoring)
   - Why it fits: Image-scoped change can delay shell launch and cause black screen after login.
   - Fastest check: Diff startup services/tasks between FIN-01 updated image and FIN-02 baseline.

3. Graphics stack change in updated image (driver/DWM/acceleration setting)
   - Why it fits: Image-only change with known black-screen symptom pattern.
   - Fastest check: Compare graphics driver/settings and DWM/Display events on FIN-01 vs FIN-02.

4. FSLogix/profile attach issue triggered by updated image
   - Why it fits: 30s clear vs persistent behavior matches attach retry/timeout patterns; user variance plausible.
   - Fastest check: Check FSLogix profile logs for attach retries/timeouts at affected login times.

5. GPO/logon script processing latency due to image client/baseline change
   - Why it fits: Possible, but weakest match to strict pool-update isolation unless image changed policy processing behavior.
   - Fastest check: Compare GroupPolicy Operational log processing duration on affected FIN-01 sessions vs FIN-02.

## Note
No single root cause is committed yet; ranking is probability-weighted using the update timing and pool-isolation evidence.

## Event Evidence Added (2024-03-15 07:00-07:30)

### Affected Host: SHFIN-01-A (POOL-FIN-01)
- 07:02:10 - Event 21 (TerminalServices-LocalSessionManager): Session logon succeeded.
- 07:02:14 - Event 1 (Kernel-General): Host boot time 02:03:11 (post overnight image update).
- 07:02:16 - Event 1000 (Application Error): dwm.exe faulting in igdumd64.dll, exception 0xc0000005.
- 07:02:17 - Event 40 (TerminalServices-LocalSessionManager): Session disconnected.
- 07:02:18 - Event 9009 (Desktop Window Manager): DWM exited with code 0x40010004.
- 07:02:44 - Event 21: Session logon succeeded (reconnect).
- 07:02:46 - Event 1000: dwm.exe faulting in igdumd64.dll (repeat crash).
- 07:02:47 - Event 40: Session disconnected.
- 07:03:01 - Event 9009: DWM exited (repeat).
- 07:03:10 - Event 21: Session logon succeeded (second reconnect).
- 07:08:24 - Event 1000: dwm.exe faulting in igdumd64.dll for another user.

### Comparison Host: SHFIN-02-A (POOL-FIN-02, unaffected)
- 07:01:46 - Event 9011 (Desktop Window Manager): DWM started successfully.
- No Application Error Event 1000 entries in the same window.

## Hypothesis Assessment Against Evidence

1. Image-level regression (OS/base image component)
   - Verdict: Supports.
   - Determining evidence: Event 1 at 07:02:14 confirms post-update reboot context on affected host; repeated Event 1000 at 07:02:16 and 07:02:46 occurs on affected updated pool host while comparison host shows Event 9011 at 07:01:46 and no Event 1000.

2. Startup agent/service changed in new image (AV/EDR/DLP/monitoring)
   - Verdict: Neutral.
   - Determining evidence: Event 1000 at 07:02:16 and 07:02:46 plus Event 9009 at 07:02:18 and 07:03:01 show display path failure, but provided logs do not directly confirm or disprove startup agent interaction.

3. Graphics stack change in updated image (driver/DWM/acceleration setting)
   - Verdict: Supports.
   - Determining evidence: Event 1000 at 07:02:16, 07:02:46, and 07:08:24 identifies dwm.exe crashing in igdumd64.dll; Event 9009 at 07:02:18 and 07:03:01 confirms DWM exits; unaffected host has Event 9011 at 07:01:46 and no matching error.

4. FSLogix/profile attach issue triggered by updated image
   - Verdict: Contradicts.
   - Determining evidence: Event 21 successful logons at 07:02:10, 07:02:44, and 07:03:10 occur before crash loop; immediate failure signature is Event 1000/9009 (display subsystem), not profile attach errors in provided logs.

5. GPO/logon script processing latency due to image client/baseline change
   - Verdict: Contradicts.
   - Determining evidence: Event 1000 at 07:02:16 and 07:02:46 with Event 9009 at 07:02:18 and 07:03:01, followed by Event 40 disconnects at 07:02:17 and 07:02:47, indicates crash-disconnect behavior rather than slow policy/script completion.

## Surviving Hypothesis
Graphics stack regression on updated POOL-FIN-01 image, specifically DWM crashing in Intel display driver module igdumd64.dll after login.

## Detailed Resolution Steps

1. Contain impact immediately
   - Set drain mode on affected POOL-FIN-01 session hosts.
   - Route new sessions to POOL-FIN-02.
   - Communicate temporary routing and service impact.

2. Confirm blast radius
   - Query POOL-FIN-01 hosts for Event 1000 (dwm.exe + igdumd64.dll), Event 9009, and Event 40.
   - Track first-seen time and crash counts by host.
   - Verify no equivalent pattern on POOL-FIN-02.

3. Identify exact image/driver delta
   - Compare updated vs pre-update images for Intel graphics driver version/package.
   - Compare WDDM/display acceleration settings.
   - Confirm all affected hosts run updated image stamp.

4. Apply fastest stable remediation
   - Preferred: Roll back POOL-FIN-01 to last known good image (matching POOL-FIN-02 baseline).
   - Alternate: On pilot host, replace Intel graphics driver with known good pre-update version, then reboot.
   - Keep host drained during validation.

5. Pilot validation
   - Test with 3 to 5 representative users.
   - Success criteria:
     - No Event 1000 (dwm.exe/igdumd64.dll) post-login.
     - No Event 9009 DWM exits.
     - No immediate Event 40 disconnect loop.
     - Desktop renders normally within expected login time.
   - Monitor for 30 to 60 minutes under user load.

6. Controlled rollout
   - Apply validated fix to remaining POOL-FIN-01 hosts in batches.
   - Reboot per host, verify logs, then remove drain mode host-by-host.
   - Keep a canary subset under enhanced monitoring before full reopen.

7. Hardening and prevention
   - Freeze problematic image from further deployment.
   - Add image promotion gate with post-login synthetic DWM stability check.
   - Block promotion if dwm.exe plus igdumd64.dll Event 1000 appears.
   - Publish known error record with signature, event pattern, and fixed version.
