# L2/L3 Knowledge Base: Autopilot Enrolment Failure — Stale Legacy MDM Enrolment Conflict

| Field | Detail |
|---|---|
| **Version** | v 1.0 |
| **Date** | 11/08/2026 |
| **Author** | DWP Engineer |
| **Status** | Draft |
| **RCA Reference** | RCA-2026-08-11-AUTOPILOT-001 |

---

## Contents

| # | Section | Use when… |
|---|---|---|
| 1 | [Background](#1-background) | You need context on what Autopilot and MDM are |
| 2 | [Symptoms](#2-symptoms) | You want to confirm this is the right article |
| 3 | [Root Cause](#3-root-cause) | You need the confirmed technical cause |
| 4 | [Detection](#4-detection) | You are diagnosing — have not acted yet |
| 5 | [Resolution](#5-resolution) | You are ready to fix — detection is done |
| 6 | [Verification](#6-verification) | You need to confirm the fix worked |
| 7 | [Rollback](#7-rollback) | Something went wrong during the fix |
| 8 | [Preventive Action](#8-preventive-action) | You are preventing recurrence |
| 9 | [Related Articles](#9-related-articles-and-incidents) | You need linked documents |

---

## Quick Reference

| Item | Detail |
|---|---|
| **What fails** | Autopilot enrolment during device OOBE |
| **Primary error** | `0x80180014` — device already enrolled in MDM |
| **Secondary error** | `0x80070005` — Access Denied on all profile pushes *(consequence, not cause)* |
| **Root cause** | Stale legacy MDM record from 2023 not removed before Autopilot provisioning |
| **Fix** | Delete legacy Intune and Entra records → reset device → Autopilot from clean OOBE |
| **Key warning** | Delete cloud records **first**, then reset device — not the other way around |

---

## 1. 📖 Background

**What Autopilot does:**
- When a device is powered on for the first time or after a full reset, it connects to Microsoft Intune during the Out-of-Box Experience (OOBE) setup screens.
- Intune recognises the device by its hardware serial number, applies the assigned Autopilot deployment profile, and pushes configuration policies.

**What must be true for this to work:**
- The device must have **no existing MDM enrolment record** in either the Intune admin centre or Azure AD (Microsoft Entra ID).

**Why this fails on legacy devices:**
- Before Autopilot was adopted, DWP devices were enrolled manually into MDM.
- Those older devices still have cloud-side records in Intune and Azure AD.
- If those records are not deleted before the device is re-submitted for Autopilot, the new enrolment attempt collides with the existing record and fails.

---

## 2. 🔴 Symptoms

**What Intune/the MDM diagnostic export shows:**

| Field | Value |
|---|---|
| `EnrollmentState` | `Failed` |
| `ErrorCode` | `0x80180014` |
| `ErrorDescription` | `The device is already enrolled in MDM` |
| `MDMEnrolled` | `Yes` |
| `EnrolmentSource` | `Legacy manual MDM enrolment` |
| `ProfilesApplied` | `0 of 4` |
| `LastError` | `0x80070005` |

**What the engineer observes:**
- Autopilot provisioning stalls or errors during OOBE, typically at the `Setting up your device for work` screen.
- The Intune admin center shows the device in `Devices > Monitor > Enrollment failures` with error `0x80180014`.
- Zero configuration profiles applied — the device receives no policies.

**What the user reports:**
- "My computer got stuck during setup."
- "Setup showed an error and stopped."
- "I can't get past the sign-in screen during setup."

---

## 3. 🔍 Root Cause

**What happened:**

| Step | Detail |
|---|---|
| 1 | Device had an active legacy MDM enrolment dated **2023-11-04** |
| 2 | That record was not removed before Autopilot provisioning was attempted |
| 3 | The MDM stack detected the conflict and rejected the new enrolment → `0x80180014` |
| 4 | With no valid enrolment authority, all 4 profile pushes were denied → `0x80070005` |

**Factors confirmed as NOT contributing:**

| Factor | Evidence |
|---|---|
| Licensing | Intune P1 `Yes`, Autopilot licence `Yes` |
| Network | All endpoints reachable, no proxy |
| Azure AD join | `AzureADJoined: Yes` |

> ⚠️ **`0x80070005` is a secondary symptom, not a root cause.** Do not investigate RBAC or profile assignment before resolving the enrolment conflict.

---

## 4. 🔎 Detection

> Complete **all** detection steps before taking any action. Each step names the exact location and what a positive result looks like.

### D1 — Check Intune enrollment failures

1. Open `https://intune.microsoft.com` and sign in.
2. Navigate to `Devices > Monitor > Enrollment failures`.
3. Search by device name or serial number.
4. Look for a row with `Error code: 0x80180014` or error message containing `already enrolled`.

> ✅ **Positive:** Row exists for the target device with `0x80180014`. Confirms enrolment was rejected at the MDM registration stage.

### D2 — Check for a stale Intune device record

1. In Intune, open `Devices > All devices`.
2. Search by device serial number.
3. Look at the `Enrollment type` column for any returned record.

> ✅ **Positive:** A record exists with `Enrollment type` showing anything other than `Windows Autopilot` (e.g. `Device enrollment manager` or `User enrollment`). This is the stale conflicting record.

### D3 — Check for a stale Azure AD device object

1. Open `https://portal.azure.com` and navigate to `Microsoft Entra ID > Devices`.
2. Search by device serial number or hostname.
3. Look at the `Join type` and `Registered` date columns.

> ✅ **Positive:** A device object exists with a registration date matching the legacy enrolment date (e.g. `2023-11-04`). This is the stale Azure AD record that must also be deleted.

### D4 — Check the device-side enrolment state

1. On the target device, open `Settings > Accounts > Access work or school`.

> ✅ **Positive:** An active organisational connection is listed, confirming local enrolment artefacts are present on the device.

### D5 — Check the device-side MDM registry

1. On the device, open `Registry Editor` (`regedit`) as Administrator.
2. Navigate to `HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Enrollments`.
3. Look for one or more GUID-named subkeys.

> ✅ **Positive:** One or more GUID subkeys exist, confirming active MDM enrolment entries are stored locally.

### D6 — Confirm via device-side event log

1. On the device, open `Event Viewer`.
2. Navigate to `Applications and Services Logs > Microsoft > Windows > DeviceManagement-Enterprise-Diagnostics-Provider > Admin`.
3. Filter for events with **Event ID 76** (enrolment failure) or **Event ID 75** (enrolment request initiated).
4. Look for log entries containing the text `already enrolled` or error code `0x80180014` around the time of the failed Autopilot attempt.

> ✅ **Positive:** An Event ID 76 entry exists with `0x80180014` at the time of the attempted enrolment.

> 📋 **Note:** Event IDs 75 and 76 are from the `DeviceManagement-Enterprise-Diagnostics-Provider` provider. If you do not see these events, confirm the log level is set to at least `Information` in Event Viewer.

---

## 5. 🔧 Resolution

> ⚠️ **Critical order:** Complete Phase 1 (cloud cleanup) before Phase 2 (device reset). Resetting first causes the device to re-register against the stale cloud record and repeat the failure.

> 🔐 **Access required:** Intune Administrator or Global Administrator role on `intune.microsoft.com` and `portal.azure.com`, plus local administrator rights on the target device.

---

### Phase 1 — Cloud Cleanup *(admin portals only — no device access needed)*

| Step | Action | Portal path | Expected result |
|---|---|---|---|
| R1 | Sign in | `https://intune.microsoft.com` | Left nav shows `Devices`; tenant name visible in top bar |
| R2 | Open device list | `Devices > All devices` | Table loads with columns: Device name, OS, Ownership, Last check-in |
| R3 | Find the stale record | Search box — enter device serial number | Stale legacy record appears in filtered results |
| R4 | Delete the Intune record | Click the record → click **Delete** → confirm | Record no longer appears after refresh. Use **Delete** only — not `Retire` and not `Wipe` |
| R5 | Open Azure portal | `https://portal.azure.com` | Azure portal home loads |
| R6 | Open Entra devices | Search bar → `Microsoft Entra ID` → `Devices` | Entra device list is displayed |
| R7 | Find the stale Entra object | Search by serial number or hostname | Stale Entra device object appears in results |
| R8 | Delete the Entra object | Click the object → click **Delete** → confirm | Object no longer appears after refresh |
| R9 | Confirm Autopilot profile | `intune.microsoft.com > Devices > Enrol devices > Windows enrollment > Devices` — search serial number | One record exists with correct deployment profile in the `Profile` column |

> ⚠️ **If the serial is missing from the Autopilot device list**, import it using a CSV before continuing. Do not proceed to Phase 2 without a confirmed profile assignment.

#### CLI Fast Path — Phase 1 (replaces R1–R9 portal steps)

> 📋 **Prerequisite:** Azure CLI installed and signed in with `az login` using an Intune Administrator or Global Administrator account. Microsoft Graph permissions `DeviceManagementManagedDevices.ReadWrite.All` and `Device.ReadWrite.All` must be consented.

```bash
# Set your device serial number once — reuse in all commands below
SERIAL="YOUR_SERIAL_NUMBER_HERE"

# --- Step 1: Find the stale Intune managed device record ---
az rest --method GET \
  --url "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices?\$filter=serialNumber eq '$SERIAL'" \
  --query "value[].{id:id, deviceName:deviceName, enrollmentType:deviceEnrollmentType, enrolledDateTime:enrolledDateTime}"
# Expected: One record returned with enrollmentType NOT equal to windowsAutoEnrollment or azureAdJoinedUsingDeviceTrust

# --- Step 2: Delete the stale Intune managed device record ---
# Replace INTUNE_DEVICE_ID with the id value returned above
INTUNE_ID="INTUNE_DEVICE_ID_HERE"
az rest --method DELETE \
  --url "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices/$INTUNE_ID"
# Expected: HTTP 204 No Content — no output means success

# --- Step 3: Find the stale Entra (Azure AD) device object ---
az rest --method GET \
  --url "https://graph.microsoft.com/v1.0/devices?\$filter=physicalIds/any(p:p eq '[SerialNumber]:$SERIAL')" \
  --query "value[].{id:id, displayName:displayName, registrationDateTime:registrationDateTime}"
# Expected: One record returned; note the id value (Entra object ID)

# --- Step 4: Delete the stale Entra device object ---
# Replace ENTRA_OBJECT_ID with the id value returned above
ENTRA_ID="ENTRA_OBJECT_ID_HERE"
az rest --method DELETE \
  --url "https://graph.microsoft.com/v1.0/devices/$ENTRA_ID"
# Expected: HTTP 204 No Content

# --- Step 5: Confirm Autopilot profile is assigned ---
az rest --method GET \
  --url "https://graph.microsoft.com/v1.0/deviceManagement/windowsAutopilotDeviceIdentities?\$filter=serialNumber eq '$SERIAL'" \
  --query "value[].{id:id, serialNumber:serialNumber, profileStatus:deploymentProfileAssignmentStatus, profileName:displayName}"
# Expected: One record with deploymentProfileAssignmentStatus = assigned
```

---

### Phase 2 — Device Cleanup and Re-provisioning *(requires access to the physical device)*

| Step | Action | Where | Expected result |
|---|---|---|---|
| R10 | Disconnect legacy work account | `Settings > Accounts > Access work or school` → select legacy connection → **Disconnect** | Legacy connection no longer listed |
| R11 | Start Reset wizard | `Settings > System > Recovery` → click **Reset PC** | Reset this PC wizard opens |
| R12 | Set wipe scope | Select **Remove everything** | Wizard shows full wipe mode |
| R13 | Set image source | Select **Cloud download** | Wizard shows cloud image source |
| R14 | Start the reset | Click **Next** → click **Reset** | Device restarts and reset progress screen appears |
| R15 | Complete OOBE | Allow device to boot to OOBE — do not interrupt — complete region, keyboard, network steps, then sign in with the assigned corporate account | Autopilot screen `Setting up your device for work` appears and completes without error |

---

## 6. ✅ Verification

> Run **all** checks before marking the incident resolved.

| Check | Where | ✅ Pass | ❌ Fail |
|---|---|---|---|
| V1 — Enrolment type | `Devices > All devices` → open device → Overview pane | `Enrollment type = Windows Autopilot` | Any other value, or no record found |
| V2 — Profile application | Same device record → `Device configuration` | All 4 profiles show `Status = Succeeded` | Any profile shows `Pending`, `Error`, or `Not applicable` |
| V3 — Enrollment failures | `Devices > Monitor > Enrollment failures` — filter by serial or device name | No active failure row for the target device | Device still listed with any error code |
| V4 — Compliance state | Device overview → `Compliance` field | `Compliant` or `In grace period` | `Not compliant` with no grace period explanation |
| V5 — dsregcmd | Elevated command prompt on device → run `dsregcmd /status` → inspect `Device State` section | `AzureAdJoined : YES` and `MDMUrl` populated | Either field is `NO` or empty |

**V6 — Evidence capture before closing:**

Attach all three items below to the incident ticket:

1. Screenshot of Intune device overview showing `Enrollment type = Windows Autopilot`
2. Screenshot of `Device configuration` showing all 4 profiles `Succeeded`
3. Copy of `dsregcmd /status` output

#### CLI Verification Commands *(replaces V1–V4 portal checks)*

> 📋 **Prerequisite:** Same `az login` session used during resolution. Replace `SERIAL` with the device serial number.

```bash
SERIAL="YOUR_SERIAL_NUMBER_HERE"

# --- V1: Confirm enrolment type is Windows Autopilot ---
az rest --method GET \
  --url "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices?\$filter=serialNumber eq '$SERIAL'" \
  --query "value[].{deviceName:deviceName, enrollmentType:deviceEnrollmentType, complianceState:complianceState}"
# Expected: enrollmentType = windowsAutoEnrollment  |  complianceState = compliant or inGracePeriod

# --- V2: Confirm all configuration profiles applied successfully ---
# Replace INTUNE_DEVICE_ID with the id from V1 output
INTUNE_ID="INTUNE_DEVICE_ID_HERE"
az rest --method GET \
  --url "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices/$INTUNE_ID/deviceConfigurationStates" \
  --query "value[].{profile:displayName, state:state}"
# Expected: All 4 entries show state = compliant. Any entry showing error or notApplicable is a fail.

# --- V3: Confirm no active enrollment failures ---
az rest --method GET \
  --url "https://graph.microsoft.com/v1.0/deviceManagement/deviceEnrollmentConfigurations" \
  --query "value[?contains(displayName,'$SERIAL')].{name:displayName, state:deviceEnrollmentConfigurationType}"
# Expected: No failure records returned for the serial number

# --- V4: Check compliance state ---
az rest --method GET \
  --url "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices?\$filter=serialNumber eq '$SERIAL'" \
  --query "value[].{deviceName:deviceName, complianceState:complianceState, lastSyncDateTime:lastSyncDateTime}"
# Expected: complianceState = compliant or inGracePeriod
```

> 📋 **V5 (dsregcmd) and V6 (evidence capture) cannot be automated via CLI** — run these on the device directly as described in the table above.

---

## 7. ↩️ Rollback

> Use this section immediately if the procedure causes additional impact. Each scenario is self-contained.

---

### 🔴 Scenario A — Wrong Intune or Entra device record deleted

1. Stop immediately. Do not delete any further records.
2. Open `portal.azure.com > Microsoft Entra ID > Devices`. Check whether the wrongly deleted Entra object is recoverable via your tenant's soft-delete or recycle period (30-day soft-delete applies in most tenants).
3. If recoverable, restore the deleted Entra device object. Verify it reappears in `Microsoft Entra ID > Devices`.
4. Re-enrol the affected device using the standard corporate enrolment method for that device type.
5. If recovery is unavailable and the affected device belongs to a critical user, escalate to a major incident bridge immediately.

**CLI commands for Scenario A rollback:**

```bash
# --- Find the deleted Entra device in soft-delete (30-day window) ---
# Replace DEVICE_NAME with the display name of the wrongly deleted device
DEVICE_NAME="WRONG_DEVICE_NAME_HERE"
az rest --method GET \
  --url "https://graph.microsoft.com/v1.0/directory/deletedItems/microsoft.graph.device?\$filter=displayName eq '$DEVICE_NAME'" \
  --query "value[].{id:id, displayName:displayName, deletedDateTime:deletedDateTime}"
# Expected: Record appears with a deletedDateTime value — note the id

# --- Restore the deleted Entra device object ---
# Replace DELETED_OBJECT_ID with the id from above
DELETED_ID="DELETED_OBJECT_ID_HERE"
az rest --method POST \
  --url "https://graph.microsoft.com/v1.0/directory/deletedItems/$DELETED_ID/restore"
# Expected: HTTP 200 with the restored device object returned in JSON

# --- Confirm the device is back in the Entra device list ---
az rest --method GET \
  --url "https://graph.microsoft.com/v1.0/devices?\$filter=displayName eq '$DEVICE_NAME'" \
  --query "value[].{id:id, displayName:displayName, registrationDateTime:registrationDateTime}"
# Expected: Device appears in results with no deletedDateTime field
```

> 📋 **Note:** Intune managed device records cannot be restored via CLI once deleted — only the Entra object has a 30-day soft-delete recovery window. If the Intune record must be restored, re-enrol the device through the standard corporate enrolment path.

---

### 🔴 Scenario B — Reset started on the wrong device

1. If the reset has not fully committed, disconnect the wrong device from the network immediately to limit further policy changes.
2. Inform the device owner and service owner that an incorrect reset was initiated.
3. Rebuild the wrong device using the approved build path and restore user data from the approved backup source.
4. Raise a process breach ticket for post-incident review of the operator action.

---

### 🔴 Scenario C — Autopilot still fails after full cleanup and reset

1. Do not run a second reset. Stop after one full cleanup-and-reset attempt.
2. Collect a fresh MDM diagnostic export from the failed OOBE session.
3. Open `Event Viewer > Applications and Services Logs > Microsoft > Windows > DeviceManagement-Enterprise-Diagnostics-Provider > Admin` on the device and export the log to a file.
4. Attach the MDM diagnostic export, the event log export, and your runbook action log to the incident ticket.
5. Escalate to Intune platform engineering as high priority, stating that the failure repeated after stale-record cleanup. Include the RCA reference RCA-2026-08-11-AUTOPILOT-001.

---

## 8. 🛡️ Preventive Action

| # | Control | Owner | Timing | Type |
|---|---|---|---|---|
| P1 | Mandatory pre-flight check — delete cloud records before rebuild | DWP Engineer (Intune Administrator) | Before deployment | Manual — automation candidate |
| P2 | Bulk audit of legacy-enrolled devices before deployment wave | DWP Engineer (Intune Administrator) | Before deployment | Manual — automation candidate |
| P3 | Enrolment restriction to block non-Autopilot enrolments | DWP Engineer (Intune Administrator) | Before deployment (one-time config) | Manual |
| P4 | Team briefing and checklist update | Service Desk Lead / Release Engineer | Before deployment | Manual |
| P5 | Pre-deployment smoke test gate | Release Engineer | Before deployment | Manual — automation candidate |
| P6 | In-flight enrolment failure monitoring | DWP Engineer (Intune Administrator) | During deployment | Manual — automation candidate |
| P7 | Post-deployment validation before change closure | Change Manager | After deployment | Manual |
| P8 | Rollback trigger threshold | DWP Engineer (Intune Administrator) | During deployment | Manual — automation candidate |
| P9 | Knowledge base and runbook update | DWP Engineer | After deployment | Manual |

---

### P1 — Mandatory pre-flight check before any Autopilot redeployment

**Who:** DWP Engineer holding Intune Administrator role.  
**When:** Before deployment — before any device is handed to the rebuild team.  
**What to do:** Search `intune.microsoft.com > Devices > All devices` by serial number. If any record exists, delete it. Search `portal.azure.com > Microsoft Entra ID > Devices` by serial number. If any object exists, delete it. Sign off the device handover form confirming both are absent.  
**Pass:** Both searches return zero results and the handover form is countersigned by a named Intune Administrator.  
**Fail:** Any existing record found at handover with no sign-off. The rebuild must not proceed — escalate to the deployment lead.  
**Automation note:** This check can be scripted using the `az rest` Graph API commands in Section 5 (CLI Fast Path steps R1 and R3). Output can be piped to a pre-flight checklist tool to block ticket progression. [REQUIRES: automated pre-flight gate in ITSM tooling]

---

### P2 — Bulk audit before next Autopilot deployment wave

**Who:** DWP Engineer (Intune Administrator).  
**When:** Before deployment — before each planned Autopilot deployment wave begins.  
**What to do:** In `Devices > All devices`, export the full device list. Filter by `Enrollment type` for any non-Autopilot value. Cross-reference against `Devices > Enrol devices > Windows enrollment > Devices`. For every device on both lists, raise a remediation task to delete the legacy Intune record and Entra object before that device enters the wave.  
**Pass:** Zero devices with a non-Autopilot enrolment type appearing in the Autopilot device register at wave start.  
**Fail:** One or more legacy-enrolled devices found in the Autopilot register. Remove them before the wave proceeds — do not deploy over stale records.  
**Automation note:** The cross-reference can be automated using Graph API batch queries against `deviceManagement/managedDevices` and `deviceManagement/windowsAutopilotDeviceIdentities`. [REQUIRES: scheduled Graph API report or Power Automate flow]

---

### P3 — Enrolment restriction to block non-Autopilot enrolments

**Who:** DWP Engineer (Intune Administrator).  
**When:** Before deployment — one-time configuration change, applied before the next deployment wave.  
**What to do:** Open `intune.microsoft.com > Devices > Enrol devices > Enrollment restrictions`. Set the default device type restriction to block personally-owned Windows devices. Confirm corporate-owned devices are classified via Autopilot hardware hash registration at point of purchase or rebuild.  
**Pass:** `Devices > All devices` shows zero new non-Autopilot Windows enrolments appearing after the restriction is applied.  
**Fail:** New non-Autopilot enrolments continue to appear after restriction. Re-check restriction scope and platform targeting — confirm it is assigned to `All Users`.

---

### P4 — Team briefing and checklist update

**Who:** Service Desk Lead and Release Engineer.  
**When:** Before deployment — prior to the next deployment wave briefing session.  
**What to do:** Brief all deployment and rebuild engineers on this specific point: a full device reset clears local MDM artefacts but does **not** remove the Intune device record or the Entra device object — both require explicit admin portal deletion first. Add this as a named, tickable checkbox on the rebuild team's pre-work checklist.  
**Pass:** All engineers on the next deployment wave can describe the pre-flight deletion step unprompted. Checklist is updated and in use.  
**Fail:** Rebuild proceeds without the pre-flight deletion checkbox completed. Treat as a process breach and raise a ticket for post-incident review.

---

### P5 — Pre-deployment smoke test gate *(gap: pre-deployment test gate)*

**Who:** Release Engineer.  
**When:** Before deployment — on a single pilot device before the full deployment wave begins.  
**What to do:** Select one device from the wave. Run the full pre-flight check (P1), reset the device, and allow Autopilot to complete. Verify using the CLI commands in Section 6 (V1–V4). If the pilot device passes all five verification checks, proceed with the full wave. If it fails, hold the wave and diagnose before continuing.  
**Pass:** Pilot device shows `enrollmentType = windowsAutoEnrollment` and all 4 profiles `state = compliant` within 60 minutes.  
**Fail:** Pilot device fails any verification check. Wave is held — do not proceed. Escalate to Intune platform engineering.  
**Automation note:** The Graph API verification commands in Section 6 can be wrapped in a CI pipeline step that gates wave progression. [REQUIRES: CI/CD pipeline or deployment orchestration tool]

---

### P6 — In-flight enrolment failure monitoring during rollout *(gap: in-flight monitoring)*

**Who:** DWP Engineer (Intune Administrator).  
**When:** During deployment — active monitoring throughout the deployment window.  
**What to do:** Keep `intune.microsoft.com > Devices > Monitor > Enrollment failures` open and refreshed every 10 minutes during the wave. Alert threshold: if more than 2 devices show `0x80180014` within a 30-minute window, pause the wave immediately.  
**Pass:** Zero `0x80180014` failures recorded across the wave.  
**Fail:** Two or more `0x80180014` failures within 30 minutes. Pause deployment, run P2 audit on remaining devices in the wave, clear stale records, then resume.  
**Automation note:** An Intune compliance or enrollment report can be polled via Graph API at `deviceManagement/deviceEnrollmentConfigurations` on a schedule and alerts raised via webhook. [REQUIRES: monitoring webhook or Azure Monitor integration]

---

### P7 — Post-deployment validation before change closure *(gap: post-deployment validation)*

**Who:** Change Manager, confirmed by DWP Engineer.  
**When:** After deployment — before the change record is closed.  
**What to do:** Run the full CLI verification block from Section 6 against all devices in the wave. Confirm all devices show `enrollmentType = windowsAutoEnrollment`, all 4 profiles `state = compliant`, and zero entries in `Devices > Monitor > Enrollment failures`.  
**Pass:** 100% of wave devices pass all five verification checks and the change record is updated with evidence.  
**Fail:** Any device fails verification after the wave. Raise a child incident, apply the resolution from Section 5 to that device, and re-run verification before closing the parent change.

---

### P8 — Rollback trigger threshold *(gap: rollback trigger)*

**Who:** DWP Engineer (Intune Administrator).  
**When:** During deployment — evaluated at each 25% completion checkpoint of the wave.  
**What to do:** At each 25% checkpoint, check `Devices > Monitor > Enrollment failures`. If more than 10% of devices in the completed portion show `0x80180014`, treat this as a systemic failure and halt the wave. Escalate to Intune platform engineering and do not resume until the stale-record audit (P2) has been completed across all remaining devices.  
**Pass:** Fewer than 10% of deployed devices at any checkpoint show enrolment failure.  
**Fail:** 10% or more failures at any checkpoint. Wave is halted. Do not attempt individual device remediation under time pressure — complete the audit first.  
**Automation note:** Graph API query against `deviceManagement/managedDevices` can calculate failure rate and trigger an alert automatically. [REQUIRES: monitoring script or Azure Monitor alert rule]

---

### P9 — Knowledge base and runbook update after each incident *(gap: knowledge update)*

**Who:** DWP Engineer who resolved the incident.  
**When:** After deployment — within 5 working days of incident closure.  
**What to do:** Update this KB article with any new signals, error codes, or portal path changes observed. Update the runbook at `Day6/Exercise/Autopilot-Enrolment-Stale-MDM-Runbook.md` with any step corrections. Update the Known Error Record at `Day6/Exercise/Known-Error-Record-Autopilot-Stale-MDM-Enrolment.md` with the confirmed workaround if it changed. Increment the version number on all updated documents.  
**Pass:** All three documents have a version number higher than at incident start and the change log entry describes what was updated.  
**Fail:** Documents unchanged after incident closure. Service Desk Lead to chase the resolving engineer and set a 5-day deadline before escalating to the team lead.

---

## 9. 🔗 Related Articles and Incidents

| Reference | Type | Description |
|---|---|---|
| RCA-2026-08-11-AUTOPILOT-001 | RCA | Full root cause analysis for this incident pattern |
| `Day6/Autopilot-Enrolment-Failure-RCA.md` | RCA document | Five Whys, evidence table, timeline, and preventive actions |
| `Day6/Autopilot-Enrolment-Failure-Stale-MDM-Analysis.md` | Incident analysis | Scope facts, differential diagnosis, remediation order |
| `Day6/Exercise/Known-Error-Record-Autopilot-Stale-MDM-Enrolment.md` | Known error record | KEDB entry for recurring detection and workaround |
| `Day6/Exercise/Autopilot-Enrolment-Stale-MDM-Runbook.md` | Runbook | Step-by-step operator runbook for this fix |
| `Day6/Exercise/L1-Self-Service-Device-Setup-Failed.md` | L1 KB | End-user self-service article for device setup failures |

---

*Article prepared by DWP Engineer | Reference: RCA-2026-08-11-AUTOPILOT-001 | 2026-08-11*
