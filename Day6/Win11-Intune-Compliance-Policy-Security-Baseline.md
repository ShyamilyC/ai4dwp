# Windows 11 – Intune Compliance Policy: Security Baseline Translation

**Author:** DWP Engineer  
**Date:** 2026-08-11  
**Scope:** Windows 11 managed devices enrolled in Microsoft Intune  
**Grace Period:** 7 days applied to all settings (configured in Actions for noncompliance)

---

## How to apply the grace period

Navigate to:
`intune.microsoft.com > Devices > Compliance policies > [Policy] > Properties > Actions for noncompliance`

Set **"Mark device noncompliant"** → **Schedule (days after noncompliance): 7**

> **Policy creation path:** `intune.microsoft.com > Devices > Compliance policies > Create policy`  
> Platform: **Windows 10 and later** → Profile type: **Windows 10/11 compliance policy** → Create  
> The sections (Device Health, Device Properties, System Security, Microsoft Defender for Endpoint) only appear after selecting this profile type.

---

## Requirement 1 – BitLocker must be enabled on the OS drive

| Field | Detail |
|---|---|
| **Setting name** | Require BitLocker |
| **Intune UI path** | `Devices > Compliance policies > Create policy > Platform: Windows 10 and later > Device Health > Windows Health Attestation Service evaluation rules > Require BitLocker` |
| **Value** | Require |
| **Effect** | The device must have BitLocker Drive Encryption active on the OS (C:) drive. Devices without encryption are marked non-compliant. Compliance is validated via the Windows Health Attestation Service, which requires a TPM. |
| **False-positive risk** | Devices where BitLocker provisioning is still **in progress** at time of check will fail. Fresh Autopilot builds before the first BitLocker configuration profile has applied will also fail. Compliance is assessed at boot — a reboot is required after encryption completes before the device shows compliant. |
| **Recommendation** | Ensure the BitLocker Intune configuration profile is assigned and has applied *before* the compliance policy is evaluated. The 7-day grace period covers initial enrolment windows. Do not rely on the weaker **System Security > Encryption > Encryption of data storage on a device** toggle — that does not confirm TPM-backed encryption. |

> ⚠️ **UI path note:** There is a second, weaker encryption setting under System Security > Encryption. Always use the Device Health path above for TPM-backed BitLocker validation. If the Device Health section is absent, verify the device is enrolled via a Windows 11 profile type and has a TPM chip detected.

---

## Requirement 2 – Secure Boot must be enabled

| Field | Detail |
|---|---|
| **Setting name** | Require Secure Boot to be enabled on the device |
| **Intune UI path** | `Devices > Compliance policies > Create policy > Platform: Windows 10 and later > Device Health > Windows Health Attestation Service evaluation rules > Require Secure Boot to be enabled on the device` |
| **Value** | Require |
| **Effect** | The device UEFI firmware must have Secure Boot active. This prevents unsigned bootloaders and boot-level rootkits from running. Validated remotely via the Windows Health Attestation Service. |
| **False-positive risk** | Legacy BIOS (non-UEFI) devices cannot support Secure Boot and will always be non-compliant. Devices with TPM 1.2 (not TPM 2.0) will also always fail — Secure Boot attestation requires TPM 2.0. Some older hardware that supports UEFI may still have Secure Boot disabled in firmware. |
| **Recommendation** | Run a pre-deployment hardware audit to identify non-UEFI and TPM 1.2 devices. Place them in a dedicated device group with a relaxed policy rather than disabling the enforcement org-wide. Do not exempt devices silently — document the gap and track remediation or hardware refresh. |

> ⚠️ **UI path note:** Path is within the same **Windows Health Attestation Service evaluation rules** section as BitLocker (Requirement 1). If this section does not appear, the device may not have a working TPM 2.0 — check device hardware inventory in Intune before troubleshooting the policy.

---

## Requirement 3 – Minimum OS build: N-1 (build 22621.2861)

| Field | Detail |
|---|---|
| **Setting name** | Minimum OS version |
| **Intune UI path** | `Devices > Compliance policies > Create policy > Platform: Windows 10 and later > Device Properties > Operating system version > Minimum OS version` |
| **Value** | `10.0.22621.2861` |
| **Effect** | Devices running a build older than Windows 11 22H2 cumulative update 22621.2861 (N-1 relative to current stable 22621.3155) are marked non-compliant. Enforces a minimum patch currency across the estate. |
| **False-positive risk** | Devices pending a Windows Update restart still report the old build number until they reboot. Devices on Windows Update for Business (WUfB) deferral rings may not yet have reached this build depending on ring delay. |
| **Recommendation** | Align the minimum build value with your WUfB deferral ring schedule — if your ring defers 14 days, allow at least 14 days after patch release before incrementing the minimum. Review and update this value each Patch Tuesday. The **Valid operating system builds** setting (also in Device Properties) accepts min/max ranges and is preferable if managing multiple Windows 11 feature versions simultaneously. |

