# Interface Quality Checklist

Verify the recommended interface against every item before finalizing.
A failing check does not necessarily block the recommendation — but it must be
acknowledged and justified in the ADR's Consequences section.

## Fundamental Design

- [ ] **Single Responsibility** — The interface serves one cohesive purpose. If you cannot describe it in one sentence without "and", split it.
- [ ] **Depth over breadth** — The interface is deep: small surface area hiding significant complexity. Depth ratio >= 3 is good; >= 5 is excellent.
- [ ] **No shallow wrappers** — Every method adds value beyond delegation. If a method just calls through to one underlying method, remove it.
- [ ] **Consistent abstraction level** — All methods operate at the same level of abstraction. Mixing high-level orchestration with low-level data access in one interface is a smell.

## Naming and Semantics

- [ ] **Domain language** — Types and methods use the domain's vocabulary, not implementation jargon (e.g., `submitOrder` not `insertOrderRow`).
- [ ] **Verb-noun methods** — Methods describe actions: `createUser`, `resolveConflict`, `calculateTotal`. Avoid vague names like `process`, `handle`, `do`.
- [ ] **No boolean traps** — No boolean parameters that change behavior. Use separate methods or options objects instead of `doThing(true, false)`.
- [ ] **Predictable return types** — Consumers can guess what a method returns without reading docs. `getUser` returns a user; `listOrders` returns a list.

## Type Safety

- [ ] **Branded identifiers** — Domain IDs use branded/nominal types, not raw strings or numbers (TypeScript: `type UserId = string & { readonly __brand: 'UserId' }`).
- [ ] **Discriminated unions for states** — State representations use tagged unions, not boolean flags or string enums. Each state variant carries only its relevant data.
- [ ] **No stringly-typed APIs** — Event names, action types, and configuration keys are typed constants or enums, not raw strings.
- [ ] **Explicit error types** — Failure modes are part of the type signature (`Result<T, E>`, union return types), not just thrown exceptions.

## Ergonomics

- [ ] **Progressive disclosure** — Common operations are simple; advanced operations are possible. The 80% use case should require minimal parameters.
- [ ] **Sensible defaults** — Optional parameters have defaults that work for most consumers. Required parameters are truly required.
- [ ] **Discoverable via autocomplete** — The interface works well with IDE tooling. Method names are distinct enough to find via fuzzy search.
- [ ] **Minimal ceremony** — A consumer can accomplish the most common task in 3-5 lines. If the "hello world" for this interface exceeds 10 lines, simplify.

## Testability

- [ ] **Injectable dependencies** — External services, clocks, random sources are injected, not imported directly. Tests can substitute fakes.
- [ ] **Pure core** — Business logic methods are pure functions where possible. Side effects are pushed to the boundary.
- [ ] **Observable behavior** — The interface exposes enough surface to verify correct behavior without accessing internals. No need to test private state.
- [ ] **Deterministic by default** — Given the same inputs, methods produce the same outputs. Non-determinism (time, randomness) is injected.

## Extensibility

- [ ] **Open for extension** — New behaviors can be added without modifying existing interface code (plugins, middleware, strategy pattern).
- [ ] **Stable contracts** — Public types and method signatures can remain stable as the implementation evolves. Internal refactoring does not break consumers.
- [ ] **Versioning path** — If this is a public API, there is a clear path for introducing breaking changes (versioned endpoints, adapter layer, deprecation strategy).

## Operational Readiness

- [ ] **Error messages are actionable** — Error types include enough context for the consumer to fix the problem without reading source code.
- [ ] **Observable** — The interface supports logging, metrics, or tracing hooks without requiring consumers to instrument the internals.
- [ ] **Concurrency story** — Thread safety, reentrancy, or async behavior is explicit in the types or documented at each method.
- [ ] **Backward compatibility** — If replacing an existing interface, the migration path is documented and incremental.
