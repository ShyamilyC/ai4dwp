# Known Error Record: Floor 3 Win11 GPO Application Failure

Cause: The Floor 3 DHCP scope option 006 still referenced a decommissioned DNS server after the DNS migration. This caused affected clients to fail DNS resolution for domain controller discovery and SYSVOL access during Group Policy processing.

Scope: Three Windows 11 machines on Floor 3 were affected. Users on those endpoints experienced Group Policy application failure at startup, while comparison hosts with correct DNS assignment were unaffected.

Workaround: Manually configure affected endpoints to use the correct new DNS server, then refresh connectivity and policy processing. Validate by renewing lease/DNS state and running Group Policy update to restore service on impacted devices.

Permanent fix: Update the Floor 3 DHCP scope option 006 to remove decommissioned DNS entries and set the correct current DNS server values. Verify there are no conflicting DNS settings at scope, server, or reservation level, then revalidate policy processing on affected clients.

How to spot it: Look for Netlogon Event 5719, GroupPolicy Events 1058/1030/1129, DNS Client Event 1014, and DHCP Client Event 50036 showing old DNS assignment. Typical messages include no domain controller available, DNS query timeout/no response, and inability to access \\FINBRIDGE-DC01\sysvol\...\gpt.ini.
