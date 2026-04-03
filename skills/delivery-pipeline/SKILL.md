---
name: delivery-pipeline
description: >-
  Master orchestrator for end-to-end feature delivery — routes work through
  ideation, discovery, specification, planning, issues, implementation, review,
  and ship stages. Detects entry point, validates handoffs, tracks progress,
  and maximizes parallel agent execution. Use when building a feature from
  scratch or resuming pipeline work. Triggers: build this feature end to end,
  full delivery pipeline, start the pipeline, ship this feature, from idea to
  production, end to end, lfg, let's build this.
license: MIT
metadata:
  author: samnetic
  version: "1.0"
---

# Delivery Pipeline

Route features through every stage from idea to production — zero domain logic, pure orchestration.

---

## Core Principles

| Principle | Meaning |
|---|---|
| **Router not doer** | This skill invokes other skills at each stage — it never writes code, creates specs, or makes design decisions itself |
| **Detect entry point** | Accept work at ANY pipeline stage (raw idea, existing PRD, existing plan, existing issues) and route to the right starting stage |
| **Artifact-driven handoffs** | Each stage produces a structured artifact with YAML metadata that the next stage consumes |
| **Maximize parallelism** | Identify independent slices/issues and spawn parallel agents whenever possible |
| **AFK by default** | Assume autonomous execution unless the stage or issue is classified as HITL |
| **Progress tracking** | Maintain a pipeline status file so work can be resumed across sessions |
| **Fail fast on gaps** | If a stage's input artifact is missing required fields, stop and surface the gap — don't proceed with incomplete data |

---

## Workflow

```
1. IDEATION ─→ 2. DISCOVERY ─→ 3. SPECIFICATION ─→ 4. PLANNING
                                                        │
   8. SHIP ←── 7. REVIEW ←── 6. IMPLEMENTATION ←── 5. ISSUES
```

| Stage | Purpose | Skills |
|---|---|---|
| 1. Ideation | Stress-test the idea | `grill-session`, `council` |
| 2. Discovery | Gather requirements through structured interview | `prd-writer` (Phases 1-3) |
| 3. Specification | Produce Plan-Ready PRD | `prd-writer` (Phases 4-5), `spec-orchestrator` |
| 4. Planning | Decompose into vertical-slice implementation plan | `prd-to-plan` |
| 5. Issues | Create dependency-ordered GitHub issues | `plan-to-issues` |
| 6. Implementation | Execute issues with TDD | `qa-testing`, domain skills |
| 7. Review | Code review and QA | `code-review`, `security-analysis`, `simplify` |
| 8. Ship | Deploy and verify | `devops-cicd`, `git-workflows` |

---

## Progressive Disclosure Map

| Reference | Path | When to read |
|---|---|---|
| Pipeline stages | references/pipeline-stages.md | At start: to understand entry/exit criteria for every stage |
| Stage transitions | references/stage-transitions.md | Between stages: to validate handoff artifacts |
| AFK orchestration | references/afk-orchestration.md | Stages 5-6: when spawning parallel agents |
| Progress tracking | references/progress-tracking-template.md | Any time: to update or resume pipeline state |

---

## Trigger Conditions

| Strength | Triggers |
|---|---|
| **Mandatory** | "full delivery pipeline", "start the pipeline", "end to end" |
| **Strong** | "build this feature", "ship this feature", "from idea to production", "lfg", "let's build this" |
| **Do NOT trigger** | Individual stage work (PRD creation, plan creation, issue creation) — those skills trigger directly |

---

## Execution Protocol

### Entry Point Detection

Before anything else, detect what the user already has:

```
What does the user have?
├─ Just an idea or problem statement → Start at IDEATION
├─ A PRD or spec document → Start at PLANNING
├─ An implementation plan → Start at ISSUES
├─ GitHub issues already created → Start at IMPLEMENTATION
├─ Code in PR → Start at REVIEW
└─ Nothing specific, just "build X" → Start at IDEATION
```

