# Comparison Matrix Template

Use this template during Phase 4 to evaluate all design proposals systematically.
Score each criterion 1-5. Justify every score with a specific observation from
the design — no scores without evidence.

## Scoring Rubric

### Ergonomics (How natural is it for consumers?)

| Score | Meaning |
|-------|---------|
| 5 | Consumer code reads like pseudocode; intent is obvious; IDE autocomplete guides usage |
| 4 | Minor friction; one or two non-obvious patterns to learn |
| 3 | Workable but requires reading docs for common operations |
| 2 | Verbose or surprising; consumers will make mistakes without examples |
| 1 | Actively hostile; easy to misuse, hard to use correctly |

### Type Safety (How many errors does the compiler catch?)

| Score | Meaning |
|-------|---------|
| 5 | Illegal states are unrepresentable; invalid call sequences are type errors |
| 4 | Most domain errors are compile-time; occasional runtime checks remain |
| 3 | Basic type checking; stringly-typed or `any` in a few places |
| 2 | Types exist but are loose; many runtime errors possible |
| 1 | Effectively untyped; `any`, `object`, or raw strings throughout |

### Testability (Can each operation be tested in isolation?)

| Score | Meaning |
|-------|---------|
| 5 | Pure functions or dependency-injected; zero mocks needed for unit tests |
| 4 | One or two dependencies to mock; straightforward test setup |
| 3 | Testable but requires non-trivial setup or fixtures |
| 2 | Tightly coupled; mocking is painful but possible |
| 1 | Cannot test without spinning up external services |

### Extensibility (How easy to add new operations or behaviors?)

| Score | Meaning |
|-------|---------|
| 5 | New behavior is a new file/class; zero existing code changes |
| 4 | One touchpoint to register a new behavior |
| 3 | Moderate changes in 2-3 places to add a new operation |
| 2 | Requires modifying core abstractions; risk of breaking existing code |
| 1 | Closed design; new operations require rewriting existing code |

### Depth Ratio (Small interface hiding significant complexity?)

| Score | Meaning |
|-------|---------|
| 5 | Tiny surface area (3-5 methods) hiding substantial implementation logic |
| 4 | Compact interface with good abstraction; some internals leak |
| 3 | Interface size is proportional to complexity (neither deep nor shallow) |
| 2 | Large interface relative to what it does; mostly pass-through |
| 1 | Shallow wrapper; interface is as complex as the implementation |

### Consistency (Does it match existing codebase patterns?)

| Score | Meaning |
|-------|---------|
| 5 | Feels native to the codebase; uses established patterns and conventions |
| 4 | Mostly consistent; introduces one new pattern with justification |
| 3 | Mixed; some conventions followed, some new patterns |
| 2 | Largely different from codebase norms; requires team education |
| 1 | Contradicts established patterns; would confuse existing contributors |

## Matrix Template

Copy and fill in for each evaluation:

```markdown
| Criterion       | Design A: [Name] | Design B: [Name] | Design C: [Name] |
|-----------------|-------------------|-------------------|-------------------|
| Ergonomics      | X — [reason]      | X — [reason]      | X — [reason]      |
| Type safety     | X — [reason]      | X — [reason]      | X — [reason]      |
| Testability     | X — [reason]      | X — [reason]      | X — [reason]      |
| Extensibility   | X — [reason]      | X — [reason]      | X — [reason]      |
| Depth ratio     | X — [reason]      | X — [reason]      | X — [reason]      |
| Consistency     | X — [reason]      | X — [reason]      | X — [reason]      |
| **Total**       | **XX/30**         | **XX/30**         | **XX/30**         |
```

## Analysis Prompts

After scoring, answer these questions:

1. **Convergent ideas** — Which concepts appear in 2+ designs? These are high-confidence elements that should appear in the final recommendation.
2. **Unique strengths** — What did only one design surface? Is it worth incorporating?
3. **Deal-breakers** — Does any design score 1-2 on a criterion the project considers critical? If so, eliminate it or note the required fix.
4. **Surprising tradeoffs** — Where did optimizing for one constraint unexpectedly improve or harm another dimension?
5. **Depth winner** — Which design has the best depth ratio? This is often the strongest starting point for synthesis.
