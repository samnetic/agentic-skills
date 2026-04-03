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
license: MIT
metadata:
  author: samnetic
  version: "1.0"
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

## Workflow

### 1. Gather Context

Read the PR description, linked issues, and related tickets. Understand the WHY before reading any code. If context is missing, ask the author before starting a detailed review.

### 2. Big-Picture Scan (5 min)

Evaluate the overall approach before diving into lines:
- Does the architecture make sense for this change?
- Are files organized logically?
- Is the scope appropriate (no unrelated changes mixed in)?
- Should this PR be split? (>400 lines is a red flag)

### 3. Detailed Line-by-Line Review (15 min)

Walk through every changed file. For each change, evaluate:
- **Correctness**: Does the logic handle edge cases (null, empty, zero, max, negative)?
- **Security**: Input validation, parameterized queries, auth checks on new endpoints, no hardcoded secrets
- **Performance**: N+1 queries, unbounded collections, missing pagination, blocking operations
- **Maintainability**: Clear names, focused functions, no dead code, helpful error messages

Use severity labels on every comment (see Comment Severity Labels below).

### 4. Assess Tests

- Do tests exist for new functionality?
- Do they cover both happy path AND error paths?
- Are edge cases tested (empty, null, boundary values)?
- Are tests independent (no shared mutable state)?
- Do test names describe the expected behavior?
- Would tests survive a refactor (no implementation details tested)?

### 5. Write Summary

Produce a structured summary with clear action items:

```markdown
## Review Summary

**Overall**: Approve / Request Changes / Comment

### Blocking Issues
1. [File:line] Description — suggested fix

### Important
1. [File:line] Description — why it matters

### Suggestions
1. [File:line] Description — alternative approach

### Praise
- What was done well and why it's good

### Missing
- [ ] What should be added before merge
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

---

## Progressive Disclosure Map

| Topic | Reference | When to read |
|---|---|---|
| Detailed checklists (correctness, security, performance, maintainability, testing, architecture) | `references/review-checklists-and-automation.md#review-checklist-by-category` | When you need category-specific review checklists for thorough line-by-line review |
| CI/CD automation (GitHub Actions, Danger.js, SonarQube) | `references/review-checklists-and-automation.md#review-automation` | When setting up or improving automated PR checks before human review |
| AI-generated code review | `references/review-checklists-and-automation.md#reviewing-ai-generated-code` | When reviewing code produced by LLMs — hallucinated APIs, phantom imports, plausible-but-wrong logic |
| Self-review checklist for PR authors | `references/review-checklists-and-automation.md#self-review-checklist` | Before requesting review — what authors should verify first |
| PR splitting strategies (vertical slices, stacked PRs) | `references/review-workflows-and-language-tips.md#pr-splitting-strategies` | When a PR exceeds 400 lines or mixes concerns |
| Review turnaround and async patterns | `references/review-workflows-and-language-tips.md#review-turnaround-guidelines` | When establishing team review SLAs or improving review speed |
| Language-specific tips (TypeScript, Python, SQL) | `references/review-workflows-and-language-tips.md#language-specific-review-tips` | When reviewing code in a specific language — common pitfalls and patterns to watch for |
| Review summary template | `references/review-workflows-and-language-tips.md#review-summary-template` | When writing a structured review summary with severity-grouped findings |

---

## Quick Checklist

- [ ] Read PR description and linked issues before any code
- [ ] Big-picture scan: architecture, scope, file organization
- [ ] Line-by-line: correctness, security, performance, maintainability
- [ ] Tests: exist, cover happy + error paths, independent, descriptive names
- [ ] Every comment has a severity label: `[blocking]`, `[important]`, `[suggestion]`, `[nit]`, `[question]`, `[praise]`
- [ ] At least one `[praise]` comment for something done well
- [ ] Summary with blocking issues, suggestions, and missing items
- [ ] PR < 400 lines (if not, ask to split)
- [ ] Review completed within 4 hours of request

---

## Pipeline-Aware Review Mode

When reviewing a PR linked to a pipeline issue (contains "Closes #N" or
references a pipeline-generated issue), apply these additional checks:

### Acceptance Criteria Verification
- [ ] Every acceptance criterion from the linked issue is covered by a test
- [ ] Tests use Given/When/Then structure matching the issue's criteria
- [ ] No acceptance criterion is missing test coverage

### Vertical Slice Completeness
- [ ] PR touches all layers specified in the issue (DB, API, UI, tests)
- [ ] No layer was skipped or deferred without justification
- [ ] Changes are self-contained within the vertical slice

### Pipeline Consistency
- [ ] PR title includes `[Phase N]` prefix matching the issue's phase
- [ ] Branch name follows `feature/{pipeline-id}/{issue-number}-{slug}` convention
- [ ] PR body links to the original issue
- [ ] No changes outside the scope of the linked issue

### AFK Review Gate
- For `agent:afk` issues: verify the agent followed TDD (tests written before implementation)
- For `agent:hitl` issues: verify the human-judgment decision was documented
