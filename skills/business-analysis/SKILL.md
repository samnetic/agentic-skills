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

## Workflow

1. Align on artifact type and audience.
2. Discover business context, users, constraints, and baseline metrics.
3. Define functional requirements, non-functional requirements, and scope.
4. Prioritize MVP and phase plan.
5. Validate with quality gates and publish in the requested format.

Use these references only as needed:
- Audience and length modes: [references/audience-mode-guide.md](references/audience-mode-guide.md)
- PRD structure: [references/prd-template.md](references/prd-template.md)
- Functional + NFR tables: [references/requirements-catalog-template.md](references/requirements-catalog-template.md)
- Prioritization methods: [references/prioritization-frameworks.md](references/prioritization-frameworks.md)
- Final QA pass: [references/review-checklist.md](references/review-checklist.md)

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

## Quality Gates

A requirements artifact is not complete unless all checks pass.

- Every functional requirement has explicit acceptance criteria.
- Every non-functional requirement is measurable (number + unit + threshold).
- Scope boundaries are explicit (`in` and `out`).
- Priorities are explicit (`Must/Should/Could/Won't` or RICE/WSJF).
- Assumptions and open questions are visible; no hidden assumptions.
- Terminology is consistent (no synonyms for the same concept).
- Document stays within the selected audience word budget.

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
