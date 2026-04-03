# The Mikado Method

A structured approach to large-scale refactoring that keeps the codebase
working at every step. Named after the Mikado game where you remove sticks
without disturbing others.

---

## Core Idea

Instead of attempting a large refactoring in one shot (which inevitably breaks
things), you:

1. **Try** the change you want to make
2. **Observe** what breaks
3. **Record** the prerequisites (what must change first)
4. **Revert** your attempt
5. **Work bottom-up** from the leaves of the dependency graph

The result is a tree of small, safe changes executed in leaf-first order.

## The Mikado Graph

```
[Goal: Rename Order to PurchaseOrder]
├── [Update OrderService references]
│   ├── [Update OrderController imports]
│   └── [Update OrderRepository interface]
├── [Update database migration]
│   └── [Add column alias for backward compat]
└── [Update API response DTOs]
    ├── [Add v2 endpoint with new name]
    └── [Deprecate v1 endpoint]
```

Each node is a single, safe commit. Work from leaves upward.

## Step-by-Step Process

### 1. State the Goal

Write the desired end state as a single sentence:
> "Extract payment processing from OrderService into a dedicated PaymentService."

### 2. Naive Attempt

Make the change directly. Don't worry about breaking things — this is
exploratory. Note every compilation error, test failure, and runtime issue.

### 3. Record Prerequisites

For each failure, create a node in the Mikado graph:
- What file/class/function needs to change?
- What is the specific change needed?
- What does this change depend on?

### 4. Revert Everything

`git checkout .` — Return to a clean state. The naive attempt was purely
for information gathering.

### 5. Solve Leaves First

Find nodes with no children (no prerequisites). These can be done safely
right now without breaking anything.

### 6. Commit Each Leaf

Each leaf node becomes one commit. After the commit:
- All tests still pass
- The codebase is in a deployable state
- No feature behavior has changed

### 7. Repeat

After committing leaves, their parent nodes may now have no remaining
prerequisites. Those become the new leaves. Continue until you reach the goal.

## When to Use Mikado

- Renaming a widely-used concept across the codebase
- Extracting a module or service from a monolith
- Replacing a library or framework dependency
- Changing a data model that touches many layers
- Any refactoring where "just do it" has failed before

## When NOT to Use Mikado

- Small, localized changes (just make the change)
- Greenfield code (no dependency graph to untangle)
- Changes that can be done with automated codemods in one pass

## Common Mistakes

1. **Skipping the revert** — Trying to "fix forward" from the naive attempt
   leads to the tangled state Mikado is designed to prevent.
2. **Nodes too large** — If a node takes more than 30 minutes, break it down
   further.
3. **Missing prerequisites** — If a leaf commit breaks tests, you missed a
   prerequisite. Add it to the graph and revert.
4. **Goal drift** — The Mikado graph is for one specific goal. Don't add
   "while I'm here" improvements — those are separate graphs.

## Integration with Refactor-Plan Skill

The refactor-plan skill uses the Mikado method as follows:
- Phase 1 (Analyze) corresponds to steps 1-3 (Goal, Naive Attempt, Record)
- Phase 2 (Decompose) corresponds to building the Mikado graph
- Phase 3 (Order) corresponds to leaf-first ordering
- Phase 4 (Classify) adds AFK/HITL labels to each node
- Phase 5 (Output) produces the commit plan from the graph
