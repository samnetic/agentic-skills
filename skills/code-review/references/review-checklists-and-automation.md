# Review Checklists and Automation

## Table of Contents

- [Review Checklist by Category](#review-checklist-by-category)
  - [Correctness](#correctness)
  - [Security](#security)
  - [Performance](#performance)
  - [Maintainability](#maintainability)
  - [Testing](#testing)
  - [Architecture](#architecture)
- [Review Automation](#review-automation)
  - [Automated Checks Before Human Review](#automated-checks-before-human-review)
  - [Danger.js — Automate PR Conventions](#dangerjs--automate-pr-conventions)
  - [SonarQube Quality Gates](#sonarqube-quality-gates)
- [Reviewing AI-Generated Code](#reviewing-ai-generated-code)
  - [What to Watch For](#what-to-watch-for)
  - [AI Code Review Checklist](#ai-code-review-checklist)
- [Self-Review Checklist](#self-review-checklist)

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

### Automated Checks Before Human Review

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
