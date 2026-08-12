# Windows 11 – Intune Compliance Policy: Security Baseline Translation

**Author:** DWP Engineer  
**Date:** 2026-08-11 (UI paths verified against Microsoft Docs — last doc update 2026-07-01)  
**Scope:** Windows 11 managed devices enrolled in Microsoft Intune  
**Grace Period:** 7 days applied to all settings below  

---

## How to apply the grace period

In the Intune portal, when assigning the compliance policy:  
`intune.microsoft.com > Devices > Compliance policies > [Policy] > Properties > Actions for noncompliance`

> When **creating** a new policy, the full entry sequence is: **Platform = Windows 10 and later** → **Profile type = Windows 10/11 compliance policy** → Create. The settings sections (Device Health, Device Properties, System Security, Microsoft Defender for Endpoint) only appear after selecting that profile type.  
Set **"Mark device noncompliant"** action to **Schedule (days after noncompliance): 7**

---

## Requirement 1 – BitLocker must be enabled on the OS drive

| Field | Detail |
|---|---|
| **Setting name** | Require BitLocker |
| **Intune UI path** | `intune.microsoft.com > Devices > Compliance policies > Create policy > Platform: Windows 10 and later > Profile type: Windows 10/11 compliance policy > Device Health > Windows Health Attestation Service evaluation rules > Require BitLocker` |
| **Value** | Require |
| **Effect** | The device must have BitLocker Drive Encryption active on the OS (C:) drive. Devices without encryption are marked non-compliant. |
| **False-positive risk** | Devices where BitLocker is provisioned but the volume encryption is still **in progress** at the time of compliance check will fail. Also fails on fresh Autopilot builds before the first BitLocker policy has applied. Compliance is evaluated at **boot time only** — a reboot is required after encryption completes before the device shows as compliant. |
| **Recommendation** | Ensure the BitLocker Intune configuration profile is assigned and has applied *before* the compliance policy is evaluated. Use a compliance grace period of 7 days to cover initial enrolment windows. |

> ✅ **UI path confirmed:** BitLocker is under **Device Health > Windows Health Attestation Service evaluation rules**. Note: there is also a separate **System Security > Encryption > Encryption of data storage on a device** setting — that is a weaker generic check; use the Device Health BitLocker setting for TPM-backed validation.

---

## Requirement 2 – Secure Boot must be enabled

| Field | Detail |
|---|---|
| **Setting name** | Require Secure Boot to be enabled on the device |
| **Intune UI path** | `intune.microsoft.com > Devices > Compliance policies > Create policy > Platform: Windows 10 and later > Profile type: Windows 10/11 compliance policy > Device Health > Windows Health Attestation Service evaluation rules > Require Secure Boot to be enabled on the device` |
| **Value** | Require |
| **Effect** | The device UEFI firmware must have Secure Boot active. This prevents boot-level rootkits and unsigned boot loaders from running. Reported via the Windows Health Attestation Service. |
| **False-positive risk** | Legacy BIOS devices (non-UEFI) cannot support Secure Boot and will always fail. Devices with TPM 1.2 (rather than 2.0) will show **Not Compliant** — Microsoft docs confirm Secure Boot requires TPM 2.0 or later. |
| **Recommendation** | Run a pre-migration hardware audit to identify non-UEFI and TPM 1.2 devices. Exclude them via a dedicated device group with a relaxed compliance policy rather than disabling Secure Boot enforcement org-wide. |

> ✅ **UI path confirmed:** Setting is under **Device Health > Windows Health Attestation Service evaluation rules**. Note: devices without TPM 2.0 will always report non-compliant for this setting by design.

---

## Requirement 3 – Minimum OS build (N-1 policy)

| Field | Detail |
|---|---|
| **Setting name** | Minimum OS version |
| **Intune UI path** | `intune.microsoft.com > Devices > Compliance policies > Create policy > Platform: Windows 10 and later > Profile type: Windows 10/11 compliance policy > Device Properties > Operating system version > Minimum OS version` |
| **Value** | `10.0.22621.2861` |
| **Effect** | Devices running a build older than Windows 11 22H2 build 22621.2861 (N-1 relative to the current stable release 22621.3155) are marked non-compliant. This enforces a minimum patch currency. |
| **False-positive risk** | Devices pending a Windows Update restart will show the old build number until they reboot. Devices on WUfB (Windows Update for Business) deferral rings may not yet have reached this build. |
| **Recommendation** | Align the minimum build number with your WUfB deferral ring schedule. If your ring is 14 days deferred, allow at least 14 days from patch release before incrementing the minimum build. Review and update this value each Patch Tuesday cycle. Consider using **Valid operating system builds** (also under Device Properties) to specify an acceptable range if you need to support multiple Windows 11 feature versions simultaneously. |

> ✅ **UI path confirmed:** Use the full four-part string in `major.minor.build.revision` format — `10.0.22621.2861`. Windows 11 still reports as `10.0.x` internally. The **Valid operating system builds** alternative setting in the same section accepts min/max ranges and is useful for WUfB ring management.

---

## Requirement 4 – Windows Defender real-time protection must be on

