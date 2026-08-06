# Ticket T-1008 Triage

## Summary (one line)
VPN connects but internal resources are unreachable after Windows 11 upgrade, indicating probable post-upgrade routing/DNS/policy path issue (to-verify).

## Impact (who/how many/business urgency)
- Who is affected: Reported user post-Win11 upgrade.
- How many affected: Currently one known user/device; wider impact unknown.
- Business urgency: High (to-verify), as user cannot access internal business resources.

## Known facts
- Ticket ID: T-1008.
- Service context: VPN connectivity to corporate environment.
- Symptom: VPN establishes connection.
- Symptom: No internal resources reachable.
- Timing/context: Issue started after Windows 11 upgrade.

## Missing information to gather
- Resource scope: Which internal resources fail (file shares, intranet, line-of-business apps, remote tools).
- Access method: Name-based vs direct address reachability behavior (to-verify).
- Authentication state: Whether VPN shows fully authenticated/healthy session.
- Split tunneling context: Expected route behavior for this user/device profile (to-verify).
- Client details: VPN client version/profile and whether re-provisioning occurred post-upgrade.
- Comparative scope: Other upgraded users on same VPN profile affected or not.
- Network context: Reproduces on different external networks/hotspot.
- Business impact: Critical tasks blocked due to internal resource unavailability.

## Likely category
Network Access -> VPN Post-Upgrade Internal Reachability Failure (to-verify exact ITSM category).

## First diagnostic step
Validate whether issue is DNS vs routing at first touch by testing one known internal resource by hostname and by direct address after VPN connection, then compare outcomes to guide next escalation path.