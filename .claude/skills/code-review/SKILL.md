---
name: code-review
description: >-
  Code review and PR review expertise. Use when reviewing pull requests, providing
  code review feedback, assessing code quality, checking for code smells, evaluating
  naming conventions, reviewing error handling, assessing test coverage adequacy,
  performing architecture reviews, checking security implications of changes,
  evaluating performance impact of changes, writing review comments with proper
  severity labels, or establishing code review processes and guidelines.
  Triggers: code review, PR review, pull request review, review feedback, code smell,
  code quality, refactor suggestion, naming convention, dead code, complexity, review
  checklist, approve, request changes, nit, blocking.
---

# Code Review Skill

Code review is a conversation, not a gatekeeping exercise. The goal is better code
AND knowledge sharing. Be specific, be kind, be helpful.

---

## Core Principles

| Principle | Meaning |
|---|---|
| **Review the code, not the person** | "This function could be clearer" not "You wrote this poorly" |
| **Explain the why** | Don't just say "change this" — explain the reasoning |
| **Distinguish severity** | Blocking issues vs suggestions vs nits |
| **Praise good work** | Call out well-designed code, clever solutions, good tests |
| **Timely reviews** | Review within 4 hours. PR author is blocked until you respond |
| **Small PRs, better reviews** | >400 lines = rubber stamp risk |

---

## Review Process

```
1. CONTEXT   → Read PR description, linked issues, understand the WHY
2. BIG PICTURE → Architecture, approach, file organization (5 min)
3. DETAILED  → Line-by-line: logic, security, performance, edge cases (15 min)
4. TESTS     → Are the tests meaningful? What's missing?
5. SUMMARY   → Overall assessment with clear action items
```

---

## Comment Severity Labels

**Always prefix comments with severity:**

| Label | Meaning | Action Required |
|---|---|---|
| `[blocking]` | Must fix before merge. Bug, security issue, data loss risk | Fix required |
| `[important]` | Should fix. Design issue, maintainability concern | Fix strongly recommended |
| `[suggestion]` | Consider this alternative. Take it or leave it | Optional |
| `[nit]` | Minor style/formatting. Don't block merge for this | Optional |
| `[question]` | Need clarification. Don't understand intent | Answer required |
| `[praise]` | This is well done. Call out good patterns | No action |

### Examples

```
[blocking] This query is vulnerable to SQL injection.
User input is interpolated directly into the query string.
Use parameterized queries instead:
`db.query('SELECT * FROM users WHERE id = $1', [userId])`

[important] This function has 5 parameters. Consider using an options
object to improve readability:
`function createUser(options: CreateUserOptions)`

[suggestion] You could simplify this with optional chaining:
`const name = user?.profile?.displayName ?? 'Anonymous'`

[nit] Typo in variable name: `recieved` → `received`

[question] Why is this timeout set to 60 seconds? Is that based
on a measured requirement or a guess?

[praise] Great use of discriminated unions here — this makes
invalid states impossible at the type level.
```

---

## Review Checklist by Category

### Correctness

- [ ] Does the code do what the PR description says?
- [ ] Are edge cases handled (empty arrays, null, zero, negative, max values)?
- [ ] Are error paths handled (network failure, invalid input, timeout)?
- [ ] Is the logic correct? (trace through mentally with sample inputs)
- [ ] Are off-by-one errors possible (loop boundaries, pagination)?
- [ ] Are race conditions possible (async operations, shared state)?

### Security

- [ ] No hardcoded secrets, tokens, or passwords
- [ ] Input validated and sanitized at boundaries
- [ ] SQL uses parameterized queries (no string interpolation)
- [ ] No `dangerouslySetInnerHTML` without sanitization
- [ ] Auth/authz checks on new endpoints
- [ ] Sensitive data not logged or exposed in errors

### Performance

