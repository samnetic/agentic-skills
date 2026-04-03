---
name: refactor-plan
description: >-
  Create refactoring plans decomposed into tiny, individually-safe commits
  using the Mikado method. Each commit preserves all tests passing and the
  codebase in a working state. Classifies each step as AFK or HITL. Use when
  planning major refactors, migrations, or architectural changes. Triggers:
  plan a refactor, refactoring plan, migration plan, how to refactor this,
  break this refactor into steps, Mikado method, safe refactoring.
license: MIT
metadata:
  author: samnetic
  version: "1.0"
---

# Refactor Plan Skill

Every large refactoring is a sequence of tiny, safe changes. The goal is never
"rewrite everything in one shot" — it is "what is the smallest change I can make
right now that moves toward the target and keeps all tests green?"

---

## Core Principles

| Principle | Meaning |
|---|---|
| **Never break green** | Every single commit must leave the test suite passing and the app deployable |
| **One atomic move per commit** | Rename, extract, move, inline, or change signature — never two at once |
| **Work backwards from the goal** | Mikado method: attempt the goal, discover what blocks it, solve blockers first |
| **Classify AFK vs HITL** | Each step is tagged: AFK (autonomous, mechanical) or HITL (needs human judgment) |
| **Rollback checkpoints** | Identify safe stopping points where the refactor can be paused indefinitely |
| **Dependency-driven ordering** | Sequence commits so each one unlocks the next; no step depends on a future step |
| **Small diffs, fast reviews** | Each commit should be reviewable in under 2 minutes |

---

## Workflow: Refactor Planning

### Phase 1 — Accept Goal

Clearly state the refactoring objective in one sentence. Confirm:

- What is the desired end state?
- What is the motivation (tech debt, new feature enablement, performance, migration)?
- What is NOT in scope?
- Are there deadlines or constraints (feature freeze, release train)?

### Phase 2 — Analyze Current State

Map the territory before changing anything:

- **Dependency graph**: which modules, classes, and functions are involved?
- **Test coverage**: what is covered, what is not? Where are the gaps?
- **Hot paths**: which files change most frequently? (`git log --format=format: --name-only | sort | uniq -c | sort -rn | head -20`)
- **Coupling points**: where does the code-to-change touch external systems, APIs, or shared state?
- **Risk zones**: untested code, concurrency, shared mutable state, generated code

### Phase 3 — Identify Target State

Describe what the code should look like after the refactoring:

- New module/file structure
- Changed interfaces or contracts
- Removed dead code or deprecated paths
- New abstractions or patterns introduced

### Phase 4 — Decompose into Micro-Commits

Break the refactoring into the smallest possible atomic operations. Each commit
must be exactly ONE of the safe refactoring moves from the catalog:

| Move | Example |
|---|---|
| **Rename** | Rename function, variable, file, or module |
| **Extract** | Extract method, class, module, constant, or type |
| **Inline** | Inline a function, variable, or unnecessary abstraction |
| **Move** | Move function, class, or file to a new location |
| **Change signature** | Add/remove/reorder parameters; change return type |
| **Introduce interface** | Create an interface or type alias to decouple |
| **Replace algorithm** | Swap implementation behind a stable interface |
| **Add tests** | Add missing test coverage before making a change |
| **Delete dead code** | Remove unused functions, imports, types, or files |

### Phase 5 — Sequence Using Mikado Method

Order the micro-commits using the Mikado dependency tree:

1. Attempt the goal change mentally (or on a scratch branch)
2. Identify what breaks — these are **blockers**
3. For each blocker, identify what blocks *it* — recurse
4. The leaves of the tree are changes with zero blockers — start there
5. Work from leaves toward the root (the original goal)

```
Goal: Extract PaymentService from OrderController
├── Move payment logic to PaymentService        [blocked by: interface exists]
│   ├── Create PaymentService interface          [blocked by: types extracted]
│   │   ├── Extract PaymentResult type           [LEAF — start here]
│   │   └── Extract PaymentRequest type          [LEAF — start here]
│   └── Add tests for payment logic in isolation [blocked by: interface exists]
├── Update OrderController to use PaymentService [blocked by: service exists]
└── Remove old payment methods from controller   [blocked by: controller updated]
```

### Phase 6 — Classify AFK / HITL

Tag every commit in the plan:

| Tag | Meaning | Examples |
|---|---|---|
| **AFK** | Mechanical, deterministic, safe for autonomous execution | Rename, move file, extract constant, add re-export, delete unused import |
| **HITL** | Requires human judgment, design decisions, or domain knowledge | Choose interface shape, decide naming convention, resolve ambiguous ownership, change public API |

