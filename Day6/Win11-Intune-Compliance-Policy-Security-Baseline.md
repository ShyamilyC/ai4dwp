# Windows 11 – Intune Compliance Policy: Security Baseline Translation

**Author:** DWP Engineer  
**Date:** 2026-08-10  
**Scope:** Windows 11 managed devices enrolled in Microsoft Intune  
**Grace Period:** 7 days applied to all settings below  

---

## How to apply the grace period

In the Intune portal, when assigning the compliance policy:  
`Intune > Devices > Compliance policies > [Policy] > Properties > Actions for noncompliance`  
Set **"Mark device noncompliant"** action to **Schedule (days after noncompliance): 7**

---

## Requirement 1 – BitLocker must be enabled on the OS drive

| Field | Detail |
|---|---|
| **Setting name** | Require BitLocker |
| **Intune UI path** | `Devices > Compliance policies > Create policy > Windows 10 and later > Device Health > Require BitLocker` |
| **Value** | Require |
| **Effect** | The device must have BitLocker Drive Encryption active on the OS (C:) drive. Devices without encryption are marked non-compliant. |
| **False-positive risk** | Devices where BitLocker is provisioned but the volume encryption is still **in progress** at the time of compliance check will fail. Also fails on fresh Autopilot builds before the first BitLocker policy has applied. |
| **Recommendation** | Ensure the BitLocker Intune configuration profile is assigned and has applied *before* the compliance policy is evaluated. Use a compliance grace period of 7 days to cover initial enrolment windows. |

> ⚠️ **UI change flag:** The BitLocker setting was previously under **Device Health** in the classic Compliance Policies wizard. In newer Intune builds (post-2023) it may appear under **System Security > Encryption**. Verify the current location in your tenant before publishing.

---

## Requirement 2 – Secure Boot must be enabled

| Field | Detail |
|---|---|
| **Setting name** | Require Secure Boot to be enabled on the device |
| **Intune UI path** | `Devices > Compliance policies > Create policy > Windows 10 and later > Device Health > Require Secure Boot to be enabled on the device` |
| **Value** | Require |
| **Effect** | The device UEFI firmware must have Secure Boot active. This prevents boot-level rootkits and unsigned boot loaders from running. Reported via the Windows Health Attestation Service. |
| **False-positive risk** | Legacy BIOS devices (non-UEFI) cannot support Secure Boot and will always fail. Certain older hardware models or custom IT-built machines may have Secure Boot disabled in firmware by default. |
| **Recommendation** | Run a pre-migration hardware audit to identify non-UEFI devices and exclude them via a separate compliance policy or a device group. Do not disable this setting organisation-wide to accommodate a minority of devices. |

> ⚠️ **UI change flag:** Secure Boot compliance relies on the **Windows Health Attestation Service (HAS)**. If your tenant uses a **custom compliance policy (JSON)** or **Endpoint security** rather than the classic wizard, the setting path will differ. Confirm HAS connectivity in your environment.

---

## Requirement 3 – Minimum OS build (N-1 policy)

| Field | Detail |
|---|---|
| **Setting name** | Minimum OS version |
| **Intune UI path** | `Devices > Compliance policies > Create policy > Windows 10 and later > Device Properties > Minimum OS version` |
| **Value** | `10.0.22621.2861` |
| **Effect** | Devices running a build older than Windows 11 22H2 build 22621.2861 (N-1 relative to the current stable release 22621.3155) are marked non-compliant. This enforces a minimum patch currency. |
| **False-positive risk** | Devices pending a Windows Update restart will show the old build number until they reboot. Devices on WUfB (Windows Update for Business) deferral rings may not yet have reached this build. |
| **Recommendation** | Align the minimum build number with your WUfB deferral ring schedule. If your ring is 14 days deferred, allow at least 14 days from patch release before incrementing the minimum build. Review and update this value each Patch Tuesday cycle. |

> ⚠️ **UI change flag:** Intune uses the full four-part version string (`10.0.22621.2861`). Earlier documentation showed three-part strings — always use the full format to avoid unexpected mismatches.

---

## Requirement 4 – Windows Defender real-time protection must be on

| Field | Detail |
|---|---|
| **Setting name** | Require real-time protection |
| **Intune UI path** | `Devices > Compliance policies > Create policy > Windows 10 and later > System Security > Microsoft Defender Antimalware > Require real-time protection` |
| **Value** | Require |
| **Effect** | Devices must have Microsoft Defender Antivirus real-time protection actively running. Devices with RTP disabled or with a third-party AV that has suppressed Defender will be flagged. |
| **False-positive risk** | Organisations running an approved third-party AV (e.g. Symantec, CrowdStrike) that registers with the Windows Security Centre and disables Defender RTP will fail this check. Temporary Defender exclusion scripts run by IT can also trigger it. |
| **Recommendation** | If a third-party AV is used, verify it correctly registers as the active AV provider in the Windows Security Centre. If it does, Intune should honour it. If false positives persist, review whether the third-party product is fully WSC-integrated. |

> ⚠️ **UI change flag:** This setting was previously listed under **Antivirus**. In the Microsoft Intune admin centre (post-2024 refresh), the grouping under **System Security** has been reorganised. Verify the current heading in your tenant.

---

## Requirement 5 – Firewall must be enabled for all profiles