- [ ] No N+1 query patterns (check ORM usage)
- [ ] Large collections are paginated
- [ ] No unnecessary database queries in loops
- [ ] New indexes added for new query patterns
- [ ] Expensive operations are cached (if appropriate)
- [ ] No blocking operations on the event loop

### Maintainability

- [ ] Code is readable without comments (self-documenting)
- [ ] Functions/methods are focused (single responsibility)
- [ ] Names are clear and consistent (no abbreviations, no x/tmp/data)
- [ ] No dead code, commented-out code, or TODOs without tickets
- [ ] Duplication is reasonable (DRY, but don't over-abstract)
- [ ] Error messages are helpful for debugging

### Testing

- [ ] Tests exist for new functionality
- [ ] Tests cover happy path AND error paths
- [ ] Tests are independent (no shared mutable state)
- [ ] Test names describe the expected behavior
- [ ] Edge cases have tests (empty, null, boundary values)
- [ ] No implementation details tested (tests survive refactoring)

### Architecture

- [ ] Changes align with existing patterns in the codebase
- [ ] New abstractions are justified (not premature)
- [ ] Dependencies flow in the right direction
- [ ] Module boundaries are respected
- [ ] Public API surface is minimal (don't export more than needed)

---

## Review Automation

### Automated Checks That Should Run Before Human Review

```yaml
# .github/workflows/pr-checks.yml
name: PR Checks
on: [pull_request]

jobs:
  lint-format:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npm ci
      - run: npx eslint . --max-warnings 0     # Zero warnings policy
      - run: npx prettier --check .             # Formatting check
      - run: npx tsc --noEmit                   # Type checking

  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npm ci
      - run: npx vitest run --coverage          # Tests + coverage
```

### Danger.js — Automate PR Conventions

```typescript
// dangerfile.ts — runs in CI, comments on PRs automatically
import { danger, warn, fail, message } from 'danger';

// PR too large — warn the author
const changedLines = danger.github.pr.additions + danger.github.pr.deletions;
if (changedLines > 400) {
  warn(`This PR has ${changedLines} changed lines. Consider splitting it.`);
}

// No PR description
if (!danger.github.pr.body || danger.github.pr.body.length < 20) {
  fail('Please add a PR description explaining what this change does and why.');
}

// New dependencies added — flag for review
const packageChanged = danger.git.modified_files.includes('package.json');
if (packageChanged) {
  warn('`package.json` was modified. Please verify new dependencies are necessary.');
}

// Test files missing for new source files
const newSrcFiles = danger.git.created_files.filter(f => f.startsWith('src/') && !f.includes('.test.'));
const newTestFiles = danger.git.created_files.filter(f => f.includes('.test.'));
if (newSrcFiles.length > 0 && newTestFiles.length === 0) {
  warn('New source files added without corresponding test files.');
}

// Migration without rollback
const hasMigration = danger.git.created_files.some(f => f.includes('migration'));
if (hasMigration) {
  message('This PR includes a database migration. Ensure it is safe for zero-downtime deploy.');
}
```

### SonarQube Quality Gates

```
Quality gate thresholds (recommended):
├── Coverage on new code: ≥ 80%
├── Duplicated lines on new code: ≤ 3%
├── Maintainability rating: A (technical debt ratio < 5%)
├── Reliability rating: A (no bugs)
├── Security rating: A (no vulnerabilities)
└── Security hotspots reviewed: 100%

Benefits:
- Blocks merge if quality drops below threshold
- Catches issues that humans miss consistently
- Provides objective quality metrics over time
- Reduces review fatigue — humans focus on logic, machines catch patterns
```

---

## Reviewing AI-Generated Code

AI-generated code requires extra scrutiny. LLMs produce plausible-looking code that may be subtly wrong.

### What to Watch For

| Issue | What It Looks Like | How to Catch It |
|---|---|---|
| **Hallucinated APIs** | Calling methods/functions that don't exist | Verify every API call against actual docs/types |
| **Phantom imports** | Importing from packages not in `package.json` | Check imports against installed dependencies |
| **Outdated patterns** | Using deprecated APIs or old syntax | Verify against current framework version |
| **Overly complex solutions** | 50 lines where 5 would do | Ask: "Is there a simpler way?" |
| **Missing error handling** | Happy path only, no try/catch, no edge cases | Check every async call, every external interaction |
| **Security vulnerabilities** | No input validation, SQL interpolation, XSS | Apply security checklist with extra care |
| **Incorrect types** | `any` everywhere, wrong type assertions | Check that types actually match runtime behavior |
| **Plausible but wrong logic** | Code reads well but produces wrong results | Trace through with concrete inputs manually |
| **Missing context** | Doesn't account for existing patterns in codebase | Compare against similar existing code in the repo |
| **Over-commenting** | Comments that restate the code verbatim | Remove comments that don't explain "why" |

### AI Code Review Checklist

```markdown
- [ ] Every import resolves to a real, installed package
- [ ] Every API/method call exists in the actual library version we use
- [ ] No `any` types unless truly unavoidable (with justification comment)
- [ ] Error handling exists for all failure modes
- [ ] The solution isn't more complex than necessary
- [ ] Code follows existing patterns in this specific codebase
- [ ] Edge cases are handled (null, empty, max values, concurrent access)
- [ ] Tests actually test the behavior, not just that the code runs
- [ ] No hardcoded values that should be configurable
- [ ] The code has been traced through with at least 2 concrete inputs
```

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

## Self-Review Checklist

What PR authors should do BEFORE requesting review:

```markdown
## Before Requesting Review

### Basics
- [ ] I re-read my own diff line by line
- [ ] PR description explains WHAT changed and WHY
- [ ] PR is linked to the relevant issue/ticket
- [ ] PR title is descriptive (not "fix stuff" or "WIP")
- [ ] No debug code left (console.log, TODO, FIXME without ticket)
- [ ] No unrelated changes included (formatting-only changes in other files)

### Code Quality
- [ ] I considered at least one alternative approach
- [ ] New functions/modules have clear, descriptive names
- [ ] Complex logic has a comment explaining WHY (not what)
- [ ] No copied code that should be shared

### Testing
- [ ] Tests pass locally
- [ ] New code has tests
- [ ] I tested the happy path manually
- [ ] I tested at least one error path manually

### Risk Assessment
- [ ] I identified the riskiest part of this change
- [ ] Database migrations are backwards compatible
- [ ] No breaking changes to public APIs (or they're documented)
- [ ] Feature is behind a flag if it's not ready for all users

### Reviewer Experience
- [ ] PR is < 400 lines (or I've explained why it can't be split)
- [ ] I added inline comments on tricky parts to guide the reviewer
- [ ] Screenshots/recordings for UI changes
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

---

## Anti-Patterns

| Anti-Pattern | Why It's Dangerous | Fix |
|---|---|---|
| Rubber stamp ("LGTM") | Misses bugs, no knowledge transfer | Actually read the code |
| Blocking on style nits | Frustrates authors, slows delivery | Label as `[nit]`, don't block |
| Reviewing after 2+ days | Blocks author, context switch | Review within 4 hours |
| Rewriting the PR in comments | Disrespectful, should be a conversation | Suggest direction, not dictation |
| No severity labels | Author doesn't know what to fix first | Always use [blocking]/[suggestion]/[nit] |
| Reviewing 1000+ line PRs | Can't catch bugs in large diffs | Ask to split into smaller PRs |
| Only finding problems | Demoralizing | Include `[praise]` for good patterns |
| "I would have done it differently" | Not actionable unless there's a concrete problem | Only suggest changes for real issues |
| Skipping AI-generated code review | AI code looks correct but may have subtle issues | Apply AI-specific checklist with extra care |
| No self-review before requesting | Wastes reviewer time on obvious issues | Authors must self-review first |
