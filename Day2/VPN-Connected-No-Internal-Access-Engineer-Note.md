Root cause:
Win11 upgrade removed the legacy VPN client and did not trigger Intune re-deployment of the new client due to a detection-rule gap.

Action taken:
Manually removed stale VPN registry entries under HKLM\SOFTWARE\<vendor>.
Force-triggered Intune sync.
New VPN client deployed.
Split-tunnel config applied.

Verification:
Connectivity confirmed to all internal subnets.
No data loss.

Preventive action needed:
Fix the Intune detection-rule gap so the Win11 upgrade scenario triggers automatic re-deployment of the new VPN client.
