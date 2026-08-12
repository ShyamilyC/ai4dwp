# Microsoft 365 Copilot Readiness Checklist - Finance (200 Users)

Date: 2026-08-12  
Department: Finance (~200 users)  
Business context: Financial services; high-sensitivity data (payroll, board packs, M&A, client financial data)  
Current state: M365 E5 licensed; Copilot add-on not assigned; SharePoint permissions inherited from 2019 migration and not audited

## How To Use This Checklist
- Tick each item only when evidence is captured.
- Do not assign Copilot licenses to end users until all Section 1 gate items are complete.
- Record owner, date completed, and evidence link for every check.

## Priority Order
1. Permissions and oversharing remediation (highest priority, mandatory gate)
2. Identity and MFA readiness
3. Sensitivity labelling and protection controls
4. Licensing and app/client readiness
5. End-user communications and enablement

---

## 1) Permissions And Oversharing Remediation (Highest Priority - Go/No-Go Gate)

### 1.1 Governance and scope
- [ ] Confirm executive risk owner (Finance Director or equivalent) for Copilot data exposure risk.
- [ ] Define in-scope repositories: all Finance SharePoint sites, Teams-connected sites, and OneDrive accounts for ~200 users.
- [ ] Freeze ad hoc broad sharing in Finance repositories during audit/remediation window (except approved business exceptions).

### 1.2 Baseline discovery (current exposure)
- [ ] Inventory SharePoint sites and document libraries used by Finance.
- [ ] Export current permissions for each site/library/folder (owners, members, visitors, unique permissions).
- [ ] Identify inherited permissions from 2019 migration and map where inheritance is broken.
- [ ] Find broad access groups and links:
- [ ] `Everyone`
- [ ] `Everyone except external users`
- [ ] `All Company`
- [ ] Large security groups not aligned to least privilege
- [ ] Anonymous or "anyone" links still active
- [ ] Identify externally shared files/folders and guest access in Finance workspaces.
- [ ] Produce an oversharing heatmap: repositories containing payroll, board, M&A, and client financial data with non-need-to-know access.

### 1.3 Remediation actions (must complete before broad Copilot rollout)
- [ ] Remove or replace broad groups with role-based least-privilege groups.
- [ ] Disable/limit anonymous sharing links for Finance sites.
- [ ] Remove stale guest access and unused direct permissions.
- [ ] Reapply inheritance where appropriate and reduce one-off unique permissions.
- [ ] Restrict high-sensitivity libraries to approved Finance sub-groups only.
- [ ] Validate board/M&A/payroll repositories are access-limited to explicitly approved users/groups.
- [ ] Implement approval workflow for future permission changes on sensitive Finance sites.

### 1.4 Verification and sign-off (hard gate)
- [ ] Re-scan permissions after remediation and confirm no unresolved critical oversharing findings.
- [ ] Run user-based spot checks:
- [ ] Standard Finance user account cannot access restricted payroll/M&A/board content.
- [ ] Privileged Finance user can access required content only.
- [ ] Document all exceptions with risk acceptance and target fix date.
- [ ] Security + Finance + M365 platform owner formally sign off Go/No-Go for Copilot license assignment.

**Gate rule:** If any critical oversharing finding remains open, stop rollout.

---

## 2) Identity And MFA Readiness
- [ ] Confirm all ~200 Finance users are cloud identities in good standing (enabled, not stale, correct department assignment).
- [ ] Confirm MFA is enforced for all Finance users, including break-glass exception review.
- [ ] Verify Conditional Access policies for Finance cover:
- [ ] MFA requirement
- [ ] Device compliance or trusted location controls
- [ ] Legacy authentication blocked
- [ ] Validate sign-in risk and impossible travel alerts are monitored and routed.
- [ ] Confirm privileged role assignments are minimized and protected with stronger controls (for example, phishing-resistant MFA where available).

---

## 3) Sensitivity Labelling And Protection
- [ ] Define or validate sensitivity labels for Finance data classes:
- [ ] Public/Internal
- [ ] Confidential Finance
- [ ] Highly Confidential (Payroll / Board / M&A / Client Financial)
- [ ] Ensure labels apply to SharePoint sites, M365 groups, documents, and emails as needed.
- [ ] Configure label policies so high-sensitivity labels enforce encryption/access restrictions where required.
- [ ] Validate default labelling for key Finance document libraries and templates.
- [ ] Verify DLP policies align to labeled content and block unsafe sharing patterns.
- [ ] Run sample tests to confirm labeled content behaves as expected in collaboration and search scenarios.

---

## 4) Licensing And Microsoft 365 Apps Readiness

### 4.1 Licensing prerequisites
- [ ] Confirm tenant is eligible for Microsoft 365 Copilot service plans.
- [ ] Confirm target users have base license prerequisites (M365 E5 already present).
- [ ] Procure/assign Copilot add-on licenses for pilot cohort first, then phased rollout to all Finance users.
- [ ] Define license assignment approach (group-based licensing recommended).
- [ ] Validate no conflicting disabled service plans for assigned users.

### 4.2 Microsoft 365 Apps client requirements
- [ ] Verify users are on supported Microsoft 365 Apps for enterprise builds/channels for Copilot features.
- [ ] Confirm update channel strategy is defined (for example Current Channel for fastest feature availability).
- [ ] Validate Office desktop apps are signed in with Entra ID work account.
- [ ] Confirm web access readiness for Word, Excel, PowerPoint, Outlook, and Teams.
- [ ] Confirm OneDrive sync client is healthy and current across Finance endpoints.

---

## 5) End-User Communications And Enablement
- [ ] Prepare Finance-specific announcement covering:
- [ ] What Copilot can/cannot access (based on existing permissions)
- [ ] Data handling expectations for payroll, board, M&A, and client data
- [ ] Where to report suspected incorrect access or output
- [ ] Deliver short mandatory training before enablement:
- [ ] Prompting basics for Finance workflows
- [ ] Responsible use and verification of outputs
- [ ] Sensitive data handling and sharing do/don't rules
- [ ] Publish quick-reference guide and support path (IT + Security contact route).
- [ ] Run pilot with selected Finance users, gather issues, then adjust controls before full rollout.

---

## Recommended Rollout Sequence
- [ ] Phase 0: Complete Section 1 and obtain Go/No-Go sign-off.
- [ ] Phase 1: Pilot (15-25 Finance users) with monitored usage and weekly risk review.
- [ ] Phase 2: Expand to remaining Finance users in waves after pilot success criteria are met.

## Evidence Tracker (fill in)
| Checklist Item | Owner | Date Completed | Evidence Link | Status |
|---|---|---|---|---|
| Permissions baseline complete |  |  |  | Not Started |
| Oversharing remediation complete |  |  |  | Not Started |
| Security sign-off complete |  |  |  | Not Started |
| Identity/MFA checks complete |  |  |  | Not Started |
| Sensitivity labels validated |  |  |  | Not Started |
| Pilot licenses assigned |  |  |  | Not Started |
| End-user training complete |  |  |  | Not Started |

## Completion Criteria
- [ ] All Section 1 gate items completed and signed off.
- [ ] No unresolved critical oversharing findings.
- [ ] Pilot outcomes acceptable and documented.
- [ ] Approval recorded for full Finance rollout.
