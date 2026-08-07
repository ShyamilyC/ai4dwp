# Title: Finance Team Cannot Access Shared Drives Runbook
# Version: 1.0
# Date: 07/08/2026
# Author: Shyamily
# Reviewed: self
# Status: draft
# Change: initial version from RCA

# Runbook: Finance Team Cannot Access Shared Drives (USER-Context Mapping Restoration)

## 1) Prerequisites

1. Confirm you have access to Microsoft Intune admin center with rights to view and edit PowerShell scripts and assignments. **[ELEVATED PERMISSIONS REQUIRED]**
2. Confirm you have access to Active Directory Group Policy Management Console (GPMC) or approved policy management path for Finance user logon scripts. **[ELEVATED PERMISSIONS REQUIRED]**
3. Confirm you can access endpoint logs for at least one affected Finance device (for example, DESKTOP-FB041) via Event Viewer or central logging.
4. Confirm you can reach the file share path `\\finbridge-fs01\Finance` from a test Finance user session.
5. Open the incident record and note affected scope as Finance users in `OU=Finance` and expected recovery target of all affected users.
6. Prepare one Finance pilot user account and one Finance endpoint for controlled validation before broad confirmation.
7. Open these tools before starting procedure: Intune admin center, GPMC (or approved equivalent), Event Viewer, and a test Finance user sign-in session.

## 2) Procedure

1. In a browser, go to `https://intune.microsoft.com` and sign in with your admin account.
Expected result: Intune home page loads and your account name appears in the top-right profile area.

2. In Intune, go to `Devices` -> `Scripts and remediations` -> `Platform scripts`.
Expected result: The script list page opens and shows Windows PowerShell script entries.

3. In `Platform scripts`, search for `Map-FinBridgeDrives.ps1` and open that script.
Expected result: Script details page opens and script name exactly matches `Map-FinBridgeDrives.ps1`.

4. Open the script `Assignments` tab. **[ELEVATED PERMISSIONS REQUIRED]**
Expected result: Current Included/Excluded group assignments are visible.

5. Edit assignments and remove the Finance target group (or move it to Excluded groups), then select `Review + save`. **[ELEVATED PERMISSIONS REQUIRED]**
Expected result: The Finance group no longer appears under Included groups for this script.

6. Select `Save` to publish the assignment change. **[ELEVATED PERMISSIONS REQUIRED]**
Expected result: Intune shows a success notification such as `Assignment updated`.

7. On a management workstation, open `Group Policy Management` (`gpmc.msc`). **[ELEVATED PERMISSIONS REQUIRED]**
Expected result: GPMC opens with forest and domain tree visible.

8. In GPMC, browse to `Forest` -> `Domains` -> `<your-domain>` -> `Group Policy Objects`.
Expected result: Existing GPO list is displayed in the center pane.

9. Select the approved Finance logon mapping GPO used for USER-context drive mapping (name should match your standard Finance mapping policy). **[ELEVATED PERMISSIONS REQUIRED]**
Expected result: GPO details pane shows status `Enabled` and a valid creation/modification record.

10. In GPMC, browse to `Forest` -> `Domains` -> `<your-domain>` -> `OU=Finance`.
Expected result: The Finance OU is selected and linked GPOs are visible.

11. In the `Linked Group Policy Objects` section, link the approved Finance mapping GPO to `OU=Finance` if it is not already linked. **[ELEVATED PERMISSIONS REQUIRED]**
Expected result: The Finance mapping GPO appears in the linked list for `OU=Finance`.

12. Set link order so the Finance mapping GPO is above conflicting drive-mapping policies (or set `Enforced` only if your change policy requires it). **[ELEVATED PERMISSIONS REQUIRED]**
Expected result: Final link order in `OU=Finance` shows Finance mapping GPO with intended precedence.

13. On the pilot Finance endpoint, sign in as the pilot Finance user.
Expected result: Desktop loads with no sign-in errors and user profile is fully loaded.

14. Open `Command Prompt` and run `gpupdate /force`.
Expected result: Output contains `User Policy update has completed successfully`.

15. Sign out of the pilot session and sign back in with the same Finance user.
Expected result: Login completes and user reaches desktop normally.

16. Open `File Explorer` -> `This PC` and check for mapped drive `S:`.
Expected result: Drive appears as `S:` and points to Finance shared storage.

17. Open drive `S:` and open at least one known folder used by Finance.
Expected result: Folder opens without `Access is denied`, `Network path not found`, or credential prompts.

18. On the pilot endpoint, open `Event Viewer` (`eventvwr.msc`) -> `Windows Logs` -> `System`, then `Filter Current Log...` for Event ID `98` and set `Logged` to `Last 1 hour`.
Expected result: No new Event ID 98 entries appear for failed `S:` mapping after the latest sign-in.

19. In Intune script details, open `Device status` (or `User status`) and filter to Finance scope.
Expected result: No new `Failed` runs for `Map-FinBridgeDrives.ps1` are shown after the assignment change timestamp.

