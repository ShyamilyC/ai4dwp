# Autopilot Enrolment Failure — Stale MDM Record Conflict

**Author:** DWP Engineer  
**Date:** 2026-08-11  
**Severity:** High — device cannot be provisioned until resolved  
**Status:** Remediation confirmed, preventive action defined

---

## 1. Incident Summary

An endpoint failed Windows Autopilot enrolment. The MDM diagnostic export returned a hard failure with error code `0x80180014` and a secondary policy-application error of `0x80070005`. Investigation identified a stale legacy MDM enrolment record from 2023 as the confirmed root cause. Licensing and network were not contributing factors.

---

## 2. Scope Facts (from MDM diagnostic export)

| Field | Value |
|---|---|
| Enrolment state | **Failed** |
| Error code | `0x80180014` |
| Error description | The device is already enrolled in MDM *(provided by export)* |
| Existing MDM enrolment | Yes — legacy manual enrolment dated **2023-11-04** |
| Enrolment source | Legacy manual MDM enrolment |
| Profiles applied | **0 of 4** |
| Last error (policy) | `0x80070005` — Access Denied *(confirmed Win32 ERROR_ACCESS_DENIED)* |
| Azure AD joined | Yes |
| Intune P1 licence | Yes |
| Autopilot licence | Yes |
| Network | All endpoints reachable, no proxy |

---

## 3. Error Code Reference

