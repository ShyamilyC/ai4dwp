# jsmith Account Lockout RCA

## Incident summary

During the reviewed 30-minute window, user `jsmith` was locked out of their workstation after repeated failed interactive logon attempts from `DESKTOP-FB001`. Access was restored after administrative intervention by `FINBRIDGE\helpdesk-admin`, followed by a successful interactive logon.

## Event ID explanation

### Event ID 4625

`4625` records a failed logon attempt. In this case, it shows:

- The target account was `jsmith`.
- The source system was `DESKTOP-FB001`.
- `Logon type 2` means an interactive sign-in at the device console.
- `Logon type 7` means an unlock attempt against an existing locked session.
- The failure reason explains whether the problem was a bad password or that the account was already locked.

### Event ID 4740

`4740` records that an account was locked out. It identifies the account that became locked and the calling computer that triggered the lockout event. In this case, the account `jsmith` was locked out, and the triggering system was `DESKTOP-FB001`.

### Event ID 4722

`4722` records that an account was enabled by an administrator or privileged operator. In this incident, `FINBRIDGE\helpdesk-admin` performed that action for `jsmith`, which indicates service-desk intervention before the user could access the device again.

### Event ID 4624

`4624` records a successful logon. Here it confirms that `jsmith` successfully signed in interactively after the account state had been corrected.

## Reconstructed sequence of events

At `08:02:14`, `jsmith` attempted to sign in locally on `DESKTOP-FB001`, but Windows rejected the attempt with `Unknown username or bad password` (`4625`, interactive logon type `2`).

At `08:04:22`, the same account failed a second local interactive sign-in on the same device for the same reason, showing a repeat of the bad-password pattern.

At `08:06:01`, Windows generated `4740`, confirming that `jsmith` was now locked out and that the lockout was triggered from `DESKTOP-FB001`.

At `08:07:45`, a further attempt was made to unlock the session on the same device. The `4625` event this time did not report a bad password; it reported `Account locked out`, which shows the account state, not credentials, was now the blocking issue.

At `08:22:10`, `FINBRIDGE\helpdesk-admin` performed an administrative recovery action recorded as `4722`, enabling the account again.

At `08:23:44`, `jsmith` successfully completed an interactive sign-in (`4624`, logon type `2`), confirming service restoration.

## Most likely cause of the lockout

The most likely cause was repeated incorrect password entry for `jsmith` at the physical workstation `DESKTOP-FB001`, which caused the account to hit the domain or local account lockout threshold.

### Evidence

- Two consecutive `4625` failures at `08:02:14` and `08:04:22` both show `Unknown username or bad password`.
- Both failed attempts came from the same endpoint: `DESKTOP-FB001`.
- The lockout event `4740` occurred immediately afterward at `08:06:01`, also attributing the lockout trigger to `DESKTOP-FB001`.
- The later `4625` at `08:07:45` changed failure reason from bad password to `Account locked out`, confirming the account state had already transitioned to locked.
- After administrative intervention at `08:22:10`, the user successfully logged on at `08:23:44`, which supports the conclusion that the issue was lockout state caused by failed authentication attempts rather than an ongoing system outage.

### Important note on certainty

This excerpt shows at least two bad-password attempts before the lockout. If the environment's lockout threshold is higher than two, then one or more earlier failed attempts likely occurred outside this provided extract or were not included in the sample. The evidence still points to repeated bad credential entry from the same workstation as the trigger.

## Root cause statement

User `jsmith` entered an incorrect password multiple times on `DESKTOP-FB001`, causing the account to meet the configured lockout threshold and become locked until re-enabled by the helpdesk.

## Impact

- User `jsmith` could not access the workstation during the lockout period.
- Service desk intervention was required to restore access.
- User productivity was interrupted for approximately 21 minutes between lockout and administrative recovery.

## 5 Whys analysis

### 1. Why was the user locked out?

Because the account exceeded the configured failed-logon threshold and Windows locked the account (`4740` at `08:06:01`).

### 2. Why did the failed-logon threshold get exceeded?

Because multiple sign-in attempts were made with invalid credentials, as shown by the repeated `4625` bad-password events at `08:02:14` and `08:04:22` from `DESKTOP-FB001`.

### 3. Why were invalid credentials being entered repeatedly?

The most likely explanation is that the user was entering the wrong password at the console, or an outdated cached password was being used during local sign-in or unlock on that same device.

### 4. Why did that lead to a full access outage instead of a single failed sign-in?

Because the environment enforces an account lockout policy that converts repeated failed authentication attempts into a lockout condition, which then blocks further sign-in and unlock attempts until administrative action or policy-based unlock occurs.

### 5. Why was administrative intervention needed to restore access?

Because once the account entered the locked state, the user could not self-recover through normal sign-in. The event trail shows `FINBRIDGE\helpdesk-admin` had to re-enable the account before a successful logon could occur.

## Contributing factors

- Repeated authentication attempts were made from a single workstation in a short time window.
- The user attempted an unlock after the account was already locked, which could not succeed.
- No evidence in the excerpt shows a proactive warning or self-service recovery path before lockout.

## Corrective and preventive actions

1. Confirm with the user whether the password had recently changed or was being entered incorrectly at the device.
2. Review account lockout policy threshold and duration to ensure it matches operational requirements.
3. Check `DESKTOP-FB001` for cached credentials, mapped resources, scheduled tasks, or saved sessions that could replay stale passwords if similar incidents recur.
4. Consider enabling or documenting a self-service password reset or unlock process if permitted by policy.
5. Provide user guidance on verifying keyboard layout, Caps Lock state, and recent password changes before retrying repeated sign-ins.

## Final conclusion

Based on the provided events, this was most likely a credential-related lockout originating from `DESKTOP-FB001`, not a device failure or a general authentication service outage. The evidence chain is consistent: repeated bad-password failures, lockout from the same source, failed unlock due to locked state, administrative re-enable, and immediate successful sign-in.