---
name: code-simplification
description: >-
  Code simplification, refactoring, and clean code expertise. Use when reducing code
  complexity, applying SOLID principles, extracting functions or classes, removing dead
  code, simplifying conditional logic, reducing cyclomatic complexity, applying design
  patterns appropriately, performing refactoring (rename, extract, inline, move),
  simplifying error handling, reducing nesting depth, eliminating code duplication
  with appropriate abstractions, identifying over-engineering, applying YAGNI principle,
  reducing cognitive load, or reviewing code for unnecessary complexity.
  Triggers: simplify, refactor, clean code, complexity, SOLID, YAGNI, DRY, KISS,
  dead code, code smell, cyclomatic complexity, extract function, inline, nesting,
  over-engineering, abstraction, design pattern, single responsibility, dependency
  injection, clean architecture, technical debt, readability.
---

# Code Simplification Skill

The best code is the code you don't write. The second best is code that's so simple
it obviously has no bugs, rather than code so complex it has no obvious bugs.

---

## Core Principles

| Principle | Meaning |
|---|---|
| **KISS** | Keep It Simple. The simplest solution that works is the best solution |
| **YAGNI** | You Aren't Gonna Need It. Don't build for hypothetical futures |
| **Rule of Three** | Duplicate once. Abstract on the third occurrence |
| **Reduce cognitive load** | Reader should understand any function in <30 seconds |
| **Delete > Refactor > Write** | Removing code is the best improvement |
| **Boring code is good code** | Clever code is a liability |

---

## Workflow: Simplification

1. **IDENTIFY** — What is complex? Use metrics, code smells, or gut feel to locate the problem
2. **QUESTION** — Is this complexity necessary? Can we delete the code entirely?
3. **PLAN** — What is the minimal change to reduce complexity? Pick one refactoring pattern
4. **REFACTOR** — Apply one refactoring at a time; tests must be green after each change
5. **VERIFY** — Is it actually simpler? Fewer lines, less nesting, clearer names, lower cognitive complexity

---

## Decision Trees

### Should I Refactor This Code?

```
Is the code actively causing bugs or blocking a feature?
├─ YES → Refactor now (it's blocking value delivery)
└─ NO
   ├─ Will you modify this code in the current task?
   │  ├─ YES → Apply Boy Scout Rule (leave it better than you found it)
   │  └─ NO → Don't touch it (YAGNI — refactoring stable code adds risk)
   └─ Is test coverage sufficient to refactor safely?
      ├─ YES → Refactor in a separate PR (don't mix with feature work)
      └─ NO → Write characterization tests first, then refactor
```

### Which Refactoring Pattern?

```
What's the code smell?
├─ Long function (>30 lines) → Extract Method
├─ Deep nesting (>3 levels) → Early Return / Guard Clauses
├─ Switch on type → Replace Conditional with Polymorphism
├─ Duplicated logic (3+ copies) → Extract and parameterize
├─ God class (>300 lines) → Extract Class by responsibility
├─ Feature envy (method uses another object's data) → Move Method
├─ Primitive obsession (raw strings for IDs, emails) → Value Object / Branded Type
└─ Shotgun surgery (one change touches 5+ files) → Inline / consolidate
```

---

## Code Smells and Fixes

| Code Smell | Sign | Refactoring |
|---|---|---|
| **Long function** (>30 lines) | Scrolling, multiple responsibilities | Extract functions with descriptive names |
| **Deep nesting** (>3 levels) | Arrow code, complex conditions | Early returns, guard clauses |
| **Primitive obsession** | Passing 5 strings that belong together | Create a value object / type |
| **Long parameter list** (>3 params) | Hard to call, easy to mix up | Options object |
| **Feature envy** | Method uses another object's data more than its own | Move method to that object |
| **Dead code** | Unreachable, commented-out, unused | Delete it. Git has history |
| **Magic numbers** | `if (status === 3)` | Named constant: `if (status === OrderStatus.SHIPPED)` |
| **Boolean parameters** | `createUser(data, true, false)` — what do they mean? | Options object or separate functions |
| **Shotgun surgery** | Change one feature = edit 10 files | Consolidate related code into one module |
| **God class/module** | 500+ lines, does everything | Extract focused modules |

