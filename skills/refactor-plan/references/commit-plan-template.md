# Commit Plan Template

Standard output format for a refactoring plan decomposed into safe, atomic
commits. Each commit preserves all tests passing and keeps the codebase
deployable.

---

## Header

```markdown
# Refactoring Plan: {Goal}

**Goal:** {One-sentence description of the desired end state}
**Scope:** {Files/modules/packages affected}
**Estimated commits:** {N}
**Estimated time:** {hours or days}
**Risk level:** {low | medium | high}
**Prerequisites:** {Any branches to merge, tests to write, or approvals needed first}
```

---

## Commit Table

```markdown
## Commits

| # | Summary | Files | Type | AFK? | Depends On | Est. |
|---|---------|-------|------|------|------------|------|
| 1 | {What this commit does} | {file list or count} | {move/rename/extract/simplify/data} | {yes/no} | {commit #s or "none"} | {min} |
| 2 | Extract validateOrder from OrderService | src/order-service.ts | extract | yes | none | 10m |
| 3 | Move validateOrder to src/validation/order.ts | 2 files | move | yes | #2 | 5m |
| 4 | Replace inline auth check with AuthGuard | 4 files | extract | no | none | 20m |
```

### Column Definitions

- **#**: Sequential commit number. Commits execute in this order.
- **Summary**: Imperative mood, under 72 characters. Becomes the commit message.
- **Files**: Files touched or count if many. Helps estimate review effort.
- **Type**: Refactoring category from the safe-refactoring-catalog.md.
- **AFK?**: Whether an autonomous agent can execute this safely without human
  review. "yes" = fully mechanical, "no" = requires judgment or HITL review.
- **Depends On**: Which prior commits must be completed first. Use "none" for
  independent commits. Independent commits with no dependencies can be
  parallelized.
- **Est.**: Time estimate for a developer familiar with the codebase.

---

## Commit Detail Blocks

For complex commits (AFK = no, or touching 5+ files), add a detail block:

```markdown
### Commit #4: Replace inline auth check with AuthGuard

**Rationale:** Auth logic is duplicated in 4 route handlers with slight
variations. Extracting to a shared guard ensures consistent behavior and
reduces the surface area for auth bugs.

**Steps:**
1. Create `src/middleware/auth-guard.ts` with the canonical auth check
2. Replace inline check in `src/routes/orders.ts`
3. Replace inline check in `src/routes/invoices.ts`
4. Replace inline check in `src/routes/shipments.ts`
5. Replace inline check in `src/routes/returns.ts`
6. Delete the old `checkAuth` helper in `src/utils/auth.ts`

**Verification:**
- Run `npm test` — all 47 auth-related tests must pass
- Run `npm run lint` — no new warnings
- Manual: attempt unauthenticated request to each endpoint

**Rollback:** `git revert {commit-hash}` — safe because this commit is
self-contained.

**Why not AFK:** The 4 inline checks have subtle differences (one checks
admin role, others don't). Human must verify the guard handles all cases.
```

---

## Dependency Graph (Optional)

For plans with complex dependencies, include an ASCII dependency graph:

```markdown
## Dependency Graph

    [1] Extract validateOrder
     │
     ▼
    [2] Move to validation/
     │
     ├──► [3] Update imports in OrderService
     │
     └──► [4] Update imports in OrderController
            │
            ▼
           [5] Remove old validation code
```

Commits at the same depth with no arrow between them can run in parallel.

---

## Risk Register

```markdown
## Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| ORM config references old class name | Medium | Tests break | grep for string references before renaming |
| Dynamic import breaks at runtime | Low | Runtime error | Add integration test before starting |
| Merge conflict with in-flight PRs | High | Delay | Coordinate with team, merge dependent PRs first |
```

---

## Completion Checklist

```markdown
## Completion Checklist

- [ ] All commits applied in order
- [ ] Full test suite passes after final commit
- [ ] No TODO/FIXME comments left from the refactoring
- [ ] Code review completed for HITL commits
- [ ] Documentation updated if public API changed
- [ ] Glossary updated if domain terms were renamed
```
