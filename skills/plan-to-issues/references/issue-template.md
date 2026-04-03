# Issue Template

Use this template for every issue created from an implementation plan.

## Title Format

```
[Phase X] Slice: {slice name}
```

**Examples:**
- `[Phase 0] Slice: Tracer bullet — create and display todo item`
- `[Phase 1] Slice: User CRUD — registration and profile endpoints`
- `[Phase 2] Slice: Dashboard — aggregated metrics view`

Keep titles under 80 characters. The phase prefix enables sorting; the slice name describes the deliverable.

## Body Template

```markdown
## Context

{1-2 sentence summary of what this slice delivers and why it matters.
Focus on the user-facing or system-level outcome, not implementation details.}

**Pipeline:** {pipeline-id}
**Phase:** {phase number} — {phase name}
**Classification:** {AFK (high) | AFK (medium) | HITL} — {rationale referencing decision tree question}

## Acceptance Criteria

- [ ] **Given** {precondition}, **When** {action}, **Then** {expected result}
- [ ] **Given** {precondition}, **When** {action}, **Then** {expected result}
- [ ] **Given** {precondition}, **When** {action}, **Then** {expected result}

## Implementation Hints

| Layer | What to Build |
|---|---|
| Database | {tables, columns, migrations, indexes, constraints} |
| Backend | {endpoints, services, business logic, validations} |
| Frontend | {components, pages, data flow, state management} |
| Tests | {test types and what to cover — unit, integration, e2e} |

> **Note:** These are hints, not prescriptions. The implementer may deviate if
> they find a better approach, as long as acceptance criteria are still met.

## Dependencies

{If no dependencies:}
None — this issue can be started immediately.

{If dependencies exist:}
Blocked by:
- #123 — {slice name and what it provides that this issue needs}
- #124 — {slice name and what it provides that this issue needs}

## Functional Requirements Covered

{List FR IDs from the PRD that this slice addresses:}
- **FR-001** — {brief description}
- **FR-003** — {brief description}

## Verification Checklist

- [ ] All acceptance criteria pass
- [ ] Tests written and passing (unit + integration minimum)
- [ ] No regressions in existing tests
- [ ] Code follows existing patterns in the codebase
- [ ] PR description links back to this issue (`Closes #N`)
```

## Template Usage Notes

### Context section
- Keep it to 1-2 sentences maximum
- Explain the "what" and "why", never the "how"
- A reader should understand the value of this slice without reading the full plan

### Acceptance criteria
- Every criterion must be independently verifiable
- Use Given/When/Then format for behavioral criteria
- Use declarative statements for structural criteria (e.g., "Migration creates `users` table with columns: ...")
- Aim for 3-7 criteria per issue; more suggests the slice is too large

### Implementation hints
- Omit layers that do not apply (e.g., skip Frontend for a pure backend slice)
- Include enough detail for an agent to start without asking questions
- Reference patterns already in the codebase rather than inventing new ones

### Dependencies
- Always include the slice name alongside the issue number for human readability
- Explain **what** the dependency provides, not just that it exists
- If a dependency is soft (nice-to-have ordering, not a hard blocker), note it as such

### Functional requirements
- Map every FR covered by this slice; this enables traceability back to the PRD
- If an FR is partially covered, note which aspects this slice handles
