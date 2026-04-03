# Plan-Ready PRD Template

Use this template when synthesizing the final PRD in Phase 5. Every section is
required. If a section has no content, write "N/A — [reason]" rather than
omitting it.

This template extends the standard business-analysis PRD template with pipeline
metadata: dependency markers, AFK-eligibility hints, vertical-slice suggestions,
module design, and codebase context. These additions make the PRD consumable by
downstream tools (e.g., `prd-to-plan`) without human translation.

---

## Template

```markdown
# PRD: {Feature Name}

## Metadata
- **Author:** {name}
- **Date:** {YYYY-MM-DD}
- **Status:** Draft | Review | Approved
- **Pipeline ID:** {kebab-case-feature-id}-{YYYYMMDD}
- **Skill:** prd-writer v1.0

---

## 1. Problem and Outcome

### Problem Statement
{2-3 sentence problem statement confirmed with the user during Phase 1. Must
describe the problem, not the solution.}

### Why Now
{Business driver or trigger — what changed that makes this urgent? Customer
feedback, competitive pressure, technical debt, compliance deadline, etc.}

### Expected Outcome
{Measurable business or user outcome. Not "build X" but "reduce Y by Z%" or
"enable users to accomplish W in T minutes instead of T' minutes."}

---

## 2. Users and Jobs-to-be-Done

| User Persona | Job to be Done | Pain Today | Desired Outcome |
|---|---|---|---|
| {Specific role, e.g., "Warehouse Manager"} | {Action they need to accomplish} | {Current frustration or workaround} | {What "done" looks like for them} |
| {Second persona} | {Job} | {Pain} | {Outcome} |

---

## 3. Codebase Context

{Populated from Phase 2 codebase analysis. If greenfield, write "Greenfield
project — no existing constraints."}

- **Tech stack:** {e.g., Next.js 15, TypeScript 5.8, PostgreSQL 16, Prisma 6}
- **Relevant existing patterns:**
  - {e.g., "API routes use cursor-based pagination via `lib/pagination.ts`"}
  - {e.g., "Auth uses NextAuth.js with session strategy"}
- **Constraints imposed by codebase:**
  - {e.g., "All API responses follow RFC 9457 Problem Details for errors"}
  - {e.g., "Database uses UUIDv7 primary keys — new tables must follow suit"}
- **Models/entities to extend:**
  - {e.g., "`users` table needs a `preferences` JSONB column"}
  - {e.g., "New `notifications` table required"}
- **Potential conflicts:**
  - {e.g., "Proposed webhook system overlaps with existing event bus in `lib/events/`"}

---

## 4. Functional Requirements

| ID | Requirement | Priority | Acceptance Criteria | Dependencies | AFK Eligible | Vertical Slice |
|---|---|---|---|---|---|---|
| FR-001 | {Clear, testable requirement} | Must | Given {context}, When {action}, Then {outcome} | — | Yes | {slice name} |
| FR-002 | {Requirement} | Must | Given {context}, When {action}, Then {outcome} | FR-001 | Yes | {slice name} |
| FR-003 | {Requirement} | Should | Given {context}, When {action}, Then {outcome} | — | No | {slice name} |
| FR-004 | {Requirement} | Could | Given {context}, When {action}, Then {outcome} | FR-002 | Yes | {slice name} |

### Column Definitions

- **ID:** Unique identifier. Sequential: FR-001, FR-002, etc.
- **Priority:** MoSCoW — Must (launch blocker), Should (high value, not blocking),
  Could (nice to have), Won't (explicitly deferred).
- **Acceptance Criteria:** Given/When/Then format. One primary criterion per row;
  add sub-bullets for edge cases.
- **Dependencies:** Other FR IDs that must be completed first. Use "—" for none.
- **AFK Eligible:** Can an autonomous agent implement this without human
  decision-making during implementation?
  - `Yes` — clear inputs, clear outputs, follows existing patterns, no ambiguous
    UX decisions.
  - `No` — requires human judgment: novel UX design, ambiguous business rules,
    complex algorithm design, external stakeholder approval needed.
- **Vertical Slice:** Which implementation slice this FR belongs to (see Section 9).

---

## 5. Non-Functional Requirements

| Attribute | Metric | Target | Validation Method |
|---|---|---|---|
| Performance | API latency P95 | < {N} ms | Load test with k6 at {N} concurrent users |
| Performance | Page load (LCP) | < {N} s | Lighthouse CI in pipeline |
| Throughput | Requests/sec | > {N} RPS | k6 stress test |
| Availability | Uptime | {N}% | Uptime monitoring (e.g., Checkly) |
| Security | Auth bypass | 0 vulnerabilities | OWASP ZAP scan + manual review |
| Data | Retention | {N} days | Automated purge job + audit log |
| Compliance | {Standard} | Compliant | {Audit method} |

### NFR Rules
- Every row must have a **numeric target** — no "should be fast."
- Every row must have a **validation method** — how do we prove we met this?
- If the user cannot provide a number, use industry defaults and mark with
  "(default — confirm with stakeholder)."

---

## 6. Module Design

| Module | Interface Size | Implementation Complexity | Depth Rating | Responsibility |
|---|---|---|---|---|
| {Module name} | Small ({N} methods) | High ({list: auth, validation, caching, ...}) | Deep | {What this module does and hides} |
| {Module name} | Medium ({N} methods) | Medium ({list}) | Moderate | {Responsibility} |
| {Module name} | Large ({N} methods) | Low ({list}) | Shallow | {Responsibility — consider merging} |

### Depth Assessment Key
- **Deep** — small interface, complex internals. This is the goal. The module
  hides significant complexity behind a simple API.
- **Moderate** — balanced. Acceptable, but look for opportunities to simplify the
  interface.
- **Shallow** — large interface, simple internals. Warning sign. Consider merging
  into an adjacent module or questioning whether this abstraction is needed.

---

## 7. Scope

### In Scope (MVP)
1. {Item — tied to specific FRs}
2. {Item}
3. {Item}

### Out of Scope
1. {Item — why it's deferred}
2. {Item — what workaround exists or why it's not needed now}
3. {Item — minimum 3 items required}

### Phase 2 Candidates
{Items that would be added in a follow-up if Phase 1 succeeds.}
1. {Item}
2. {Item}

---

## 8. Dependencies, Risks, and Assumptions

| Type | Item | Impact | Owner | Mitigation |
|---|---|---|---|---|
| Dependency | {e.g., "Payment API v3 must be live"} | Blocks FR-003 | {Team/person} | {Fallback plan} |
| Risk | {e.g., "Third-party API rate limits may throttle bulk operations"} | Degrades FR-005 | {Owner} | {Caching, circuit breaker, etc.} |
| Assumption | {e.g., "Users have modern browsers (ES2020+)"} | Affects FR-001 | {Owner} | {Polyfill strategy or graceful degradation} |

### Assumption Rules
- Every assumption is a hidden risk. Surface it here or pay for it later.
- For each assumption, ask: "What happens if this is wrong?" If the answer is
  "we're screwed," it's a risk, not an assumption.

---

## 9. Vertical Slice Suggestions

| Slice | FRs Included | Layer Coverage | Phase | AFK Eligible | Estimated Complexity |
|---|---|---|---|---|---|
| {Slice name — e.g., "Tracer bullet: basic CRUD"} | FR-001, FR-002 | DB + API + UI + Test | Phase 0 (tracer bullet) | Yes | Small |
| {Slice name} | FR-003, FR-004 | API + UI + Test | Phase 1 | Partial | Medium |
| {Slice name} | FR-005 | DB + API + Test | Phase 2 | Yes | Large |

### Slice Rules
- **Phase 0 (tracer bullet):** The thinnest possible slice that proves the
  architecture works end-to-end. Should be 1-2 FRs maximum, touching every layer
  (database, API, UI, test). This slice de-risks the entire feature.
- **Subsequent phases:** Build on the tracer bullet. Each slice should deliver
  user-visible value, not just technical plumbing.
- **AFK Eligible column:** If all FRs in the slice are AFK-eligible, the entire
  slice can be delegated to an autonomous agent.

---

## 10. Success Metrics

| KPI | Baseline | Target | Measurement Method | Timeline |
|---|---|---|---|---|
| {e.g., "Task completion time"} | {Current: 12 min} | {Target: 3 min} | {Analytics event tracking} | {30 days post-launch} |
| {e.g., "Error rate"} | {Current: 8%} | {Target: < 1%} | {Error monitoring (Sentry)} | {14 days post-launch} |
| {e.g., "User adoption"} | {Current: 0} | {Target: 60% of eligible users} | {Feature flag analytics} | {60 days post-launch} |

### Metric Rules
- Every metric needs a **baseline** (where are we today?) and a **target** (where
  do we want to be?).
- Every metric needs a **measurement method** — if you can't measure it, you
  can't track it.
- Include a **timeline** — when do we expect to hit the target?

---

## 11. Open Questions

| # | Question | Impact | Owner | Target Date |
|---|---|---|---|---|
| 1 | {Unresolved question} | {What it blocks or affects} | {Who can answer} | {When we need an answer} |
| 2 | {Question} | {Impact} | {Owner} | {Date} |

---

## 12. Next Actions

| Action | Owner | Due Date | Blocked By |
|---|---|---|---|
| {e.g., "Review PRD with engineering lead"} | {Name} | {Date} | — |
| {e.g., "Confirm API rate limits with vendor"} | {Name} | {Date} | — |
| {e.g., "Begin Phase 0 tracer bullet implementation"} | {Name} | {Date} | PRD approval |
```

---

## Template Usage Notes

1. **Pipeline ID format:** Use `{feature-name}-{YYYYMMDD}`, e.g.,
   `user-notifications-20260403`. This ID is referenced by downstream tools.
2. **FR numbering:** Always sequential within a single PRD. Never reuse IDs.
   If an FR is removed during review, leave a gap — do not renumber.
3. **AFK eligibility:** Be conservative. When in doubt, mark `No`. It is better
   to have a human review an AFK-eligible FR than to have an agent struggle with
   an ambiguous one.
4. **Vertical slices:** The tracer bullet (Phase 0) is non-negotiable. Every PRD
   must have one. It is the single most important risk-reduction tool in
   incremental delivery.
5. **Out-of-scope minimum:** Three items. If the user insists nothing is out of
   scope, push back. A feature with no boundaries has no definition.
