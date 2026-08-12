# Autopilot Enrolment Communication — Three Audiences

## Audience 1 — Non-technical executive

Your access and data are safe. A device setup failed because an older management record from 2023 was not removed before rebuild. We removed the old records, cleared the old work connection, reset the device, and ran setup again. We confirmed the device set up correctly and all four required settings applied. We are adding a pre-check to remove old records before rebuilds. No action is needed unless we contact you.

## Audience 2 — Affected end-user team

Your access and data are safe. One device setup failed because an older management record from 2023 was not removed before rebuild. We removed the old records, cleared the old work connection, reset the device, and ran setup again. We confirmed the device set up correctly and all four required settings applied. We are adding a pre-check to remove old records before rebuilds. If you see the same setup issue, stop and report it without retrying. Contact the Service Desk.

## Audience 3 — Engineer-to-engineer internal note

User access and data were not impacted; the issue was limited to device provisioning. Root cause was a stale legacy manual MDM enrolment dated 2023-11-04 that had not been removed before Autopilot redeployment, so Autopilot failed with `0x80180014`; `0x80070005` on profile application was secondary because no valid new enrolment authority was established.

Action taken: deleted the stale device record in `intune.microsoft.com > Devices > All devices`, deleted the matching Azure AD device object, disconnected the existing work or school connection on the device, ran `Reset this PC > Remove everything > Cloud download`, and allowed the device to return to OOBE so Autopilot could run again.

Config / control detail: the device serial must be present in `Devices > Enrol devices > Windows enrollment > Devices` with the correct Autopilot deployment profile assigned before the reset and rebuild stage.

Verification: confirmed the device completed Autopilot successfully, appeared in Intune with **Enrolment type: Windows Autopilot**, and all 4 configuration profiles showed **Succeeded**.

Preventive action: add a mandatory pre-flight decommission check to the redeployment runbook requiring deletion of any existing Intune and Azure AD device records for the target serial before handing the device to the rebuild team. If this recurs, stop and report it without retrying. Contact the Service Desk.
