---
name: business-analysis
description: >-
  Business analysis and requirements engineering skill for PRDs, functional and
  non-functional specifications, and audience-specific requirement artifacts.
  Use when scoping features, clarifying stakeholders, defining acceptance
  criteria, prioritizing MVP vs later phases, or translating business intent
  into implementable specs. Triggers: PRD, requirements, functional
  requirements, non-functional requirements, business analyst, scope, backlog,
  user stories, acceptance criteria, KPI, prioritization, BA.
---

# Business Analysis

Create requirements artifacts that are decision-ready, testable, and scoped for
a specific audience.

## Core Principles

| Principle | Meaning |
|---|---|
| Outcome over output | Every requirement traces to a measurable user or business outcome, not a feature checkbox. |
| Testable by default | If you cannot write an acceptance test for it, it is not a requirement — it is a wish. |
| Right audience, right depth | Tailor detail level to the reader; executives need decisions, engineers need edge cases. |
| Scope is a weapon | Explicitly saying "out of scope" prevents more rework than any amount of in-scope detail. |
| Assumptions are risks | Every unstated assumption is a hidden risk; surface them early or pay later. |
| Progressive refinement | Requirements evolve — start coarse, refine through feedback, freeze only at commitment points. |

## Decision Tree — Choosing the Right Artifact

Use this tree to select the correct deliverable before you start writing.

```
Is the goal to get a GO/NO-GO decision from leadership?
├─ YES → Executive Brief (exec mode, ≤600 words)
│        Focus: problem, ROI, timeline, ask
└─ NO
   ├─ Is this a net-new product or major feature (multi-sprint)?
   │  ├─ YES → PRD (product or engineering mode)
   │  │        Focus: problem, users, scope, phased roadmap
   │  │        Template: references/prd-template.md
   │  └─ NO
   │     ├─ Is the audience engineering / QA?
   │     │  ├─ YES → Functional Spec + NFR Table (engineering mode)
   │     │  │        Focus: acceptance criteria, measurable NFRs, edge cases
   │     │  │        Template: references/requirements-catalog-template.md
   │     │  └─ NO
   │     │     ├─ Do you need to break work into small, estimable units?
   │     │     │  ├─ YES → User Story Map
   │     │     │  │        Focus: persona → goal → stories → acceptance criteria
   │     │     │  └─ NO → Scope & Priority Brief (product mode)
   │     │     │           Focus: in/out scope, MoSCoW or RICE ranking
```

## Workflow

1. Align on artifact type and audience (use Decision Tree above).
2. Discover business context, users, constraints, and baseline metrics.
3. Define functional requirements, non-functional requirements, and scope.
4. Prioritize MVP and phase plan.
5. Validate with quality gates and publish in the requested format.

## Progressive Disclosure Map

Load references only when needed. Reading them all up front wastes context.

| Reference | Path | When to read |
|---|---|---|
| Audience and length modes | [references/audience-mode-guide.md](references/audience-mode-guide.md) | When unsure which mode fits or user requests multiple audiences |
| PRD structure | [references/prd-template.md](references/prd-template.md) | When writing a full PRD for a new product or major feature |
| Functional + NFR tables | [references/requirements-catalog-template.md](references/requirements-catalog-template.md) | When producing engineering-ready specs with acceptance criteria |
| Prioritization methods | [references/prioritization-frameworks.md](references/prioritization-frameworks.md) | When ranking backlog items or justifying MVP scope cuts |
| Final QA pass | [references/review-checklist.md](references/review-checklist.md) | After drafting, before handing off — run every quality gate |

## Audience Modes

Pick one primary audience before drafting.

| Mode | Primary Reader | Goal | Word Budget |
|---|---|---|---:|
| `exec` | Founder/leadership | Decision and ROI clarity | <= 600 |
| `product` | PM/BA/design | Scope, priorities, user outcomes | <= 1300 |
| `engineering` | Engineers/QA | Build-ready requirements and acceptance | <= 1700 |
| `architecture-input` | Architect/staff eng | Constraints, risks, quality attributes | <= 1000 |

If the user requests multiple audiences, create one primary artifact and add
appendices for secondary audiences.

## Output Contract

Every response must include these sections, in this order:

1. `Problem and Outcome`
2. `Audience and Scope` (in-scope, out-of-scope)
3. `Functional Requirements` (ID, requirement, priority, acceptance)
4. `Non-Functional Requirements` (attribute, metric, target)
5. `Dependencies, Risks, and Assumptions`
6. `Open Questions and Decisions Needed`
7. `Next Actions` (owner + date)

When asked for a PRD, use the PRD reference template and write concise prose
plus tables.

## User Story Template

When the deliverable calls for user stories, use this structure.

```yaml
story:
  id: US-042
  title: "Bulk CSV import for product catalog"
  persona: Warehouse Manager
  narrative: >
    As a warehouse manager,
    I want to upload a CSV of up to 10,000 products,
    so that I can onboard a new supplier's catalog in under 5 minutes.
  acceptance_criteria:
    - given: a valid CSV with ≤10,000 rows
      when: the user clicks "Import"
      then: all rows are created and a summary toast shows created/skipped counts
    - given: a CSV with duplicate SKUs
      when: the user clicks "Import"
      then: duplicates are skipped, listed in an error report, and valid rows still import
    - given: a CSV exceeding 10,000 rows
      when: the user selects the file
      then: a validation error appears before upload begins
  priority: Must (MoSCoW)
  nfr_targets:
    - attribute: throughput
      metric: "rows/sec"
      target: "≥ 200"
    - attribute: error_rate
      metric: "percent silent failures"
      target: "0%"
  dependencies:
    - "Product Service bulk-create API (API-107)"
  open_questions:
    - "Should we support XLSX in addition to CSV for v1?"
```

## Functional Requirements Table Template

Use this format for engineering-mode deliverables.

```markdown
| ID | Requirement | Priority | Acceptance Criteria |
|----|-------------|----------|---------------------|
| FR-001 | System shall allow CSV upload up to 10K rows | Must | Upload completes in <30s; success toast with count |
| FR-002 | Duplicate SKUs are skipped, not failed | Must | Error report lists skipped SKUs; valid rows persist |
| FR-003 | File size validated client-side before upload | Should | Files >50MB show error; no network request sent |
| FR-004 | Import progress bar with cancel support | Could | Progress updates every 2s; cancel aborts cleanly |
```

## Quality Gates

A requirements artifact is not complete unless all checks pass.

- Every functional requirement has explicit acceptance criteria.
- Every non-functional requirement is measurable (number + unit + threshold).
- Scope boundaries are explicit (`in` and `out`).
- Priorities are explicit (`Must/Should/Could/Won't` or RICE/WSJF).
- Assumptions and open questions are visible; no hidden assumptions.
- Terminology is consistent (no synonyms for the same concept).
- Document stays within the selected audience word budget.

## Delivery Checklist

Run this checklist before sharing any requirements artifact.

- [ ] Artifact type matches the Decision Tree recommendation
- [ ] Single primary audience mode selected and stated
- [ ] Word count within budget for the chosen mode
- [ ] Problem statement includes measurable baseline and target outcome
- [ ] All seven Output Contract sections present and in order
- [ ] Every FR has at least one Given/When/Then acceptance criterion
- [ ] Every NFR has a numeric threshold with unit (e.g., "p99 < 200ms")
- [ ] In-scope and out-of-scope lists are explicit
- [ ] Priorities use a stated framework (MoSCoW, RICE, or WSJF)
- [ ] Dependencies reference specific system or team identifiers
- [ ] Assumptions listed separately from decisions already made
- [ ] Open questions have a proposed owner and target resolution date
- [ ] No vague adjectives remain ("fast", "easy", "scalable") without numbers
- [ ] Terminology audit: each domain concept uses exactly one term throughout
- [ ] Artifact reviewed against references/review-checklist.md

## Anti-Patterns

- Vague terms without thresholds (`fast`, `easy`, `robust`) in final specs.
- Requirements that imply implementation details without user/business outcome.
- Mixing discovery notes and final requirements with no clear separation.
- Overlong narrative where a table is clearer.

## Handoff Rules

- If uncertainty blocks quality gates, ask targeted clarification questions.
- If architecture trade-offs dominate, hand off to `software-architecture`.
- If document structure/voice quality dominates, hand off to
  `technical-writing`.
