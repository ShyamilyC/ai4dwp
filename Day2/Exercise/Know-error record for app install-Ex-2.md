# Known-Error Record — 7-Zip Install Failure via Company Portal

**Symptom:** "7-Zip" shows as failed in Company Portal; installation does not complete.
**Cause:** To confirm — likely detection rule mismatch after a version bump, or Win32 app package not updated to current 7-Zip release in Intune.
**Scope:** All devices assigned the 7-Zip app deployment; to confirm whether scoped by device group or affects all users.
**Workaround:** IT to manually install 7-Zip directly on affected devices; not user-fixable via Company Portal.
**Permanent fix:** Verify and update the Intune Win32 app package and detection rule to match the current 7-Zip version; test deployment on a pilot device before re-assigning to the wider group.