**Rule of thumb**: if a competent engineer would do it identically every time
without thinking, it is AFK. If two competent engineers might do it differently,
it is HITL.

### Phase 7 — Output Commit Plan

Produce the final ordered plan. Each entry contains:

1. **Step number** and **dependency** (which prior step it depends on)
2. **Atomic move** (from the catalog)
3. **Description** (what exactly changes)
4. **Files affected**
5. **AFK / HITL** classification
6. **Verification** (how to confirm this step is correct — test command or manual check)
7. **Rollback checkpoint** marker (if this is a safe stopping point)

See `references/commit-plan-template.md` for the output format.

---

## Decision Tree: Is This Step Safe?

```
Does this commit change observable behavior?
├─ YES
│  ├─ Is the behavior change covered by existing tests?
│  │  ├─ YES → Safe, but mark as HITL for review
│  │  └─ NO  → STOP. Add tests first (make that a preceding commit)
│  └─ Does it change a public API contract?
│     ├─ YES → HITL. Requires deprecation plan or versioning
│     └─ NO  → Proceed with test coverage
└─ NO (pure structural change, same behavior)
   ├─ Can automated tooling verify it? (compiler, tests, linter)
   │  ├─ YES → AFK
   │  └─ NO  → HITL (manual verification needed)
   └─ Proceed
```

---

## Progressive Disclosure Map

| Topic | Reference | When to read |
|---|---|---|
| Mikado method with tree diagram walkthrough | `references/mikado-method.md` | When learning or applying the Mikado dependency decomposition |
| Catalog of atomic refactoring moves | `references/safe-refactoring-catalog.md` | When choosing which move to apply for a specific commit |
| Commit plan output template | `references/commit-plan-template.md` | When formatting the final deliverable |

---

## Trigger Conditions

Activate this skill when the user asks to:

- Plan a refactoring or migration
- Break a large change into safe steps
- Apply the Mikado method
- Decompose a refactor into commits
- Create a step-by-step refactoring plan
- Understand the order of changes for a refactor
- Classify refactoring steps as autonomous or human-required

---

## Execution Protocol

1. **Read the codebase first** — understand the current state before proposing changes
2. **Never skip Phase 2** — analysis before planning prevents wasted commits
3. **One move per commit** — resist the urge to combine "while I'm here" changes
4. **Tests gate every step** — if tests don't pass, the step is wrong
5. **Mark rollback checkpoints** — at least every 3-5 commits, identify a safe parking spot
6. **Surface unknowns early** — if a step has unclear risk, mark it HITL and flag it

---

## Quality Gates

| Gate | Criteria |
|---|---|
| **Completeness** | Every file touched in the refactor appears in at least one commit |
| **Ordering** | No commit depends on a future commit; dependency graph is a DAG |
| **Atomicity** | Each commit is exactly one refactoring move |
| **Green guarantee** | Each commit description includes a verification command |
| **AFK/HITL coverage** | Every commit is classified; no untagged steps |
| **Rollback points** | At least one checkpoint every 5 commits |
| **Scope discipline** | No commit introduces new features or fixes unrelated bugs |

---

## Anti-Patterns

| Anti-Pattern | Why It Fails | Fix |
|---|---|---|
| Big-bang rewrite | Untestable, unreviewable, high risk of regression | Decompose into 10-50 micro-commits |
| Refactor + feature in one PR | Impossible to review, impossible to bisect | Separate PRs: refactor first, then feature |
| Skipping test coverage | No safety net; you will break things silently | Add characterization tests before any structural change |
| Optimistic ordering | "It should work if we do X first" without checking | Build the Mikado tree; let dependencies dictate order |
| Combining moves | "Rename and move in one commit" | One move per commit — rename first, then move |
| Ignoring rollback points | 30 commits in and something is wrong; where do you stop? | Mark checkpoints; verify the codebase is shippable at each |
| All-AFK plans | Marking judgment calls as AFK leads to bad autonomous decisions | Be honest — design decisions are always HITL |
| Refactoring without a goal | "Let's clean this up" with no target state | Define the goal first; refactor toward something specific |

---

## Delivery Checklist

- [ ] Goal is stated in one sentence
- [ ] Current state is analyzed (deps, coverage, hot paths, risk zones)
- [ ] Target state is described (structure, interfaces, removed code)
- [ ] Mikado dependency tree is drawn
- [ ] Every step is one atomic refactoring move
- [ ] Steps are ordered by dependency (leaves first, goal last)
- [ ] Every step is classified AFK or HITL
- [ ] Every step has a verification command
- [ ] Rollback checkpoints are marked (at least every 5 commits)
- [ ] No step combines multiple refactoring moves
- [ ] No step introduces new features or unrelated fixes
- [ ] Plan is formatted using the commit plan template
