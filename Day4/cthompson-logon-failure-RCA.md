# Root Cause Analysis (RCA)
## Incident: cthompson Logon Failure and Account Lockout

## 1. Executive Summary
On 2024-03-15, user FINBRIDGE\cthompson was unable to log on, with the incident window starting at approximately 08:40. The issue was limited to one user and was ultimately traced to repeated bad-password submissions that led to account lockout, with continued authentication failures also observed from a second source after the lockout occurred.

The incident was resolved at 09:09 AM after the recommended remediation was applied. Recovery was validated by a successful account-state recovery event at 09:08:14 and a successful interactive logon at 09:09:01 from DESKTOP-FB022. User verification confirmed successful access to the host with no further issues reported.

## 2. Business Impact
- Affected population: one user, FINBRIDGE\cthompson.
- User-facing symptom: unable to log on to the workstation/host.
- Service scope: isolated user incident, not a wider authentication outage.
- Operational impact: short-duration access loss for the affected user and service desk intervention required.

## 3. Scope Facts and Initial Conditions
- Symptom onset: around 08:40.
- Who affected: cthompson only.
- Reported change: nil.
- Initial probability weighting: user-specific causes ranked above platform-wide causes because there was no evidence of broader user impact.

## 4. Supporting Technical Evidence

### Primary Failure Evidence: DESKTOP-FB022
- 08:44:01 - Security Event 4776 (Audit Failure): Domain controller credential validation failed for FINBRIDGE\cthompson with error code 0xC000006A (wrong password).
- 08:44:03 - Security Event 4625 (Audit Failure): Interactive logon failed for FINBRIDGE\cthompson with failure reason unknown user name or bad password; source DESKTOP-FB022.
- 08:44:28 - Security Event 4625 (Audit Failure): Interactive logon failed for FINBRIDGE\cthompson with failure reason unknown user name or bad password; source DESKTOP-FB022.
- 08:44:55 - Security Event 4625 (Audit Failure): Interactive logon failed for FINBRIDGE\cthompson with failure reason unknown user name or bad password; source DESKTOP-FB022.
- 08:44:56 - Security Event 4740 (Audit Failure): Account FINBRIDGE\cthompson was locked out; caller computer DESKTOP-FB022.
- 08:45:10 - Security Event 4625 (Audit Failure): Unlock attempt failed for FINBRIDGE\cthompson because the account was locked out; logon type 7; source DESKTOP-FB022.

### Additional Failure Evidence: Secondary Authentication Source
- 08:45:44 - Security Event 4771 (Audit Failure): Kerberos pre-authentication failed for FINBRIDGE\cthompson with failure code 0x18 (wrong password); source IP 10.10.8.112.
- 08:46:01 - Security Event 4771 (Audit Failure): Kerberos pre-authentication failed for FINBRIDGE\cthompson with failure code 0x18 (wrong password); source IP 10.10.8.112.
- 08:46:33 - Security Event 4771 (Audit Failure): Kerberos pre-authentication failed for FINBRIDGE\cthompson with failure code 0x18 (wrong password); source IP 10.10.8.112.

### Recovery and Verification Evidence
- 09:08:14 - Security Event 4722 (Audit Success): Account FINBRIDGE\cthompson was enabled; action performed by FINBRIDGE\helpdesk-admin.
- 09:09:01 - Security Event 4624 (Audit Success): FINBRIDGE\cthompson successfully logged on interactively; source DESKTOP-FB022.
- 09:09 AM - User verification: user confirmed successful logon to host and no issues reported.

### Interpretation
The failure evidence shows a clear sequence of bad-password authentication failures followed by account lockout on DESKTOP-FB022. The later Kerberos pre-authentication failures from 10.10.8.112 show that invalid credentials continued to be submitted from an additional source even after the user account was locked. The recovery evidence confirms that account-state remediation was applied and that the user could successfully complete an interactive logon immediately afterward.

## 5. Hypothesis Elimination Summary
1. Account lockout or bad password/credential issue: supported.
2. Password expired or interactive sign-in blocked by account state: contradicted by wrong-password event codes rather than expiry/restriction signatures.
3. Conditional Access, MFA, or identity policy challenge/failure: contradicted by direct bad-password and lockout evidence.
4. Endpoint-specific issue on the device in use: neutral, because DESKTOP-FB022 was a confirmed source of bad attempts, but the evidence did not prove a device fault as the primary cause.
5. User profile or session initialization failure after authentication: contradicted by the absence of successful logon before failure in the incident window.

## 6. Confirmed Root Cause
The incident was caused by repeated submission of an incorrect password, or stale cached credentials using an outdated password, for FINBRIDGE\cthompson. These repeated failures triggered account lockout on DESKTOP-FB022 at 08:44:56, and additional bad-password attempts from source IP 10.10.8.112 continued after the lockout, indicating at least one secondary source still held invalid credentials.

