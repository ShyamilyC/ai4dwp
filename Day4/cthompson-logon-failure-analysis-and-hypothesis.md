# User Logon Incident Analysis - cthompson

## Scope Facts
- Symptom: User cthompson not able to login
- Who: cthompson only; one user affected
- Since: ~08:40 this morning
- Change: Nil

## Ranking Logic
The scope points first toward causes that are user-specific rather than service-wide, because only one user is affected and there is no known concurrent change.

## Re-ranked Hypotheses (Most probable first)

1. Account lockout or bad password/credential issue
   - Why it fits: Single-user scope strongly matches an account-specific authentication problem. No wider user impact and no stated change both fit a lockout, repeated bad password, or stale saved credential rather than a platform outage.
   - Fastest check: Check whether the account is currently locked and review the latest sign-in or lockout event for cthompson.

2. Password expired or interactive sign-in blocked by account state
   - Why it fits: This is still user-specific, can start suddenly at a specific time, and does not require an environmental change. A user can report this simply as "cannot login" even when the underlying issue is expiry, disabled account, or a sign-in restriction.
   - Fastest check: Open the account record and verify password expiry status, enabled state, and any sign-in restrictions.

3. User targeted by Conditional Access, MFA, or identity policy challenge/failure
   - Why it fits: A policy or MFA failure can affect one user only, start at a precise time, and appear with no obvious local change to the user. This remains plausible because the scope does not show any wider authentication failure.
   - Fastest check: Review the latest identity sign-in log for cthompson and confirm whether the attempt was blocked by MFA, Conditional Access, or another policy decision.

4. Endpoint-specific issue on the device cthompson is using
   - Why it fits: One-user-only scope also fits a local device problem such as broken network path at the device, cached credential corruption, clock skew, or the logon UI failing on that endpoint. No broader user impact makes a shared back-end fault less likely.
   - Fastest check: Have cthompson attempt sign-in from a different known-good device or session path to separate account problems from endpoint problems.

5. User profile or session initialization failure after successful authentication
   - Why it fits: Users often describe any failure after credential entry as "cannot login." If only cthompson is affected, a profile load problem or session initialization error is possible, though it is less likely than pure authentication causes because the symptom wording does not confirm that credentials are accepted first.
   - Fastest check: Review the target endpoint or session host for User Profile Service or logon/session errors at around 08:40 for cthompson.

## Note
No single root cause is committed yet. This ranking is probability-weighted from the narrow scope: one user only, a clear start time, and no known change.

## Event Evidence Added (2024-03-15 08:44-09:12)

### Affected Endpoint: DESKTOP-FB022
- 08:44:01 - Event 4776 (Audit Failure): Domain credential validation failed for FINBRIDGE\cthompson with error code 0xC000006A (wrong password).
- 08:44:03 - Event 4625 (Audit Failure): Interactive logon failed for FINBRIDGE\cthompson with failure reason unknown user name or bad password.
- 08:44:28 - Event 4625 (Audit Failure): Interactive logon failed for FINBRIDGE\cthompson with failure reason unknown user name or bad password.
- 08:44:55 - Event 4625 (Audit Failure): Interactive logon failed for FINBRIDGE\cthompson with failure reason unknown user name or bad password.
- 08:44:56 - Event 4740 (Audit Failure): FINBRIDGE\cthompson account locked out; caller computer DESKTOP-FB022.
- 08:45:10 - Event 4625 (Audit Failure): Unlock attempt failed for FINBRIDGE\cthompson with failure reason account locked out.

### Additional Authentication Attempts from Other Source
- 08:45:44 - Event 4771 (Audit Failure): Kerberos pre-authentication failed for FINBRIDGE\cthompson with failure code 0x18 (wrong password) from source IP 10.10.8.112.
- 08:46:01 - Event 4771 (Audit Failure): Kerberos pre-authentication failed for FINBRIDGE\cthompson with failure code 0x18 (wrong password) from source IP 10.10.8.112.
- 08:46:33 - Event 4771 (Audit Failure): Kerberos pre-authentication failed for FINBRIDGE\cthompson with failure code 0x18 (wrong password) from source IP 10.10.8.112.

