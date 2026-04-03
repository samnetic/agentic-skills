# Safe Refactoring Catalog

A catalog of refactoring moves that are individually safe — each preserves all
existing tests and behavior. Use this when decomposing a refactoring plan into
atomic commits.

---

## Structural Moves

### Extract Function / Method

**What:** Pull a block of code into a named function.
**Safe when:** The extracted code has no side effects on local variables that
remain in the caller, or all such variables are passed as parameters and
returned.
**Commit message pattern:** `refactor: extract {functionName} from {source}`
**Risk level:** Low. Automated tooling can do this reliably.
**AFK-eligible:** Yes

### Inline Function / Method

**What:** Replace a function call with the function body.
**Safe when:** The function is called from exactly one place, or when inlining
eliminates indirection without changing behavior.
**Commit message pattern:** `refactor: inline {functionName} into {target}`
**Risk level:** Low.
**AFK-eligible:** Yes

### Extract Class / Module

**What:** Move a group of related fields and methods into a new class or module.
**Safe when:** The extracted group has a clear cohesion boundary and all
references are updated.
**Commit message pattern:** `refactor: extract {ClassName} from {source}`
**Risk level:** Medium. Cross-file reference updates can be missed.
**AFK-eligible:** Yes, with grep verification step

### Move Function / Method

**What:** Relocate a function from one module to another.
**Safe when:** All call sites are updated and no circular dependencies are
introduced.
**Commit message pattern:** `refactor: move {functionName} from {source} to {target}`
**Risk level:** Medium.
**AFK-eligible:** Yes, with import verification

---

## Rename Moves

### Rename Variable / Parameter

**What:** Change a variable name to better reflect its purpose.
**Safe when:** All references within scope are updated. For exported symbols,
all consumers must be updated.
**Commit message pattern:** `refactor: rename {old} to {new} in {scope}`
**Risk level:** Low for local scope. Medium for exported symbols.
**AFK-eligible:** Yes

### Rename Type / Class

**What:** Change a type or class name.
**Safe when:** All references (imports, type annotations, documentation) are
updated in the same commit.
**Commit message pattern:** `refactor: rename {OldType} to {NewType}`
**Risk level:** Medium. String-based references (ORM configs, serialization)
can be missed.
**AFK-eligible:** Yes, with string-search verification

### Rename File / Module

**What:** Change a file name to match its contents or conventions.
**Safe when:** All imports referencing the old path are updated.
**Commit message pattern:** `refactor: rename {old-file} to {new-file}`
**Risk level:** Medium. Dynamic imports and config references can be missed.
**AFK-eligible:** Yes, with grep for old filename

---

## Simplification Moves

### Replace Conditional with Polymorphism

**What:** Convert a switch/if-else chain into polymorphic dispatch.
**Safe when:** All branches are covered by the new type hierarchy and existing
tests still pass.
**Commit message pattern:** `refactor: replace {condition} switch with polymorphism`
**Risk level:** High. Behavior changes can be subtle.
**AFK-eligible:** No — requires HITL review

### Remove Dead Code

**What:** Delete code that is never reached or called.
**Safe when:** Verified unreachable via static analysis, grep, and test coverage.
**Commit message pattern:** `refactor: remove unused {functionName/className}`
**Risk level:** Low if verified. High if guessed.
**AFK-eligible:** Yes, with static analysis verification

### Simplify Boolean Expression

**What:** Reduce a complex conditional to a simpler equivalent.
**Safe when:** Truth table equivalence is verified or tests cover all branches.
**Commit message pattern:** `refactor: simplify conditional in {location}`
**Risk level:** Medium. Edge cases in boolean logic are common mistake sources.
**AFK-eligible:** Yes, if test coverage is comprehensive

---

## Data Moves

### Introduce Parameter Object

**What:** Replace multiple function parameters with a single object.
**Safe when:** All call sites are updated to pass the object.
**Commit message pattern:** `refactor: introduce {ParamObject} for {functionName}`
**Risk level:** Low.
**AFK-eligible:** Yes

### Replace Primitive with Value Object

**What:** Wrap a primitive type (string, number) in a domain-specific type.
**Safe when:** All construction and comparison sites are updated.
**Commit message pattern:** `refactor: replace {primitive} with {ValueObject}`
**Risk level:** Medium. Equality semantics may change.
**AFK-eligible:** Yes, with type-checker verification

### Change Function Signature

**What:** Add, remove, or reorder parameters.
**Safe when:** All call sites are updated. Use a two-phase approach for breaking
changes: add new signature -> migrate callers -> remove old signature.
**Commit message pattern:** `refactor: update {functionName} signature`
**Risk level:** High for widely-used functions. Low for internal functions.
**AFK-eligible:** Depends on blast radius

---

## Safety Verification Checklist

After each refactoring commit, verify:

- [ ] All existing tests pass (no red tests introduced)
- [ ] No new compiler/type-checker errors
- [ ] No new linter warnings related to the changed code
- [ ] `git diff --stat` shows only expected files changed
- [ ] No behavioral changes visible in manual smoke test (if applicable)
- [ ] The commit can be reverted independently without breaking other commits