| Field | Detail |
|---|---|
| **Setting name** | Microsoft Defender Firewall |
| **Intune UI path** | `Devices > Compliance policies > Create policy > Windows 10 and later > System Security > Windows Firewall > Microsoft Defender Firewall` |
| **Value** | Require |
| **Effect** | Windows Firewall must be active on all three network profiles: **Domain**, **Private**, and **Public**. A single disabled profile causes non-compliance. |
| **False-positive risk** | Some enterprise network management tools or legacy Group Policy objects disable the Domain profile firewall on domain-joined machines as a misguided "trust" configuration. Devices joining via VPN may briefly show the Public profile as active. |
| **Recommendation** | Audit existing GPO settings for `Network List Manager` and firewall configurations before enabling. Use Intune Firewall configuration profiles to enforce all three profiles simultaneously alongside this compliance check. |

> ⚠️ **UI change flag:** Intune's compliance wizard has a single **Microsoft Defender Firewall** toggle — it evaluates all three profiles. If you need per-profile granularity, use **Endpoint Security > Firewall** policies instead.

---

## Requirement 6 – A PIN or password must be configured

| Field | Detail |
|---|---|
| **Setting name** | Require a password to unlock mobile devices / Password required |
| **Intune UI path** | `Devices > Compliance policies > Create policy > Windows 10 and later > System Security > Password > Require a password to unlock mobile devices` |
| **Value** | Require |
| **Supporting settings** | |
| – Minimum password length | `8` (recommended minimum) |
| – Required password type | `Alphanumeric` or `Numeric (Windows Hello PIN)` |
| – Maximum minutes of inactivity before password is required | `15` |
| **Effect** | The device must have an active password or PIN set. Devices at the Windows sign-in screen with no credentials configured (e.g., auto-logon kiosks or shared lab machines) will be flagged. |
| **False-positive risk** | Shared kiosk/single-app devices configured with auto-logon will always fail. Windows Hello for Business enrolled devices using biometrics (face/fingerprint) satisfy this requirement as a backed credential exists — these should not false-positive. |
| **Recommendation** | Exclude kiosk device groups from this policy and apply a separate Kiosk compliance policy. For WHfB environments, confirm that the Intune Windows Hello configuration profile has applied before compliance is evaluated. |

---

## Requirement 7 – Device must not be jailbroken or rooted

| Field | Detail |
|---|---|
| **Setting name** | Device Health Attestation – No jailbreak |
| **Intune UI path** | `Devices > Compliance policies > Create policy > Windows 10 and later > Device Health > Require the device to be at or under the machine risk score` |
| **Value** | `Low` (or use Microsoft Defender for Endpoint integration: **Clear**) |
| **Effect** | For Windows 11 devices, "jailbroken/rooted" maps to the **Windows Health Attestation** risk score or the **Microsoft Defender for Endpoint (MDE) machine risk score**. A device with tampered boot components, disabled Secure Boot, or active threats will score above "Low/Clear" and be marked non-compliant. |
| **False-positive risk** | Devices running security research tools, penetration testing software, or unsigned drivers may generate elevated risk scores. A misconfigured or unreachable Health Attestation server can cause all devices to appear risky. |
| **Recommendation** | Integrate Microsoft Defender for Endpoint with Intune for the most accurate risk scoring. Set the compliance threshold to **Low** rather than **Clear** to reduce false positives from transient threat signals that auto-remediate. Review MDE alerts alongside compliance reports. |

> ⚠️ **UI change flag:** The "jailbreak" setting for Windows is not a direct toggle as it is on iOS/Android. It is expressed through the **MDE machine risk score** integration or HAS. If your tenant does not have MDE P1/P2 licensed, you will rely solely on HAS, which is less granular. Verify your licensing before configuring.

---

## Summary Table

| # | Requirement | Setting name | Value | Grace period |
|---|---|---|---|---|
| 1 | BitLocker on OS drive | Require BitLocker | Require | 7 days |
| 2 | Secure Boot enabled | Require Secure Boot | Require | 7 days |
| 3 | Minimum OS build N-1 | Minimum OS version | `10.0.22621.2861` | 7 days |
| 4 | Defender RTP on | Require real-time protection | Require | 7 days |
| 5 | Firewall all profiles | Microsoft Defender Firewall | Require | 7 days |
| 6 | PIN or password set | Require a password to unlock | Require | 7 days |
| 7 | Not jailbroken/rooted | Machine risk score | Low / Clear | 7 days |

---

## UI Change Flags – Summary

The following settings should be **verified in your tenant** before publishing, as the Intune admin centre UI has been restructured since late 2023:

1. **BitLocker** – may have moved from *Device Health* to *System Security > Encryption*
2. **Secure Boot** – depends on Health Attestation Service connectivity; custom compliance JSON paths differ
3. **Defender RTP** – grouping under *System Security* was reorganised in the 2024 admin centre refresh
4. **Firewall** – single toggle covers all profiles; per-profile control requires Endpoint Security policies
5. **Jailbreak/Root (Windows)** – no native toggle; requires MDE integration or HAS; verify licensing

**Recommended validation step:** Create the policy in a test tenant or against a pilot device group first, then review the compliance report before broad assignment.

---

*Document prepared by DWP Engineer | Based on Microsoft Intune documentation and Windows 11 security baseline guidance | Build reference: 22621.3155 (current) / 22621.2861 (N-1)*
