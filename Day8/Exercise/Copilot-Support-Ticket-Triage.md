# Copilot Support Ticket Triage

## At a Glance

| # | User | Issue | Copilot bug? |
|---|------|-------|:------------:|
| 1 | Paralegal | "I don't have access to that content" (SharePoint NDA) | No |
| 2 | New associate | Copilot in Outlook can't find case emails | No |
| 3 | Partner | Copilot surfaced a draft settlement from an unassigned matter | No |
| 4 | Legal Ops Manager | All 40 Legal team members lost Copilot access simultaneously | No |
| 5 | Contract specialist | Vague, generic answers about contract template clauses | Unclear |

---

## Ticket 1 — Paralegal: "I don't have access to that content"

> She asked Copilot to summarise a client NDA in SharePoint — a folder she has never actually opened.

**Likely causes (most probable first)**
1. **Permissions/access boundary** — she has never opened the folder and almost certainly has no direct permission to it. SharePoint access is not granted simply by hearing about a file in a meeting.
2. **Sensitivity label restriction** — the NDA may carry a label (e.g. Confidential/Legal) that blocks Copilot from surfacing it, even if read access were later granted.

**Fastest check**
- Open the SharePoint folder in a browser logged in as her and confirm whether she can open the file manually.

**Copilot bug?** No
- Copilot correctly honours SharePoint permission boundaries.
- If she cannot open the file in the browser, this is expected behaviour, not a fault.

---

## Ticket 2 — New Associate: Copilot in Outlook can't find case emails

> Started this week; Copilot cannot find any of the case emails needed for context.

**Likely causes (most probable first)**
1. **Licence/client prerequisite issue** — the M365 Copilot licence may not yet be assigned to a brand-new account.
2. **Data indexing lag** — even with a licence, new mailboxes can take 24–72 hours to be fully indexed for Copilot/Search.

**Fastest check**
- In the Microsoft 365 admin centre, confirm a Copilot licence is assigned to the account and note the assignment date.

**Copilot bug?** No
- New-account indexing lag and a missing licence are both standard, expected causes for this symptom.

---

## Ticket 3 — Partner: Copilot surfaced an unassigned matter's draft settlement

> Copilot summarised a draft settlement from a matter the partner is not assigned to — they didn't know they could even see that folder.

**Likely causes (most probable first)**
1. **Permissions/access boundary** — the partner likely has broader read access than they realise (e.g. inherited site membership, a broad "Legal team" group, or owner-level rights across all matters). Copilot only ever surfaces content the user can already access.
2. **Sensitivity label restriction** — the absence of a restrictive label on the draft means nothing prevented Copilot from returning it once access existed.

**Fastest check**
- Check the SharePoint permissions on the settlement document and confirm whether the partner is a direct or inherited member of a group with read access.

**Copilot bug?** No
- Copilot does not bypass permissions — it surfaces content the user is already permitted to see.
- This is an overly permissive access control issue, not a Copilot fault.

---

## Ticket 4 — Legal Ops Manager: Entire team lost Copilot access this morning

> All 40 people on the Legal team lost Copilot access simultaneously; it worked fine last week.

**Likely causes (most probable first)**
1. **Licence/client prerequisite issue** — a bulk licence change, reassignment, or expiry event (e.g. an Azure AD group change removing a licence-bearing group) is the most common cause of sudden, team-wide loss.
2. **Permissions/access boundary** — an admin change to the Entra ID group controlling Copilot access could have removed all 40 members at once.

**Fastest check**
- In the M365 admin centre, check the licence assignment for the Legal team group and review the audit log for any changes made this morning.

**Copilot bug?** No
- Simultaneous loss across an entire team almost always points to an admin or licence change, not a product fault.

---

## Ticket 5 — Contract Specialist: Vague, generic answers about contract clauses

> Copilot gives generic answers when asked about clauses in the contract templates library and doesn't seem to read the actual documents.

**Likely causes (most probable first)**
1. **Sensitivity label restriction** — templates with restrictive labels (e.g. Highly Confidential) may block Copilot from reading their full content, causing fallback to general knowledge.
2. **Permissions/access boundary** — if the library has broken inheritance or restricted access, Copilot cannot retrieve the documents at all.
3. **Data indexing lag** — if the library was recently migrated or files recently uploaded, they may not yet be fully indexed.

**Fastest check**
- Ask Copilot to cite which documents it used in its answer.
- If it names none, open a template in the browser to confirm read access, then check whether a sensitivity label is applied.

**Copilot bug?** Unclear
- If access, labels, and indexing are all confirmed fine, a genuine grounding/retrieval issue cannot be ruled out.
- Eliminate those causes first before escalating as a Copilot fault.

---
