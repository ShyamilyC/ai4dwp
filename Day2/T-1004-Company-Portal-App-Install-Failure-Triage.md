# Ticket T-1004 Triage

## Summary (one line)
Company app installation from Company Portal fails with error 0x87D1041C, indicating an app deployment/compliance/assignment issue (to-verify).

## Impact (who/how many/business urgency)
- Who is affected: User attempting to install required company app (to-verify if broader).
- How many affected: Currently one reported device/user.
- Business urgency: Medium to high (to-verify), especially if app is business-critical.

## Known facts
- Ticket ID: T-1004.
- Service context: Company Portal app install.
- Symptom: App fails to install.
- Reported code: 0x87D1041C.

## Missing information to gather
- App identity: Exact app name/version targeted for install.
- Requirement level: Required deployment vs available/self-service install.
- Scope: Whether other users/devices can install the same app.
- Device status: Enrollment health, sync recency, and compliance state at incident time (to-verify).
- Assignment path: User-group vs device-group targeting and filter applicability (to-verify).
- Dependency chain: Any prerequisite app/package requirement status (to-verify).
- Device constraints: Disk space, connectivity state, and installation context (user/device).
- Business impact: Whether this blocks role-critical tasks or onboarding.

## Likely category
Endpoint Management -> Intune / Company Portal Application Deployment Failure (to-verify exact ITSM category).

## First diagnostic step
Confirm whether the same app installs successfully on another similarly managed device and verify this device's latest management sync/compliance state to isolate assignment or device-state causes before deeper log analysis.