| Field | Detail |
|---|---|
| **Setting name** | Require real-time protection |
| **Intune UI path** | `intune.microsoft.com > Devices > Compliance policies > Create policy > Platform: Windows 10 and later > Profile type: Windows 10/11 compliance policy > System Security > Defender > Real-time protection` |
| **Value** | Require |
| **Effect** | Devices must have Microsoft Defender Antivirus real-time protection actively running. Devices with RTP disabled or with a third-party AV that has suppressed Defender will be flagged. |
| **False-positive risk** | Organisations running an approved third-party AV (e.g. Symantec, CrowdStrike) that registers with the Windows Security Centre and disables Defender RTP will fail this check. Temporary Defender exclusion scripts run by IT can also trigger it. |
| **Recommendation** | If a third-party AV is used, verify it correctly registers as the active AV provider in the Windows Security Centre. If it does, Intune should honour it. If false positives persist, review whether the third-party product is fully WSC-integrated. |

> ✅ **UI path confirmed:** The section heading is **Defender** (not "Antivirus" or "Microsoft Defender Antimalware"). The setting label is **Real-time protection**. Also consider enabling **Microsoft Defender Antimalware** (the service toggle above it in the same section) alongside RTP.

---

## Requirement 5 – Firewall must be enabled for all profiles

| Field | Detail |
|---|---|
| **Setting name** | Microsoft Defender Firewall |
| **Intune UI path** | `intune.microsoft.com > Devices > Compliance policies > Create policy > Platform: Windows 10 and later > Profile type: Windows 10/11 compliance policy > System Security > Device security > Firewall` |
| **Value** | Require |
| **Effect** | Windows Firewall must be active. A single disabled profile across Domain, Private, or Public causes non-compliance. |
| **False-positive risk** | Some enterprise network management tools or legacy Group Policy objects disable the Domain profile firewall on domain-joined machines. Also note: if a device **syncs immediately after a reboot or wake from sleep**, the Firewall check may return an **Error** status — this is a known Intune timing issue and does not necessarily mean the device is non-compliant. A manual sync resolves it. |
| **Recommendation** | Audit existing GPO firewall settings and migrate them to Intune before enabling this check. For per-profile granularity, use `intune.microsoft.com > Endpoint Security > Firewall` policies instead of the compliance toggle. |

> ✅ **UI path confirmed:** The section heading is **Device security** and the setting label is **Firewall** (not "Windows Firewall" or "Microsoft Defender Firewall"). The single toggle covers all three profiles.

---

## Requirement 6 – A PIN or password must be configured

| Field | Detail |
|---|---|
| **Setting name** | Require a password to unlock mobile devices / Password required |
| **Intune UI path** | `intune.microsoft.com > Devices > Compliance policies > Create policy > Windows 10 and later > System Security > Password > Require a password to unlock mobile devices` |
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
| **Setting name** | Require the device to be at or under the machine risk score |
| **Intune UI path** | `intune.microsoft.com > Devices > Compliance policies > Create policy > Platform: Windows 10 and later > Profile type: Windows 10/11 compliance policy > Microsoft Defender for Endpoint > Microsoft Defender for Endpoint rules > Require the device to be at or under the machine risk score` |
| **Value** | `Low` (most secure without false positives) or `Clear` (strictest — flags any detected threat) |
| **Effect** | For Windows 11, there is no direct "jailbreak" toggle as on iOS/Android. This setting uses the **Microsoft Defender for Endpoint (MDE) machine risk score** to flag devices with tampered boot components, active threats, or compromised integrity as non-compliant. |
| **False-positive risk** | Devices running security research tools, penetration testing software, or unsigned drivers may generate elevated risk scores. Transient threat detections that auto-remediate can briefly push a device above "Low". |
| **Recommendation** | Requires **MDE P1 or P2** licensing and the Intune–MDE connector enabled. Set to **Low** rather than **Clear** to tolerate auto-remediated signals. If MDE is not licensed in your tenant, this section will not be available — document this gap and raise a licensing review. |

> ✅ **UI path confirmed:** This setting is under the **Microsoft Defender for Endpoint** section (its own top-level section in the wizard), not under Device Health. MDE connector must be active in your tenant for this setting to function.

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

## UI Paths – Verification Status

All paths below verified against Microsoft Docs (last updated 2026-07-01). Source: [learn.microsoft.com/en-us/intune/intune-service/protect/compliance-policy-create-windows](https://learn.microsoft.com/en-us/intune/intune-service/protect/compliance-policy-create-windows)

| # | Setting | Verified path | Notes |
|---|---|---|---|
| 1 | BitLocker | Device Health > Windows Health Attestation Service evaluation rules | Stays in Device Health — NOT moved to System Security |
| 2 | Secure Boot | Device Health > Windows Health Attestation Service evaluation rules | TPM 2.0 required; TPM 1.2 devices always non-compliant |
| 3 | Minimum OS version | Device Properties > Operating system version | Use full `10.0.x.x` format; consider Valid OS builds for ring mgmt |
| 4 | Defender RTP | System Security > **Defender** > Real-time protection | Section heading is Defender, not Antivirus or Antimalware |
| 5 | Firewall | System Security > **Device security** > Firewall | Section heading is Device security, not Windows Firewall |
| 6 | Password | System Security > Password | Confirmed — no change |
| 7 | Jailbreak/Risk score | **Microsoft Defender for Endpoint** > Microsoft Defender for Endpoint rules | Top-level section in wizard, not under Device Health; requires MDE licence |

**Recommended validation step:** Create the policy in a test tenant or against a pilot device group first, then review the compliance report before broad assignment.

---

*Document prepared by DWP Engineer | Based on Microsoft Intune documentation and Windows 11 security baseline guidance | Build reference: 22621.3155 (current) / 22621.2861 (N-1)*
