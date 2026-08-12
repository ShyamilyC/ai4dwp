Title: Intune Windows App Catalog Onboarding Guide (FinBridge Connect v3.1)
Version: 1.0
Date: 11/08/2026
Status: Draft

# Step-by-Step Guide: Add a Windows App to Intune Before Phased Rollout

Use this guide before any phased rollout starts. It is written for DWP engineers with no prior Intune app deployment experience.

Worked example used throughout:
- App: FinBridge Connect v3.1
- Package type: Windows LOB app packaged as .intunewin
- Install command: FinBridgeConnect_Setup.exe /silent
- Uninstall command: FinBridgeConnect_Setup.exe /uninstall /silent
- Detection method: Registry value
- Detection value: HKLM\\SOFTWARE\\FinBridge\\Connect\\Version = 3.1

Important UI note:
- Intune UI labels and menu order can vary by tenant version and portal updates.
- Every step marked with UI variation warning must be verified in your live tenant. Do not rely only on label text in this document.

## 1. Add the App in Intune (Where and Which Type)

1. Sign in to Microsoft Intune admin center.
Expected result: Admin portal loads.

2. Navigate to Apps > Windows > Add.
UI variation warning: Label names can appear as Apps > All apps > Add, or Apps > Windows apps. Verify your live tenant navigation instead of trusting this label exactly.
Expected result: Add app panel opens.

3. In App type, choose the correct type for your package scenario:
- For FinBridge Connect v3.1 (.intunewin): select Windows app (Win32).
- For Microsoft Store-delivered apps: select Microsoft Store app (new).
- For a browser shortcut/URL only: select Web link.
UI variation warning: App type labels may differ slightly by tenant version. Verify by checking the description shown for each type.
Expected result: Correct app type is selected for your deployment method.

4. Click Select, then upload the .intunewin package for FinBridge Connect v3.1.
UI variation warning: The upload control may be shown as Select app package file. Verify control names in your tenant.
Expected result: Package upload completes and app creation wizard advances.

## 2. Complete Required Fields for a Windows LOB App

5. Go to App information and enter required metadata.
Minimum values for this worked example:
- Name: FinBridge Connect
- Description: Finance client application for FinBridge services
- Publisher: FinBridge
- Version: 3.1
UI variation warning: Some tenants split metadata into required and optional fields differently. Verify any red asterisk field in your tenant is completed.
Expected result: No validation errors in App information.

6. Go to Program and configure install behavior.
Set values:
- Install command: FinBridgeConnect_Setup.exe /silent
- Uninstall command: FinBridgeConnect_Setup.exe /uninstall /silent
- Install behavior/context: System
When to use User context: only if the app explicitly requires per-user install and does not need machine-level access.
UI variation warning: Install behavior may appear under Install context. Verify the field intent, not only field name.
Expected result: Program page validates without errors.

7. Go to Requirements and set platform requirements.
Set minimum baseline:
- Operating system architecture: 64-bit
- Minimum operating system: Windows 11 (supported release used in your estate)
UI variation warning: Minimum OS list labels can vary by release naming. Verify against your tenant supported build list.
Expected result: Requirement rules match the target device estate.

8. Go to Detection rules and configure registry-based detection.
Choose:
- Rule type: Registry
- Key path: HKLM\\SOFTWARE\\FinBridge\\Connect
- Value name: Version
- Detection method: String comparison equals
- Operator: Equals
- Value: 3.1
UI variation warning: Detection operator labels may appear as Equals or String equals. Verify behavior preview if available.
Expected result: Intune can detect version 3.1 from registry after install.

9. Go to Return codes and validate success versus failure handling.
Recommended baseline:
- 0 = Success
- 3010 = Soft reboot required (treat as success)
- 1641 = Hard reboot initiated (treat as success)
- 1618 = Retry (another install in progress)
- Any unlisted non-zero code = Failure
UI variation warning: Some portals prepopulate return codes while others require manual confirmation. Verify mapping before saving.
Expected result: Return-code table reflects your intended install outcome handling.

