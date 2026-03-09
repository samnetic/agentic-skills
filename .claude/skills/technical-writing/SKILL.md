---
name: technical-writing
description: >-
  Technical writing skill for specifications, architecture docs, API docs,
  runbooks, and developer documentation with audience-aware structure. Use when
  drafting, reviewing, or refactoring documentation for clarity, length control,
  and fit-for-purpose format (Diataxis, ADR, PRD, reference, how-to).
  Triggers: documentation, spec, PRD, ADR, runbook, README, API docs,
  technical writing, developer guide, architecture document, doc review.
---

# Technical Writing

Write the shortest document that lets the target audience take the next correct
action.

## Workflow

1. Select audience mode and document type.
2. Define the core question the document must answer.
3. Choose a template and fill only required sections.
4. Edit for scannability and evidence.
5. Run quality gates before finalizing.

Reference files:
- Doc-type selection: [references/doc-type-selector.md](references/doc-type-selector.md)
- Audience budgets and voice: [references/audience-length-budgets.md](references/audience-length-budgets.md)
- Reusable templates: [references/doc-templates.md](references/doc-templates.md)
- Final editing pass: [references/editing-checklist.md](references/editing-checklist.md)

## Audience Modes

| Mode | Reader | Primary Need | Word Budget |
|---|---|---|---:|
| `exec` | Leadership | Decision and impact | <= 500 |
| `product` | PM/BA/design | Scope and trade-offs | <= 1100 |
| `engineering` | Dev/QA/SRE | Exact implementation/operations steps | <= 1400 |
| `reference` | Power users/integrators | Fast lookup accuracy | <= 1800 |

If no mode is provided, default to `engineering` for implementation tasks and
`product` for planning tasks.

## Output Contract

Every technical writing output must include:

1. `Audience and Purpose` (one sentence each)
2. `Type` (`tutorial`, `how-to`, `reference`, or `explanation`)
3. `Main Content` using the selected template
4. `Assumptions and Limits`
5. `Next Action` for the reader

If asked to improve an existing document, include a short `Change Summary`
listing structural edits and major deletions.

## Quality Gates

- One document type only; do not mix tutorial/how-to/reference/explanation.
- Opening section states audience and purpose explicitly.
- Every section heading answers a concrete reader question.
- Steps are executable and ordered for real usage.
- Claims are supported by evidence or explicitly marked as assumptions.
- Terminology is consistent with project vocabulary.
- Document stays within the selected audience word budget.

## Style Rules

- Prefer tables/checklists over long prose when possible.
- Prefer active voice and specific verbs.
- Keep paragraphs short (2-4 sentences).
- Use examples when introducing new terms.
- Remove repetitive background unless requested.

## Escalation Rules

- If the core issue is missing requirements, hand off to `business-analysis`.
- If architecture decisions are unresolved, hand off to
  `software-architecture`.
