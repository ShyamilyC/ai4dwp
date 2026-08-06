Symptom     : User FINBRIDGE\cthompson was unable to log on to the workstation/host from about 08:40. The user later confirmed access was restored and no further issues were reported.

Cause       : The verified root cause was repeated submission of an incorrect password, or stale cached credentials using an outdated password, for FINBRIDGE\cthompson. These failures triggered account lockout on DESKTOP-FB022, while additional bad-password attempts continued from source IP 10.10.8.112.

Scope       : The incident affected one user only: FINBRIDGE\cthompson. The confirmed systems in the incident evidence were DESKTOP-FB022 and a secondary authentication source at 10.10.8.112.

Workaround  : Restore account access by applying the account-state remediation and then perform a fresh interactive sign-in from DESKTOP-FB022. In this incident, account restoration was evidenced by Event 4722 at 09:08:14 and successful sign-in by Event 4624 at 09:09:01.

Permanent fix: Apply the stale-credential remediation path so invalid saved or cached credentials are cleared or corrected before retest. The lasting resolution in this case was completed before the verified successful logon at 09:09:01.

How to spot it: Look for Security Event 4776 with error code 0xC000006A (wrong password), Security Event 4625 with failure reason unknown user name or bad password, and Security Event 4740 showing account lockout on DESKTOP-FB022. Also look for Security Event 4771 with failure code 0x18 (wrong password) from source IP 10.10.8.112, followed by recovery evidence from Security Event 4722 and successful logon Event 4624.