> ⚠️ **UI path note:** The value must be entered in full four-part `major.minor.build.revision` format — `10.0.22621.2861`. Windows 11 still reports internally as `10.0.x`. Entering only three parts (e.g. `10.0.22621`) is accepted but does not enforce a specific cumulative update level.

---

## Requirement 4 – Windows Defender real-time protection must be on

| Field | Detail |
|---|---|
| **Setting name** | Real-time protection |
| **Intune UI path** | `Devices > Compliance policies > Create policy > Platform: Windows 10 and later > System Security > Defender > Real-time protection` |
| **Value** | Require |
| **Effect** | Microsoft Defender Antivirus real-time protection must be actively running. Devices with RTP disabled, or where a third-party AV has suppressed Defender without correctly registering, will be flagged as non-compliant. |
| **False-positive risk** | Organisations using an approved third-party AV (e.g. CrowdStrike, Symantec) that disables Defender RTP may trigger this if the third-party product does not fully integrate with the Windows Security Centre (WSC). Temporary Defender exclusion scripts run by IT can also briefly trigger non-compliance. |
| **Recommendation** | If a third-party AV is in use, verify it registers correctly as the active AV provider in the Windows Security Centre — Intune reads its compliance state from WSC. If false positives persist, check the AV vendor's WSC integration documentation. Also enable the adjacent **Microsoft Defender Antimalware** service toggle in the same section for defence in depth. |

> ⚠️ **UI path note:** The section heading in the compliance wizard is **Defender** — not "Antivirus", "Antimalware" or "Microsoft Defender Antimalware". If you do not see a Defender section, confirm the policy is scoped to **Windows 10 and later**, not a mobile or macOS profile type.

---

## Requirement 5 – Firewall must be enabled for all profiles

| Field | Detail |
|---|---|
| **Setting name** | Firewall |
| **Intune UI path** | `Devices > Compliance policies > Create policy > Platform: Windows 10 and later > System Security > Device security > Firewall` |
| **Value** | Require |
| **Effect** | Windows Firewall must be active across all three profiles (Domain, Private, Public). A single disabled profile is sufficient to trigger non-compliance. |
| **False-positive risk** | Enterprise network management tools or legacy Group Policy objects that disable the Domain profile on domain-joined machines will cause false positives. Devices syncing immediately after a wake-from-sleep or reboot may briefly return an **Error** state on the Firewall check — this is a known Intune timing issue, not a true policy failure. A manual sync resolves it. |
| **Recommendation** | Audit existing GPO firewall settings before enabling this check and migrate them to Intune Endpoint Security policies. For per-profile firewall control, use `intune.microsoft.com > Endpoint Security > Firewall` policies rather than relying solely on the compliance toggle. |

> ⚠️ **UI path note:** The section heading in the wizard is **Device security**, not "Windows Firewall" or "Microsoft Defender Firewall". The single **Firewall** toggle covers all three profiles. There is no per-profile granularity within the compliance policy — use Endpoint Security > Firewall for that.

---

## Requirement 6 – A PIN or password must be configured

| Field | Detail |
|---|---|
| **Setting name** | Require a password to unlock mobile devices |
| **Intune UI path** | `Devices > Compliance policies > Create policy > Platform: Windows 10 and later > System Security > Password > Require a password to unlock mobile devices` |
| **Value** | Require |
| **Supporting settings** | |
| – Minimum password length | `8` |
| – Required password type | `Alphanumeric` |
| – Maximum minutes of inactivity before password is required | `15` |
| **Effect** | A PIN, password, or Windows Hello for Business credential must be configured on the device. Devices configured for auto-logon or with no credentials set (e.g. shared lab machines, unattended kiosks) will be marked non-compliant. |
| **False-positive risk** | Shared kiosk/single-app devices with auto-logon always fail. Windows Hello for Business devices using biometrics (face or fingerprint) should satisfy this requirement as a backed PIN/credential exists — they should not false-positive if WHfB is correctly provisioned. |
| **Recommendation** | Exclude kiosk and shared device groups from this policy and apply a dedicated Kiosk compliance policy instead. For WHfB environments, ensure the WHfB configuration profile has fully applied before the compliance evaluation runs. |

