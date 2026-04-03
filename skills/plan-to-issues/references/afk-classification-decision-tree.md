# AFK/HITL Classification Decision Tree

Every issue must be classified as AFK (autonomous agent can complete) or HITL (requires human judgment). Use this tree for each issue.

## Decision Tree

```
Is this issue safe for autonomous agent execution?

1. Does it touch authentication, authorization, or session management?
   ├─ YES → HITL (security-sensitive, needs human review)
   └─ NO → continue

2. Does it touch payment processing, billing, or financial data?
   ├─ YES → HITL (financial-sensitive, needs human review)
   └─ NO → continue

3. Does it handle PII (personally identifiable information)?
   ├─ YES → HITL (privacy-sensitive, needs human review)
   └─ NO → continue

4. Does it require design decisions not already made in the plan?
   ├─ YES → HITL (ambiguous, needs human judgment)
   └─ NO → continue

5. Are the acceptance criteria unambiguous and testable?
   ├─ NO → HITL (unclear scope, needs human clarification)
   └─ YES → continue

6. Does it modify shared infrastructure (CI/CD, deployment, monitoring)?
   ├─ YES → HITL (blast radius too high for autonomous)
   └─ NO → continue

7. Is it a pure CRUD operation with clear schema?
   ├─ YES → AFK (high confidence)
   └─ NO → continue

8. Is it a pure refactoring with existing test coverage?
   ├─ YES → AFK (high confidence)
   └─ NO → continue

9. Is it a new feature with clear vertical slice and acceptance criteria?
   ├─ YES → AFK (medium confidence, PR review required)
   └─ NO → HITL (default conservative)
```

## Confidence Levels

| Classification | Confidence | Meaning |
|---|---|---|
| AFK (high) | Agent can complete and merge with minimal review | CRUD, refactoring with tests, well-defined utilities |
| AFK (medium) | Agent can complete but PR needs careful human review | New features with clear specs |
| HITL | Human must be involved in decisions or review | Security, payments, PII, ambiguous scope, infra |

## How to Apply

For each issue, walk through the questions **in order** (1 through 9). Stop at the first question that produces a terminal answer. Record which question determined the classification.

**Example walkthrough:**

> Issue: "[Phase 1] Slice: Add pagination to /api/todos endpoint"
> 1. Auth/sessions? No
> 2. Payments/billing? No
> 3. PII? No
> 4. Unmade design decisions? No (plan specifies cursor-based pagination)
> 5. Acceptance criteria testable? Yes
> 6. Shared infra? No
> 7. Pure CRUD? No (it modifies query behavior)
> 8. Pure refactoring? No
> 9. New feature with clear slice? Yes
> **Result: AFK (medium) — Question 9**

## Override Rules

- If the plan already classified an issue, respect it **unless** the decision tree clearly disagrees
- When overriding, document the reason: "Plan tagged as AFK, but reclassified to HITL because it touches user sessions (Question 1)"
- When in doubt, default to HITL — it is cheaper to over-review than to miss a security issue

## Edge Cases

| Scenario | Classification | Rationale |
|---|---|---|
| Database migration that adds a non-sensitive column | AFK (high) | Pure schema change, no security/PII concern |
| Database migration that adds RLS policies | HITL | Touches authorization (Question 1) |
| Adding a new API endpoint for public data | AFK (medium) | New feature with clear slice (Question 9) |
| Adding rate limiting to existing endpoints | HITL | Shared infrastructure concern (Question 6) |
| Writing tests for existing untested code | AFK (high) | Pure test addition, similar to refactoring (Question 8) |
| Integrating a third-party OAuth provider | HITL | Authentication-sensitive (Question 1) |
| UI component with no data dependencies | AFK (high) | Pure presentational, similar to CRUD (Question 7) |
| Refactoring with no existing tests | HITL | No safety net; risk of undetected regressions (Question 9 → NO) |
