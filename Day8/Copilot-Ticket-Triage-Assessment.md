# Copilot Ticket Triage Assessment (Day8)

Date: 2026-08-12
Role context: DWP engineer triaging Copilot support tickets

Method used:
- Ranked likely causes using only the allowed list.
- Defaulted to non-Copilot causes unless evidence strongly indicates otherwise.
- Kept "genuine Copilot fault" as last resort.

## At-a-glance verdicts

- No: 5 tickets (3, 4, 6, 8, and likely 2)
- Unclear pending checks: 3 tickets (1, 5, 7)
- Yes (confirmed Copilot bug): 0 tickets

## Ticket assessments

### Ticket 1
Issue:
Finance lead cannot summarise Q3 board pack in SharePoint, but can see the file.

Likely cause (ranked):
1. data indexing lag
2. sensitivity label restriction
3. permissions/access boundary
4. genuine Copilot fault

Fastest check:
Check when the board pack was uploaded or changed. If recent, retry after index catch-up time.

Is this actually a Copilot bug?
Unclear. User visibility does not guarantee immediate grounding if indexing is incomplete.

### Ticket 2
Issue:
New hire (started yesterday): Copilot in Outlook knows nothing about recent emails.

Likely cause (ranked):
1. data indexing lag
2. license/client prerequisite issue
3. permissions/access boundary
4. genuine Copilot fault

Fastest check:
Confirm Copilot license/service plan is assigned and active for the new hire account.

Is this actually a Copilot bug?
No. Most consistent with new-account provisioning/index freshness.

### Ticket 3
Issue:
HR manager in Word asked Copilot to pull from a sensitive salary review spreadsheet and got "I don't have access to that content."

Likely cause (ranked):
1. permissions/access boundary
2. sensitivity label restriction
3. data indexing lag
4. genuine Copilot fault

Fastest check:
Open the spreadsheet directly as the same HR manager account to verify effective access.

Is this actually a Copilot bug?
No. This is expected access enforcement behavior.

### Ticket 4
Issue:
Sales rep in Teams cannot find a client contract shared via a guest link from another org.

Likely cause (ranked):
1. guest/external sharing limitation
2. permissions/access boundary
3. data indexing lag
4. genuine Copilot fault

Fastest check:
Verify the user has proper B2B guest access in the source tenant, not only an ad-hoc guest link.

Is this actually a Copilot bug?
No. Cross-tenant guest-link scenarios commonly limit grounding scope.

### Ticket 5
Issue:
IT admin reports Copilot stopped for the whole Finance team this morning; it worked yesterday.

Likely cause (ranked):
1. license/client prerequisite issue
2. permissions/access boundary
3. genuine Copilot fault

Fastest check:
Check Microsoft 365 admin/service health and any recent license or policy changes for Finance users.

Is this actually a Copilot bug?
Unclear. Tenant config/service state can cause team-wide symptoms without a product defect.

### Ticket 6
Issue:
Manager says Copilot summarized a file from a folder they forgot they had access to.

Likely cause (ranked):
1. permissions/access boundary
2. data indexing lag
3. genuine Copilot fault

Fastest check:
Check the manager's current effective permissions on that folder and file.

Is this actually a Copilot bug?
No. Copilot using content the user is authorized to access is expected behavior.

### Ticket 7
Issue:
Analyst gets generic answers and Copilot appears not to use internal SharePoint content.

Likely cause (ranked):
1. license/client prerequisite issue
2. permissions/access boundary
3. data indexing lag
4. genuine Copilot fault

Fastest check:
Verify the analyst is in a supported Copilot client/session with the correct licensed work account.

Is this actually a Copilot bug?
Unclear. Account/client/license context issues are more likely than a defect.

### Ticket 8
Issue:
Executive assistant in Outlook cannot access a shared mailbox calendar managed for their director.

Likely cause (ranked):
1. permissions/access boundary
2. license/client prerequisite issue
3. data indexing lag
4. genuine Copilot fault

Fastest check:
Confirm delegate/shared mailbox calendar permissions by opening the director calendar directly in Outlook with the same account.

Is this actually a Copilot bug?
No. Most likely delegate/scope boundary behavior.

## Overall pattern

- The dominant causes are non-Copilot: permissions/access boundary, indexing/provisioning delay, and license/client prerequisites.
- Ticket 5 is the strongest "Unclear" until admin health and policy/licensing checks complete.
- None of the tickets currently justify "genuine Copilot fault" as the primary cause.
