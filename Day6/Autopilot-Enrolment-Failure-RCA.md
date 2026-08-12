# Root Cause Analysis — Autopilot Enrolment Failure: Stale MDM Enrolment Conflict

**RCA Reference:** RCA-2026-08-11-AUTOPILOT-001  
**Author:** DWP Engineer  
**Date of Incident:** 2026-08-11  
**Date of RCA:** 2026-08-11  
**Status:** Closed — root cause confirmed, remediation defined, preventive action assigned  
**Severity:** High — device could not be provisioned; blocked user deployment

---

## 1. Executive Summary

A Windows endpoint failed Autopilot enrolment with error `0x80180014`. Investigation established that a legacy manual MDM enrolment from November 2023 was never removed before the device was submitted for Autopilot provisioning. The existing enrolment record — present in both the Intune portal and on the device — prevented the new Autopilot enrolment from completing. A secondary error, `0x80070005` (Access Denied), was a direct consequence: with no valid Autopilot enrolment authority established, the MDM agent was denied permission to apply any configuration profiles (0 of 4 succeeded).

Licensing, network connectivity, and Azure AD join state were all healthy and did not contribute.

---

## 2. Supporting Evidence

### 2.1 MDM Diagnostic Export

| Field | Value | Significance |
|---|---|---|
| `EnrollmentState` | Failed | Hard failure — enrolment did not complete |
| `ErrorCode` | `0x80180014` | MDM enrolment rejected — export description: "The device is already enrolled in MDM" |
| `ErrorDescription` | The device is already enrolled in MDM | Provided by the diagnostic export; not inferred |
| `MDMEnrolled` | Yes | Confirms an active MDM enrolment exists on the device |
| `EnrolmentSource` | Legacy manual MDM enrolment | Not an Autopilot enrolment — manually provisioned outside standard process |
| `EnrolmentDate` | 2023-11-04 | Enrolment is approximately 2 years and 9 months old |
| `ProfilesApplied` | 0 of 4 | No configuration profiles applied — policy push completely blocked |
| `LastError` | `0x80070005` | Windows `ERROR_ACCESS_DENIED` — confirmed standard Win32 error 5 in HRESULT format |
| `AzureADJoined` | Yes | Azure AD join is intact — not a contributing factor |
| `IntuneP1License` | Yes | Licensing confirmed present — not a contributing factor |
| `AutopilotLicense` | Yes | Autopilot licensing confirmed — not a contributing factor |
| `Network` | All endpoints reachable, no proxy | Network healthy — not a contributing factor |

### 2.2 Error Code Analysis

