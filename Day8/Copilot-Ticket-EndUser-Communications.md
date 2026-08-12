# Copilot Support Tickets - End User Communications

Date: 2026-08-12
Audience: End users
Purpose: Plain-English updates and next steps for each ticket

## Ticket 1 - Finance lead (SharePoint board pack not summarising)

Suggested message to user:

Hi, thanks for reporting this.

You can see the Q3 board pack, but Copilot may not be able to use it immediately if the file was recently uploaded or updated. Copilot relies on Microsoft 365 indexing, and that can sometimes take a little time to catch up.

What to do next:
1. Please check when the file was last updated.
2. If it was updated recently, wait a short period and try again.
3. If it still fails later today, reply with the exact time you tested and a screenshot of the prompt/result so we can check label/access controls next.

Current status:
This does not currently look like a confirmed Copilot bug.

---

## Ticket 2 - New hire (Outlook Copilot knows nothing about recent emails)

Suggested message to user:

Hi, thanks for flagging this.

Because your account is new, Copilot may not yet have full indexed context for your mailbox, and sometimes license provisioning also takes time after start date.

What to do next:
1. Confirm you are signed in with your work account in Outlook.
2. We will verify Copilot licensing is active on your account.
3. Please retry later today after mailbox/indexing has had more time to settle.

Current status:
This is most likely onboarding/provisioning timing, not a Copilot product bug.

---

## Ticket 3 - HR manager (salary spreadsheet access error in Word)

Suggested message to user:

Hi, thanks for the details.

The message "I don't have access to that content" usually means Copilot is correctly enforcing access rules. Even if the file exists, Copilot can only use it when your account has the required permissions and label rights.

What to do next:
1. Try opening the salary spreadsheet directly with the same account.
2. If direct access fails, request access from the file owner.
3. If direct access works but Copilot still shows the same error, send us the file location and timestamp and we will investigate further.

Current status:
This currently looks like expected access-control behavior, not a Copilot bug.

---

## Ticket 4 - Sales rep (cannot find contract shared via guest link)

Suggested message to user:

Hi, thanks for reporting this.

When a contract is shared through a guest link from another organization, Copilot may not be able to ground on it unless full guest/B2B access is correctly in place.

What to do next:
1. Confirm you can open the contract directly from the shared source.
2. Ask the source organization to confirm your B2B guest access is fully configured (not just link-based access).
3. Retry Copilot after access confirmation.

Current status:
This is likely a cross-organization sharing/access limitation, not a Copilot bug.

---

## Ticket 5 - IT admin (Finance team-wide Copilot stopped this morning)

Suggested message to user:

Hi, thanks for escalating this.

Because this affected the whole Finance team at once, this is more likely related to tenant service health, policy, or licensing changes than a single-user issue.

What to do next:
1. We are checking Microsoft 365 service health and recent policy/license changes for the Finance group.
2. Please share exact first-failure time and sample affected users.
3. We will update you once those checks complete.

Current status:
Not yet confirmed as a Copilot bug. Investigation is in progress.

---

## Ticket 6 - Manager (Copilot summarised a file user forgot they could access)

Suggested message to user:

Hi, thanks for raising this.

Copilot can use files your account is allowed to access, even if you have not opened them recently or forgot that permission existed. So this behavior can be expected.

What to do next:
1. Review your access to the folder/file in question.
2. If that access is no longer appropriate, ask the data owner to remove or adjust permissions.
3. If needed, we can help identify and review broad access groups.

Current status:
This does not indicate a Copilot bug. It points to existing permissions scope.

---

## Ticket 7 - Analyst (generic answers, no apparent SharePoint grounding)

Suggested message to user:

Hi, thanks for reporting this.

Generic responses usually happen when Copilot is not getting enough organizational context from the current account/session or client setup.

What to do next:
1. Confirm you are signed into the correct work account.
2. Confirm Copilot license is active for your user.
3. Retry in a supported client/session and test with a specific internal SharePoint file prompt.

Current status:
Not currently a confirmed Copilot bug. Account/client/license context is the likely cause.

---

## Ticket 8 - Executive assistant (shared mailbox calendar not visible to Copilot)

Suggested message to user:

Hi, thanks for the report.

Shared mailbox and delegate calendar scenarios can be restricted by access boundaries. Copilot may not be able to use that calendar unless delegated permissions are fully effective for the active account/session.

What to do next:
1. Open the director's shared calendar directly in Outlook with the same account.
2. If access is missing or partial, request delegate permission review.
3. After permission confirmation, retry Copilot.

Current status:
This is most likely a delegate/shared-access boundary issue, not a Copilot bug.

---

## Standard closing line (optional for all responses)

If the issue continues after these checks, please reply with:
1. Time of latest test
2. App used (Word, Outlook, Teams, etc.)
3. Exact prompt used
4. Screenshot of the error/result

This helps us complete root-cause checks quickly.
