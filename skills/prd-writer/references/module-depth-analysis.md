# Module Depth Analysis

A framework for assessing module quality during PRD module design (Phase 4).
Based on John Ousterhout's "A Philosophy of Software Design" — the single most
useful lens for evaluating whether a proposed module boundary is good or bad.

## The Core Idea

A module's value is the complexity it hides minus the complexity of its
interface. The best modules have **small interfaces** that hide **significant
implementation complexity**. The worst modules have **large interfaces** that
hide **almost nothing**.

```
Module Value = Implementation Complexity - Interface Complexity
```

- **High value (deep module):** The module does a lot of work behind a simple
  API. Users of the module get enormous benefit for a tiny learning cost.
- **Low value (shallow module):** The module's interface is nearly as complex as
  its implementation. Using it isn't much simpler than doing the work yourself.

## Deep Modules (Goal)

A deep module has a small, simple interface that hides significant internal
complexity. This is the design goal.

### Characteristics

- **Few public methods or endpoints** — typically 3-7 for a module, 1-3 for a
  focused service.
- **Few parameters per method** — each method takes the minimum input needed.
- **Rich internal behavior** — behind the simple interface, the module handles
  validation, caching, error recovery, retry logic, data transformation,
  permission checks, logging, and more.
- **Stable interface** — the public API rarely changes even as internals are
  refactored or optimized.

### Examples

| Module | Interface | Hidden Complexity | Why It's Deep |
|---|---|---|---|
| `FileSystem.read(path)` | 1 method, 1 param | Disk I/O, caching, permissions, encoding, buffering, error handling | Tiny interface hides an entire storage subsystem |
| `AuthService.authenticate(credentials)` | 1 method, 1 param | Password hashing, rate limiting, session creation, MFA check, audit logging, account lockout | Caller doesn't know or care about the 15 internal steps |
| `PaymentProcessor.charge(order)` | 1 method, 1 param | Provider selection, retry logic, idempotency, fraud checks, webhook registration, receipt generation | Enormous complexity behind a single call |
| `SearchIndex.query(term, filters)` | 1 method, 2 params | Tokenization, stemming, ranking, pagination, caching, typo tolerance, faceting | Complex retrieval engine with a simple query interface |
| `NotificationService.send(recipient, event)` | 1 method, 2 params | Channel selection (email/SMS/push), template rendering, delivery tracking, retry queue, preference checks | Multi-channel delivery hidden behind one call |

### Why Deep Modules Win

1. **Lower cognitive load** — engineers using the module learn one simple API
   instead of understanding all the internal complexity.
2. **Easier to change** — internals can be refactored without breaking callers.
3. **Better testability** — test the interface, mock the module. Internal tests
   cover the hidden complexity independently.
4. **Natural AFK boundaries** — a deep module with a clear interface is easy to
   spec as an autonomous work unit.

## Shallow Modules (Warning)

A shallow module has a large interface relative to the complexity it hides. It
forces callers to understand nearly as much as the implementer.

### Characteristics

- **Many public methods** — 10+ methods, many of which are simple pass-throughs
  or trivial wrappers.
- **Many parameters** — methods require the caller to provide most of the
  information the module needs, leaving little for the module to figure out.
- **Thin implementation** — each method does one simple thing (a single
  validation, a single database call, a single transformation).
- **Leaky interface** — internal concepts (database column names, external API
  response shapes) appear in the public API.

### Examples

| Module | Interface | Implementation | Why It's Shallow |
|---|---|---|---|
| `UserFormValidator` with 20 methods | `validateEmail()`, `validatePhone()`, `validateName()`, ... (20 methods) | Each method: one regex check | The caller must know which validators to call and in what order — the module hides almost nothing |
| `DatabaseWrapper` that mirrors SQL | `select()`, `insert()`, `update()`, `delete()`, `join()`, `where()`, ... | Each method builds one SQL clause | The caller still thinks in SQL — the wrapper adds complexity without removing it |
| `ApiClient` with one method per endpoint | `getUser()`, `updateUser()`, `deleteUser()`, `listUsers()`, `getUserPrefs()`, ... | Each method: one HTTP call | A thin wrapper over REST that doesn't hide HTTP concepts (pagination, error codes, retry) |
| `ConfigManager` with get/set for every field | `getTimeout()`, `setTimeout()`, `getRetryCount()`, `setRetryCount()`, ... | Each method: read/write one config value | The caller must know every config field — the module is just a glorified dictionary |

### Red Flags for Shallow Modules

1. **Pass-through modules** — the module receives a call and immediately forwards
   it to another module with minimal transformation. It adds a layer of
   indirection without adding value.

2. **God interfaces** — a module with 15+ public methods. If you need that many
   entry points, the module is probably doing too many unrelated things (split
   it) or not doing enough internally (merge it).

