# Stage Transitions Reference

Artifact formats, validation rules, and failure recovery for handoffs between pipeline stages.

---

## Artifact Metadata Header

Every artifact produced by a pipeline stage MUST include a YAML metadata header:

```yaml
---
pipeline-id: {feature-slug}-{YYYYMMDD}
pipeline-stage: {stage name}
stage-number: {1-8}
input-from: {previous stage name, or "user" for Stage 1}
output-to: {next stage name}
created: {YYYY-MM-DD}
status: complete | in-progress | blocked
blocked-by: {description of blocker, only if status is blocked}
---
```

Example:

```yaml
---
pipeline-id: user-notifications-20260403
pipeline-stage: specification
stage-number: 3
input-from: discovery
output-to: planning
created: 2026-04-03
status: complete
---
```

---

## Transition: IDEATION to DISCOVERY

### Required Fields in Stress Test Report

| Field | Required | Description |
|---|---|---|
| Problem statement | Yes | One-paragraph bounded problem description |
| Assumptions list | Yes | Each assumption with confidence rating (LOW/MEDIUM/HIGH) |
| Risks identified | Yes | Key risks surfaced during stress testing |
| User decision on LOW assumptions | Conditional | Required if any assumption rated LOW |
| Recommendation | Yes | Proceed, pivot, or abandon |

### Validation Checklist

- [ ] Stress Test Report file exists
- [ ] Problem statement is present and non-empty
- [ ] At least one assumption listed
- [ ] No LOW-confidence assumptions without user decision
- [ ] Recommendation is "proceed"

### On Validation Failure

| Missing | Action |
|---|---|
| No Stress Test Report | Re-run `grill-session` on the idea |
| LOW assumptions without decision | Surface to user, ask for explicit accept/pivot/abandon |
| Recommendation is "abandon" | Stop pipeline, inform user |
| Recommendation is "pivot" | Re-run ideation with pivoted framing |

---

## Transition: DISCOVERY to SPECIFICATION

### Required Fields in Discovery Notes

| Field | Required | Description |
|---|---|---|
| User personas | Yes | At least one persona with goals and pain points |
| Functional requirements | Yes | Enumerated list (IDs not yet required) |
| Non-functional requirements | Yes | Performance, security, scalability targets |
| Scope boundaries | Yes | Explicit in-scope and out-of-scope lists |
| Open questions | Conditional | Must be empty or all deferred with rationale |

### Validation Checklist

- [ ] At least one user persona defined
- [ ] Functional requirements list is non-empty
- [ ] Non-functional requirements list is non-empty
- [ ] Scope in/out boundaries defined
- [ ] No unresolved open questions (all resolved or deferred with rationale)

### On Validation Failure

| Missing | Action |
|---|---|
| No personas | Re-run `prd-writer` Phase 1 (problem discovery interview) |
| No functional requirements | Re-run `prd-writer` Phase 2 (requirements gathering) |
| Unresolved open questions | Surface questions to user before proceeding |
| Scope not defined | Ask user to confirm in/out boundaries |

---

## Transition: SPECIFICATION to PLANNING

### Required Fields in Plan-Ready PRD

| Field | Required | Description |
|---|---|---|
| YAML metadata header | Yes | With pipeline-id and status |
| FR IDs | Yes | Every functional requirement has FR-001, FR-002, etc. |
| Acceptance criteria | Yes | Every FR has Given/When/Then or equivalent |
| Dependencies | Yes | FR-to-FR dependency mapping |
| AFK/HITL hints | Yes | Each FR annotated with `afk` or `hitl` |
| NFR targets | Yes | Measurable targets (e.g., "p95 < 200ms") |

### Validation Checklist

- [ ] PRD has YAML metadata header with pipeline-id
- [ ] Every FR has a unique ID matching pattern `FR-\d{3}`
- [ ] Every FR has acceptance criteria
- [ ] Dependency map present (even if empty for independent FRs)
- [ ] AFK/HITL annotation present on every FR
- [ ] NFRs have numeric or measurable targets

### On Validation Failure

| Missing | Action |
|---|---|
| No FR IDs | Re-run `prd-writer` Phase 5 (PRD synthesis) to assign IDs |
| Missing acceptance criteria | Re-run `prd-writer` Phase 4 (module design) for the affected FRs |
| No AFK/HITL hints | Classify each FR: default to `afk` unless it touches security, payments, or PII |
| NFRs without targets | Ask user for measurable targets or apply sensible defaults |

