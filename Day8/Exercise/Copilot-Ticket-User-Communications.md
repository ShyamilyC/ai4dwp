# Copilot Support — User Communications

---

## Ticket 1 — Paralegal

**Subject: Re: Copilot can't access the NDA in SharePoint**

Hi,

Thanks for getting in touch. The message you saw — "I don't have access to that content" — is Copilot telling you exactly what's happening: it can't read a file you don't currently have permission to open.

Copilot can only work with files you can already access yourself. Simply hearing about a file in a meeting doesn't give you access to it in SharePoint.

**What to do next:**

1. Try opening the file yourself by navigating to the SharePoint folder in your browser. If you can't open it, that confirms it's a permissions issue rather than a Copilot problem.
2. Contact the document owner or your team's SharePoint administrator and ask them to share the folder or file with you directly.
3. Once you have access and can open the file in your browser, try your Copilot request again — it should work.

If you still see the same message after being given access, please reply to this ticket and we'll investigate further.

---

## Ticket 2 — New Associate

**Subject: Re: Copilot in Outlook not finding case emails**

Hi,

Welcome to the team! The issue you're experiencing is very common for new starters and is almost certainly down to one of two things:

- Your Microsoft 365 Copilot licence may not have been assigned to your account yet.
- Even if it has been assigned, it can take up to 72 hours after a new account is created for your emails to be fully indexed and searchable by Copilot.

**What to do next:**

1. Check whether Copilot works for other things — for example, try asking it to draft a short email. If that works, the licence is active and you just need to wait for the email index to catch up.
2. If Copilot doesn't respond at all, it's likely a licence issue. Please contact your line manager or IT helpdesk to confirm your Copilot licence has been activated.
3. If you've had your account for more than three working days and Copilot still can't find emails, reply to this ticket so we can investigate.

In most cases this resolves itself within a day or two — hang tight!

---

## Ticket 3 — Partner

**Subject: Re: Copilot showed me a file I wasn't expecting to see**

Hi,

Thank you for flagging this — it's really helpful that you reported it.

Copilot only ever shows you content you already have permission to access in Microsoft 365. It doesn't create new access or bypass any security controls. What this means in your case is that your account already had read access to that folder — most likely through a broader group membership (for example, a firm-wide "Legal team" site) that you may not have been aware of.

**This is not a Copilot fault, but it is worth reviewing the access controls.**

**What to do next:**

1. No immediate action is needed on your part — you haven't done anything wrong.
2. We will review the permissions on that matter's folder to understand why your account has access to it.
3. If the access is not appropriate, your SharePoint administrator will tighten the permissions so only assigned team members can see those files in future.
4. We'll update you once the permissions review is complete.

Thank you again for raising this — it helps us keep our data access controls accurate.

---

## Ticket 4 — Legal Ops Manager (and Legal Team)

**Subject: Copilot access outage — Legal team update**

Hi all,

We're aware that Copilot stopped working for everyone on the Legal team this morning and we're treating this as a priority.

The most likely cause is a change to your team's licence assignment or group membership — something that would affect everyone at the same time. This is an administrative issue, not a problem with Copilot itself.

**What is happening right now:**

- Our IT team is reviewing the Microsoft 365 licence assignments and the audit log to identify exactly what changed and when.
- We aim to restore access for the whole team as quickly as possible.

**What you can do in the meantime:**

1. Continue with your work as normal — all your files and emails are unaffected, only Copilot is unavailable.
2. If you have an urgent task that relied on Copilot, please let your manager know so it can be prioritised once access is restored.
3. There is no need for individuals to log separate tickets — this is being handled centrally.

We will send a further update as soon as access has been restored. We apologise for the disruption.

---

## Ticket 5 — Contract Specialist

**Subject: Re: Copilot giving generic answers about contract templates**

Hi,

Thanks for reporting this. When Copilot gives vague, general answers instead of referencing specific documents, it usually means it isn't able to read the actual files — even if you can open them yourself.

There are a few common reasons for this:

- A **sensitivity label** on the templates (e.g. Highly Confidential) may be preventing Copilot from reading the full content.
- A **permissions setting** on the library may be restricting Copilot's access behind the scenes.
- The files may not yet be fully **indexed** if the library was recently moved or updated.

**What to try now:**

1. In your next Copilot prompt, add: *"Please tell me which documents you used to answer this."* If Copilot can't name any specific files, it confirms it isn't reaching the templates.
2. Open one of the contract templates directly in your browser and check the top banner — if it shows a sensitivity label such as "Highly Confidential", that is likely the cause.
3. Reply to this ticket with what you find and we'll take it from there.

**If the steps above don't help:**

- We will check the library permissions and sensitivity label settings on your behalf and make any adjustments needed.

We'll aim to have this resolved or escalated within one working day of hearing back from you.

---
