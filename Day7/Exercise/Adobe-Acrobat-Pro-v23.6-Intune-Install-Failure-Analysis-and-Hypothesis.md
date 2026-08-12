# Adobe Acrobat Pro v23.6 Intune Install Failure Analysis and Hypothesis

## Incident Snapshot
- App: Adobe Acrobat Pro v23.6
- Delivery: Intune Win32 app
- Install context: SYSTEM
- Install command: msiexec /i AcrobatPro.msi /quiet
- Outcome: Return code 1603 on initial attempt and retry
- Detection configured: HKLM\SOFTWARE\Adobe\Acrobat Reader\23.0 (not found)

## Ranked Top 5 Most Likely Causes

### 1) Incorrect deployment method or install command for Acrobat Pro packaging
- Weight: 35%
- Why this cause fits:
  The deployment uses a bare MSI call. Acrobat Pro enterprise deployments commonly require Adobe setup wrapper and configuration artifacts, not only a direct MSI execution. Fast, repeatable 1603 failures are consistent with a packaging or command mismatch.
- Single fastest check:
  Run the same command as SYSTEM with verbose MSI logging and inspect first fatal error line:
  `msiexec /i AcrobatPro.msi /quiet /L*v C:\Windows\Temp\acrobat-install.log`

### 2) Existing Adobe product conflict or stale uninstall remnants
- Weight: 25%
- Why this cause fits:
  1603 frequently appears when Reader/Acrobat versions conflict, downgrade/upgrade rules block install, or prior uninstall remnants remain. Retry fails identically, suggesting a persistent host state issue.
- Single fastest check:
  Enumerate installed Adobe entries and product codes in uninstall registry hives:
  `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall`
  and
  `HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall`

### 3) Pending reboot or Windows Installer transaction state
- Weight: 15%
- Why this cause fits:
  MSI 1603 commonly occurs when pending reboot flags or locked replacement operations are present. A repeated failure pattern across retries is compatible with this condition.
- Single fastest check:
  Check reboot-pending indicators:
  `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending`
  and
  `HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\PendingFileRenameOperations`

### 4) Detection rule mismatch (Reader key used for Pro)
- Weight: 15%
- Why this cause fits:
  Detection is keyed to Acrobat Reader path, while the deployed app is Acrobat Pro. Even if installation partially succeeds, incorrect detection can keep reporting Not detected and drive repeated retries.
- Single fastest check:
  Validate detection against a known-good Acrobat Pro install and switch detection to a Pro-specific artifact (for example product code or Pro uninstall key).

### 5) Incomplete or corrupt intunewin content structure
- Weight: 10%
- Why this cause fits:
  If MSI dependencies (CAB/MSP/resource files) are missing or misplaced relative to the MSI, installations can fail with 1603 quickly under SYSTEM context.
- Single fastest check:
  Extract source package content and verify all MSI-referenced files exist in expected relative paths before repackaging and re-uploading.

## Most Probable Immediate Triage Path
1. Reproduce with verbose MSI logging as SYSTEM.
2. Confirm Adobe-recommended enterprise installer method for this build (setup wrapper vs raw MSI).
3. Correct detection logic to Acrobat Pro-specific evidence.
4. Check Adobe conflict/remnant state and pending reboot indicators.
5. Rebuild package if content integrity/pathing is suspect.

## Working Hypothesis
Primary hypothesis: the package/command is not aligned with Acrobat Pro enterprise deployment requirements, resulting in deterministic MSI 1603 failures.

Secondary hypothesis: even if install behavior is corrected, current detection logic is likely invalid for Acrobat Pro and may continue to report false negatives until updated.

---

## Update: Event Details, Surviving Hypothesis, and Resolution

### Updated Event Details
- First attempt:
  - 10:01:03 install command started: `msiexec /i AcrobatPro.msi /quiet`
  - 10:01:44 failed with return code 1603 (about 41 seconds)
- Detection immediately after failure:
  - Registry detection checked: `HKLM\SOFTWARE\Adobe\Acrobat Reader\23.0`
  - Value not found, detection result Not detected
- Retry behavior:
  - Retry started at 11:01:48 with same install command
  - Failed again at 11:02:31 with return code 1603 (about 43 seconds)
- Pattern observed:
  - Deterministic, repeatable MSI failure under SYSTEM context
  - Failure occurs before any evidence of successful install footprint

### Surviving Hypothesis
Packaging and install command mismatch for Acrobat Pro in Intune Win32 deployment.

Reason this hypothesis survives elimination:
- The failure is consistent in both attempts with the same code and near-identical runtime.
- Return code 1603 occurs in the installation phase, which points to installer execution/package method rather than detection-only logic.
- Detection mismatch explains repeated retry/non-detection state, but does not independently explain MSI 1603.
- No contrary evidence in the event stream indicates transient device-state causes as primary.

### Detailed Resolution Steps
1. Capture one authoritative failure log as SYSTEM.
  - Launch SYSTEM shell and run:
    `msiexec /i AcrobatPro.msi /qn /norestart /L*v C:\Windows\Temp\AcrobatPro-rawmsi.log`
  - Confirm `Return value 3` and record first fatal MSI error line for evidence.

2. Rebuild the installer using Adobe enterprise packaging workflow.
  - Create a new Acrobat Pro enterprise package from Adobe Admin Console.
  - Keep full exported folder structure and required configuration artifacts.

3. Repackage correctly as Intune Win32 app.
  - Use source root containing `setup.exe` and all package content.
  - Build `.intunewin` from source root, not MSI-only subfolder.

4. Update Intune install/uninstall commands.
  - Install: use Adobe package setup command (typically `setup.exe --silent`, or package-documented equivalent).
  - Uninstall: use package-provided uninstall command or validated product-code uninstall.

5. Correct detection logic to Acrobat Pro-specific evidence.
  - Replace Reader registry key detection with:
    - MSI product code detection, or
    - Acrobat Pro file/path version detection.
  - Validate detection on a known-good reference device.

6. Validate return code mappings.
  - Success: `0`
  - Soft reboot: `3010`
  - Failure: `1603`

7. Pilot deployment and verification.
  - Assign to a small pilot group.
  - Verify Intune status, IME logs, and MsiInstaller events.
  - Confirm criteria: install success and detection equals detected.

8. Controlled rollout.
  - Migrate assignments using phased deployment or supersedence.
  - Retire prior mispackaged app entry after pilot success window.

9. Prevent recurrence.
  - Add packaging checklist control: Adobe Pro must follow vendor enterprise setup workflow, not raw MSI-only deployment unless explicitly validated.