Scan for existing artifacts:
1. Check `docs/pipeline/*/status.md` for an in-progress pipeline
2. Check `docs/prd-*.md` or `docs/specs/` for existing PRDs
3. Check `plans/` for existing implementation plans
4. Check GitHub issues for linked feature work

If an in-progress pipeline is found, jump to **Resumption Protocol** below.

---

### Stage 1: IDEATION

- **Skills:** `grill-session` (mandatory), `council` (if high-stakes decision)
- **Input:** raw idea or problem statement
- **Process:** run grill-session to stress-test assumptions, identify risks, and validate the problem is worth solving
- **Exit criteria:** Stress Test Report with all assumptions rated medium or high confidence
- **If any assumption rated LOW:** surface to user, get decision before proceeding
- **Output artifact:** validated idea + stress test report

```
IDEATION complete when:
├─ Stress Test Report exists
├─ All assumptions ≥ medium confidence (or user accepted LOW risks)
└─ Problem statement is crisp and bounded
```

---

### Stage 2: DISCOVERY

- **Skills:** `prd-writer` (Phases 1-3)
- **Input:** validated idea from Stage 1
- **Process:** problem discovery, codebase analysis, requirements interview
- **Exit criteria:** all requirements gathered, user personas defined, scope agreed
- **Output artifact:** discovery notes (fed into Stage 3)

```
DISCOVERY complete when:
├─ User personas defined
├─ Functional requirements enumerated
├─ Non-functional requirements enumerated
├─ Scope boundaries agreed (in/out)
└─ Open questions resolved or deferred with rationale
```

---

### Stage 3: SPECIFICATION

- **Skills:** `prd-writer` (Phases 4-5), `spec-orchestrator` (for complex multi-audience specs)
- **Input:** discovery notes from Stage 2
- **Process:** module design + PRD synthesis
- **Exit criteria:** Plan-Ready PRD with FR IDs, acceptance criteria, dependencies, AFK hints
- **Output artifact:** Plan-Ready PRD document

```
SPECIFICATION complete when:
├─ Plan-Ready PRD exists with YAML metadata
├─ Every FR has a unique ID (FR-001, FR-002, ...)
├─ Every FR has acceptance criteria
├─ Dependencies mapped between FRs
├─ AFK/HITL hints annotated on each FR
└─ NFRs have measurable targets
```

---

### Stage 4: PLANNING

- **Skills:** `prd-to-plan`
- **Input:** Plan-Ready PRD from Stage 3
- **Process:** codebase scan, vertical-slice decomposition, phase sequencing
- **Exit criteria:** phased implementation plan with dependency graph
- **Output artifact:** implementation plan in `./plans/`

```
PLANNING complete when:
├─ Implementation plan exists in plans/
├─ Work decomposed into vertical slices
├─ Phases sequenced with dependency graph
├─ Each slice has estimated complexity (S/M/L)
└─ AFK/HITL classification per slice
```

---

### Stage 5: ISSUES

- **Skills:** `plan-to-issues`
- **Input:** implementation plan from Stage 4
- **Process:** issue generation, AFK/HITL classification, dependency linking
- **Exit criteria:** all issues created with labels and dependencies
- **Output artifact:** GitHub issues with URLs

```
ISSUES complete when:
├─ GitHub issues created for every slice
├─ Labels applied: agent:afk or agent:hitl
├─ Labels applied: status:ready or status:blocked
├─ Dependencies linked between issues
├─ Issue bodies contain acceptance criteria from PRD
└─ Milestone or project board assigned
```

---

### Stage 6: IMPLEMENTATION

- **Skills:** `qa-testing` (TDD), domain skills (`typescript-engineering`, `nodejs-engineering`, `nextjs-react`, `python-engineering`, etc.)
- **Input:** GitHub issues from Stage 5
- **Process:**
  1. Identify AFK issues with no blockers (`status:ready` + `agent:afk`)
  2. For parallelizable issues: spawn one sub-agent per issue (read references/afk-orchestration.md)
  3. Each sub-agent: write failing tests first (TDD), implement, verify all tests pass
  4. Create PR per issue, link to issue
