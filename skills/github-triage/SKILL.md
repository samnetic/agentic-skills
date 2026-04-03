---
name: github-triage
description: >-
  Label-based state machine for systematic GitHub issue triage. Classifies
  issues by type and severity, attempts reproduction for bugs, routes to
  AFK-ready or HITL queues, and maintains triage state via standardized
  labels. Use when processing new issues, triaging backlogs, or setting up
  issue workflows. Triggers: triage issues, triage this issue, process
  backlog, classify issues, issue triage, review new issues, bug triage.
license: MIT
metadata:
  author: samnetic
  version: "1.0"
---

# GitHub Triage Skill

Process every issue through the same state machine. Classification first, severity second, investigation third, routing last. No issue leaves triage without a label set and a comment.

---

## Core Principles

| Principle | Meaning |
|---|---|
| **Oldest first** | Process the backlog in FIFO order to prevent issue rot |
| **Classify before you judge** | Determine type (bug/enhancement/question) before assessing severity |
| **Reproduce before you route** | Bug reports need reproduction attempts before assignment |
| **Labels are state** | The label set on an issue IS its triage state -- keep it consistent |
| **One pass, full context** | Read the entire issue, related issues, and recent activity before acting |
| **Comment what you did** | Every triage action gets a structured comment explaining the decision |

---

## Workflow: Every Triage Session

```
1. OVERVIEW      -> Query issues grouped by state, oldest-first
2. CLASSIFY      -> Assign type label (bug / enhancement / improvement / question / docs)
3. ASSESS        -> Determine severity using the severity matrix
4. INVESTIGATE   -> Bugs: reproduce + root cause area; Features: scope estimate
5. ROUTE         -> Apply final labels, add triage comment, link related issues
```

**Never skip step 1.** Start every session with a full picture of the backlog.

---

### Step 1: Overview

Query issues in this priority order:

| Group | Query | Why first |
|---|---|---|
| Unlabeled | `is:issue is:open no:label sort:created-asc` | Unknown state -- highest triage urgency |
| Needs-triage | `is:issue is:open label:needs-triage sort:created-asc` | Entered pipeline but not yet processed |
| Needs-info with activity | `is:issue is:open label:needs-info sort:updated-desc` | Author may have replied -- check for unblock |
| Stale needs-info | `is:issue is:open label:needs-info sort:updated-asc` | Candidates for closing if no response >30 days |

Report a summary before proceeding:

```markdown
## Triage Overview
- **Unlabeled**: N issues (oldest: #XXX, DD days ago)
- **Needs-triage**: N issues
- **Needs-info with recent activity**: N issues
- **Stale needs-info (>30d)**: N issues
- **Total to process**: N
```

---

### Step 2: Classify

Assign exactly one type label per issue:

| Type Label | Criteria |
|---|---|
| `type: bug` | Something that worked before is now broken, or behavior contradicts docs |
| `type: enhancement` | New capability that does not exist today |
| `type: improvement` | Better behavior for an existing capability |
| `type: question` | User needs help, not reporting a defect or requesting a feature |
| `type: docs` | Documentation is missing, incorrect, or unclear |

**Classification rules:**
- If unclear between bug and enhancement, ask: "Did this ever work?" Yes = bug, No = enhancement
- If the issue contains both a bug report and a feature request, split into two issues
- If the issue is a duplicate, label `duplicate`, link the original, and close

---

### Step 3: Assess Severity

Use the severity matrix to determine impact and urgency:

| Severity | Criteria | Response target |
|---|---|---|
| `severity: critical` | Data loss, security vulnerability, or complete service outage | Same day |
| `severity: high` | Major feature broken with no workaround | 2 business days |
| `severity: medium` | Feature broken but workaround exists, or significant UX degradation | 1 week |
| `severity: low` | Cosmetic issue, minor inconvenience, or edge case | Best effort |

> Full decision tree with edge cases: see `references/severity-matrix.md`

