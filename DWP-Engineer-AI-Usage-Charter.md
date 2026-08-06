# Personal AI Usage Charter — DWP Desktop/Endpoint Engineer
**Version:** 1.0 | **Date:** 2026-08-03 | **Owner:** [Your Name]

---

## 1. Appropriate Uses of Public AI Assistants

I may use public LLMs (e.g. GitHub Copilot, ChatGPT, Copilot in Windows) for the following, provided no restricted data is included in the prompt:

| Task | Examples |
|---|---|
| Script drafting | PowerShell for disk clean-up, registry queries, log parsing |
| Config file syntax | Group Policy ADMX templates, SCCM/Intune JSON payloads (sanitised) |
| Generic troubleshooting | "Why does WinRM fail with error 5?" using error codes only |
| Documentation drafting | Runbooks, SOPs, change record descriptions — no live system details |
| Learning & research | Explaining CVEs, Windows internals, patching concepts |
| Code review support | Reviewing scripts I have written for logic errors or security issues |
| Test data generation | Dummy hostnames, synthetic log lines, placeholder values |

---

## 2. Tasks I Will NOT Use Public AI Assistants For

| Category | Why Off-limits |
|---|---|
| Prompts containing real usernames, NI numbers, claim IDs, case references | PII leaves DWP control; no consent from data subjects |
| Prompts containing real hostnames, IP ranges, domain names, or asset tags | Operational topology is sensitive; aids threat actors |
| Passwords, API keys, certificates, or PAT tokens in any prompt | Credentials must never leave the trust boundary |
| DWP network architecture, firewall rules, or security controls | Classified or OFFICIAL-SENSITIVE; not for public platforms |
| Active incident details (ticket numbers, affected services, user counts) | Operational data; could constitute a data breach |
| GDPR-regulated or benefit-payment transaction data | Legal obligation; no legitimate basis for processing outside DWP systems |
| Third-party contract or procurement details | Commercial sensitivity |

If a task requires any of the above, I use internal tools (M365 Copilot where licensed and approved, internal KB, colleagues) only.

---

## 3. Data-Handling Rule — End-User PII and Credentials

> **Before I type any prompt into a public AI tool, I apply the RED-AMBER-GREEN test:**

- **RED — Never enter:** Real names, NI numbers, dates of birth, addresses, claim IDs, phone numbers, email addresses of claimants or staff, passwords, tokens, certificates, MFA seeds.
- **AMBER — Sanitise first:** Error messages → strip usernames and machine names. Config snippets → replace real values with `<PLACEHOLDER>`. Log lines → anonymise before pasting.
- **GREEN — Safe as-is:** Generic error codes, publicly documented registry paths, vendor KB article numbers, fictitious/synthetic examples I have created myself.

**Credentials rule (absolute):** I will never paste, attach, or describe a real credential — partial or complete — in any public AI prompt, chat window, or shared document. If I need help with an authentication issue I describe the *flow* and *error code* only.

---

## 4. Personal 'Generate Then Verify' Rule — Scripts and System Changes

Public AI output is a **first draft, not a finished artefact.** I apply the following gates before any AI-assisted script or change reaches a managed endpoint:

1. **Read every line.** I do not run a script I cannot explain. If a line is unclear, I ask the AI to explain it, then verify the explanation against official documentation (Microsoft Learn, vendor docs).

2. **Static analysis.** Run PowerShell scripts through `PSScriptAnalyzer` or equivalent before execution. Check for unsafe cmdlets (`Invoke-Expression`, `iex`, unvalidated `$env:` inputs).

3. **Test in isolation first.** Execute on a personal test VM or sandbox endpoint, never directly on a managed production machine or shared infrastructure.

4. **Diff against known-good.** For config changes, compare the AI-suggested version against the current baseline using a diff tool before applying.

5. **Log and attribute.** Add a comment header to any AI-assisted script: `# AI-assisted draft — reviewed and verified by [Name] on [Date]`. Retain the original prompt and AI response in the associated change ticket.

6. **Peer review for high-impact changes.** Any script that modifies the registry, manages user accounts, alters firewall rules, or affects more than one device must be reviewed by a second engineer before deployment.

---

*This charter supplements, and does not replace, DWP's official Acceptable Use Policy, the Civil Service Code, and any applicable OFFICIAL-SENSITIVE handling instructions. Review this charter whenever DWP AI guidance is updated.*
