# GPO Missing on Win11 Machines (Floor 3) - Scope-Based Hypothesis Analysis

Date: 2026-08-06
Role: DWP Engineer

## Instruction Boundary
This analysis uses only the provided scope facts and does not commit to a single root cause.

## Scope Facts
- Machines affected: Three
- Build: Win 11
- Since: Nil
- Change: Nil

## Ranked Top 5 Most Likely Causes (Most Probable First)

### 1) OU misplacement or security filtering issue (targeting mismatch)
Why this cause fits the scope facts:
- Only three devices are affected, which strongly indicates a targeting/scoping issue rather than a domain-wide GPO outage.
- "Since: Nil" and "Change: Nil" do not rule out accidental OU move or group membership drift.

Single fastest check:
- Run gpresult /r on one affected machine and verify whether the expected GPO appears under Applied GPOs or Denied GPOs (with reason).

### 2) AD replication delay or inconsistency between domain controllers
Why this cause fits the scope facts:
- A small subset of devices can fail GPO application when authenticating against a DC with stale OU/group or GPO metadata.
- No declared change can still coexist with replication lag or partial sync.

Single fastest check:
- On an affected machine, run echo %logonserver% and compare policy behavior/visibility when checking against another DC.

### 3) SYSVOL/NETLOGON access issue from Floor 3 network path
Why this cause fits the scope facts:
- If the three machines are in the same floor segment/VLAN, they may be unable to read policy files while otherwise appearing online.
- That condition presents as "missing" GPO on endpoints.

Single fastest check:
- From one affected machine, open \\<domain>\SYSVOL and verify read access and normal response.

### 4) Client-side Group Policy processing failure (GPSVC/CSE/WMI)
Why this cause fits the scope facts:
- Endpoint-local processing failures commonly impact a small set of devices with similar health/state.
- Win11 build commonality supports a potential client-side processing issue.

Single fastest check:
- Run gpupdate /force, then immediately review Microsoft-Windows-GroupPolicy/Operational for current-cycle errors.

### 5) DNS/site mapping issue causing suboptimal DC selection
Why this cause fits the scope facts:
- Floor-specific resolver or site mapping drift can affect only a few nearby endpoints.
- Wrong DC/site selection can cause policy application gaps without a visible "change" event.

Single fastest check:
- Run nltest /dsgetdc:<yourdomain> on an affected machine and confirm expected DC/site; compare with a healthy Floor 3 peer.

## Note
This is a hypothesis ranking only. No single cause is confirmed yet.

## Evidence Review Update (Event Logs) - Appended

### Evidence Source Snapshot
- Affected machine timeline provided for DESKTOP-FB031 during startup window 07:40-07:55.
- Comparison host provided for DESKTOP-FB029 (same OU, unaffected).
- DHCP comparison shows affected hosts received decommissioned DNS while unaffected host had correct DNS.

### Hypothesis-by-Hypothesis Judgement Against Evidence

#### 1) OU misplacement or security filtering issue (targeting mismatch)
Judgement: Contradicts

Evidence anchors (Event ID and timestamp):
- 07:40:08 Netlogon Event 5719: no domain controller available; DNS query no response.
- 07:40:09 GroupPolicy Event 1058: cannot access \\FINBRIDGE-DC01\sysvol\...\gpt.ini.
- 07:40:12 GroupPolicy Event 1129: no network connectivity to a domain controller.

Reasoning:
- The failure pattern indicates DNS/DC reachability and SYSVOL access failure, not policy scope filtering behavior.

#### 2) AD replication delay or inconsistency between domain controllers
Judgement: Neutral (weakly contradicting)

Evidence anchors (Event ID and timestamp):
- 07:40:08 Netlogon Event 5719: no DC available due to DNS failure.
- 07:41:05 DNS Client Event 1014: DNS timeout; configured DNS servers did not respond.

Reasoning:
- No direct replication-error evidence is present in the supplied logs. Connectivity failure can mask policy retrieval and is a more immediate explanation.

#### 3) SYSVOL/NETLOGON access issue from Floor 3 network path
Judgement: Supports

