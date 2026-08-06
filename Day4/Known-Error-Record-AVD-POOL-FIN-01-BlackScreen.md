Symptom     : Users see a black screen immediately after sign-in to AVD. For some users it clears after about 30 seconds; for others the session disconnects and they must reconnect.

Cause       : A graphics stack regression was introduced in the updated POOL-FIN-01 image. During sign-in, dwm.exe crashed in igdumd64.dll (Application Error Event 1000), which led to DWM exits and session disconnect/reconnect behavior.

Scope       : The incident affected approximately 40% of users on POOL-FIN-01. POOL-FIN-02 was unaffected during the same window because it was not updated.

Workaround  : Drain impacted POOL-FIN-01 hosts to reduce new failed logons and route new sessions to healthy capacity. This containment step restores user access while host remediation is performed.

Permanent fix: Restore the known-good graphics stack baseline on POOL-FIN-01 hosts using the approved rollback path, then reboot and validate. Service was confirmed restored by 10:00 AM with successful user logons and no further black-screen reports in the verification window.

How to spot it: Look for Application Error Event 1000 showing dwm.exe faulting in igdumd64.dll with exception 0xc0000005, followed by Desktop Window Manager Event 9009. In affected sessions, TerminalServices-LocalSessionManager Event 40 disconnects occur shortly after Event 21 successful logon, while unaffected hosts show DWM Event 9011 and no Event 1000 in the same window.