## Hypothesis Assessment Against Evidence

1. Account lockout or bad password/credential issue
   - Verdict: Supports.
   - Determining evidence: Event 4776 at 08:44:01 shows wrong password; Event 4625 at 08:44:03, 08:44:28, and 08:44:55 shows repeated interactive bad-password failures; Event 4740 at 08:44:56 confirms the account was locked out; Event 4625 at 08:45:10 shows a follow-on failure because the account was locked.

2. Password expired or interactive sign-in blocked by account state
   - Verdict: Contradicts.
   - Determining evidence: Event 4776 at 08:44:01 records error 0xC000006A (wrong password), and Event 4771 at 08:45:44, 08:46:01, and 08:46:33 records failure code 0x18 (wrong password). The evidence points to invalid credentials and then lockout, not password-expired or generic sign-in restriction codes.

3. User targeted by Conditional Access, MFA, or identity policy challenge/failure
   - Verdict: Contradicts.
   - Determining evidence: Event 4776 at 08:44:01 and Event 4625 at 08:44:03, 08:44:28, and 08:44:55 all indicate bad password handling at authentication time, while Event 4740 at 08:44:56 shows lockout after repeated failures. No cited event indicates MFA denial, Conditional Access enforcement, or policy-based block.

4. Endpoint-specific issue on the device cthompson is using
   - Verdict: Neutral.
   - Determining evidence: Event 4740 at 08:44:56 identifies DESKTOP-FB022 as the caller computer for the lockout, which is consistent with the user entering bad credentials there. But Event 4771 at 08:45:44, 08:46:01, and 08:46:33 shows additional wrong-password attempts from source IP 10.10.8.112, a different source. That means the endpoint may be part of the symptom path, but these events do not by themselves prove DESKTOP-FB022 has a device fault rather than a credential issue or another stale credential source.

5. User profile or session initialization failure after successful authentication
   - Verdict: Contradicts.
   - Determining evidence: Event 4776 at 08:44:01, Event 4625 at 08:44:03, 08:44:28, and 08:44:55, and Event 4771 at 08:45:44, 08:46:01, and 08:46:33 all show authentication failing before a successful logon is established. Event 4740 at 08:44:56 then confirms lockout. There is no event here showing successful authentication followed by profile or session startup failure.

## Surviving Hypothesis
Account lockout caused by repeated bad password or stale cached credentials for FINBRIDGE\cthompson, with at least one additional authentication source continuing to submit the wrong password after the lockout.

## Detailed Resolution Steps

1. Contain the immediate symptom
   - Unlock the FINBRIDGE\cthompson account.
   - Confirm the user stops attempting sign-in until the stale credential source is identified.
   - Reason: Event 4740 at 08:44:56 shows the account is locked, so restoration starts with clearing the lockout state.

2. Identify all bad-password sources
   - Confirm DESKTOP-FB022 as one source from Event 4740 at 08:44:56 and Event 4625 failures at 08:44:03, 08:44:28, and 08:44:55.
   - Trace source IP 10.10.8.112 from Event 4771 at 08:45:44, 08:46:01, and 08:46:33.
   - Determine whether 10.10.8.112 is another workstation, VPN client, mobile device, legacy app, mapped drive target, or scheduled process.

3. Remove stale credentials from the user endpoint
   - On DESKTOP-FB022, clear saved credentials from Credential Manager.
   - Check for mapped drives, Outlook profiles, Teams, OneDrive, VPN clients, browser-saved credentials, Windows cached credentials, and RunAs entries using old passwords.
   - Sign out and sign back in after clearing any stale entries.

