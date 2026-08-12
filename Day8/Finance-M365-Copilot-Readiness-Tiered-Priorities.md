# Finance M365 Copilot Readiness - Tiered Priorities

Date: 2026-08-12  
Scope: Finance department (~200 users), financial services, high-sensitivity data  
Related checklist: [Finance-M365-Copilot-Readiness-Checklist.md](Finance-M365-Copilot-Readiness-Checklist.md)

## Tier 1: MUST Complete Before Rollout (Blocking)

These items are mandatory Go/No-Go controls. If any are incomplete, do not assign Copilot licenses broadly.

### A) Permissions and oversharing audit and remediation (full Section 1)
- [ ] Complete permission inventory across all Finance SharePoint/Teams sites and OneDrives.
- [ ] Identify and remove broad access (`Everyone`, `Everyone except external users`, legacy large groups, anonymous links).
- [ ] Remediate inherited/broken permissions from 2019 migration.
- [ ] Restrict payroll, board, M&A, and client financial repositories to approved least-privilege groups.
- [ ] Re-test effective access with user spot checks and close critical findings.
- [ ] Obtain formal Security + Finance + Platform sign-off.

### B) Identity and MFA baseline enforcement
- [ ] Confirm all in-scope users are valid identities in good standing.
- [ ] Enforce MFA for all Finance users.
- [ ] Confirm Conditional Access baseline (legacy auth blocked; core sign-in protections enabled).

### C) Minimum sensitivity protection for highest-risk data classes
- [ ] Ensure high-sensitivity labels/policies exist and are active for Payroll, Board, M&A, Client Financial data.
- [ ] Confirm at least baseline DLP/label protections are in place for these data classes before enablement.

### D) Copilot license gating and controlled assignment
- [ ] Confirm prerequisite base licensing (M365 E5) is valid.
- [ ] Assign Copilot add-on only after A-C are complete, starting with pilot cohort.

---

## Tier 2: SHOULD Complete Before Rollout (High Risk If Skipped)

These should be completed before full rollout; skipping them materially increases operational and compliance risk.

### A) Broader label and DLP tuning beyond minimum baseline
- [ ] Validate full label taxonomy across documents, email, sites/groups.
- [ ] Tune DLP rules to reduce false positives/negatives in Finance workflows.

### B) Microsoft 365 Apps client/channel consistency checks
- [ ] Verify Office app builds/channels are consistent and supported.
- [ ] Confirm users are signed in correctly and OneDrive sync health is stable.

### C) End-user comms and mandatory short training package ready
- [ ] Pre-rollout communication drafted and approved.
- [ ] Quick training on responsible prompting, output verification, and sensitive-data handling prepared.

### D) Exception and access governance process
- [ ] Document exception workflow for urgent access requests.
- [ ] Define recurring permission recertification cadence.

---

## Tier 3: CAN Complete During/After Rollout (Lower Risk)

These are important, but can be phased while rollout proceeds in controlled waves.

### A) Expanded enablement and optimization
- [ ] Deeper role-based prompt libraries for Finance sub-functions.
- [ ] Advanced scenario workshops (FP&A, controllership, treasury, procurement).

### B) Post-pilot and post-rollout optimization
- [ ] Refine helpdesk scripts and KBs from pilot incidents.
- [ ] Improve adoption metrics dashboards and usage coaching.

### C) Continuous improvement controls
- [ ] Add richer quality checks for Copilot outputs in specific Finance processes.
- [ ] Iterate communication content from user feedback.

---

## Why Permissions/Oversharing Is MUST (Finance-Specific Justification)

Licensing assignment and client version checks are technically easier and faster, but they do not reduce data exposure risk by themselves. In this Finance context, permissions hygiene is the true risk control, for these reasons:

1. Copilot respects existing permissions, including bad ones.
If users can already access overshared content, Copilot can help them discover and summarize it faster. Existing over-permissioning becomes amplified access, not reduced risk.

2. Finance data in scope is highly sensitive and high-impact.
Payroll, board packs, M&A materials, and client financial data can trigger regulatory, contractual, and reputational impact if exposed internally to unauthorized users, even without external breach.

3. Legacy migration permissions are a known unresolved risk.
The 2019 migration inheritance model was never fully audited. This creates a documented uncertainty area where hidden broad access can exist in nested folders, libraries, and stale groups.

4. Fast enablement without access cleanup creates silent failure modes.
Rollout may appear successful technically (licenses assigned, apps updated) while still violating least privilege. These failures are harder to detect after broad activation and can spread quickly.

5. Regulatory and audit defensibility requires evidence.
For financial services, you need demonstrable pre-rollout control effectiveness: permission inventory, remediation evidence, test results, and sign-off. Licensing proof alone is insufficient for control assurance.

6. Sequencing matters: access control before feature enablement.
The lowest-risk order is: fix effective access first, then enable Copilot. Reversing this order increases immediate blast radius from day one.

In short: licensing/client readiness proves technical capability; permissions/oversharing readiness proves safe operability. For Finance, safe operability is the blocking criterion.

---

## Practical Go/No-Go Rule
- [ ] Go only when all Tier 1 items are complete and evidenced.
- [ ] If any critical oversharing finding remains open, rollout remains blocked.
- [ ] Proceed in phased waves (pilot first), not all 200 users at once.
