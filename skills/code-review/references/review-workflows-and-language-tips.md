# Review Workflows and Language-Specific Tips

## Table of Contents

- [PR Splitting Strategies](#pr-splitting-strategies)
  - [Strategy 1: Vertical Slices](#strategy-1-vertical-slices)
  - [Strategy 2: Refactor-Then-Feature](#strategy-2-refactor-then-feature)
  - [Strategy 3: Stacked PRs](#strategy-3-stacked-prs)
  - [When to Split](#when-to-split)
- [Review Turnaround Guidelines](#review-turnaround-guidelines)
  - [Response Time Expectations](#response-time-expectations)
  - [Prioritizing Reviews](#prioritizing-reviews)
  - [Async Review Patterns](#async-review-patterns)
- [Reviewing Different Types of Changes](#reviewing-different-types-of-changes)
  - [Bug Fixes](#bug-fixes)
  - [New Features](#new-features)
  - [Refactoring](#refactoring)
  - [Dependencies](#dependencies)
- [How to Give Good Feedback](#how-to-give-good-feedback)
- [Language-Specific Review Tips](#language-specific-review-tips)
  - [TypeScript](#typescript)
  - [Python](#python)
  - [SQL](#sql)
- [Review Summary Template](#review-summary-template)

---

## PR Splitting Strategies

When a PR exceeds 400 lines, review quality drops sharply. Split it.

### Strategy 1: Vertical Slices

```
Original: "Add user profile feature" (800 lines)

Split into:
  PR 1: Database schema + migration (100 lines)
  PR 2: API endpoint + tests (150 lines)
  PR 3: UI component + tests (200 lines)
  PR 4: Integration + E2E tests (100 lines)

Each PR is independently deployable and reviewable.
```

### Strategy 2: Refactor-Then-Feature

```
Original: "Refactor auth module and add SSO" (600 lines)

Split into:
  PR 1: Refactor auth module (pure refactor, no behavior change) (250 lines)
  PR 2: Add SSO support (new feature on clean foundation) (200 lines)

Rule: Never mix refactoring and feature work in the same PR.
Refactoring PRs should have NO test changes (behavior preserved).
```

### Strategy 3: Stacked PRs

```
For features that build on each other:

  PR 1: Base infrastructure (merged first)
    ↓
  PR 2: Core feature (based on PR 1)
    ↓
  PR 3: Polish and edge cases (based on PR 2)

Tools:
- gh pr create --base feature/step-1   (stack PR 2 on PR 1)
- Graphite (graphite.dev) — manages stacked PR workflows
- git-town — git extension for stacked branches
```

### When to Split

| Signal | Action |
|---|---|
| PR > 400 lines changed | Split into smaller units |
| PR touches > 10 files | Likely doing too many things |
| PR has refactoring + new features | Separate into refactor PR and feature PR |
| Review takes > 30 minutes | PR is too large for effective review |
| Multiple unrelated changes | Each change should be its own PR |

---

## Review Turnaround Guidelines

### Response Time Expectations

| PR Size | Target Review Time | Rationale |
|---|---|---|
| Small (< 100 lines) | < 2 hours | Quick to review, unblocks author fast |
| Medium (100-400 lines) | < 4 hours | Standard review, same business day |
| Large (400+ lines) | < 8 hours | Needs more time, but don't let it sit overnight |
| Urgent/hotfix | < 1 hour | Production issues take priority |

### Prioritizing Reviews

```
Review priority order:
1. Hotfixes and production incidents
2. PRs that block other team members
3. PRs that have been waiting the longest (FIFO)
4. Small PRs (quick to review, quick to unblock)
5. Large PRs (schedule dedicated time)
```

### Async Review Patterns

```markdown
## For distributed/async teams:

- Set "review hours" — e.g., first hour of your day is for reviews
- Use draft PRs for early feedback (before the PR is "done")
- Batch nits — collect all minor feedback in one pass, don't drip-feed
- Use "approve with comments" for nit-only feedback — don't block
- If a review will take > 30 min, acknowledge the PR and give an ETA:
  "I'll review this thoroughly by end of day"
- Use PR templates to reduce back-and-forth:
  "I tested this by..." saves the reviewer from asking
```

---

## Reviewing Different Types of Changes

### Bug Fixes
1. Does the PR include a regression test that fails without the fix?
2. Is the root cause identified (not just symptoms patched)?
3. Are there similar bugs elsewhere in the codebase?
4. Does the fix handle the edge case that caused the bug?

### New Features
1. Does the implementation match the requirements?
2. Is the feature flag-gated if it's not ready for all users?
3. Is the migration safe for zero-downtime deploy?
4. Is the API design consistent with existing endpoints?
5. Are there tests for the happy path and error paths?

### Refactoring
1. Is behavior preserved? (Are there tests to prove it?)
2. Is the refactoring isolated from new features? (Separate PRs)
3. Is the new structure actually simpler/clearer?
4. Are test changes minimal? (If tests change a lot, behavior may have changed)

### Dependencies
1. Is the new dependency necessary? (Can we use what we have?)
2. Is it actively maintained? (Last commit, open issues, bus factor)
3. What's the bundle size impact?
4. Are there known vulnerabilities? (`npm audit`)
5. Is the license compatible?

---

## How to Give Good Feedback

### DO

```
"Consider extracting this into a helper function — it appears in 3 places
and the logic is identical each time."

"This works, but `Map` would be more efficient than `Array.find()` here
since you're doing lookups in a loop. O(1) vs O(n) per lookup."

"Nice pattern! I'm going to use this approach in the payments module too."
```

### DON'T

```
"This is wrong."                     → No explanation of what or why
"I wouldn't do it this way."         → Not actionable
"Can you refactor this?"             → What specifically? Why?
"LGTM"                               → Not a review, just a rubber stamp
"This whole file needs rewriting."   → Too vague, demoralizing
```

---

## Language-Specific Review Tips

### TypeScript

```typescript
// Watch for:

// 1. `any` type — defeats the purpose of TypeScript
// BAD:
function processData(data: any): any { ... }
// GOOD:
function processData(data: UserInput): ProcessedResult { ... }

// 2. Type assertions hiding bugs
// BAD:
const user = data as User;  // What if data isn't actually a User?
// GOOD:
const user = userSchema.parse(data);  // Runtime validation with Zod

// 3. Non-null assertion operator (!)
// BAD:
const name = user.profile!.name!;  // Crashes if null
// GOOD:
const name = user.profile?.name ?? 'Anonymous';

// 4. Enums (prefer discriminated unions)
// BAD:
enum Status { Active, Inactive }  // Compiles to runtime object
// GOOD:
type Status = 'active' | 'inactive';  // Zero runtime cost

// 5. Missing return type on public APIs
// BAD:
export function getUser(id: string) { ... }  // Return type inferred, can change accidentally
// GOOD:
export function getUser(id: string): Promise<User> { ... }  // Explicit contract
```

### Python

```python
# Watch for:

# 1. Missing type hints on public functions
# BAD:
def process_order(order, user):
    ...
# GOOD:
def process_order(order: Order, user: User) -> ProcessedOrder:
    ...

# 2. Mutable default arguments
# BAD:
def add_item(item: str, items: list[str] = []) -> list[str]:
    items.append(item)  # Mutates the default!
    return items
# GOOD:
def add_item(item: str, items: list[str] | None = None) -> list[str]:
    if items is None:
        items = []
    items.append(item)
    return items

# 3. async correctness — forgetting to await
# BAD:
async def process():
    fetch_data()  # Returns a coroutine, never executed!
# GOOD:
async def process():
    await fetch_data()

# 4. Bare except clauses
# BAD:
try:
    risky_operation()
except:  # Catches SystemExit, KeyboardInterrupt too!
    pass
# GOOD:
try:
    risky_operation()
except SpecificError as e:
    logger.error("Operation failed", exc_info=e)
    raise
```

### SQL

```sql
-- Watch for:

-- 1. N+1 queries — check ORM-generated SQL
-- Look at query logs during code review, not just the ORM code

-- 2. Missing indexes on foreign keys and WHERE columns
-- Every foreign key should have an index
-- Every column in a WHERE clause used in production queries needs one

-- 3. SELECT * in production code
-- BAD:
SELECT * FROM users WHERE id = $1;
-- GOOD:
SELECT id, name, email FROM users WHERE id = $1;

-- 4. Unbounded queries
-- BAD:
SELECT * FROM events WHERE created_at > '2024-01-01';
-- GOOD:
SELECT id, type, created_at FROM events
WHERE created_at > '2024-01-01'
ORDER BY created_at DESC
LIMIT 100;

-- 5. Missing transaction for multi-step operations
-- BAD: two separate queries that should be atomic
UPDATE accounts SET balance = balance - 100 WHERE id = 1;
UPDATE accounts SET balance = balance + 100 WHERE id = 2;
-- GOOD:
BEGIN;
UPDATE accounts SET balance = balance - 100 WHERE id = 1;
UPDATE accounts SET balance = balance + 100 WHERE id = 2;
COMMIT;
```

---

## Review Summary Template

```markdown
## Review Summary

**Overall**: Approve / Request Changes / Comment

### Blocking Issues
1. [File:line] SQL injection in search handler — use parameterized query
2. [File:line] Missing auth check on DELETE endpoint

### Important
1. [File:line] N+1 query in user listing — consider batch loading
2. [File:line] Error silently swallowed — should be logged and re-thrown

### Suggestions
1. [File:line] Consider using `Map` for O(1) lookups instead of `Array.find`
2. [File:line] This could be simplified with optional chaining

### Praise
- Great test coverage on the edge cases
- Clean separation of concerns in the service layer

### Missing
- [ ] Tests for error path (what happens when external API is down?)
- [ ] Migration rollback script
```