4. Remove stale credentials from the secondary source
   - On the system at 10.10.8.112, inspect for stored credentials, services, scheduled tasks, scripts, mobile mail profiles, or background apps using FINBRIDGE\cthompson.
   - Disable or update any process still attempting authentication with the old password.
   - Reason: The repeated Event 4771 failures after lockout show something beyond the interactive desktop attempt is still submitting a bad password.

5. Verify the correct credential with the user
   - Confirm whether cthompson changed their password recently or may be entering an outdated password.
   - If there is uncertainty, perform a controlled password reset and communicate the new sign-in steps.
   - Ensure the user uses the updated password only after stale sources have been cleaned up.

6. Validate recovery with focused checks
   - Attempt a fresh interactive sign-in on DESKTOP-FB022 after unlock and credential cleanup.
   - Confirm there are no new Event 4776, 4625, 4740, or 4771 failures for FINBRIDGE\cthompson during the test window.
   - Confirm the user can complete desktop sign-in successfully.

7. Monitor for re-lockout
   - Watch authentication and lockout events for FINBRIDGE\cthompson for a short observation period.
   - If failures recur, use the source workstation and source IP fields to isolate any missed device or service still using stale credentials.

8. Close with preventive action
   - Record the offending source or application that held the stale password.
   - If the repeated source was a common client or workflow, publish a short known issue note so future lockouts can be cleared faster.

## Addendum - Event Detail Summary

### Confirmed Event Sequence
- 08:44:01 - Event 4776 on DESKTOP-FB022: Domain credential validation failed for FINBRIDGE\cthompson with error code 0xC000006A (wrong password).
- 08:44:03 - Event 4625 on DESKTOP-FB022: Interactive sign-in failed with failure reason unknown user name or bad password.
- 08:44:28 - Event 4625 on DESKTOP-FB022: Interactive sign-in failed with failure reason unknown user name or bad password.
- 08:44:55 - Event 4625 on DESKTOP-FB022: Interactive sign-in failed with failure reason unknown user name or bad password.
- 08:44:56 - Event 4740 on DESKTOP-FB022: Account FINBRIDGE\cthompson was locked out.
- 08:45:10 - Event 4625 on DESKTOP-FB022: Unlock attempt failed because the account was locked out.
- 08:45:44 - Event 4771 from source IP 10.10.8.112: Kerberos pre-authentication failed with failure code 0x18 (wrong password).
- 08:46:01 - Event 4771 from source IP 10.10.8.112: Kerberos pre-authentication failed with failure code 0x18 (wrong password).
- 08:46:33 - Event 4771 from source IP 10.10.8.112: Kerberos pre-authentication failed with failure code 0x18 (wrong password).

### Appended Surviving Hypothesis
The surviving hypothesis is account lockout caused by repeated bad password entry or stale cached credentials for FINBRIDGE\cthompson, with continued bad-password submissions from at least one secondary source after the lockout occurred.

### Appended Resolution Detail
1. Unlock FINBRIDGE\cthompson and pause further sign-in attempts while the stale credential source is investigated.
2. Treat DESKTOP-FB022 as the confirmed interactive source and investigate source IP 10.10.8.112 as a separate authentication source.
3. Clear saved credentials on DESKTOP-FB022, including Credential Manager entries, mapped drives, mail profiles, collaboration clients, VPN clients, browser-saved credentials, and any RunAs usage.
4. Investigate 10.10.8.112 for stored credentials in services, scheduled tasks, scripts, mobile profiles, or background applications using FINBRIDGE\cthompson.
5. Confirm the correct password with the user or perform a controlled password reset if the current password is uncertain.
6. Retest sign-in only after stale credential sources are cleaned up.
7. Validate success by confirming no fresh Event 4776, 4625, 4740, or 4771 entries appear for FINBRIDGE\cthompson during the retest window.
8. Monitor briefly for re-lockout and record the stale credential source for future prevention.