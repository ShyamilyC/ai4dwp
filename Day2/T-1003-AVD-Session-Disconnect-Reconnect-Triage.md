# Ticket T-1003 Triage

## Summary (one line)
AVD session disconnects after about 10 minutes and then reconnects, suggesting possible session stability/policy/network timeout behavior (to-verify).

## Impact (who/how many/business urgency)
- Who is affected: Reported user(s) using Azure Virtual Desktop (to-verify exact user count).
- How many affected: Unknown; currently one reported ticket.
- Business urgency: Medium to high (to-verify), depending on workload interruption and frequency.

## Known facts
- Ticket ID: T-1003.
- Service context: AVD.
- Symptom: Session disconnects at roughly 10-minute interval.
- Follow-on behavior: Session reconnects after disconnect.

## Missing information to gather
- Scope: Single user vs multiple users, single host pool vs multiple.
- Client details: Windows/macOS/web client and client version (to-verify).
- Network context: Office, home, or VPN path and whether issue reproduces across networks.
- Session pattern: Happens when idle, active, or both.
- Timing evidence: Approximate timestamps for recent disconnect/reconnect events.
- Host/session details: Assigned host pool, session host name, and region (sanitised).
- Change history: Recent policy updates, image changes, agent updates, or network/firewall adjustments (to-verify).
- Business impact: Whether users lose unsaved work or critical call/meeting continuity.

## Likely category
End User Compute -> Azure Virtual Desktop Session Stability (to-verify exact ITSM category).

## First diagnostic step
Reproduce with the user while collecting precise timestamps and connection path, then correlate one disconnect event against AVD session diagnostics to determine whether the drop is client-side, network-path related, or session-host/policy driven.