| Code | Status | Meaning |
|---|---|---|
| `0x80070005` | **Confirmed** | Standard Windows `ERROR_ACCESS_DENIED` (Win32 error 5), wrapped in HRESULT `0x8007xxxx` format. The MDM management agent was denied permissions to apply policy — consistent with a management authority conflict caused by the existing enrolment. |
| `0x80180014` | **Description taken from export** | Export states: *"The device is already enrolled in MDM."* This falls within the `0x8018xxxx` range used for Microsoft MDM/enrolment HRESULTs. Independent confirmation of the exact canonical code definition should be verified against [Microsoft MDM enrollment error reference](https://learn.microsoft.com/en-us/windows/client-management/mdm/mdm-enrollment-of-windows-devices) if required for formal records. |

---

## 4. Root Cause Analysis

**Confirmed root cause:** The device retains an active MDM enrolment record from a legacy manual enrolment performed on 2023-11-04. Autopilot cannot complete enrolment over a conflicting existing enrolment — the MDM stack rejects the new enrolment attempt at the point of registration, resulting in `0x80180014`. Because enrolment never completes, the management agent has no valid authority to apply configuration profiles, producing `0x80070005` (Access Denied) on all 4 profile pushes.

**Factors confirmed as not contributing:**

- Licensing (Intune P1 + Autopilot) — present and correct
- Network connectivity — all endpoints reachable, no proxy
- Azure AD join state — device is joined

---

## 5. Differential (Hypotheses Considered and Eliminated)

| Hypothesis | Eliminated by |
|---|---|
| Licensing gap preventing enrolment | `IntuneP1License: Yes`, `AutopilotLicense: Yes` in export |
| Network / proxy blocking Autopilot endpoints | `Network: All endpoints reachable, no proxy` in export |
| Azure AD join failure | `AzureADJoined: Yes` in export |
| Autopilot profile not assigned | Not evidenced — retained as secondary check during remediation verification |

---

## 6. Remediation — Order of Operations

> Steps marked **[ADMIN CENTER]** require only Intune/Azure portal access.  
> Steps marked **[DEVICE]** require physical access or an active remote session.

| # | Step | Location | Notes |
|---|---|---|---|
| 1 | Sign in to `intune.microsoft.com` | **[ADMIN CENTER]** | Requires Intune Administrator or Global Administrator role |
| 2 | Navigate to `Devices > All devices` — search by device serial or hostname — locate the 2023-11-04 legacy record | **[ADMIN CENTER]** | |
| 3 | Select the legacy device record → **Delete** | **[ADMIN CENTER]** | Use **Delete**, not Retire or Wipe — Retire leaves the object; Wipe triggers a factory reset command that may conflict |
| 4 | Navigate to `portal.azure.com > Azure Active Directory > Devices` — search for the same device — **Delete** the stale AAD device object if present | **[ADMIN CENTER]** | Removing only the Intune record without removing the AAD object can cause a duplicate object conflict on re-enrolment |
| 5 | Navigate to `intune.microsoft.com > Devices > Enrol devices > Windows enrollment > Devices` — confirm device serial is listed and assigned to the correct Autopilot deployment profile | **[ADMIN CENTER]** | If the serial is missing, import it via CSV or re-register via OEM/partner before proceeding |
| 6 | On the device: `Settings > Accounts > Access work or school` — if an active connection is shown, click **Disconnect** and confirm | **[DEVICE]** | Removes the local MDM connection entry; clears the user-visible enrolment |
| 7 | On the device: `Settings > System > Recovery > Reset this PC > Remove everything > Cloud download` | **[DEVICE]** | **Cloud download** ensures a clean OS image. This removes all local MDM artefacts including certificates and registry entries under `HKLM\SOFTWARE\Microsoft\Enrollments` |
| 8 | Allow the device to boot into OOBE — Autopilot detects the registered serial and begins provisioning automatically | **[DEVICE]** | Do not interrupt OOBE or attempt to skip Autopilot screens |

> **Critical sequencing note:** Complete steps 1–5 (cloud-side cleanup) before performing steps 6–8 (device reset). If the device re-registers before the stale cloud records are removed, a duplicate object conflict can occur and the failure will repeat.

---

## 7. Verification — Confirming Successful Remediation

Perform all checks within 30–60 minutes of OOBE completion:

**Admin center checks:**

1. `intune.microsoft.com > Devices > All devices` — device appears with **Enrolment type: Windows Autopilot**
2. `Devices > [Device] > Device configuration` — all 4 profiles show status **Succeeded** (resolves the `0 of 4` failure)
3. `Devices > Monitor > Enrollment failures` — device serial no longer listed
4. Compliance state shows **Compliant** or **In grace period** (grace period is expected for a freshly enrolled device)

**Device-side check:**

5. Run `dsregcmd /status` in an elevated command prompt — confirm:
   - `AzureAdJoined : YES`
   - `MDMUrl` populated with the tenant Intune URL
   - No legacy/duplicate enrolment IDs visible

---

## 8. Preventive Action — Legacy Enrolment Conflicts at Scale

To prevent this recurring across other devices with legacy manual enrolments:

**Immediate (before next Autopilot deployment wave):**

1. In `intune.microsoft.com > Devices > All devices`, filter by **Enrolment type** or sort by **Enrolled date** to identify all devices with pre-Autopilot manual enrolments
2. Export the list and cross-reference against the Autopilot device register (`Devices > Enrol devices > Windows enrollment > Devices`)
3. For any device appearing in **both** lists, raise a remediation task to delete the legacy Intune and Azure AD records **before** the device enters the Autopilot deployment wave

**Process control (ongoing):**

4. Establish a mandatory device decommission step in the rebuild/redeployment runbook: the Intune record and Azure AD device object **must** be deleted by an admin before any device is handed to the rebuild team for Autopilot provisioning
5. Add this as a pre-flight checklist item in any Autopilot deployment playbook — confirm `Devices > All devices` shows no existing record for the target serial before initiating OOBE

**Optional — enrolment restriction (admin center):**

6. Review `Devices > Enrol devices > Enrollment restrictions` — consider restricting personally-owned device enrolment to reduce future legacy enrolment accumulation, while ensuring corporate-owned devices are correctly classified via Autopilot registration

---

## 9. Summary

| Item | Detail |
|---|---|
| **Root cause** | Stale legacy MDM enrolment (2023-11-04) not removed before Autopilot provisioning |
| **Primary error** | `0x80180014` — device already enrolled, Autopilot rejected |
| **Secondary error** | `0x80070005` — Access Denied on all 4 profile pushes (consequence of enrolment failure) |
| **Licensing/network** | Not implicated |
| **Resolution** | Delete legacy Intune and AAD records → full device reset → Autopilot from clean OOBE |
| **Prevention** | Pre-flight decommission step added to rebuild runbook; bulk audit of legacy-enrolled devices before next Autopilot wave |

---

*Document prepared by DWP Engineer | Autopilot enrolment failure analysis | 2026-08-11*