3. **Decorator disease** — wrapping a module just to add logging, metrics, or
   validation that could be handled by middleware or aspects. Each decorator is
   a shallow module.

4. **Method-per-field** — a module that exposes a getter/setter for every
   internal field. This is a data structure pretending to be a module.

5. **Mirror interfaces** — the module's interface is identical to the interface
   of the thing it wraps. If `UserService` has the same methods as `UserRepository`,
   one of them is unnecessary.

## Depth Assessment Framework

Use this framework during Phase 4 to evaluate each proposed module.

### Step 1: Count the Interface

For each module, count:
- Number of public methods or endpoints
- Average number of parameters per method
- Number of distinct types/concepts exposed in the interface

**Score:**
- **Small** (1-5 methods, 1-3 params each) — good
- **Medium** (6-10 methods, 3-5 params each) — acceptable
- **Large** (11+ methods, or 5+ params on average) — warning

### Step 2: Assess the Implementation

For each module, estimate:
- Lines of non-trivial implementation logic
- Number of internal branches (if/else, error handling, retry logic)
- Number of external dependencies managed internally (APIs, caches, queues)
- Number of cross-cutting concerns handled (auth, logging, validation, rate limiting)

**Score:**
- **High** (100+ lines of logic, 5+ branches, 2+ external deps) — good
- **Medium** (50-100 lines, 3-5 branches) — acceptable
- **Low** (< 50 lines, 1-2 branches, no external deps) — warning

### Step 3: Compute Depth Rating

| Interface Size | Implementation Complexity | Depth Rating | Action |
|---|---|---|---|
| Small | High | **Deep** | Keep as-is. This is the goal. |
| Small | Medium | **Moderate** | Acceptable. Look for opportunities to absorb more responsibility. |
| Medium | High | **Moderate** | Acceptable. Look for opportunities to simplify the interface. |
| Medium | Medium | **Moderate** | Fine, but watch for interface growth. |
| Medium | Low | **Shallow** | Warning. Consider merging into an adjacent module. |
| Large | High | **Moderate** | The complexity is real, but the interface is too big. Split into 2-3 deep modules. |
| Large | Medium | **Shallow** | Merge or split. This module is not earning its keep. |
| Large | Low | **Shallow** | Eliminate. Merge into the caller or an adjacent module. |
| Small | Low | **Shallow** | Too trivial to be its own module. Inline it. |

### Step 4: Check for Red Flags

For each module rated Shallow or Moderate, check:

- [ ] Is this a pass-through that just forwards calls?
- [ ] Does the interface mirror the interface of what it wraps?
- [ ] Could this be middleware, a decorator, or configuration instead of a module?
- [ ] Does the caller need to understand the module's internals to use it correctly?

If any answer is "yes," the module boundary is probably wrong.

## Applying Depth to PRD Module Design

When designing modules in Phase 4 of the PRD workflow:

1. **Start with responsibilities, not names.** List what the feature must do
   internally (validate, store, notify, transform, authorize). Group related
   responsibilities into modules.

2. **Design the interface first.** For each module, write the 2-3 method
   signatures a caller would use. If you need more than 5, you're probably
   grouping the wrong things.

3. **Verify depth.** Ask: "Is the implementation behind this interface
   significantly more complex than the interface itself?" If not, merge the
   module into a neighbor.

4. **Map FRs to modules.** Each FR should map to exactly one module. If an FR
   spans multiple modules, either the FR is too coarse (split it) or the module
   boundaries are wrong (adjust them).

5. **Prefer fewer, deeper modules.** Three deep modules are better than seven
   shallow ones. Every module boundary is a coordination point — minimize them.

## Decision Heuristic

> **If the module's interface is larger than its implementation, it's probably
> shallow — consider merging it into an adjacent module.**

This single heuristic catches 80% of bad module boundaries. Apply it ruthlessly.

## Module Depth in the PRD Table

Record your assessment in the Module Design table:

```markdown
| Module | Interface Size | Implementation Complexity | Depth Rating | Responsibility |
|---|---|---|---|---|
| AuthModule | Small (2 methods: login, verify) | High (password hashing, rate limiting, MFA, session management, audit log) | Deep | Authenticate users and manage sessions |
| NotificationModule | Small (1 method: send) | High (channel routing, template rendering, delivery tracking, retry queue) | Deep | Deliver notifications across email, SMS, and push |
| UserPrefsModule | Large (12 getter/setter methods) | Low (read/write JSONB column) | Shallow | Store user preferences — MERGE into UserModule |
```

When a module is rated Shallow, always include a recommendation: merge, inline,
or restructure. Do not leave shallow modules in the design without explanation.