---

## Transition: PLANNING to ISSUES

### Required Fields in Implementation Plan

| Field | Required | Description |
|---|---|---|
| Vertical slices | Yes | Each slice delivers user-visible value |
| Phase sequence | Yes | Ordered phases with dependency graph |
| Complexity estimates | Yes | S/M/L per slice |
| AFK/HITL classification | Yes | Per slice |
| Dependency graph | Yes | Which slices block which |

### Validation Checklist

- [ ] At least one vertical slice defined
- [ ] Phases sequenced (Phase 1, Phase 2, etc.)
- [ ] Every slice has complexity estimate (S/M/L)
- [ ] Every slice has AFK/HITL classification
- [ ] Dependency graph has no circular dependencies
- [ ] Phase 1 slices have no unresolved external dependencies

### On Validation Failure

| Missing | Action |
|---|---|
| No vertical slices | Re-run `prd-to-plan` — plan may have used horizontal slicing |
| Circular dependencies | Re-run `prd-to-plan` with explicit instruction to break cycles |
| Missing complexity | Apply defaults: single-file changes = S, multi-file = M, new subsystem = L |
| Missing AFK/HITL | Inherit from PRD FR annotations |

---

## Transition: ISSUES to IMPLEMENTATION

### Required Fields on GitHub Issues

| Field | Required | Description |
|---|---|---|
| Title | Yes | Descriptive, references plan slice |
| Body | Yes | Acceptance criteria, implementation hints |
| Label: agent | Yes | `agent:afk` or `agent:hitl` |
| Label: status | Yes | `status:ready` or `status:blocked` |
| Dependencies | Yes | Linked blocking/blocked issues |

### Validation Checklist

- [ ] Issues exist for every slice in the plan
- [ ] Every issue has `agent:afk` or `agent:hitl` label
- [ ] Every issue has `status:ready` or `status:blocked` label
- [ ] `status:ready` issues have no unresolved blocking dependencies
- [ ] Issue bodies contain acceptance criteria

### On Validation Failure

| Missing | Action |
|---|---|
| Missing issues | Re-run `plan-to-issues` for the missing slices |
| No labels | Apply labels manually: default `agent:afk` + `status:ready` for independent slices |
| `status:ready` with unresolved blockers | Change to `status:blocked` and link the blocking issue |

---

## Transition: IMPLEMENTATION to REVIEW

### Required Fields on Pull Requests

| Field | Required | Description |
|---|---|---|
| Linked issue | Yes | PR references the GitHub issue it implements |
| Passing CI | Yes | All checks green |
| Tests | Yes | Test files present, written before implementation (TDD) |
| No merge conflicts | Yes | Branch is up to date |

### Validation Checklist

- [ ] Every issue has a linked PR
- [ ] Every PR has passing CI
- [ ] Every PR includes test files
- [ ] No unresolved merge conflicts
- [ ] PR description summarizes changes and links to issue

### On Validation Failure

| Missing | Action |
|---|---|
| Issue without PR | Flag as incomplete — re-enter Stage 6 for that issue |
| Failing CI | Fix failures before proceeding to review |
| No tests | Reject PR — re-enter Stage 6 with explicit TDD instruction |
| Merge conflicts | Rebase PR branch onto main |

---

## Transition: REVIEW to SHIP

### Required Fields on Approved PRs

| Field | Required | Description |
|---|---|---|
| Approval | Yes | PR approved (auto or human) |
| Review feedback resolved | Yes | All comments addressed |
| Security scan | Yes | No critical/high findings |
| HITL sign-off | Conditional | Required for security/payment/PII PRs |

### Validation Checklist

- [ ] Every PR approved
- [ ] All review comments resolved
- [ ] Security scan shows no critical or high findings
- [ ] HITL PRs have explicit human approval
- [ ] Merge order determined from dependency graph

### On Validation Failure

| Missing | Action |
|---|---|
| PR not approved | Complete review cycle |
| Unresolved comments | Address feedback, request re-review |
| Security findings | Fix findings, re-run security scan |
| HITL without human approval | Escalate to user — do not auto-merge |
