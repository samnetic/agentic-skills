---
name: prd-to-plan
description: >-
  Transform PRDs into phased, vertical-slice implementation plans using the
  tracer-bullet approach. Each phase delivers narrow but complete end-to-end
  functionality through all layers. Produces dependency graphs, AFK eligibility
  tags, and sequenced phases starting with a Phase 0 tracer bullet. Use when
  you have a PRD and need an implementation plan. Triggers: plan this PRD,
  create implementation plan, break this into phases, vertical slices, tracer
  bullet, turn this spec into a plan, how should we build this.
license: MIT
metadata:
  author: samnetic
  version: "1.0"
---

# PRD to Plan

Transform requirements into vertical-slice implementation plans where every phase delivers working, demoable software.

---

## Core Principles

| Principle | Meaning |
|---|---|
| **Vertical over horizontal** | Every slice cuts through ALL layers (DB → API → UI → tests) — never "do all DB first, then all API." |
| **Tracer bullet first** | Phase 0 is the thinnest possible end-to-end path proving architecture works. |
| **Durable decisions first** | Identify routes, schema, data models, API contracts early — these are expensive to change later. |
| **Demoable phases** | Every phase produces something you can show to a stakeholder. |
| **Dependency-aware sequencing** | Slices that other slices depend on come first. |
| **AFK-aware classification** | Each slice is tagged for autonomous (AFK) or human-required (HITL) execution. |
| **Plan survives refactoring** | Describe behaviors and contracts, not file paths or line numbers — plans must remain valid even if the codebase is restructured. |

---

## Workflow

1. **Ingest PRD** — accept PRD from prd-writer output or user-provided document.
2. **Codebase Scan** — understand existing architecture, patterns, tech stack.
3. **Identify Durable Decisions** — routes, schema, data models, API contracts.
4. **Decompose into Vertical Slices** — each slice = complete path through every layer.
5. **Sequence into Phases** — Phase 0 (tracer bullet) → Phase 1-N (incremental capability).
6. **Quiz User** — present breakdown, iterate on granularity/dependencies/classifications.
7. **Write Plan** — output structured plan to `./plans/` directory.

---

## Progressive Disclosure Map

| Reference | Path | When to read |
|---|---|---|
| Vertical slice decomposition | [references/vertical-slice-decomposition.md](references/vertical-slice-decomposition.md) | Step 4: before decomposing into slices |
| Tracer bullet pattern | [references/tracer-bullet-pattern.md](references/tracer-bullet-pattern.md) | Step 5: before defining Phase 0 |
| Dependency graph template | [references/dependency-graph-template.md](references/dependency-graph-template.md) | Step 5: when mapping dependencies |
| Plan output template | [references/plan-output-template.md](references/plan-output-template.md) | Step 7: when writing the final plan |

---

## Trigger Conditions

**Mandatory triggers** — always activate this skill:
- "plan this PRD"
- "create implementation plan"
- "turn this spec into a plan"

**Strong triggers** — activate when combined with a PRD or spec context:
- "break this into phases"
- "vertical slices"
- "tracer bullet"
- "how should we build this"
- "implementation plan"

**Do NOT trigger on:**
- PRD creation → use `prd-writer`
- Issue creation from a plan → use `plan-to-issues`
- Architecture decisions without a PRD → use `software-architecture`

---

## Execution Protocol

### Phase 1: Ingest PRD

- Accept PRD from: file path, GitHub issue URL, pasted content, or `prd-writer` output.
- Parse structured sections: FRs with IDs, NFRs, dependencies, module design.
- If PRD lacks FR IDs or acceptance criteria, flag gaps and suggest using `prd-writer` first.
- Confirm understanding: *"This PRD describes [X] with [N] functional requirements. Shall I proceed?"*

### Phase 2: Codebase Scan

- **Explore:** directory structure, `package.json` / `Gemfile` / `requirements.txt`, existing models, API routes, test setup.
- **Map:** tech stack, ORM/database, API framework, test framework, build tools.
- **Identify:** existing patterns to follow, code to extend vs create new, integration points.
- **Document:** *"The codebase uses [framework] with [DB]. Relevant existing code: [list]."*

### Phase 3: Identify Durable Decisions

These are decisions that are expensive to change later:

- Database schema / new tables / migrations
- API routes and endpoint contracts
- Data models and their relationships
- Authentication/authorization boundaries
- Third-party service integrations

Document each decision with rationale. Flag any that need user input before proceeding.

### Phase 4: Decompose into Vertical Slices

> Read [references/vertical-slice-decomposition.md](references/vertical-slice-decomposition.md) before starting this phase.

For each slice, define WHAT it delivers through EVERY layer:

| Layer | What to define |
|---|---|
| **Database** | Tables, columns, migrations, seeds |
| **Backend** | API endpoints, business logic, validations |
| **Frontend** | UI components, pages, forms |
| **Tests** | Unit tests, integration tests, E2E tests |

- Group related FRs into slices (a slice typically covers 1-3 FRs).
- Each slice must be independently demoable.

### Phase 5: Sequence into Phases

> Read [references/tracer-bullet-pattern.md](references/tracer-bullet-pattern.md) and [references/dependency-graph-template.md](references/dependency-graph-template.md) before starting this phase.

**Phase 0 — Tracer Bullet:**
- Pick the single most representative user flow.
- Implement the simplest version through ALL layers.
- This proves: architecture works, build pipeline works, deploy pipeline works.
- Example: for a todo app, Phase 0 = create one todo item with one field, display it, save to DB.

**Phase 1-N — Incremental Capability:**
- Respect dependency ordering (slices that block others come first).
- Group related slices into phases for logical releases.

**Tagging:**
- Tag each slice: **AFK** (agent can complete autonomously) or **HITL** (needs human judgment).
- Generate dependency graph in mermaid format.

### Phase 6: Quiz User

Present the complete breakdown:

- Phase table with all slices
- Dependency graph
- AFK/HITL classification rationale

Ask specific questions:

1. *"Is the Phase 0 tracer bullet thin enough?"*
2. *"Should any slices be split further or merged?"*
3. *"Do the AFK/HITL classifications look right?"*
4. *"Are there dependency relationships I missed?"*

Iterate based on feedback.

### Phase 7: Write Plan

> Read [references/plan-output-template.md](references/plan-output-template.md) before starting this phase.

- Write to `./plans/{feature-name}-plan.md`.
- Include all sections from the template.
- Report file path to user.

---

## Quality Gates

- [ ] PRD was ingested and all FRs accounted for in slices
- [ ] Codebase was scanned and findings incorporated
- [ ] Durable decisions documented with rationale
- [ ] Every slice cuts through ALL layers (DB/API/UI/tests)
- [ ] Phase 0 is a genuine tracer bullet (thinnest end-to-end)
- [ ] Dependencies between slices are explicitly mapped
- [ ] AFK/HITL classification applied to every slice
- [ ] Dependency graph generated in mermaid format
- [ ] User confirmed the breakdown
- [ ] Plan file written to `./plans/`

---

## Anti-Patterns

| Anti-Pattern | Why It's Dangerous | Fix |
|---|---|---|
| **Horizontal slicing** | "Phase 1: all DB, Phase 2: all API, Phase 3: all UI" — nothing works until Phase 3. | Vertical slice through all layers instead. |
| **Fat tracer bullet** | Phase 0 that tries to do too much — delays first proof of architecture. | Strip to absolute minimum end-to-end path. |
| **Missing layer in slice** | A slice with API but no tests — accumulates integration risk. | Every slice MUST include its test layer. |
| **Ignoring the codebase** | Planning features that conflict with existing architecture. | Always run Phase 2 scan. |
| **Over-sequencing** | Making everything depend on everything — kills parallelism. | Maximize parallelism, minimize dependencies. |
| **AFK optimism** | Tagging auth/payment/PII work as AFK — leads to autonomous mistakes in sensitive areas. | Default to HITL for sensitive domains. |

---

## Delivery Checklist

- [ ] PRD ingested and FRs mapped to slices
- [ ] Codebase scanned
- [ ] Durable decisions documented
- [ ] Vertical slices decomposed
- [ ] Phases sequenced with Phase 0 tracer bullet
- [ ] AFK/HITL tagged
- [ ] Dependency graph generated
- [ ] User quizzed and feedback incorporated
- [ ] Plan written to `./plans/`
- [ ] File path shared with user
