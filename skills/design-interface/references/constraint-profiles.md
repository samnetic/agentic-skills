# Constraint Profiles

Each constraint profile is a lens that forces the designer to optimize for one
dimension above all others. The resulting designs will differ — that is the
point. Differences reveal tradeoffs that a single design attempt hides.

## How to Use

1. Select 3-5 profiles from the list below (or create a domain-specific one).
2. Include the full profile text in each sub-agent's prompt alongside the Design Brief.
3. The designer must follow the constraint rules strictly — no hedging or "balanced" approaches.

---

## Profile: Minimalist

**Optimize for:** Smallest possible interface surface area.

**Rules for the designer:**
- Expose the fewest methods that cover all required operations.
- Prefer a single polymorphic method over multiple specialized ones when the type system allows it.
- Every public method must justify its existence — if two methods can be merged, merge them.
- Configuration via options objects, not method overloads.
- Target: fewer than 5 public methods for most modules.

**What this sacrifices:** Discoverability, self-documenting naming, specialized error types.

**Evaluate by:** Count of public methods and types. Lower is better.

---

## Profile: Extensibility-First

**Optimize for:** Easy to add new behaviors without modifying existing code.

**Rules for the designer:**
- Apply the Open-Closed Principle aggressively — design for plugins, middleware, or strategy patterns.
- Prefer composition over inheritance.
- Define extension points explicitly: hooks, interceptors, or registries.
- New operations should be addable by consumers without forking the module.
- Use generic types or protocols to allow custom implementations.

**What this sacrifices:** Simplicity for the common case, immediate readability, startup performance.

**Evaluate by:** Can a new operation be added without changing existing code? How many lines does it take?

---

## Profile: Type-Safe-Maximum

**Optimize for:** Maximum compile-time guarantees. Illegal states should be unrepresentable.

**Rules for the designer:**
- Use branded/nominal types for domain identifiers (UserId, OrderId — not raw strings).
- Use discriminated unions for states (not boolean flags or string enums).
- Make invalid method call sequences a type error (builder pattern, state machines via types).
- Prefer `Result<T, E>` over thrown exceptions where the language supports it.
- Generic constraints should be as tight as possible.

**What this sacrifices:** Boilerplate, learning curve, interop with loosely-typed consumers.

**Evaluate by:** How many classes of runtime error become compile-time errors?

---

## Profile: Performance-First

**Optimize for:** Zero-cost abstractions. Minimize allocations, copies, and indirection on the hot path.

**Rules for the designer:**
- Avoid allocations in the primary execution path.
- Prefer value types / structs over heap-allocated objects where possible.
- Batch operations instead of per-item method calls.
- Lazy evaluation for expensive computations.
- Streaming/iterator-based APIs over collect-then-process.
- Pre-allocate buffers; accept user-provided buffers where it matters.

**What this sacrifices:** Ergonomics, safety (manual memory management), readability of batch APIs.

**Evaluate by:** Allocations per operation, method call overhead, data copy count.

---

## Profile: DDD-Pure

**Optimize for:** Domain-driven design with ubiquitous language and aggregate boundaries.

**Rules for the designer:**
- Name every type and method using the domain's ubiquitous language — no generic CRUD verbs.
- Separate commands (state changes) from queries (reads) explicitly.
- Define aggregate roots with clear invariant boundaries.
- Value objects for all domain concepts that have equality semantics (Money, Email, DateRange).
- Domain events for state transitions — the interface should emit or return them.
- No infrastructure concerns (database, HTTP) leak into the interface.

**What this sacrifices:** Simplicity for CRUD-like operations, familiarity for developers new to DDD.

**Evaluate by:** Does the interface read like domain documentation? Can a domain expert validate it?

---

## Creating Custom Profiles

For domain-specific needs, define a profile with this structure:

```
## Profile: [Name]

**Optimize for:** [One sentence — the single dimension this lens maximizes]

**Rules for the designer:**
- [3-6 concrete rules the designer must follow]

**What this sacrifices:** [What gets worse under this constraint]

**Evaluate by:** [Measurable criterion for success]
```

Examples of custom profiles:
- **Backward-Compatible** — optimize for zero breaking changes from an existing v1 API
- **CLI-Friendly** — optimize for ergonomic command-line usage with minimal flags
- **Streaming-Native** — optimize for real-time data flow with backpressure
- **Multi-Tenant** — optimize for tenant isolation at the type level
