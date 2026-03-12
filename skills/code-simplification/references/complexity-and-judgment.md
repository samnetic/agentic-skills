# Complexity Metrics & Refactoring Judgment

## Table of Contents

- [Cognitive Complexity vs Cyclomatic Complexity](#cognitive-complexity-vs-cyclomatic-complexity)
  - [What's the Difference?](#whats-the-difference)
  - [Measuring Complexity](#measuring-complexity)
  - [Complexity Targets](#complexity-targets)
- [Complexity Measurement Commands](#complexity-measurement-commands)
- [When NOT to Simplify](#when-not-to-simplify)
- [When NOT to Refactor — Expanded](#when-not-to-refactor--expanded)

---

## Cognitive Complexity vs Cyclomatic Complexity

### What's the Difference?

```typescript
// Cyclomatic complexity counts decision points (if, else, while, for, &&, ||)
// Cognitive complexity weights NESTED structures higher — matches human difficulty

// Example: Both have cyclomatic complexity ~4, but different cognitive complexity

// LOW cognitive complexity (flat structure, easy to read)
function processA(input: Input): Result {
  if (!input.valid) return { error: 'invalid' };       // +1
  if (!input.data) return { error: 'no data' };        // +1
  if (input.data.length === 0) return { error: 'empty' }; // +1
  return process(input.data);                           // +1 (call)
}
// Cognitive complexity: 3 (flat, no nesting penalty)

// HIGH cognitive complexity (deeply nested, hard to follow)
function processB(input: Input): Result {
  if (input.valid) {                                    // +1
    if (input.data) {                                   // +2 (nesting!)
      if (input.data.length > 0) {                      // +3 (more nesting!)
        return process(input.data);
      }
    }
  }
  return { error: 'failed' };
}
// Cognitive complexity: 6 (nesting penalties compound)
```

### Measuring Complexity

```bash
# ESLint plugin for cognitive complexity (recommended)
npm install -D eslint-plugin-sonarjs

# .eslintrc or eslint.config.js
{
  "plugins": ["sonarjs"],
  "rules": {
    "sonarjs/cognitive-complexity": ["error", 15],  // Max 15 per function
    "complexity": ["error", 10],                     // Cyclomatic max 10
  }
}

# Run:
npx eslint --rule '{"sonarjs/cognitive-complexity": ["error", 15]}' src/

# The sonarjs plugin also catches:
# - Duplicate string literals
# - Identical functions
# - Collapsible if statements
# - Unused collection operations
```

### Complexity Targets

| Metric | Good | Acceptable | Refactor Now |
|---|---|---|---|
| Cognitive complexity | ≤ 8 | 9-15 | > 15 |
| Cyclomatic complexity | ≤ 5 | 6-10 | > 10 |
| Function length | ≤ 20 lines | 21-30 | > 30 |
| Nesting depth | ≤ 2 | 3 | > 3 |

---

## Complexity Measurement Commands

```bash
# Measure cyclomatic complexity
npx eslint --rule '{"complexity": ["error", 10]}' src/  # Max 10 paths per function

# Count function length
npx eslint --rule '{"max-lines-per-function": ["warn", 30]}' src/

# Count nesting depth
npx eslint --rule '{"max-depth": ["warn", 3]}' src/

# Find duplicate code
npx jscpd src/ --min-lines 5 --min-tokens 50
```

**Additional targets:**
- Cyclomatic complexity per function: ≤ 10
- Lines per function: ≤ 30
- Nesting depth: ≤ 3
- Parameters per function: ≤ 3
- File length: ≤ 300 lines

---

## When NOT to Simplify

| Situation | Why to Leave It Alone |
|---|---|
| Working code with good tests | Don't refactor for aesthetics |
| Performance-critical hot path | Clarity may be traded for speed (with comments explaining why) |
| Domain complexity (not code complexity) | Complex business rules need complex code — simplify the code, not the rules |
| Three similar lines | Don't abstract until the third occurrence |
| External API integration | Adapters are inherently messy — isolate, don't simplify |

---

## When NOT to Refactor — Expanded

### 1. The code works and isn't being changed

If nobody is reading or modifying it, refactoring adds risk for zero benefit. "If it ain't broke, don't fix it" applies to stable, tested code.

### 2. You're creating abstractions for one use case

A function called from one place doesn't need an interface. An abstraction is only justified when there are 2+ concrete implementations. "But we might need it later" = YAGNI. Delete and recreate when you actually need it.

### 3. The refactoring is premature optimization

Don't optimize code that runs once during startup. Don't optimize code that takes 1ms when the API call takes 200ms. Profile first. Only optimize actual bottlenecks.

### 4. You're in the middle of a feature

Refactoring and feature work in the same PR = guaranteed merge conflicts. Note it, create a ticket, come back after the feature ships.

### 5. You don't have tests

Refactoring without tests = rolling the dice. Write tests first (characterization tests), then refactor.
