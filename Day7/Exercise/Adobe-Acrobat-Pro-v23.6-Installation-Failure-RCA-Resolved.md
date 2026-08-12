# RCA: Adobe Acrobat Pro v23.6 Intune Installation Failure (Resolved)

## 1) Incident Summary
- Incident: Adobe Acrobat Pro v23.6 failed to install via Intune Win32 deployment.
- Initial user impact: Targeted endpoints could not receive required Acrobat Pro application.
- Detection/monitoring symptom: Intune Management Extension reported repeated install failure with return code 1603 and scheduled retries.
- Final status: Resolved after packaging and deployment method correction.

## 2) Scope and Impact
- Affected service: Endpoint application deployment via Intune (Win32 app model).
- Affected app: Adobe Acrobat Pro v23.6.
- Affected population: Devices in assignment scope for the Acrobat Pro deployment.
- Business impact:
  - Delay in application availability.
  - Increased support overhead due to repeated retry/failure cycle.
  - Potential compliance and productivity risk for users requiring Acrobat Pro.

## 3) Supporting Evidence

### 3.1 Primary Event Evidence (from install logs)
- `[2024-03-15 10:01:03] AppInstaller Install command: msiexec /i AcrobatPro.msi /quiet`
- `[2024-03-15 10:01:44] AppInstaller Return code: 1603`
- `[2024-03-15 10:01:44] AppInstaller Install failed. Return code 1603.`
- `[2024-03-15 10:01:45] DetectionRule Key: HKLM\SOFTWARE\Adobe\Acrobat Reader\23.0`
- `[2024-03-15 10:01:45] DetectionRule Value: not found`
- `[2024-03-15 10:01:46] DetectionRule Detection result: Not detected`
- `[2024-03-15 11:01:48] AppInstaller Install command: msiexec /i AcrobatPro.msi /quiet`
- `[2024-03-15 11:02:31] AppInstaller Return code: 1603`

### 3.2 Pattern Evidence
- Two consecutive attempts failed with the same code (1603).
- Runtime to failure was near-identical (~41s, ~43s), indicating deterministic failure behavior.
- Install context was SYSTEM for both attempts.

### 3.3 Elimination Evidence
- Detection mismatch (Reader key for Pro) explains post-install reporting/retry behavior, but does not independently produce MSI 1603 during install execution.
- Repeatable pre-detection install failure pointed to installer/package execution method.

### 3.4 Resolution Evidence
- Deployment was rebuilt using Adobe enterprise packaging workflow and proper setup wrapper execution path.
- Intune Win32 package was recreated from source root with full package content.
- Detection logic was corrected to Acrobat Pro-specific evidence.
- Post-change validation outcome: installation succeeded and detection returned detected (issue resolved).

## 4) Timeline (UTC/Local as captured in source logs)
- 2024-03-15 10:01:00: AgentExecutor started app install for Adobe Acrobat Pro v23.6.
- 2024-03-15 10:01:01: Install context confirmed as SYSTEM.
- 2024-03-15 10:01:03: Install command started: `msiexec /i AcrobatPro.msi /quiet`.
- 2024-03-15 10:01:44: Install failed with return code 1603.
- 2024-03-15 10:01:45 to 10:01:46: Detection check ran against Reader key, result Not detected.
- 2024-03-15 10:01:47: Agent marked install result Failed; retry scheduled in 60 minutes.
- 2024-03-15 11:01:47: Retry attempt 1 started.
- 2024-03-15 11:01:48: Same install command executed.
- 2024-03-15 11:02:31: Retry failed with return code 1603.
- Post-incident remediation window: package and detection corrected, redeployed, and validated as successful.

## 5) Root Cause Statement
The Win32 app package and install command were not aligned with Adobe Acrobat Pro enterprise deployment requirements. The deployment invoked a raw MSI command (`msiexec /i AcrobatPro.msi /quiet`) rather than the Adobe package orchestration method (setup wrapper and full content structure), causing deterministic MSI 1603 failures under SYSTEM context.

## 6) Contributing Factors
- Detection rule targeted Acrobat Reader registry path rather than Acrobat Pro-specific artifact.
- Packaging quality gate did not enforce vendor-specific deployment model checks before production assignment.
- Retry behavior masked root-cause clarity by repeatedly reattempting the same invalid install pattern.

## 7) 5-Why Analysis
1. Why did the app fail to install?
   - Because the installer returned MSI code 1603 during execution.
2. Why did MSI return 1603 consistently?
   - Because deployment used a raw MSI command path incompatible with required Acrobat Pro enterprise install orchestration.
3. Why was the incompatible command/path used?
   - Because the Intune Win32 package was prepared around direct MSI invocation instead of vendor-recommended setup wrapper and full package structure.
4. Why was this not caught before assignment?
   - Because packaging validation did not include a mandatory vendor-method compliance check and SYSTEM-context pilot verification gate.
5. Why was repeated failure not quickly isolated to packaging method?
   - Because detection was also misconfigured (Reader key), adding noisy retry symptoms and delaying pinpoint diagnosis.

Root cause from 5-Why:
- Lack of enforcement of vendor-specific packaging standards in the Win32 app release process allowed an incorrect installation method to reach deployment.

## 8) Resolution Actions Implemented
1. Rebuilt Adobe Acrobat Pro installer package using Adobe enterprise packaging workflow.
2. Repackaged Win32 app from correct source root including all required content.
3. Updated install command to package-supported setup execution method.
4. Updated detection rule to Acrobat Pro-specific evidence.
5. Revalidated deployment in pilot scope under SYSTEM context.
6. Confirmed successful install and positive detection state.

## 9) Preventive Actions (Corrective and Preventive Action Plan)

### 9.1 Process Controls
- Introduce mandatory packaging checklist item:
  - Adobe and other vendor-special apps must use documented enterprise deployment method.
- Add release gate:
  - SYSTEM-context install test with verbose logging before production assignment.
- Add detection design gate:
  - Detection must map to exact product edition (Pro vs Reader) and be validated on known-good endpoint.

### 9.2 Technical Controls
- Standardize Win32 packaging template for Adobe applications:
  - Source root structure requirements.
  - Approved install/uninstall command patterns.
  - Return code mapping baseline (0, 3010, 1603).
- Maintain a reusable validation script/checklist for:
  - Install command verification.
  - Detection artifact verification.
  - Retry/failure signal interpretation.

### 9.3 Operational Controls
- Pilot ring requirement for all net-new or reworked Win32 app packages.
- Define rollback/supersedence strategy before broad rollout.
- Add post-deployment monitoring checkpoint at 24h and 48h.

## 10) Validation and Closure Criteria
- Installation success rate in pilot meets acceptance threshold.
- Detection status reports detected for successfully installed endpoints.
- No repeated 1603 pattern in monitoring during observation window.
- Old mispackaged deployment retired or superseded.

Closure status: Closed - Resolved.

## 11) Lessons Learned
- MSI 1603 in repeatable short cycles under SYSTEM often indicates packaging/method mismatch rather than transient endpoint issues.
- Detection inaccuracies can amplify noise and prolong diagnosis even when not the primary install failure cause.
- Vendor-specific deployment workflows must be encoded into packaging governance, not left as optional practice.
