# Exercise 1 - Application Crash Analysis (Event Viewer, Application Log)

## Incident Summary
- Repeated Outlook crashes were recorded in the Application log on 2024-03-15.
- The crash pattern points to an access violation in `KERNELBASE.dll` while running `OUTLOOK.EXE` (Office 16 build `16.0.17126.20132`).
- Follow-up telemetry (.WER and .NET runtime) confirms app termination after unhandled exception.

### At a glance
- Affected app: `OUTLOOK.EXE`
- Primary fault code: `0xc0000005` (Access Violation)
- Repeated fault location: `KERNELBASE.dll` at `0x000000000003a4b2`
- Pattern: repeatable crash within minutes

## Event-by-Event Explanation

### Event ID 1000 (Source: Application Error, Level: Error)
What it records:
- A process crashed at runtime.
- It identifies the faulting application, faulting module, exception code, fault offset, process details, and report ID.

What this specific Event 1000 shows:
- Faulting app: `OUTLOOK.EXE` version `16.0.17126.20132`.
- Faulting module: `KERNELBASE.dll` version `10.0.22621.3155`.
- Exception code: `0xc0000005` (Access Violation - invalid memory read/write).
- Fault offset: `0x000000000003a4b2` (same location appears again in later crash).
- The first crash happened at `09:14:22`; Outlook started at `09:13:44` (crash occurred about 38 seconds after launch).
- A second Event 1000 occurred at `09:17:45` with the same module, exception code, and offset, showing recurrence and signature consistency.

Key interpretation:
- This is the primary crash event and strongest technical evidence.

### Event ID 1001 (Source: Windows Error Reporting, Level: Information)
What it records:
- Windows Error Reporting (WER) metadata generated after a crash.
- Fault bucket/event classification used by Microsoft telemetry and local diagnostics.

What this specific Event 1001 shows:
- Event Name: `APPCRASH`.
- Fault bucket `1847362910`, type `4`.
- Confirms the crash was captured and classified by WER shortly after Event 1000.
- Logged at `09:18:01`, immediately after repeated crash activity.

Key interpretation:
- Confirms Windows recognized and grouped the failure as an application crash.

### Event ID 1026 (Source: .NET Runtime, Level: Error)
What it records:
- A managed (.NET) runtime exception caused a process to terminate.
- Identifies framework version and unhandled exception type.

What this specific Event 1026 shows:
- Application: `OUTLOOK.EXE`.
- .NET Framework: `v4.0.30319`.
- Unhandled exception: `System.AccessViolationException`.
- Logged at `09:18:05`, indicating the process ended due to unhandled invalid memory access in managed execution path (or transition between managed/unmanaged components).

Key interpretation:
- Confirms the access violation was unhandled, so Outlook could not continue running.

## Reconstructed Sequence of Events (Plain English)
- `09:13:44` - User launches Outlook.
- `09:14:22` - Outlook crashes (Event 1000) with access violation `0xc0000005` in `KERNELBASE.dll`.
- `09:17:45` - Outlook crashes again with identical signature (same module, code, and offset).
- `09:18:01` - WER records `APPCRASH` bucket details (Event 1001).
- `09:18:05` - .NET Runtime logs unhandled `System.AccessViolationException` (Event 1026).
- Outcome: repeated, deterministic crash path rather than a one-off failure.

## Most Likely Cause (with Evidence)
### Most likely cause
A recurring memory access fault triggered by Outlook code path or an integrated component (for example, add-in, extension, or interop path) leading to an unhandled access violation.

### Evidence from events
- `0xc0000005` in both Event 1000 entries: canonical signature for invalid memory access.
- Same faulting module and same fault offset (`KERNELBASE.dll` + `0x000000000003a4b2`) across repeated crashes: points to deterministic, repeatable failure path rather than random system instability.
- Event 1026 reports unhandled `System.AccessViolationException`: aligns directly with Event 1000 low-level access violation.
- Repetition across short time window: strongly indicates persistent trigger (same startup action, mailbox content handling path, add-in loading path, or client state corruption) rather than one-time transient fault.

Confidence assessment:
- High confidence in "repeatable access violation crash" diagnosis.
- Medium confidence on precise trigger (requires add-in/profile/dump validation).

## 5 Whys Analysis
### Problem Statement
Outlook repeatedly crashes shortly after launch for the same user/session.

### Why 1
Why did Outlook close unexpectedly?
- Because the process hit an unhandled access violation and terminated.
- Evidence: Event 1000 (`0xc0000005`) and Event 1026 (`System.AccessViolationException`).

### Why 2
Why was there an access violation?
- A code path attempted invalid memory access while Outlook was running.
- Evidence: consistent `KERNELBASE.dll` fault and identical fault offset across crashes.

### Why 3
Why did the same invalid memory access happen repeatedly?
- The same trigger condition was present each time Outlook ran (for example startup component load sequence, add-in invocation, or the same mailbox/profile operation).
- Evidence: second crash has same signature as first (module, exception code, offset).

### Why 4
Why did Outlook not recover from that fault?
- The exception was unhandled in the active execution path, so runtime terminated the process.
- Evidence: .NET Runtime Event 1026 explicitly states process terminated due to unhandled exception.

### Why 5
Why was the triggering condition still present after restart?
- No corrective change occurred between launches (same build, same environment, same startup conditions), so the fault path reoccurred.
- Evidence: repeated crash within minutes with unchanged signature and immediate WER APPCRASH classification.

5 Whys conclusion:
- Persistent startup/runtime condition repeatedly triggers invalid memory access.
- No mitigation step between launches allowed the same failure path to recur.

## Technical Conclusion
- The incident is a repeatable application-level crash pattern centered on access violation during Outlook execution.
- The logs do not indicate random hardware instability.
- The strongest evidence is the repeated Event 1000 signature plus Event 1026 unhandled `AccessViolationException`.

## Recommended Next Validation Steps (for complete RCA in production)
- Correlate with Outlook add-in inventory and disable non-Microsoft add-ins to test crash cessation.
- Test Outlook in safe mode and with a clean/new profile to isolate profile or add-in trigger.
- Check Office build channel history and recent updates around incident time.
- Collect and inspect WER dump (if available) for stack trace near `KERNELBASE.dll+0x3a4b2`.
- Compare behavior on same host with another user profile to separate user-state vs host-state issue.

## Severity and Impact Assessment
- Severity: Medium to High (user productivity loss due to repeated mail client failure).
- Scope from provided logs: single application instance, recurring.
- Business impact: inability to use Outlook reliably during incident window.