## 7. Detailed Incident Timeline
- Around 08:40 - User begins experiencing inability to log on.
- 08:44:01 - Event 4776 records wrong-password credential validation failure for FINBRIDGE\cthompson.
- 08:44:03 - Event 4625 records first interactive bad-password logon failure from DESKTOP-FB022.
- 08:44:28 - Event 4625 records second interactive bad-password logon failure from DESKTOP-FB022.
- 08:44:55 - Event 4625 records third interactive bad-password logon failure from DESKTOP-FB022.
- 08:44:56 - Event 4740 records account lockout for FINBRIDGE\cthompson, caller computer DESKTOP-FB022.
- 08:45:10 - Event 4625 records failed unlock attempt because the account was locked out.
- 08:45:44 - Event 4771 records Kerberos pre-authentication failure from source IP 10.10.8.112.
- 08:46:01 - Event 4771 records another Kerberos pre-authentication failure from source IP 10.10.8.112.
- 08:46:33 - Event 4771 records a third Kerberos pre-authentication failure from source IP 10.10.8.112.
- Incident triage window - Hypothesis ranking and evidence-based elimination completed.
- Remediation window - Recommended account-state and stale-credential remediation actions applied.
- 09:08:14 - Event 4722 records account FINBRIDGE\cthompson enabled by FINBRIDGE\helpdesk-admin.
- 09:09:01 - Event 4624 records successful interactive logon by FINBRIDGE\cthompson on DESKTOP-FB022.
- 09:09 AM - User verifies access restored and no issues reported.

## 8. Resolution Actions Performed
1. Immediate restoration
- Account-state remediation was performed by helpdesk administration, evidenced by Event 4722 at 09:08:14.
- The affected user then performed a fresh interactive sign-in on DESKTOP-FB022.

2. Credential-path recovery
- The previously recommended resolution path was applied to address the bad-password or stale-credential condition.
- The working hypothesis for resolution remains that invalid saved or cached credentials were cleared or corrected before retest.

3. Recovery validation
- Successful logon was confirmed by Security Event 4624 at 09:09:01.
- User validation confirmed the logon completed successfully and no further issue was reported.

## 9. 5 Whys Analysis
1. Why could cthompson not log on?
Because authentication attempts failed and the account became locked.

2. Why did authentication attempts fail?
Because the environment received repeated wrong-password submissions for FINBRIDGE\cthompson, evidenced by Event 4776 at 08:44:01 and Event 4625 at 08:44:03, 08:44:28, and 08:44:55.

3. Why did the account become locked?
Because repeated failed authentication attempts reached the lockout threshold, evidenced by Event 4740 at 08:44:56.

4. Why did failed attempts continue even after the account was locked?
Because at least one additional source still held and continued using invalid credentials, evidenced by Event 4771 at 08:45:44, 08:46:01, and 08:46:33 from source IP 10.10.8.112.

5. Why was this able to impact the user instead of being corrected earlier?
Because stale or incorrect credential use across one or more client sources was not identified and cleared before repeated authentication retries caused lockout.

## 10. Preventive and Corrective Actions

### A. Credential Hygiene
1. Identify and clear any saved credentials associated with FINBRIDGE\cthompson on DESKTOP-FB022.
2. Investigate source IP 10.10.8.112 for services, scheduled tasks, mail/mobile profiles, mapped drives, scripts, or applications using cached credentials.
3. Instruct users to update saved credentials immediately after password changes.

### B. Monitoring and Detection
1. Add alerting for repeated Event 4776, 4625, or 4771 failures for the same user within a short time window.
2. Add correlation alerting for Event 4740 lockouts followed by continued bad-password attempts from additional sources.
3. Improve service desk visibility of caller computer and source IP details during account lockout triage.

### C. Service Desk Process
1. Update the lockout triage playbook to require checking both interactive source workstation and any secondary source IPs.
2. Include Credential Manager, Outlook, Teams, OneDrive, VPN clients, mobile mail, scheduled tasks, and mapped drives in the standard stale-credential checklist.
3. Require post-remediation validation of a successful Event 4624 logon before incident closure.

### D. User Education
1. Remind users to avoid repeated sign-in retries when they suspect password issues.
2. Provide guidance on updating passwords on secondary devices and applications after a password change.

## 11. Owners and Target Actions
- Service Desk Operations: update lockout triage checklist and closure validation steps.
- Identity and Access Management: review lockout monitoring and alerting improvements.
- Endpoint Support: identify and remediate stale credential sources on user endpoints and secondary devices.

Target: implement playbook and monitoring improvements in the next operational review cycle.

## 12. Closure Statement
Incident resolved at 09:09 AM. Supporting evidence shows account-state remediation at 09:08:14 and successful interactive logon at 09:09:01. User confirmation verified restored access to the host with no further issues reported.