| Code | Confidence | Basis |
|---|---|---|
| `0x80070005` | **Confirmed** | Standard Windows `ERROR_ACCESS_DENIED` (Win32 error 5). The `0x8007xxxx` HRESULT prefix wraps standard Win32 error codes. This is well-established and unambiguous. |
| `0x80180014` | **Description taken from export** | The diagnostic export supplied the human-readable description directly. The `0x8018xxxx` range is used for Microsoft MDM/enrolment HRESULTs. The export description is treated as authoritative; independent verification of the canonical code definition is recommended for formal records — see [Microsoft MDM enrollment error reference](https://learn.microsoft.com/en-us/windows/client-management/mdm/mdm-enrollment-of-windows-devices). |

### 2.3 Factors Eliminated

| Factor | Evidence for Elimination |
|---|---|
| Licensing gap | `IntuneP1License: Yes`, `AutopilotLicense: Yes` |
| Network / proxy blocking | `Network: All endpoints reachable, no proxy` |
| Azure AD join failure | `AzureADJoined: Yes` |
| Autopilot profile not assigned | Not confirmed as absent — retained as a secondary check during post-remediation verification |
| Hardware incompatibility | Not evidenced; device reached the enrolment attempt stage successfully |

---

## 3. Incident Timeline

| Time | Event |
|---|---|
| 2023-11-04 | Device manually enrolled in MDM outside of standard Autopilot process (legacy manual enrolment). No Autopilot profile assigned at this time. |
| 2023-11-04 → 2026-08-11 | Device remains under legacy manual MDM management. No decommission or unenrolment action recorded. |
| 2026-08-11 (pre-incident) | Device identified for redeployment and submitted for Autopilot provisioning. No pre-flight check performed to verify existing enrolment state. Legacy Intune and Azure AD device records not deleted before handover. |
| 2026-08-11 | Autopilot enrolment attempted from device OOBE. MDM stack detects existing enrolment — rejects new enrolment with `0x80180014`. |
| 2026-08-11 | MDM agent attempts to apply 4 configuration profiles. With no valid Autopilot enrolment authority, all 4 profile pushes are denied — `0x80070005` returned for each. Final state: `ProfilesApplied: 0 of 4`. |
| 2026-08-11 | MDM diagnostic export collected. Scope facts extracted and analysed. Root cause confirmed. |
| 2026-08-11 | Remediation steps defined. RCA completed. Preventive action assigned. |

---

## 4. Five Whys Analysis

**Problem statement:** Autopilot enrolment failed with error `0x80180014` — the device could not be provisioned.

---

**Why 1 — Why did Autopilot enrolment fail?**

> Because the device already had an active MDM enrolment. The MDM stack detected a conflicting enrolment record and rejected the Autopilot attempt.

---

**Why 2 — Why did the device have an existing MDM enrolment?**

> Because the device was manually enrolled in MDM in November 2023 and was never properly unenrolled before being submitted for Autopilot reprovisioning. The local enrolment state, MDM certificates, and registry entries persisted on the device.

---

**Why 3 — Why was the legacy enrolment not removed before the Autopilot attempt?**

> Because no pre-flight check or decommission step was performed before the device was handed to the rebuild team. There was no documented process requiring the existing Intune device record and Azure AD object to be deleted prior to Autopilot re-deployment.

---

**Why 4 — Why was there no decommission process in place?**

> Because the organisation's device redeployment process was designed around a manual MDM enrolment model. When Autopilot was introduced, the redeployment runbook was not updated to include a cloud-record cleanup step as a prerequisite for provisioning. The assumption was that a device reset would clear all relevant state — it does not clear the cloud-side Intune and Azure AD records.

---

**Why 5 — Why was the runbook not updated when Autopilot was adopted?**

> Because the transition to Autopilot did not include a formal process review of the existing device lifecycle and decommission procedures. Legacy enrolment cleanup was not identified as a dependency, and no ownership was assigned for maintaining the runbook in line with MDM model changes.

---

**Root cause (confirmed):** The absence of a mandatory decommission step — requiring deletion of legacy Intune and Azure AD device records before Autopilot provisioning — combined with a device redeployment process that was not updated when Autopilot was adopted.

---

## 5. Remediation — Confirmed Steps

> **[ADMIN CENTER]** = Intune or Azure portal only, no device access required.  
> **[DEVICE]** = Requires physical access or active remote session.

### Order of operations — cloud cleanup first, device reset second

| # | Step | Location | Detail |
|---|---|---|---|
| 1 | Open `intune.microsoft.com > Devices > All devices` | **[ADMIN CENTER]** | Requires Intune Administrator or Global Administrator role |
| 2 | Search by device serial number or hostname — locate the 2023-11-04 legacy enrolment record | **[ADMIN CENTER]** | |
| 3 | Select record → **Delete** | **[ADMIN CENTER]** | Use **Delete** — not Retire (leaves object managed) and not Wipe (issues factory reset command to device) |
| 4 | Open `portal.azure.com > Azure Active Directory > Devices` — search for same device — **Delete** the stale AAD object | **[ADMIN CENTER]** | Required in addition to Intune deletion — an orphaned AAD object causes a duplicate conflict on re-registration |
| 5 | Open `intune.microsoft.com > Devices > Enrol devices > Windows enrollment > Devices` — confirm device serial is registered with correct Autopilot deployment profile assigned | **[ADMIN CENTER]** | If missing, import via CSV before proceeding |
| 6 | On device: `Settings > Accounts > Access work or school` → select existing connection → **Disconnect** | **[DEVICE]** | Removes user-visible enrolment connection |
| 7 | On device: `Settings > System > Recovery > Reset this PC > Remove everything > Cloud download` | **[DEVICE]** | Cloud download ensures a clean OS image; removes all local MDM artefacts including certificates and `HKLM\SOFTWARE\Microsoft\Enrollments` registry entries |
| 8 | Allow device to boot into OOBE — Autopilot detects registered serial and provisions automatically | **[DEVICE]** | Do not interrupt OOBE |

> **Sequencing is critical:** Steps 1–5 must be completed before steps 6–8. Resetting the device before deleting the cloud records risks the device re-registering against the stale object, repeating the conflict.

---

## 6. Verification Checks

Perform within 30–60 minutes of OOBE completion:

**Admin center:**

1. `intune.microsoft.com > Devices > All devices` — device present with **Enrolment type: Windows Autopilot**
2. `Devices > [Device] > Device configuration` — all 4 profiles show **Succeeded**
3. `Devices > Monitor > Enrollment failures` — device serial no longer listed
4. Compliance state shows **Compliant** or **In grace period**

**Device-side** (elevated command prompt):

5. Run `dsregcmd /status` — confirm:
   - `AzureAdJoined : YES`
   - `MDMUrl` populated with tenant Intune URL
   - No legacy enrolment IDs present

---

## 7. Preventive Actions

### 7.1 Immediate — before next Autopilot deployment wave

| Action | Owner | Detail |
|---|---|---|
| Bulk audit of legacy-enrolled devices | Intune Administrator | In `Devices > All devices`, filter or sort by enrolment type and enrolled date. Export list. Cross-reference against Autopilot device register (`Devices > Enrol devices > Windows enrollment > Devices`). Any device on both lists must have legacy records deleted before it enters the next Autopilot wave. |
| Triage outstanding devices with stale enrolments | Deployment team | For each identified device, log a remediation task: delete Intune record, delete AAD object, confirm Autopilot profile assigned, schedule full reset. |

### 7.2 Process — runbook update (permanent fix)

| Action | Detail |
|---|---|
| Update device redeployment runbook | Add a mandatory pre-flight checklist item: *"Confirm no existing Intune or Azure AD device record exists for the target serial. If present, delete both before handing device to rebuild team."* |
| Add decommission step to device handover form | Any device submitted for rebuild/redeployment must be signed off by an Intune admin confirming cloud records have been deleted. |
| Brief deployment and rebuild teams | Ensure all engineers involved in device provisioning understand that a device reset alone does not clear cloud-side MDM records — admin portal action is always required in parallel. |

### 7.3 Optional — enrolment restriction (admin center)

Review `Devices > Enrol devices > Enrollment restrictions`:

- Consider restricting personal device enrolment to reduce accumulation of unmanaged legacy records
- Ensure corporate-owned devices are correctly classified via Autopilot hardware hash registration at point of purchase or rebuild

---

## 8. Lessons Learned

| # | Lesson |
|---|---|
| 1 | A full device reset clears local MDM state but does **not** remove the cloud-side Intune device record or Azure AD object. Both must be explicitly deleted by an admin. |
| 2 | Autopilot cannot complete over an existing MDM enrolment — the pre-flight check for conflicting enrolments must be a mandatory step in any Autopilot deployment process. |
| 3 | When adopting a new provisioning model (e.g. moving from manual MDM to Autopilot), all downstream processes — decommission, rebuild, redeployment runbooks — must be reviewed and updated in scope. |
| 4 | `0x80070005` (Access Denied) on profile application is a secondary symptom of enrolment failure, not an independent permissions problem. Diagnosing the enrolment error first avoids chasing a false trail through profile assignment and RBAC settings. |
| 5 | Diagnostic exports that include human-readable error descriptions should be used as-is; independently verifying code meanings prevents introducing inaccurate interpretations into the record. |

---

## 9. Summary

| Item | Detail |
|---|---|
| **Root cause** | Legacy MDM enrolment (2023-11-04) not removed before Autopilot provisioning; no decommission step in redeployment process |
| **Primary error** | `0x80180014` — device already enrolled, Autopilot rejected at registration |
| **Secondary error** | `0x80070005` — Access Denied on all 4 profile pushes (consequence of enrolment failure, not an independent cause) |
| **Factors not implicated** | Licensing, network, Azure AD join state |
| **Remediation** | Delete legacy Intune + AAD records (admin center) → full device reset → Autopilot from clean OOBE |
| **Permanent fix** | Mandatory decommission pre-flight step added to device redeployment runbook |
| **Wider risk** | Other devices with legacy manual enrolments scheduled for Autopilot must be audited and cleaned before their provisioning wave |

---

*RCA prepared by DWP Engineer | Reference: RCA-2026-08-11-AUTOPILOT-001 | 2026-08-11*