> ⚠️ **UI path note:** Despite the label saying "mobile devices", this setting applies to Windows 11 PCs when the profile type is **Windows 10 and later**. The label is a legacy carry-over from Intune's unified device management origins. Behaviour on desktops is confirmed to be a standard Windows logon password/PIN check.

---

## Requirement 7 – Device must not be jailbroken or rooted

| Field | Detail |
|---|---|
| **Setting name** | Require the device to be at or under the machine risk score |
| **Intune UI path** | `Devices > Compliance policies > Create policy > Platform: Windows 10 and later > Microsoft Defender for Endpoint > Microsoft Defender for Endpoint rules > Require the device to be at or under the machine risk score` |
| **Value** | `Low` (recommended) or `Clear` (strictest — flags any detected threat signal) |
| **Effect** | Windows 11 has no direct "jailbreak" toggle equivalent to iOS/Android. This setting uses the **Microsoft Defender for Endpoint (MDE) machine risk score** to flag devices with tampered boot components, active threats, or compromised integrity as non-compliant. This is the closest Windows 11 equivalent to a jailbreak/root check. |
| **False-positive risk** | Devices running security research tools, penetration testing software, or unsigned drivers may generate elevated risk scores. Transient threat detections that auto-remediate can briefly push a device above **Low**, triggering a 7-day grace period countdown before the device recovers. |
| **Recommendation** | Set to **Low** rather than **Clear** to tolerate auto-remediated signals and reduce noise. This setting requires **Microsoft Defender for Endpoint Plan 1 or Plan 2** licensing and the **Intune–MDE connector** to be enabled in your tenant (`intune.microsoft.com > Tenant administration > Connectors and tokens > Microsoft Defender for Endpoint`). If MDE is not licensed, this section will not appear in the wizard — document this as a compliance gap and raise a licensing review with your team. |

> ⚠️ **UI path note:** **Microsoft Defender for Endpoint** is a separate top-level section in the compliance wizard — it is NOT under Device Health or System Security. If the section is missing entirely, the MDE connector is not enabled or not licensed. Verify at: `Tenant administration > Connectors and tokens > Microsoft Defender for Endpoint`.

---

## Summary Table

| # | Requirement | Setting name | Value | Grace period |
|---|---|---|---|---|
| 1 | BitLocker on OS drive | Require BitLocker | Require | 7 days |
| 2 | Secure Boot enabled | Require Secure Boot to be enabled on the device | Require | 7 days |
| 3 | Minimum OS build N-1 | Minimum OS version | `10.0.22621.2861` | 7 days |
| 4 | Defender RTP on | Real-time protection | Require | 7 days |
| 5 | Firewall all profiles | Firewall | Require | 7 days |
| 6 | PIN or password set | Require a password to unlock mobile devices | Require | 7 days |
| 7 | Not jailbroken/rooted | Require device at or under machine risk score | Low | 7 days |

---

## UI Path Verification Status

Paths were cross-referenced against Microsoft Learn documentation.  
Source: [learn.microsoft.com – Create a compliance policy: Windows](https://learn.microsoft.com/en-us/intune/intune-service/protect/compliance-policy-create-windows)

| # | Setting | Section in wizard | Verified? | Notes |
|---|---|---|---|---|
| 1 | Require BitLocker | Device Health > Windows Health Attestation Service evaluation rules | ✅ | Not moved to System Security — remains in Device Health |
| 2 | Require Secure Boot | Device Health > Windows Health Attestation Service evaluation rules | ✅ | TPM 2.0 required; TPM 1.2 devices always non-compliant |
| 3 | Minimum OS version | Device Properties > Operating system version | ✅ | Must use full `10.0.x.x` four-part format |
| 4 | Real-time protection | System Security > **Defender** | ✅ | Section heading is "Defender", not "Antivirus" or "Antimalware" |
| 5 | Firewall | System Security > **Device security** | ✅ | Section heading is "Device security", not "Windows Firewall" |
| 6 | Password / PIN | System Security > Password | ✅ | "Mobile devices" label is legacy; applies to Windows 11 PCs |
| 7 | Machine risk score | **Microsoft Defender for Endpoint** (top-level section) | ✅ | Requires MDE P1/P2 licence and Intune–MDE connector active |

> **Recommended validation step:** Deploy the policy to a pilot device group first. Review the compliance report after 48 hours to catch unexpected false positives before broad assignment. Check `Devices > Monitor > Noncompliant devices` for a breakdown by setting.

---

*Document prepared by DWP Engineer | Windows 11 security baseline translation | Build reference: 22621.3155 (current stable) / 22621.2861 (N-1 minimum)*
