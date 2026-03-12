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

## Core Principles

| Principle | Meaning |
|---|---|
| Audience-first | Every sentence must serve a specific reader role; cut anything the reader already knows |
| One purpose per doc | A document is a tutorial OR a how-to OR a reference OR an explanation — never a blend |
| Scannable over literary | Readers skim; use headings, tables, and lists so the answer is findable in under 10 seconds |
| Evidence over opinion | Back claims with data, links, or code; mark everything else as an assumption |
| Shortest viable length | Respect the word budget for the audience mode; move overflow to appendices |
| Executable steps | Every instruction must be copy-pasteable or directly actionable — no vague guidance |
| Living documents | Docs rot; include a "Last verified" date and an owner so staleness is visible |

## Workflow

1. Select audience mode and document type.
2. Define the core question the document must answer.
3. Choose a template and fill only required sections.
4. Edit for scannability and evidence.
5. Run quality gates before finalizing.

## Decision Tree — Choosing a Document Type

Start from the reader's immediate need and follow the first matching branch.

```
Is the reader learning a concept for the first time?
├─ YES → Is there a working example to build?
│        ├─ YES → TUTORIAL (guided lesson, start to finish)
│        └─ NO  → EXPLANATION (context, rationale, trade-offs)
└─ NO  → Does the reader need to complete a specific task right now?
         ├─ YES → Is it a one-off operational procedure?
         │        ├─ YES → RUNBOOK (preconditions, steps, rollback)
         │        └─ NO  → HOW-TO (preconditions, ordered steps, verify)
         └─ NO  → Does the reader need to look up exact facts?
                  ├─ YES → REFERENCE (tables, parameters, errors, examples)
                  └─ NO  → Is a decision being recorded for future teams?
                           ├─ YES → ADR (context, decision, consequences)
                           └─ NO  → Is the audience leadership or cross-functional?
                                    ├─ YES → README / OVERVIEW (purpose, quick start, links)
                                    └─ NO  → PRD / SPEC (scope, requirements, acceptance criteria)
```

Quick-pick summary:

| Signal in Request | Doc Type | Template |
|---|---|---|
| "Set up from scratch", "learn how" | Tutorial | Guided lesson |
| "I need to do X now" | How-To | Steps + verify |
| "What are the options / parameters?" | Reference | Tables + examples |
| "Why did we choose X?" | ADR | Context → Decision → Consequences |
| "On-call procedure", "incident response" | Runbook | Preconditions → Steps → Rollback |
| "Introduce the project" | README | Purpose → Quick start → Links |
| "What should we build?" | PRD / Spec | Scope → Requirements → Acceptance |
| "Explain the concept" | Explanation | Context → Rationale → Trade-offs |

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

## ADR Template Example

Use this as a starting point for Architecture Decision Records:

```markdown
# ADR-NNN: Use PostgreSQL for Transactional Data

**Status:** Accepted
**Date:** 2026-03-10
**Deciders:** @backend-team, @db-architect

## Context

The service processes ~2 000 orders/sec with ACID requirements. We evaluated
PostgreSQL 16, CockroachDB, and DynamoDB.

## Decision

Adopt PostgreSQL 16 on RDS with read replicas.

### Rationale
- ACID compliance out of the box; no application-level conflict resolution.
- Team has 5+ years operational experience; reduces onboarding cost.
- RDS handles backups, failover, and minor-version upgrades.

## Consequences

- **Good:** Familiar tooling, strong ecosystem (pgvector, PostGIS).
- **Bad:** Horizontal write-scaling requires sharding or Citus later.
- **Neutral:** Must size connection pool carefully (PgBouncer).

## Alternatives Considered

| Option | Rejected Because |
|---|---|
| CockroachDB | Higher per-node cost; team lacks operational experience |
| DynamoDB | Single-table design complexity; no ad-hoc SQL joins |
```

## Runbook Template Example

```markdown
# Runbook: Restart Payment Service

**Owner:** @sre-team | **Last verified:** 2026-02-15

## When to Use
Payment service returns HTTP 503 for > 2 min AND auto-scaling has not resolved.

## Prerequisites
- `kubectl` access to `prod-payments` namespace
- PagerDuty incident open

## Steps
1. Verify the failure: `kubectl get pods -n prod-payments`
2. Check logs: `kubectl logs -n prod-payments -l app=payment --tail=100`
3. Restart: `kubectl rollout restart deployment/payment -n prod-payments`
4. Watch rollout: `kubectl rollout status deployment/payment -n prod-payments`

## Verify
- `curl -s https://api.example.com/health` returns `200`
- Grafana dashboard "Payment SLO" shows error rate < 0.1%

## Rollback
If the new pods crash-loop, roll back:
`kubectl rollout undo deployment/payment -n prod-payments`
```

## Anti-Patterns

| Anti-Pattern | Why It's Dangerous | Fix |
|---|---|---|
| Wall of text | Readers skip it entirely; critical info is buried | Break into headed sections; use tables and lists |
| Mixed doc types | Half-tutorial, half-reference confuses both audiences | Pick one Diataxis type; split if needed |
| Assumed context | New team members cannot act on the doc | State audience, prerequisites, and definitions up front |
| Stale screenshots | Mislead readers when UI changes | Use text descriptions or auto-generated output; add "Last verified" date |
| Copy-paste syndrome | Duplicated content drifts and contradicts itself | Single-source shared content; link instead of copying |
| Missing "Next Action" | Reader finishes but doesn't know what to do | Always end with a concrete next step |
| Jargon without definition | Excludes readers outside the inner circle | Define terms on first use or link to a glossary |
| Undated decisions | Impossible to judge if advice is still current | Add date and status to every ADR and runbook |
| Giant README | One file tries to be tutorial + reference + changelog | Keep README as entry point; link to dedicated docs |
| No verify step | Reader follows steps but can't confirm success | Add a verification section with expected output |

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

## Pre-Publish Checklist

- [ ] Audience and purpose are stated in the first section.
- [ ] Exactly one Diataxis document type is used throughout.
- [ ] Every heading is phrased as a task or question the reader has.
- [ ] All steps are numbered, ordered, and copy-pasteable.
- [ ] Claims cite evidence or are marked `[assumption]`.
- [ ] Terminology matches the project glossary — no silent synonyms.
- [ ] Word count is within the audience mode budget.
- [ ] A "Next Action" section tells the reader what to do after reading.
- [ ] Code examples have been tested or marked `[untested]`.
- [ ] Dates and owners are present on ADRs, runbooks, and specs.
- [ ] No sensitive data (secrets, internal URLs) in the document.
- [ ] Links are valid and point to versioned/permanent targets.
- [ ] Document has been reviewed by at least one member of the target audience.

## Progressive Disclosure Map

| Reference File | Contains | When to Read |
|---|---|---|
| [references/doc-type-selector.md](references/doc-type-selector.md) | Diataxis type matrix and decision rules | When unsure which document type to pick |
| [references/audience-length-budgets.md](references/audience-length-budgets.md) | Tone, required signals, and max words per mode | When calibrating length and voice for a specific audience |
| [references/doc-templates.md](references/doc-templates.md) | Starter templates for spec, how-to, reference, and ADR | When beginning a new document from scratch |
| [references/editing-checklist.md](references/editing-checklist.md) | Final editing pass checklist | After drafting, before publishing or handing off |

## Escalation Rules

- If the core issue is missing requirements, hand off to `business-analysis`.
- If architecture decisions are unresolved, hand off to
  `software-architecture`.
