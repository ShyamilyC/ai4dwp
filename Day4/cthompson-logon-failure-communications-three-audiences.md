# End-User Communication Pack - cthompson Logon Failure

## Audience 1 - Non-Technical Executive (under 80 words)
Your access and data are safe. One user, cthompson, could not sign in from about 8:40 AM because repeated incorrect or saved old sign-in details locked the account, and another source kept retrying. IT restored the account at 9:08 AM, confirmed a successful sign-in at 9:09 AM from the same computer, and the user reported no further issues. No action is needed unless this happens again; contact the IT Service Desk.

## Audience 2 - Affected End-User Team (under 100 words)
Hi team, your access and data are safe. From about 8:40 AM, cthompson could not sign in because repeated wrong or saved old sign-in details locked the account, and another device kept retrying. IT restored the account at 9:08 AM, confirmed a successful sign-in at 9:09 AM from the same computer, and the user reported no further issues. If you see the same problem, stop retrying, then contact the IT Service Desk.

## Audience 3 - Engineer-to-Engineer Internal Note
Subject: cthompson logon failure - closure and handoff details

Status:
- Resolved at 09:09 AM.
- User verified successful logon to host and no further issues reported.
- Single-user scope only: FINBRIDGE\cthompson.

Same incident facts carried forward:
- Symptom started around 08:40.
- Repeated bad password submission or stale cached credentials locked the account.
- Secondary source continued bad-password attempts after lockout.
- Account was restored at 09:08 AM and successful interactive sign-in was confirmed at 09:09 AM from the same endpoint.

Root cause:
- Repeated submission of an incorrect password, or stale cached credentials using an outdated password, for FINBRIDGE\cthompson.
- These failures triggered lockout on DESKTOP-FB022, and additional bad-password attempts continued from source IP 10.10.8.112.

Supporting evidence:
- 08:44:01 - Event 4776 on DESKTOP-FB022: 0xC000006A wrong password.
- 08:44:03 - Event 4625 on DESKTOP-FB022: interactive logon failed, bad password.
- 08:44:28 - Event 4625 on DESKTOP-FB022: interactive logon failed, bad password.
- 08:44:55 - Event 4625 on DESKTOP-FB022: interactive logon failed, bad password.
- 08:44:56 - Event 4740: account locked out; caller computer DESKTOP-FB022.
- 08:45:10 - Event 4625: unlock attempt failed because account locked out.
- 08:45:44 - Event 4771 from 10.10.8.112: pre-auth failed, 0x18 wrong password.
- 08:46:01 - Event 4771 from 10.10.8.112: pre-auth failed, 0x18 wrong password.
- 08:46:33 - Event 4771 from 10.10.8.112: pre-auth failed, 0x18 wrong password.
- 09:08:14 - Event 4722: account enabled by FINBRIDGE\helpdesk-admin.
- 09:09:01 - Event 4624 on DESKTOP-FB022: successful interactive logon for FINBRIDGE\cthompson.

Exact action taken:
1. Applied the recommended account-state and stale-credential remediation path.
2. Account was enabled by FINBRIDGE\helpdesk-admin at 09:08:14.
3. User performed a fresh interactive sign-in on DESKTOP-FB022.

Config detail to retain:
- Affected user: FINBRIDGE\cthompson.
- Primary interactive source: DESKTOP-FB022.
- Secondary auth source: 10.10.8.112.
- Lockout indicator: Event 4740.
- Failure indicators: Event 4776, Event 4625, Event 4771 with wrong-password codes.
- Recovery indicator: Event 4722 followed by Event 4624.

Verification step performed:
- Confirmed Event 4624 at 09:09:01 on DESKTOP-FB022 for FINBRIDGE\cthompson.
- User confirmed successful access to host with no further issues.

Preventive action needed:
1. Check both the interactive endpoint and any secondary source IP during lockout triage.
2. Clear saved credentials from Credential Manager, mail profiles, collaboration clients, VPN clients, mobile devices, mapped drives, scheduled tasks, scripts, and services after password changes.
3. Add alerting for clustered Event 4776, 4625, or 4771 failures and for Event 4740 followed by continued attempts from another source.
4. Require successful Event 4624 verification before closure on future lockout incidents.