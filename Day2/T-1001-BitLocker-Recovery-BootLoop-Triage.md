# Ticket T-1001 Triage

## Summary (one line)
New Windows 11 laptop is prompting for BitLocker recovery key at every boot, indicating recurring pre-boot trust validation failure (to-verify root cause).

## Impact (who/how many/business urgency)
- Who is affected: Single end user with a new laptop (to-verify user role and criticality).
- How many affected: Currently reported as one device/one user.
- Business urgency: Medium to high (to-verify), because repeated recovery prompts interrupt normal access and increase service desk handling effort.

## Known facts
- Ticket ID: T-1001.
- Device state: New Windows 11 laptop.
- Symptom: BitLocker recovery key prompt appears every boot.
- Symptom pattern: Repeats on each restart/boot, not a one-time prompt.

## Missing information to gather
- Device identity: Hostname, asset tag, and serial number (sanitised for public sharing).
- User context: Department, business criticality, and whether VIP/high-priority support applies.
- Enrollment/build status: Whether device is domain-joined or Entra-joined, and managed by Intune/SCCM (to-verify).
- Trigger timing: Whether issue started immediately after first build, after updates, after BIOS/firmware changes, or after docking/peripheral changes.
- Recovery behavior: Whether entering the correct recovery key allows normal boot each time.
- Scope check: Any similar reports from same hardware model or same build wave (to-verify).
- Security posture checks: Any recent TPM/secure boot/firmware policy changes applied to this device cohort (to-verify).
- User impact details: Number of lost working hours and whether this blocks critical business tasks.

## Likely category
Endpoint Security -> BitLocker / Device Encryption Incident (to-verify exact service taxonomy in local ITSM catalog).

## First diagnostic step
Confirm the issue pattern in real time with the user: perform one controlled reboot after successful unlock, verify the recovery prompt reappears, and capture the exact pre-boot behavior and recent change history to determine whether trust state is repeatedly being invalidated.