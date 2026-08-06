# Ticket T-1006 Triage

## Summary (one line)
User reports broad system slowness after upgrading to Windows 11 two days ago, requiring baseline and resource-path validation (to-verify root cause).

## Impact (who/how many/business urgency)
- Who is affected: Single user (currently reported) after Win11 upgrade.
- How many affected: One known device; broader pattern unknown (to-verify).
- Business urgency: Medium (to-verify), potentially high if productivity is materially reduced.

## Known facts
- Ticket ID: T-1006.
- Change context: User upgraded to Windows 11 two days ago.
- Symptom statement: "Everything is slow" (generalised performance complaint).

## Missing information to gather
- Symptom scope: Startup, login, app launch, browser, file access, or network latency.
- Repro pattern: Constant vs intermittent, and time-of-day/load correlation.
- Hardware profile: Device model, RAM/storage type/free space, and power mode.
- Upgrade path: In-place upgrade vs rebuild and whether post-upgrade tasks completed.
- Background activity: Ongoing indexing, sync, update scans, endpoint security scans (to-verify).
- App specificity: Which business apps are most impacted and by how much.
- Comparison: Whether similar complaints exist for same hardware model/upgrade cohort.
- Business impact: Missed SLAs, delayed case handling, or blocked deliverables.

## Likely category
Endpoint Performance -> Post-Windows 11 Upgrade Degradation (to-verify exact ITSM category).

## First diagnostic step
Capture a quick performance baseline with the user during a slow period (CPU, memory, disk, and startup load indicators) to identify whether degradation is resource-bound, app-specific, or network-dependent before remediation.