20. Repeat steps 13 through 17 on a second Finance endpoint.
Expected result: Second endpoint shows `S:` mapped and browsable with no access errors.

21. Send a Service Desk update requesting user confirmation from at least two Finance representatives.
Expected result: Service Desk records positive confirmation from Finance users that shared drive access is restored.

22. Add all action timestamps, screenshots, and validation evidence to the incident ticket.
Expected result: Incident record includes full remediation evidence and is ready for closure review.

## 3) Verification

1. Verify on Endpoint 1: `File Explorer` -> `This PC` shows `S:` mapped for an active Finance user session.
Success looks like: `S:` is visible immediately after sign-in and remains visible after File Explorer refresh.

2. Verify on Endpoint 1: open `S:` and browse to `\\finbridge-fs01\Finance` content.
Success looks like: At least one known Finance folder opens and file listing loads in under 10 seconds with no credential prompt.

3. Verify on Endpoint 2: `File Explorer` -> `This PC` shows `S:` mapped for a different Finance user or device.
Success looks like: `S:` is present and accessible on the second endpoint as well.

4. Verify in Intune: `Devices` -> `Scripts and remediations` -> `Platform scripts` -> `Map-FinBridgeDrives.ps1` -> `Device status`/`User status`.
Success looks like: After the assignment-change timestamp, Finance targets do not show new `Failed` executions for this script.

5. Verify in Event Viewer on both validated endpoints: `Windows Logs` -> `System` filtered for Event ID `98` in `Last 1 hour`.
Success looks like: No new Event ID 98 entries indicating drive letter `S:` mapping failure.

6. Verify user communications: incident ticket contains responses from Service Desk and at least two Finance users.
Success looks like: Written confirmation states shared drives are accessible and business work resumed.

7. Verify closure evidence is complete in the incident ticket.
Success looks like: Ticket includes Intune assignment screenshot, GPO link/preference screenshot, endpoint validation notes, and final recovery timestamp.

## 4) Rollback (Immediate Actions if Impact Worsens)

Target execution time: 3 minutes or less.

1. Open `https://intune.microsoft.com` -> `Devices` -> `Scripts and remediations` -> `Platform scripts` -> `Map-FinBridgeDrives.ps1` -> `Assignments`. **[ELEVATED PERMISSIONS REQUIRED]**
Expected result: Assignment editor opens for the exact script.

2. In `Assignments`, remove Finance from `Excluded groups` and add Finance back to `Included groups`, then select `Review + save`. **[ELEVATED PERMISSIONS REQUIRED]**
Expected result: Finance appears in Included groups for `Map-FinBridgeDrives.ps1`.

3. Select `Save` and wait for the success banner.
Expected result: Intune shows `Assignment updated`.

4. Open `Group Policy Management` (`gpmc.msc`) -> `Forest` -> `Domains` -> `<your-domain>` -> `OU=Finance`. **[ELEVATED PERMISSIONS REQUIRED]**
Expected result: `OU=Finance` linked GPO list is visible.

5. In `Linked Group Policy Objects`, right-click the Finance USER-context mapping GPO and select `Link Enabled` to uncheck it (or select `Delete` to unlink only from this OU). **[ELEVATED PERMISSIONS REQUIRED]**
Expected result: Finance mapping GPO shows disabled link or is removed from `OU=Finance` links.

6. In the incident ticket, post `Emergency rollback applied`, include exact timestamp, and note `Intune assignment restored + Finance USER-context GPO link disabled`. 
Expected result: Major incident timeline shows rollback completion time and exact state change.

7. Capture one screenshot of Intune `Assignments` state and one screenshot of GPMC `OU=Finance` link state, then attach both to the ticket.
Expected result: On-call and incident manager can confirm rollback state without additional calls.

8. Notify Service Desk channel: `Rollback complete; ask users to sign out/sign in; collecting validation from 2 Finance users`.
Expected result: Service Desk starts coordinated user revalidation immediately.

9. If new high-severity failures continue after 10 minutes, escalate to Major Incident bridge and keep Finance USER-context GPO unlinked while leaving Intune assignment restored. **[ELEVATED PERMISSIONS REQUIRED]**
Expected result: Conflicting mapping methods are not active at the same time during escalation.

## 5) Notes

- Root cause pattern: USER-resource mapping was moved to SYSTEM-context script without redesign for credential/timing dependencies.
- Timing dependency: Workstation service readiness can occur after script execution at startup; no-retry scripts can fail permanently for that session.
- Edge case: Hybrid or remote users on slow links may need an additional sign-out/sign-in cycle before user-context mapping appears.
- Edge case: If drive letter `S:` is already occupied by another mapping, remove conflicting mapping before validating Finance path.
- Warning: Do not broad-assign mapping changes without pilot validation on representative Finance users/devices.
- Monitoring signal to watch during deployment windows: Script failure exit code 1, Service Control Manager 7036 timing, Ntfs 98 mapping failures.
- Related incident family: Broad endpoint-script migrations from GPO USER context to Intune SYSTEM context for login-time resources.