10. Review and create the app.
UI variation warning: Final action may be labeled Create, Add, or Review + Create. Verify the final confirmation action in your tenant.
Expected result: App object is created in Intune catalog.

## 3. Assignment Basics (Pilot First)

11. Open the created app and go to Assignments.
UI variation warning: This can appear as Properties > Assignments in some tenants. Verify your path.
Expected result: Assignment blade opens.

12. Understand assignment types before targeting:
- Required: Intune installs automatically for targeted users/devices.
- Available for enrolled devices: App is visible in Company Portal for user-initiated install.
- Uninstall: Intune removes app from targeted users/devices.
Expected result: Engineer can distinguish enforced install, self-service install, and removal intent.

13. Create a small pilot group assignment first (never start with all 10,000 devices).
Pilot recommendation:
- Start with 25 to 50 IT and business pilot devices.
- Include mixed hardware profiles.
- Include at least a few low-memory devices if relevant to app behavior.
Why: Limits blast radius, validates detection and return codes, and proves install experience before broad rollout.
Expected result: App is assigned to a controlled pilot group only.

14. Set pilot assignment type to Required for validation speed.
Optional: Also set an Available assignment for a secondary self-service validation group.
Expected result: Pilot devices receive install policy automatically.

15. Save assignment changes and document pilot start time.
Expected result: Assignment is active and trackable in deployment logs.

## 4. Verification Steps

16. Confirm the app appears correctly in the catalog.
Navigation: Apps > Windows (or Apps > All apps) and search for FinBridge Connect.
Check:
- Name displays correctly
- Version shows 3.1
- Publisher and description are correct
UI variation warning: Catalog columns differ by tenant; verify by opening app properties if a column is missing.
Expected result: Catalog entry is present and metadata is correct.

17. Confirm assignment is present on the app.
Open app > Assignments and confirm pilot group is listed as Required.
Expected result: Target group and assignment intent are correct.

18. Check install status summary in Intune.
Open app > Device install status (or Monitor > Device install status).
UI variation warning: Monitor blade names vary. Verify using install status views available in your tenant.
Expected result: Devices begin reporting status.

19. Check status on a specific assigned pilot device.
Navigation option A: Open app > Device install status > find device.
Navigation option B: Devices > All devices > select device > Managed apps > FinBridge Connect.
UI variation warning: Device-centric app views can have different labels across tenants. Verify equivalent status view.
Expected result: You can see per-device state for FinBridge Connect.

20. Interpret deployment statuses correctly:
- Installed: App installed and detection rule matched (registry version equals 3.1).
- Failed: Installation attempt completed with failure return code or detection did not match expected value.
- Not applicable: Device does not meet requirement rules or assignment scope.
Expected result: Engineer can triage whether issue is install failure, targeting issue, or requirement mismatch.

21. If status is Failed, troubleshoot in this order:
1) Validate install/uninstall command syntax.
2) Validate detection key path, value name, and value data.
3) Validate requirement rules (OS version and architecture).
4) Validate return-code mapping.
Expected result: Root cause category is identified quickly.

22. Capture go or no-go evidence before phased rollout.
Minimum evidence set:
- Pilot install success rate
- Count of Failed and Not applicable
- Screenshot or export of app status summary
- Sample device confirmation showing Installed
Expected result: Formal readiness evidence exists before any large-scale assignment.

## 5. Quick Reference (Worked Example Values)

- App type: Windows app (Win32)
- Package: FinBridgeConnect_v3.1.intunewin
- Install command: FinBridgeConnect_Setup.exe /silent
- Uninstall command: FinBridgeConnect_Setup.exe /uninstall /silent
- Install context: System
- Detection rule:
  - Registry path: HKLM\\SOFTWARE\\FinBridge\\Connect
  - Value name: Version
  - Operator: Equals
  - Expected value: 3.1
- Initial assignment: Required to pilot group only

## 6. Completion Criteria

You are ready to begin phased rollout only when all are true:
1. App is visible in Intune catalog with correct metadata.
2. Pilot group assignment is active and scoped correctly.
3. Pilot devices report stable Installed status.
4. Failed and Not applicable counts are understood and acceptable.
5. Evidence is documented in the deployment record.
