**Title:** Runbook: Autopilot Enrolment Failure Caused by Stale Legacy MDM Enrolment  
**Version:** 1.0  
**Date:** 11/08/2026  
**Author:** Shyamily  
**Reviewed:** self  
**Status:** draft  
**Change:** initial version from RCA

# Runbook: Autopilot Enrolment Failure Caused by Stale Legacy MDM Enrolment

**Document owner:** DWP Engineer  
**Last updated:** 2026-08-11  
**Incident pattern:** Autopilot enrolment fails because a legacy manual MDM enrolment record already exists for the device.

---

## Prerequisites

### Access rights

- Intune Administrator or Global Administrator access to `intune.microsoft.com` **[ELEVATED]**
- Permission to delete Azure AD device objects in Azure portal **[ELEVATED]**
- Local administrator rights on the target device to run recovery/reset actions **[ELEVATED]**

### Required systems and tools

- Intune admin center: `intune.microsoft.com`
- Azure portal: `portal.azure.com`
- Target Windows device with physical access or approved remote control session
- Stable internet connection for Cloud download reset path

### Required identifiers before starting

- Device serial number
- Device hostname (if available)
- Confirmation the device is registered in Autopilot device list

---

## Procedure

Perform steps in order. Do not skip steps.

1. Sign in to `https://intune.microsoft.com` using an Intune Administrator or Global Administrator account. **[ELEVATED]**  
Expected result: The left navigation shows `Devices`, and the tenant name is visible in the top bar.

2. Click `Devices` in the left navigation.  
Expected result: The Devices workspace opens and shows the device management menu.

3. Click `All devices` under Devices.  
Expected result: A table loads with columns such as `Device name`, `OS`, `Ownership`, and `Last check-in`.

4. Enter the target serial number in the `Search` box above the table and press Enter.  
Expected result: The table filters to records that match the serial number.

5. Click the matching device row that represents the legacy enrolment.  
Expected result: A device overview page opens for the selected record.

6. Click `Delete` at the top of the device page and confirm the delete prompt. **[ELEVATED]**  
Expected result: After returning to `All devices` and refreshing, that legacy record no longer appears in results for the serial number.

7. Open `https://portal.azure.com` and sign in with an account that can delete Azure AD devices. **[ELEVATED]**  
Expected result: Azure portal home page loads.

8. In the Azure portal search bar, type `Microsoft Entra ID` and open it.  
Expected result: The Entra tenant blade opens.

9. Click `Devices` in the Entra left navigation.  
Expected result: The Entra device list table is displayed.

10. Enter the same serial number or hostname in the device list search box and run the search.  
Expected result: The matching stale device object appears in the filtered results if it exists.

11. Click the matching Entra device object row.  
Expected result: The selected device details page opens.

12. Click `Delete` and confirm the deletion. **[ELEVATED]**  
Expected result: The stale Entra device object disappears from the filtered results after refresh.

13. Return to `https://intune.microsoft.com` and open `Devices > Enrol devices > Windows enrollment > Devices`.  
Expected result: The Windows Autopilot devices list is displayed.

14. Search the Autopilot list for the target serial number.  
Expected result: Exactly one target row is returned for the serial number.

15. Open the target Autopilot row and check the `Profile status` or assigned profile field.  
Expected result: The correct Autopilot deployment profile is assigned for this rebuild.

16. On the target device, open `Settings > Accounts > Access work or school`.  
Expected result: Existing organisational connections are listed.

17. Select the legacy organisational connection and click `Disconnect`, then confirm.  
Expected result: The legacy connection is removed from the list.

18. On the target device, open `Settings > System > Recovery` and click `Reset PC`. **[ELEVATED]**  
Expected result: The `Reset this PC` wizard opens.

19. Select `Remove everything`.  
Expected result: The wizard shows full wipe mode selected.

20. Select `Cloud download`.  
Expected result: The wizard shows cloud image source selected.

21. Click `Next` through the summary and click `Reset`. **[ELEVATED]**  
Expected result: The device restarts and begins reset.

