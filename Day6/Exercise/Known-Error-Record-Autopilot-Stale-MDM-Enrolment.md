# Known Error Record — Autopilot Enrolment Failure Due to Stale Legacy MDM Enrolment

**Cause:** The device had a legacy manual MDM enrolment from 2023-11-04 that was not removed before Autopilot provisioning. The verified RCA confirmed there was no mandatory decommission step to delete the existing Intune and Azure AD device records before redeployment.

**Workaround:** Delete the stale device record in `intune.microsoft.com > Devices > All devices`, delete the matching Azure AD device object, then on the device disconnect the existing work or school account and run `Reset this PC > Remove everything > Cloud download`. After the device returns to OOBE, allow Autopilot to run again.

**Permanent fix:** Update the device redeployment runbook to require a pre-flight check that confirms no existing Intune or Azure AD device record exists for the target serial before handing the device to the rebuild team. Any device submitted for rebuild must be signed off by an Intune admin confirming both cloud-side records have been deleted.

**How to spot it:** The specific signals are `EnrollmentState: Failed`, `ErrorCode: 0x80180014`, `ErrorDescription: The device is already enrolled in MDM`, `MDMEnrolled: Yes`, and `EnrolmentSource: Legacy manual MDM enrolment`. Supporting failure indicators from the same incident were `ProfilesApplied: 0 of 4`, `LastError: 0x80070005`, and the affected module path on the device was the MDM enrolment stack shown through the local work account connection in `Settings > Accounts > Access work or school`.
