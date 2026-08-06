# RCA: Floor 3 Win11 GPO Application Failure

Date: 2026-08-06
Incident date (from logs): 2024-03-15
Prepared by: DWP Engineering
Status: Resolved at 08:00

## 1) Executive Summary
Three Windows 11 machines on Floor 3 failed to apply Group Policy during startup because they could not resolve/reach the domain controller. The affected clients were assigned a decommissioned DNS server via DHCP scope option 006. After DHCP DNS scope correction and client lease/DNS refresh, all three affected machines successfully applied Group Policy. Verification completed at 08:00.

## 2) Impact Assessment
- Affected population: 3 Win11 machines (Floor 3).
- Not affected: devices using correct DNS configuration (comparison host FB029/FB058 behavior provided).
- User impact: startup/session policy processing failure for affected endpoints.
- Technical impact: inability to reach DC/SYSVOL during policy processing window.

## 3) Supporting Evidence

### A) Affected machine event sequence (DESKTOP-FB031)
- 07:40:08 - Netlogon Event 5719 (Error)
  - No domain controller available; DNS query for FINBRIDGE-DC01.finbridge.local returned no response.
- 07:40:09 - GroupPolicy Event 1058 (Error)
  - Cannot access \\FINBRIDGE-DC01\sysvol\finbridge.local\Policies\{3A1B2C4D-E5F6-7890-ABCD-EF1234567890}\gpt.ini
  - Error code 0x3.
- 07:40:10 - GroupPolicy Event 1030 (Warning)
  - Cannot query list of Group Policy objects.
- 07:40:11 - GroupPolicy Event 1058 (Error)
  - Repeat SYSVOL access failure.
- 07:40:12 - GroupPolicy Event 1129 (Error)
  - No network connectivity to a domain controller during policy processing.
- 07:41:05 - DNS Client Event 1014 (Warning)
  - Name resolution timed out; configured DNS servers did not respond.
- 07:42:18 - DHCP Client Event 50036 (Information)
  - DNS assigned by DHCP: old/decommissioned DNS server.
- 07:44:01 - GroupPolicy Event 1129 (Error)
  - Repeated no-DC-connectivity failure.

### B) Unaffected comparison host evidence
- 07:40:05 - DHCP Client Event 50036
  - DNS assigned: correct new DNS server.
- 07:40:11 - GroupPolicy Event 1500 (Information)
  - Group Policy processed successfully.

### C) DHCP server-side comparison evidence
- Affected set (FB055-057): old/decommissioned Floor 3 DNS assigned.
- Unaffected host (FB058): correct central DNS assigned (manually preconfigured).
- Configuration gap: Floor 3 DHCP scope not updated to new DNS after migration wave.

## 4) Timeline (All Times Local)
- 02:00 - Legacy DNS server decommissioned as part of migration wave.
- 07:40:08 - First Netlogon failure (5719) on affected endpoint.
- 07:40:09 to 07:44:01 - Repeated GroupPolicy failures (1058/1030/1129) on affected endpoint.
- 07:41:05 - DNS timeout warning (1014) confirms resolver failure path.
- 07:42:18 - DHCP evidence confirms old DNS assignment on affected endpoint.
- 07:40:05 to 07:40:11 (comparison host) - Correct DNS assignment and successful GPO processing.
- 08:00 - Resolution confirmed; all three affected Win11 machines verified with successful GPO application.

## 5) Root Cause Statement
Primary root cause: Floor 3 DHCP scope option 006 still referenced a decommissioned DNS server after DNS migration, causing affected clients to fail DNS resolution for domain controller discovery and SYSVOL access during Group Policy processing.

Contributing factors:
- DNS migration and DHCP scope update were not fully synchronized for the Floor 3 subnet.
- No pre/post cutover validation gate to confirm DHCP option 006 values per subnet.

## 6) 5-Why Analysis
1. Why did Group Policy fail on the three Win11 machines?
- Because the clients could not contact a domain controller/SYSVOL at startup.

2. Why could they not contact a domain controller?
- Because DNS resolution for FINBRIDGE-DC01 timed out (Netlogon 5719, DNS 1014).

3. Why did DNS resolution time out on only these machines?
- Because these machines received an old/decommissioned DNS server via DHCP.

4. Why was old DNS still assigned by DHCP?
- Because Floor 3 DHCP scope option 006 was not updated after DNS migration.

5. Why was the DHCP scope not updated/validated in time?
- Because the migration process lacked an enforced subnet-level DHCP DNS verification checkpoint and monitoring trigger.

## 7) Resolution Actions Implemented
1. Updated Floor 3 DHCP scope option 006:
- Removed decommissioned DNS server entries.
- Added correct current DNS server entries in proper order.

2. Verified no conflicting DNS settings:
- Checked scope-level, server-level, and reservation-level options.

3. Refreshed affected clients:
- Performed lease renewal and DNS cache refresh.
- Validated corrected DNS assignment.

4. Revalidated domain/policy path:
- Confirmed DC discovery and SYSVOL path access.
- Forced Group Policy processing and confirmed policy application.

5. Closure validation:
- Verified all three affected Win11 machines at 08:00 with successful GPO application.

## 8) Preventive Actions

### Immediate controls
- Add mandatory DHCP option 006 verification for every impacted subnet in DNS cutover runbooks.
- Add post-change validation checklist item: confirm at least one endpoint per subnet receives correct DNS lease.

### Monitoring and detection
- Alert on spikes/correlation for:
  - DNS Client Event 1014
  - Netlogon Event 5719
  - GroupPolicy Events 1058, 1030, 1129
- Add dashboard slice by subnet/floor to identify localized configuration drift quickly.

### Process and governance
- Introduce a formal migration gate requiring sign-off from both DNS and DHCP owners.
- Maintain a live inventory of DHCP scopes and intended DNS option values.
- Include rollback criteria and time-bounded verification windows in change plans.

## 9) Verification and Closure Evidence
- Incident marked resolved at 08:00.
- Verification completed on all three previously affected Win11 machines.
- Group Policy application confirmed successful on all three devices.

## 10) Lessons Learned
- Localized DNS misconfiguration can present as policy engine failure but is often a dependency-path issue.
- Comparison-host evidence is critical for rapid elimination of incorrect hypotheses.
- DHCP scope option checks must be treated as mandatory controls in DNS migrations.