22. Wait for the device to return to OOBE and stop at the first region/language screen.  
Expected result: The out-of-box setup screen appears.

23. Complete OOBE network and sign-in steps with the assigned corporate user account.  
Expected result: The Autopilot provisioning flow starts and reaches completion without enrolment error.

---

## Verification

Complete all checks before closure.

1. In Intune, open `Devices > All devices` and search for the target serial number.  
Expected result: One active device record is returned for the serial number.

2. Open the returned device record and check `Enrollment type` in the Overview pane.  
Expected result: `Enrollment type` shows `Windows Autopilot`.

3. In the same device record, open `Device configuration`.  
Expected result: The policy list shows the required 4 profiles with `Status = Succeeded`.

4. In Intune, open `Devices > Monitor > Enrollment failures` and filter by the target serial number or device name.  
Expected result: No active failure entry exists for the target device.

5. On the device, open `Command Prompt` as Administrator. **[ELEVATED]**  
Expected result: Command window title includes `Administrator: Command Prompt`.

6. Run `dsregcmd /status` and inspect the `Device State` and tenant sections.  
Expected result: `AzureAdJoined : YES` is present and `MDMUrl` is populated with the tenant MDM service URL.

7. Capture evidence by taking screenshots of Intune device overview, Intune device configuration status, and `dsregcmd /status` output, then attach all three to the incident ticket.  
Expected result: Ticket contains all three evidence artefacts and can be closed without additional validation requests.

---

## Rollback

Use this section immediately if the procedure causes additional impact.

### Scenario A: Wrong device record was deleted in Intune or Azure AD

1. Stop this runbook and do not delete anything else.  
Expected result: No more records are removed by mistake.

2. Open your tenant recycle/recovery area and look for the deleted device record. **[ELEVATED]**  
Expected result: You can see the deleted record details.

3. Restore the deleted Azure AD (Microsoft Entra) device object, if restore is available. **[ELEVATED]**  
Expected result: The device appears again in the Entra device list.

4. Re-enrol the wrong device using your normal company enrolment method. **[ELEVATED]**  
Expected result: The unrelated device is managed again.

5. Start a major incident call if restore is not possible or a critical user is affected.  
Expected result: Escalation owner is assigned and recovery is coordinated.

### Scenario B: Device reset started on wrong endpoint

1. If the reset has not fully started, disconnect the wrong device from network immediately.  
Expected result: Extra policy actions are reduced while you triage.

2. Inform the user and service owner that the wrong device was selected for reset.  
Expected result: Affected people are informed and next steps are clear.

3. Rebuild the wrong device with the approved build process and restore user data from approved backup. **[ELEVATED]**  
Expected result: The device is back to a supported state and user work can continue.

4. Raise a process breach ticket for review of the operator action.  
Expected result: A formal review record exists for follow-up.

### Scenario C: Autopilot still fails after cleanup and reset

1. Do not run another reset after one full cleanup-and-reset attempt fails.  
Expected result: Extra disruption is avoided.

2. Collect a new MDM diagnostic export from the failed attempt.  
Expected result: Fresh technical evidence is available.

3. Add the export and your runbook action log to the incident ticket.  
Expected result: Complete evidence is available for the next engineer.

4. Escalate to Intune platform engineering as high priority and state that failure repeated after stale-record cleanup.  
Expected result: Platform engineering takes ownership for deep troubleshooting.

---

## Notes

- **Critical warning:** Delete cloud records first, then reset device; reversing this order can recreate the conflict.
- `0x80180014` in this incident pattern was accompanied by export text indicating the device was already enrolled in MDM.
- `0x80070005` was observed as a secondary profile-application error when enrolment authority was not successfully established.
- Licensing and network were healthy in the verified case (`IntuneP1License: Yes`, `AutopilotLicense: Yes`, all endpoints reachable, no proxy).
- Related documents for reference:
  - `Day6/Autopilot-Enrolment-Failure-RCA.md`
  - `Day6/Autopilot-Enrolment-Failure-Stale-MDM-Analysis.md`
  - `Day6/Exercise/Known-Error-Record-Autopilot-Stale-MDM-Enrolment.md`