---

## SOLID Principles (Practical, Not Dogmatic)

| Principle | Practical Meaning | When To Apply |
|---|---|---|
| **S** — Single Responsibility | A function/class should have one reason to change | When a function does 2+ unrelated things |
| **O** — Open/Closed | Extend behavior without modifying existing code | When you keep adding cases to a switch/if chain |
| **L** — Liskov Substitution | Subtypes must be substitutable for their base types | When using inheritance (prefer composition) |
| **I** — Interface Segregation | Don't force clients to depend on methods they don't use | When interfaces get >5 methods |
| **D** — Dependency Inversion | Depend on abstractions, not concrete implementations | When you need to swap implementations (DB, email, etc.) |

**Important**: SOLID is a tool, not a religion. Apply when it reduces complexity. Don't apply when it adds complexity for no benefit.

---

## Anti-Patterns

| Anti-Pattern | Why It's Dangerous | Fix |
|---|---|---|
| Premature abstraction | Abstracts the wrong thing, harder to change | Wait for the third occurrence |
| Over-engineering | Factories, strategies, decorators for simple code | YAGNI — simplest solution first |
| Clever code | One-liners that take 5 minutes to understand | Write boring, readable code |
| Comments explaining what | `// increment counter` before `counter++` | Self-documenting code, comments for WHY |
| Wrapper hell | Wrapping everything "for flexibility" | Direct usage until wrapper is needed |
| Design patterns as goals | "We need a Strategy pattern here" | Patterns emerge from needs, not vice versa |
| DRY obsession | Abstracting 2 similar but different things | Duplication is cheaper than wrong abstraction |
| Config-driven everything | 200-line config file instead of 20 lines of code | Code is configuration. Use code |
| Big-bang refactoring | Rewriting entire modules in one PR | Incremental: strangler fig, feature flags |
| Refactoring without tests | No safety net to catch regressions | Write characterization tests first |

---

## Progressive Disclosure Map

| Topic | Reference | When to read |
|---|---|---|
| Refactoring patterns with code examples | `references/refactoring-patterns.md` | When applying a specific refactoring (guard clauses, extract function, polymorphism, switch-to-map, etc.) |
| Coupling reduction (DI, interface segregation, circular deps) | `references/refactoring-patterns.md#coupling-reduction` | When reducing tight coupling, improving testability, or breaking circular dependencies |
| Incremental refactoring (strangler fig, feature flags, parallel run) | `references/refactoring-patterns.md#incremental-refactoring` | When refactoring a large or risky codebase incrementally |
| Cognitive vs cyclomatic complexity explained | `references/complexity-and-judgment.md` | When measuring or comparing code complexity metrics |
| Complexity measurement commands (ESLint, jscpd) | `references/complexity-and-judgment.md#complexity-measurement-commands` | When setting up linting rules or running complexity analysis |
| When NOT to simplify or refactor | `references/complexity-and-judgment.md#when-not-to-simplify` | Before starting a refactoring effort, to check if it is justified |

---

## Checklist: Simplification Review

- [ ] No function exceeds 30 lines
- [ ] No nesting deeper than 3 levels (use guard clauses)
- [ ] No function has more than 3 parameters
- [ ] No dead code, commented-out code, or unused imports
- [ ] No magic numbers (use named constants)
- [ ] No boolean parameters (use options objects or separate functions)
- [ ] Complex conditions extracted into named functions
- [ ] Each module has a clear, single purpose
- [ ] Abstractions are justified by actual usage (not theoretical future use)
- [ ] Code reads top-to-bottom without jumping around
- [ ] Cognitive complexity ≤ 15 per function (eslint-plugin-sonarjs)
- [ ] Switch/if chains on type fields replaced with strategy maps where appropriate
- [ ] Dependencies are injected, not hardcoded (for external services)
- [ ] No circular dependencies between modules
- [ ] Refactoring is incremental (one PR per transformation, not big-bang)
