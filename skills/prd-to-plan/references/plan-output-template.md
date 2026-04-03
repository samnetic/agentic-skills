# Plan Output Template

Use this template when writing the final implementation plan in Phase 7. Write the plan to `./plans/{feature-name}-plan.md`.

---

## Template

```markdown
# Implementation Plan: {Feature Name}

## Metadata
- **PRD:** {link to PRD or file path}
- **Date:** {YYYY-MM-DD}
- **Pipeline ID:** {feature-id-YYYYMMDD}
- **Status:** Draft | Approved

## Codebase Context
- **Tech Stack:** {framework, language, DB, ORM, test tools}
- **Relevant Existing Code:** {brief list of files/modules that will be extended}
- **Key Patterns to Follow:** {architectural patterns discovered during codebase scan}

## Durable Decisions

| Decision | Choice | Rationale | Reversibility |
|---|---|---|---|
| {decision area} | {chosen approach} | {why this choice} | Low / Medium / High |

Example:
| Decision | Choice | Rationale | Reversibility |
|---|---|---|---|
| Primary key strategy | UUIDv7 | Sortable, no collisions, consistent with existing tables | Low |
| API versioning | URL prefix `/api/v1` | Matches existing API conventions | Medium |
| State management | Server Components + Server Actions | Reduces client bundle, matches Next.js patterns | Medium |

## Phase Overview

| Phase | Slice | Description | FRs Covered | Dependencies | AFK/HITL | Est. Effort |
|---|---|---|---|---|---|---|
| 0 | Tracer bullet | {one-line description} | FR-001 | — | AFK | S |
| 1A | {slice name} | {one-line description} | FR-002, FR-003 | Phase 0 | AFK | M |
| 1B | {slice name} | {one-line description} | FR-004 | Phase 0 | HITL | M |
| 2A | {slice name} | {one-line description} | FR-005, FR-006 | Phase 1A, 1B | AFK | L |

Effort estimates: S = <1 day, M = 1-2 days, L = 3-5 days

## Dependency Graph

{paste mermaid diagram here — see references/dependency-graph-template.md}

## Phase Details

### Phase 0: Tracer Bullet — {slice name}

**Goal:** Prove end-to-end architecture works with the thinnest possible path.
**FRs:** FR-001
**AFK:** Yes / No
**Estimated effort:** S

| Layer | What to build | Details |
|---|---|---|
| Database | {tables, columns} | {migration name, column types, constraints, seed data} |
| Backend | {endpoints, logic} | {route, handler, validation rules, response shape} |
| Frontend | {components, pages} | {UI elements, data fetching, user interactions} |
| Tests | {test types} | {what to assert, acceptance criteria to verify} |

**Acceptance Criteria:**
- Given {context}, when {action}, then {result}
- Given {context}, when {action}, then {result}

**Verification:**
- [ ] Migration runs cleanly
- [ ] API endpoint returns expected response
- [ ] UI renders with real data
- [ ] All tests pass
- [ ] Deploys to staging/preview successfully

---

### Phase 1A: {slice name}

**Goal:** {what this slice adds to the system}
**FRs:** FR-002, FR-003
**AFK:** Yes / No
**Estimated effort:** M
**Depends on:** Phase 0

| Layer | What to build | Details |
|---|---|---|
| Database | {tables, columns} | {details} |
| Backend | {endpoints, logic} | {details} |
| Frontend | {components, pages} | {details} |
| Tests | {test types} | {details} |

**Acceptance Criteria:**
- Given {context}, when {action}, then {result}

**Verification:**
- [ ] {specific verification step}
- [ ] All tests pass

---

### Phase 1B: {slice name}

{same structure as Phase 1A — repeat for every phase/slice}

---

## Risk Register

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| {risk description} | Low / Medium / High | Low / Medium / High | {mitigation strategy} |

Example:
| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Third-party API rate limits hit during development | Medium | Medium | Use recorded fixtures for tests; implement retry with backoff |
| Schema migration conflicts with concurrent work | Low | High | Coordinate migration ordering; use feature branch migrations |
| Auth flow complexity underestimated | Medium | High | Marked as HITL; allocate extra review time |

## Out of Scope (from PRD)

Items explicitly excluded in the PRD or deferred to future work:

1. {out-of-scope item from PRD}
2. {out-of-scope item from PRD}

## Notes

- {any additional context, open questions, or follow-up items}
```

---

## Section-by-Section Guidance

### Metadata

- **Pipeline ID** uses the pattern `{feature-slug}-{YYYYMMDD}` for traceability across PRD, plan, and issues.
- **Status** starts as `Draft` until the user confirms the plan in Phase 6 (Quiz User).

### Codebase Context

Pull this directly from the Phase 2 (Codebase Scan) findings. Keep it brief — this section orients anyone reading the plan to the existing architecture.

### Durable Decisions

From Phase 3. Only include decisions that are **expensive to reverse**. Each needs a rationale so future readers understand *why*, not just *what*.

### Phase Overview Table

One row per slice. This is the at-a-glance summary. Readers should be able to understand the full plan from this table alone.

### Dependency Graph

Copy from the mermaid diagram generated in Phase 5. Include AFK/HITL visual convention (solid vs dashed borders).

### Phase Details

One section per phase/slice. Every section must include:

1. **All four layers** (DB, Backend, Frontend, Tests) — even if a layer has minimal work, state what it is.
2. **Acceptance criteria** in Given/When/Then format — these come from the PRD's FR acceptance criteria.
3. **Verification checklist** — concrete steps to confirm the slice is done.

### Risk Register

Include risks identified during planning. Focus on risks specific to this plan, not generic software risks. Each risk needs a concrete mitigation.

### Out of Scope

Copy directly from the PRD's out-of-scope section. This prevents scope creep during implementation.