**Priority modifiers** (upgrade severity by one level if any apply):
- Affects >10% of users (based on issue reactions or reports)
- Regression from a recent release
- Blocks a downstream dependency or integration

---

### Step 4: Investigate

**For bugs (`type: bug`):**

1. Attempt reproduction using the steps provided
2. If steps are missing or unclear, label `needs-info` and comment asking for reproduction steps
3. If reproducible, identify the root cause area (component, module, or file)
4. If not reproducible, note environment differences and ask for more detail

**For enhancements / improvements:**

1. Estimate scope: small (< 1 day), medium (1-3 days), large (> 3 days)
2. Check for existing issues or PRs that overlap
3. Identify which component or area of the codebase is affected

**For questions:**

1. If answerable from docs, answer and label `resolved`
2. If docs are missing, convert to `type: docs` issue
3. If it reveals a real bug, reclassify to `type: bug`

---

### Step 5: Route

Apply the final label set and add a triage comment:

| Destination | Labels | When |
|---|---|---|
| **AFK queue** | `ready-for-agent` | Clear reproduction, known root cause area, tests exist |
| **HITL queue** | `ready-for-human` | Ambiguous scope, architectural decision needed, or security-sensitive |
| **Waiting on author** | `needs-info` | Missing reproduction steps, environment details, or expected behavior |
| **Won't fix** | `wontfix` | Out of scope, by design, or cost/benefit does not justify |

> Full state machine with transitions: see `references/triage-state-machine.md`

Add a structured triage comment to every processed issue:

> Comment template: see `references/triage-comment-template.md`

Link related issues using GitHub's cross-reference syntax (`Relates to #123`, `Duplicate of #456`).

---

## Label State Machine

```
unlabeled ─────> needs-triage ─────> needs-info ─────> ready-for-agent (AFK)
                      │                   │                    │
                      │                   │              ready-for-human (HITL)
                      │                   │                    │
                      │                   └──────────────> wontfix
                      │                                        │
                      └────────────────────────────────────> closed
```

**Transitions are one-way except:** `needs-info` can return to `needs-triage` when the author provides requested information.

---

## Anti-Patterns

| Anti-Pattern | Why It Fails | Fix |
|---|---|---|
| Triaging newest issues first | Oldest issues rot and accumulate | Always process oldest-first (FIFO) |
| Skipping severity assessment | Everything becomes "medium" by default | Use the severity matrix for every issue |
| Routing bugs without reproduction | Agent or developer wastes time on unclear reports | Reproduce or request info before routing |
| Using labels inconsistently | State machine breaks, queries return wrong results | Use only labels from the defined set |
| Closing without comment | Author gets no feedback, may reopen or create duplicate | Always leave a triage comment |
| Bulk-labeling without reading | Misclassification causes wrong routing | Read every issue fully before labeling |

---

## Progressive Disclosure Map

| Topic | Reference | When to read |
|---|---|---|
| Label definitions, colors, state transitions, and valid transition rules | `references/triage-state-machine.md` | When setting up labels for the first time or debugging state inconsistencies |
| Severity and priority decision tree with edge cases and modifier rules | `references/severity-matrix.md` | When severity is ambiguous or you need to justify a severity upgrade |
| Standardized comment format for triage findings with fill-in template | `references/triage-comment-template.md` | When writing triage comments to ensure consistent formatting |

---

## Checklist: After Every Triage Session

- [ ] All unlabeled issues now have at least a type label
- [ ] Every processed issue has a severity label (bugs and enhancements)
- [ ] Bugs routed to `ready-for-agent` have confirmed reproduction
- [ ] Every processed issue has a triage comment
- [ ] Related issues are cross-linked
- [ ] Stale `needs-info` issues (>30 days) reviewed for closure
- [ ] Triage overview summary posted (before/after counts)
- [ ] No issue left in `needs-triage` without action
