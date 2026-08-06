# Triage Summary — VPN Connects but No Internal Resources Reachable After Win11 Upgrade

**Summary:** VPN connects successfully but internal resources are unreachable following a Win11 upgrade.
**Impact:** Affected user(s) fully blocked from internal systems; high priority given potential data/work access loss.
**Known facts:** Issue follows Win11 upgrade; VPN connection establishes without error; internal resources (file shares, intranet, internal apps — to confirm which) are not reachable post-connection.
**Missing info:** Which internal resources are affected (all or specific); whether DNS resolution is failing or routing is the issue; split-tunnel vs full-tunnel VPN config; whether other users on the same upgrade batch are affected; any VPN client version change alongside the upgrade.
**Likely category:** VPN client misconfiguration or DNS/routing regression introduced by Win11 upgrade (e.g. changed network adapter binding order, broken split-tunnel routes, or updated VPN client incompatible with Win11 network stack).
**First step:** Check VPN client logs and run `ipconfig /all` + `nslookup <internal-host>` post-connection to determine whether DNS resolution or routing is the failure point.
