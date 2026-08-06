# Ticket T-1005 Triage

## Summary (one line)
Teams audio is not working on three machines in the same meeting room, indicating a likely shared room-level audio path issue (to-verify).

## Impact (who/how many/business urgency)
- Who is affected: Users joining meetings from one meeting room.
- How many affected: Three machines reported in the same room.
- Business urgency: High (to-verify), due to direct impact on meeting continuity and collaboration.

## Known facts
- Ticket ID: T-1005.
- Service context: Microsoft Teams meetings.
- Symptom: Audio not working (dead audio).
- Scope clue: Three machines in same meeting room affected.

## Missing information to gather
- Audio direction: No input (mic), no output (speaker), or both.
- Consistency: Fails in all meetings/apps or Teams only.
- Peripheral map: Shared dock/speakerphone/headset/USB hub in room (to-verify).
- Recent changes: Any room equipment swaps, cable changes, or updates.
- User path: Whether affected users can get audio from same account on another device/room.
- Device settings: Selected Teams audio devices and OS default devices at failure time.
- Scope extension: Any adjacent rooms/floors showing same symptom (to-verify).
- Business impact: Number of disrupted meetings and critical participants.

## Likely category
Collaboration Services -> Teams Audio/Peripherals Incident (to-verify exact ITSM category).

## First diagnostic step
Perform a controlled in-room test on one affected machine: verify OS playback/recording with a local sound test, then Teams test call using known-good headset bypassing shared room peripherals to distinguish endpoint software from room hardware path issues.