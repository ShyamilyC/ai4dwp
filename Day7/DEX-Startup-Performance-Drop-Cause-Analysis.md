# DEX Startup Performance Drop - Ranked Cause Analysis

## Context Used for Ranking
- Affected group: Finance-Win11 (215 devices).
- Change applied: 2026-08-04 02:00, security baseline deployed to Finance-Win11 only.
- Immediate signal shift: startup score fell from 84 (2026-08-03) to 61 (2026-08-04), then stayed degraded (59-60).
- Clean comparison: IT-Win11 (40 devices), not targeted by the change, remained stable (85 -> 84 -> 85).

## Ranked Likely Causes

### 1) New startup compliance-logging script in the deployed baseline is adding synchronous logon/startup delay
Why it fits the evidence:
- Timing matches exactly: degradation starts on the first full day after the 02:00 deployment.
- Scope matches exactly: only the changed group (Finance-Win11) degraded; unchanged IT-Win11 stayed stable.
- Symptom matches startup path impact: a startup/logon script is directly in the critical path from login to usable desktop.

Fastest check to confirm or eliminate:
- On a small Finance pilot ring, temporarily disable only the startup script portion of the baseline (keep other settings), force policy refresh, and measure next-login startup median for 5-10 test devices.
- If startup time rapidly returns near pre-change levels while controls remain unchanged, this cause is strongly confirmed.

### 2) Additional Defender scan policy introduced in the same baseline is causing heavy logon-time scan activity
Why it fits the evidence:
- Timing and scope also align with the targeted baseline rollout to Finance only.
- Mechanism is plausible for startup regression: more aggressive scan behavior can consume CPU and disk during early session initialization.
- Comparison group stability strengthens this: IT-Win11 did not get the policy and did not show degradation.

Fastest check to confirm or eliminate:
- Compare Defender operational telemetry on affected Finance devices before vs after 2026-08-04 (scan start at logon, CPU/disk impact in first 5-10 minutes).
- Then run a controlled pilot with only the Defender-scan delta rolled back (script unchanged) and re-measure startup.

### 3) Combined baseline interaction effect (startup script + Defender policy together) causing additive contention at logon
Why it fits the evidence:
- Both settings were introduced at the same timestamp to the same group, and the degradation is immediate and sustained.
- If each individual change is moderate alone, their overlap at logon can still produce a large step-change in startup time.
- Clean unaffected group again supports a change-driven effect rather than platform-wide drift.

Fastest check to confirm or eliminate:
- Use an A/B/C split within Finance test devices for one login cycle:
	- A: script enabled, Defender delta disabled
	- B: script disabled, Defender delta enabled
	- C: both enabled
- Compare startup medians across A/B/C vs control. A materially worse C than A or B indicates interaction/additive impact.

## Confidence Note
Ranking is intentionally weighted toward the 2026-08-04 02:00 targeted config change and the stable unaffected comparison group, which together are the strongest available evidence.
