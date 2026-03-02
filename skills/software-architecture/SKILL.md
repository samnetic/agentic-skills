---
name: software-architecture
description: >-
  Software architecture and system design skill for architecture decision
  records, architecture design documents, and non-functional requirement
  modeling. Use when evaluating architecture options, defining boundaries,
  setting measurable quality targets, and producing audience-specific design
  artifacts. Triggers: architecture design, system design, ADR, NFR,
  scalability, resilience, distributed systems, C4, trade-off analysis.
---

# Software Architecture

Produce architecture artifacts that make trade-offs explicit and execution-safe.

## Workflow

1. Frame the problem, constraints, and quality attributes.
2. Evaluate at least two architecture options with trade-offs.
3. Select a recommendation and draft/update ADRs.
4. Define implementation boundaries, rollout plan, and observability.
5. Validate design against quality gates.

Progressive references:
- Full design doc template: [references/architecture-design-doc-template.md](references/architecture-design-doc-template.md)
- ADR format: [references/adr-template.md](references/adr-template.md)
- C4 communication checklist: [references/c4-checklist.md](references/c4-checklist.md)
- NFR metrics and fitness checks: [references/nfr-fitness-catalog.md](references/nfr-fitness-catalog.md)
- Risk register format: [references/risk-register-template.md](references/risk-register-template.md)

## Audience Modes

| Mode | Reader | Goal | Word Budget |
|---|---|---|---:|
| `exec` | CTO/founder | Strategic trade-off + investment decision | <= 700 |
| `product` | PM/BA | Product constraints and delivery impact | <= 1100 |
| `engineering` | Eng lead/team | Buildable architecture and boundaries | <= 1800 |
| `architecture-review` | Staff/principal/security | Decision rationale + risks + controls | <= 2200 |

Default to `engineering` unless the user asks for a decision brief.

## Output Contract

Every architecture response must include:

1. `Context and Constraints`
2. `Quality Targets` (NFR metrics with numbers)
3. `Options Considered` (at least 2)
4. `Recommended Architecture`
5. `Boundary and Ownership Model`
6. `Risks and Mitigations`
7. `Rollout and Validation Plan`
8. `ADR Delta` (new ADR or updates required)

If diagrams are requested, provide a Mermaid C4-level summary plus narrative.

## Quality Gates

- NFRs are measurable (metric + threshold + validation method).
- At least two viable options are compared.
- Recommendation traces back to stated constraints.
- Component boundaries and ownership are explicit.
- Failure modes for critical dependencies are documented.
- Security/privacy constraints are represented where relevant.
- Rollout plan includes verification and rollback criteria.
- Output stays within chosen audience word budget.

## Common Failure Modes

- Choosing patterns by trend instead of constraints.
- Describing components without ownership boundaries.
- Listing NFRs without test/monitoring strategy.
- Ignoring migration and rollback in rollout plans.

## Escalation Rules

- If requirements are unclear, loop through `business-analysis` first.
- If final document readability/format is weak, run
  `technical-writing` cleanup before handoff.