- **Exit criteria:** all issues have PRs with passing tests
- **AFK orchestration:** read references/afk-orchestration.md for parallel execution patterns

```
IMPLEMENTATION complete when:
├─ Every issue has a linked PR
├─ Every PR has passing tests (written TDD-style)
├─ No PR has unresolved merge conflicts
├─ AFK issues executed in parallel where possible
└─ HITL issues flagged for human implementation or review
```

---

### Stage 7: REVIEW

- **Skills:** `code-review`, `security-analysis`, `simplify`
- **Input:** PRs from Stage 6
- **Process:** run code review on each PR, security scan, simplification pass
- **Exit criteria:** all PRs approved
- **For AFK PRs:** auto-review unless security/payments/PII
- **For HITL PRs:** flag for human review

```
REVIEW complete when:
├─ Every PR reviewed by code-review skill
├─ Security scan passed (security-analysis)
├─ Simplification pass completed (simplify)
├─ HITL PRs flagged for human sign-off
└─ All review feedback addressed
```

---

### Stage 8: SHIP

- **Skills:** `devops-cicd`, `git-workflows`
- **Input:** approved PRs from Stage 7
- **Process:** merge PRs in dependency order, deploy, verify
- **Exit criteria:** feature deployed and verified in production/staging

```
SHIP complete when:
├─ PRs merged in dependency order
├─ CI/CD pipeline green
├─ Feature deployed to staging/production
├─ Smoke tests pass on deployed environment
└─ Pipeline status file marked complete
```

---

### Progress Tracking

After every stage transition:
1. Read references/progress-tracking-template.md
2. Create or update `docs/pipeline/{pipeline-id}/status.md`
3. Record: current stage, completed stages, artifacts produced, open blockers

The pipeline ID format is: `{feature-slug}-{YYYYMMDD}` (e.g., `user-notifications-20260403`).

---

### Resumption Protocol

When a user returns to an in-progress pipeline:
1. Check for `docs/pipeline/*/status.md` files
2. Present: "Found pipeline `{id}` at stage {N} ({stage name}). Last completed: {stage}. Resume?"
3. If yes: pick up from the next stage using the last artifact
4. Validate the last artifact still meets exit criteria (code may have changed between sessions)

---

## Quality Gates

- [ ] Entry point detected correctly
- [ ] Each stage's exit criteria met before proceeding
- [ ] Handoff artifacts validated between stages (read references/stage-transitions.md)
- [ ] Pipeline status file updated after every stage
- [ ] Parallel agents spawned where possible (Stage 6)
- [ ] HITL stages escalated to user
- [ ] Feature delivered end-to-end

---

## Anti-Patterns

| Anti-Pattern | Why It's Dangerous | Fix |
|---|---|---|
| **Doing work directly** | The pipeline orchestrator writing code or specs blurs responsibilities and produces lower-quality output | Always delegate to specialized skills — never generate artifacts yourself |
| **Skipping stages** | Jumping from idea to code means no validated requirements, no plan, no traceability | Every stage exists for a reason; validate exit criteria before advancing |
| **Sequential everything** | Running one issue at a time when 5 could run in parallel wastes time and context | Use AFK orchestration to parallelize independent issues |
| **Ignoring HITL** | Auto-proceeding on security, payment, or PII tasks risks shipping dangerous code | Always escalate HITL-classified work to a human |
| **Lost state** | Not tracking progress forces a full restart on context loss or session timeout | Always update the pipeline status file after every stage |
| **Over-orchestrating** | Running the full 8-stage pipeline for a 5-line bug fix wastes effort | Detect scope first — suggest lighter workflows for small changes |

---

## Delivery Checklist

- [ ] Entry point detected
- [ ] Appropriate stages executed (not all stages are needed for every entry point)
- [ ] All handoffs validated with artifact metadata
- [ ] Pipeline status tracked in `docs/pipeline/{id}/status.md`
- [ ] Feature delivered or progress saved for resumption
