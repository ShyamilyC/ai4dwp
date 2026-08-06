# Ticket T-1002 Triage

## Summary (one line)
Finance user cannot open a shared mailbox after migration, likely related to post-migration permissions/profile mapping (to-verify).

## Impact (who/how many/business urgency)
- Who is affected: Finance user (single reported user; to-verify if others affected).
- How many affected: Currently one known user/mailbox path.
- Business urgency: High (to-verify), due to potential disruption to finance operations and shared workflow access.

## Known facts
- Ticket ID: T-1002.
- User role context: Finance.
- Symptom: Cannot open a shared mailbox.
- Timing/context: Issue occurs after migration.

## Missing information to gather
- User identity and mailbox details: UPN, affected shared mailbox address (sanitised in external contexts).
- Scope: Whether other Finance users can open the same shared mailbox.
- Access path: Outlook desktop, Outlook on the web, or both.
- Error visibility: Exact user-facing message text/screenshot (no sensitive data).
- Migration details: Cutover date/time and whether mailbox was moved, remapped, or permission model changed.
- Permission checks: Current Full Access/Send As assignments and effective access propagation status (to-verify).
- Client state: Whether Outlook profile was recreated and whether cached credentials/session tokens were refreshed.
- Business impact: Whether payment runs, approvals, or deadlines are currently blocked.

## Likely category
Messaging and Collaboration -> Exchange Online / Shared Mailbox Access Issue (to-verify exact ITSM category).

## First diagnostic step
Validate scope and permission path quickly: confirm if the same shared mailbox opens for another authorised Finance user and, for the affected user, test mailbox access in Outlook on the web to separate client-profile issues from backend permission/migration issues.