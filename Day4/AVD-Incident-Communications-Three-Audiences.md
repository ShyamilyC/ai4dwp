# End-User Communication Pack - AVD Black Screen Incident

## Audience 1 - Non-Technical Executive (under 80 words)
Your access and data are safe. This morning, after a 2:00 AM overnight update to one desktop group (POOL-FIN-01), about 40% of users in that group saw a black screen after sign-in; some recovered in about 30 seconds, others had to reconnect. A second group (POOL-FIN-02) was unaffected. We resolved this by 10:00 AM and verified normal sign-ins with no new issues. No action is required; if it recurs, contact the IT Service Desk.

## Audience 2 - Affected End-User Team (under 100 words)
Hi team, your access and data are safe. This morning, after a 2:00 AM update to POOL-FIN-01, about 40% of users in that pool saw a black screen after sign-in; for some it cleared in about 30 seconds, and for others it caused reconnect attempts, while POOL-FIN-02 was unaffected. The fix was completed by 10:00 AM, and we verified users are signing in normally with no further issues reported. If you see the same issue again, reconnect once and then contact the IT Service Desk.

## Audience 3 - Engineer-to-Engineer Internal Note
Subject: POOL-FIN-01 black screen incident - closure and handoff details

Status:
- Resolved at 10:00 AM.
- Post-fix verification confirmed successful user logons on POOL-FIN-01 with no further black-screen reports.
- Data/access impact: session experience only; user access and data are safe.

Scope and timeline facts:
- Symptom onset around 07:00.
- Impacted cohort: about 40% of users on POOL-FIN-01.
- Control pool POOL-FIN-02 remained unaffected.
- Change correlation: overnight image update to POOL-FIN-01 at 02:00; POOL-FIN-02 not updated.

Root cause:
- Graphics stack regression introduced in updated POOL-FIN-01 image.
- During sign-in, dwm.exe repeatedly faulted in igdumd64.dll (Intel display driver path), causing DWM exit and session disconnect/reconnect behavior.

Supporting evidence used:
- Affected host SHFIN-01-A:
  - 07:02:16, Event 1000 (Application Error): dwm.exe faulting module igdumd64.dll, exception 0xc0000005.
  - 07:02:18, Event 9009 (Desktop Window Manager): DWM exited (0x40010004).
  - 07:02:17, Event 40 (TS LSM): session disconnected.
  - Repeats at 07:02:46 (Event 1000), 07:02:47 (Event 40), 07:03:01 (Event 9009), and another user hit at 07:08:24 (Event 1000).
- Control host SHFIN-02-A:
  - 07:01:46, Event 9011: DWM started successfully.
  - No Event 1000 in same window.

Exact action taken:
1. Contained impact by draining affected POOL-FIN-01 hosts and routing active sign-ins to healthy capacity.
2. Restored known-good graphics stack baseline on POOL-FIN-01 via approved rollback path.
3. Rebooted remediated hosts.
4. Validated logs and user outcomes before reopening capacity.

Config detail to retain for recurrence handling:
- Fault signature: Application Error Event 1000 where app = dwm.exe and module = igdumd64.dll.
- Correlated events: DWM Event 9009 and TS session disconnect Event 40 shortly after Event 21 logon.
- Change boundary: issue confined to updated POOL-FIN-01 image baseline.

Verification step performed:
- Confirmed users can log in to POOL-FIN-01 after remediation.
- Confirmed no repeat Event 1000 dwm.exe/igdumd64.dll and no recurring Event 9009 pattern during verification window.

Preventive action required:
1. Enforce canary rollout for image updates with progressive expansion gates.
2. Add automated rollback trigger if canary emits dwm.exe Event 1000 with igdumd64.dll.
3. Add mandatory post-update synthetic logon and shell-render validation.
4. Alert on Event 1000 (dwm.exe/igdumd64.dll), Event 9009 spikes, and Event 40 spikes within 60 seconds of Event 21.
5. Pin approved graphics driver baseline and maintain known-good driver rollback package.
6. Keep pool-to-pool comparison dashboard and updated known-error runbook for service desk.