Evidence anchors (Event ID and timestamp):
- 07:40:09 and 07:40:11 GroupPolicy Event 1058: SYSVOL path for gpt.ini not accessible.
- 07:40:10 GroupPolicy Event 1030: cannot query list of GPOs.
- 07:40:12 and 07:44:01 GroupPolicy Event 1129: no DC connectivity.

Reasoning:
- The exact errors are SYSVOL/DC accessibility failures, which directly align with this hypothesis.

#### 4) Client-side Group Policy processing failure (GPSVC/CSE/WMI)
Judgement: Contradicts

Evidence anchors (Event ID and timestamp):
- 07:40:08 Netlogon Event 5719: secure channel/DC unavailable.
- 07:41:05 DNS Client Event 1014: DNS infrastructure unreachable from client.
- 07:42:18 DHCP Client Event 50036: old DNS server assigned.

Reasoning:
- Evidence points to upstream DNS/DC dependency failure rather than local Group Policy engine malfunction.

#### 5) DNS/site mapping issue causing suboptimal DC selection
Judgement: Strongly supports

Evidence anchors (Event ID and timestamp):
- 07:41:05 DNS Client Event 1014: resolution timeout and non-responsive DNS servers.
- 07:40:08 Netlogon Event 5719: DNS query for FINBRIDGE-DC01 returned no response.
- 07:42:18 DHCP Client Event 50036: DNS assigned as old/decommissioned server.
- Comparison host 07:40:05 DHCP Client Event 50036: correct new DNS assigned.
- Comparison host 07:40:11 GroupPolicy Event 1500: Group Policy processed successfully.

Reasoning:
- The affected vs unaffected split is explained directly by DNS assignment differences.

### Surviving Hypothesis
DNS/site resolution failure caused by incorrect DHCP DNS assignment on the Floor 3 subnet.

### Detailed Resolution Steps

#### 1) Confirm current fault condition
1. On one affected endpoint, run `ipconfig /all` and verify DNS points to old/decommissioned resolver.
2. Run `nslookup FINBRIDGE-DC01.finbridge.local` and confirm timeout/failure.
3. Run `nltest /dsgetdc:finbridge.local` and confirm DC discovery issues.

#### 2) Correct DHCP scope options (primary fix)
1. Open DHCP management on the authoritative DHCP server.
2. Locate the Floor 3 subnet scope.
3. Update Option 006 (DNS Servers):
	- Remove decommissioned DNS IP entries.
	- Add valid current DNS server IPs in correct priority order.
4. Validate there are no conflicting DNS values at:
	- Scope options
	- Server options
	- Reservation options (if used for impacted devices)
5. If DHCP failover is in use, replicate/sync to partner.

#### 3) Refresh client leases and DNS cache
1. On each affected endpoint run:
	- `ipconfig /release`
	- `ipconfig /renew`
	- `ipconfig /flushdns`
2. Re-run `ipconfig /all` to verify corrected DNS assignment.

#### 4) Validate domain and SYSVOL reachability
1. Run `nslookup FINBRIDGE-DC01.finbridge.local`.
2. Run `nltest /dsgetdc:finbridge.local`.
3. Browse `\\FINBRIDGE-DC01\sysvol\finbridge.local\Policies\`.

#### 5) Reprocess and verify Group Policy
1. Run `gpupdate /force`.
2. Confirm via `gpresult /r` that expected GPOs are applied.
3. Check for absence of fresh startup-cycle errors:
	- Netlogon 5719
	- GroupPolicy 1058/1030/1129
4. Confirm successful policy processing events where available.

#### 6) Validate all impacted devices and close out
1. Repeat checks on all three affected machines.
2. Reboot one representative machine to confirm startup policy application is healthy.
3. Compare with unaffected baseline behavior.

#### 7) Prevent recurrence
1. Remove legacy DNS references from DHCP templates/documentation.
2. Add migration checklist control: verify DHCP Option 006 per subnet before and after DNS cutover.
3. Implement monitoring alerts for spikes in:
	- DNS Client Event 1014
	- Netlogon Event 5719
	- GroupPolicy Events 1058/1030/1129
