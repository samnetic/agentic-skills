---
name: qa-testing
description: >-
  Software testing and quality assurance expertise. Use when writing unit tests,
  integration tests, or end-to-end tests, implementing Test-Driven Development (TDD),
  designing test strategies, writing Playwright/Cypress E2E tests, setting up test
  fixtures and factories, implementing contract testing, designing test data management,
  measuring and improving code coverage, writing Vitest/Jest tests, implementing
  property-based testing, designing mock strategies, running mutation testing,
  implementing CI test pipelines, debugging flaky tests, or reviewing test quality.
  Triggers: test, testing, TDD, BDD, unit test, integration test, E2E, end-to-end,
  Playwright, Cypress, Vitest, Jest, pytest, coverage, mock, stub, fixture, factory,
  assertion, test strategy, test pyramid, flaky test, mutation testing, contract test,
  test data, regression test, smoke test.
license: MIT
metadata:
  author: samnetic
  version: "1.0"
---

# QA & Testing Skill

Tests are documentation that verifies itself. Write tests that catch bugs,
enable refactoring, and run fast. Follow the testing pyramid.

---

## Core Principles

| Principle | Meaning |
|---|---|
| **Test behavior, not implementation** | Tests should survive refactoring |
| **Testing pyramid** | Many unit, some integration, few E2E |
| **Fast tests run often** | Suite < 30 seconds encourages running on every save |
| **Deterministic always** | No flaky tests. Fix or delete |
| **Arrange-Act-Assert** | Every test follows this structure |
| **One reason to fail** | Each test verifies one behavior |
| **Verify through the interface** | Assert via public API, not DB queries or internal state |
| **Wrap external dependencies** | Interface-based design enables testing without real services |

---

## Testing Pyramid

```
         /\
        /  \         E2E Tests (5-10%)
       / E2E\        — Critical user journeys only
      /──────\       — Slow, expensive, brittle
     /        \
    /Integration\    Integration Tests (20-30%)
   /────────────\    — API endpoints, DB queries, external services
  /              \
 /  Unit Tests    \  Unit Tests (60-70%)
/──────────────────\ — Pure functions, business logic, fast
```

| Level | What to Test | Tools | Speed |
|---|---|---|---|
| **Unit** | Pure functions, business logic, validators, utils | Vitest, Jest, pytest | <1ms per test |
| **Integration** | API routes, DB queries, service interactions | Supertest, httpx, testcontainers | <100ms per test |
| **E2E** | Critical user flows (login, checkout, signup) | Playwright | <10s per test |

---

## Workflow

### 1. Choose the Right Test Type

```
What are you testing?
├─ Pure function / single class logic?
│  └─ Unit test (Vitest / Jest / pytest)
├─ Multiple modules working together?
│  ├─ Involves database/API? → Integration test (Testcontainers / MSW)
│  └─ Component rendering? → Component test (Testing Library)
├─ Critical user journey (login, checkout, signup)?
│  └─ E2E test (Playwright)
├─ Visual appearance / layout?
│  └─ Visual regression (Playwright screenshots / Chromatic)
└─ Performance / load?
   └─ Load test (k6 / Artillery)
```

### 2. Decide TDD vs Test-After

```
Is the requirement clear and well-defined?
├─ YES → TDD (Red-Green-Refactor) — tests guide the implementation
└─ NO
   ├─ Exploratory / prototype phase? → Spike first, then write tests before merging
   └─ Bug fix? → Write a failing test that reproduces the bug, then fix (always TDD for bugs)
```

### 3. Apply TDD Red-Green-Refactor

```
1. RED    → Write a failing test that describes the desired behavior
2. GREEN  → Write the MINIMUM code to make the test pass
3. REFACTOR → Clean up code while tests stay green
4. REPEAT → Next behavior
```

**Rules:**
- Never write production code without a failing test first
- Write the simplest test that could fail
- Write the simplest code that could pass
- Refactor only when tests are green
- Run the full suite before committing

### 4. Follow Arrange-Act-Assert

```typescript
describe('calculateDiscount', () => {
  it('applies 10% discount for orders over $100', () => {
    // Arrange
    const order = { items: [{ price: 120, quantity: 1 }] };

    // Act
    const discount = calculateDiscount(order);

    // Assert
    expect(discount).toBe(12);
  });
});
```

### 5. Name Tests Clearly

```typescript
// Pattern: "it [does something] when [condition]"
it('returns empty array when no users match the filter', () => { ... });
it('throws NotFoundError when user ID does not exist', () => { ... });
it('sends welcome email when user is created', () => { ... });
it('retries 3 times when external API returns 503', () => { ... });
```

### 6. Mock Only External Dependencies

- Mock external services (APIs, email, payment)
- Mock time (`vi.useFakeTimers()`)
- DO NOT mock the thing you're testing
- DO NOT mock data structures (use real objects)
- Prefer dependency injection over module mocking
- Use MSW for HTTP-level API mocking over `vi.mock`

### 7. Build Features as Vertical Slices

Build features as thin vertical slices through ALL layers, not horizontal slices:

| Horizontal Slices (BAD) | Vertical Slices (GOOD) |
|---|---|
| Build all DB models first | Build one complete feature end-to-end |
| Then all API endpoints | User can see/use the feature after each slice |
| Then all UI components | Integration issues found immediately |
| Integration happens last | Each slice is independently deployable |

For each slice, apply Red-Green-Refactor:
1. Write a failing E2E/integration test for the user-facing behavior
2. Write failing unit tests for the business logic
3. Implement the minimum code to pass (all layers)
4. Refactor while tests stay green
5. The slice is "done" when the E2E test passes

### 8. Apply the System-Wide Test Checklist

Before marking a feature as fully tested, answer these 5 questions:

1. **What fires?** — What events, webhooks, notifications, or side effects does this action trigger? Are those tested?
2. **Real chain?** — Does the test exercise the real chain of components, or are critical parts mocked away? Can you reduce mocking?
3. **Orphaned state?** — If this operation fails halfway, is there orphaned state (dangling records, partial writes)? Is that tested?
4. **Other interfaces?** — Is this feature accessible through other interfaces (API, CLI, webhook, background job)? Are those paths tested?
5. **Error alignment?** — Do error messages match what users see? Are error codes/types tested, not just happy paths?

### 9. Verify Through the Interface

After a test action, verify the result through the same interface the user would use — NOT by querying the database directly or checking internal state.

```typescript
// BAD — checking DB directly (tests implementation, not behavior)
await userService.register({ email: 'a@b.com', name: 'Alice' });
const row = await db.query('SELECT * FROM users WHERE email = $1', ['a@b.com']);
expect(row).toBeDefined();

// GOOD — checking through the interface (tests behavior)
await userService.register({ email: 'a@b.com', name: 'Alice' });
const user = await userService.getByEmail('a@b.com');
expect(user).toMatchObject({ email: 'a@b.com', name: 'Alice' });
```

### 10. Design for Testability

Wrap every external dependency in an interface you control:

```typescript
// GOOD — interface-based, easy to mock
interface FileStorage {
  upload(key: string, body: Buffer): Promise<void>;
  download(key: string): Promise<Buffer>;
  delete(key: string): Promise<void>;
}

// In tests — no AWS SDK needed
class InMemoryStorage implements FileStorage {
  private files = new Map<string, Buffer>();
  async upload(key: string, body: Buffer) { this.files.set(key, body); }
  async download(key: string) { return this.files.get(key)!; }
  async delete(key: string) { this.files.delete(key); }
}
```

---

## Decision Tree: Mocking Strategy

```
What dependency are you dealing with?
├─ External HTTP API?
│  └─ Use MSW (network-level interception, works with any HTTP client)
├─ Database?
│  ├─ Unit test? → Repository interface with in-memory implementation
│  └─ Integration test? → Testcontainers (real DB in Docker)
├─ Time/dates?
│  ├─ Unit test? → vi.useFakeTimers()
│  └─ E2E test? → Playwright Clock API
├─ File system / storage?
│  └─ Interface + in-memory implementation
├─ Email / SMS / payment?
│  └─ Interface + spy/fake implementation
└─ Internal module?
   └─ DO NOT MOCK — test through the public API
```

---

## Anti-Patterns

| Anti-Pattern | Why It's Dangerous | Fix |
|---|---|---|
| Testing implementation details | Tests break on refactoring | Test behavior (input -> output) |
| No assertions in test | Test passes but verifies nothing | Every test must have `expect()` |
| `test.skip` left in codebase | Skipped tests rot | Fix or delete, never skip |
| Shared mutable state between tests | Order-dependent, flaky | Isolate with fresh setup per test |
| Testing private methods | Coupling to implementation | Test through public API |
| E2E for everything | Slow, flaky, expensive | Testing pyramid — most tests should be unit |
| `sleep(1000)` in tests | Slow, still flaky | Proper awaits, event-driven assertions |
| Snapshot abuse | Huge snapshots nobody reviews | Small, focused snapshots or explicit assertions |
| No test for edge cases | Bugs hide in boundaries | Empty arrays, null, max values, unicode, concurrent access |
| Mock everything | Tests prove mocks work, not code | Only mock external dependencies |
| No CI integration | Tests pass locally, fail in CI | Run tests in CI on every PR |
| Mocking databases in integration tests | False confidence, misses real SQL issues | Testcontainers for real DB instances |
| Hardcoded test data | Brittle, doesn't find edge cases | Faker-based factories |
| `getByTestId` as first choice | Doesn't test accessibility, fragile | Query priority: role > label > text > testId |

---

## Progressive Disclosure Map

| Topic | Reference | When to read |
|---|---|---|
| Unit tests (Vitest/Jest), mocking, MSW, Testing Library, factories | [Unit & Integration Testing](references/unit-integration-testing.md) | Writing unit tests, mocking external APIs, component tests, test data factories |
| API integration tests, database testing, Testcontainers, contract testing (Pact) | [Unit & Integration Testing](references/unit-integration-testing.md) | Testing API endpoints, DB queries, cross-service contracts |
| Playwright E2E, visual regression, accessibility testing, Chromatic | [E2E & Visual Testing](references/e2e-visual-testing.md) | Writing Playwright tests, visual regression, a11y audits |
| Property-based testing, mutation testing, performance testing (k6), benchmarks | [Advanced Testing Patterns](references/advanced-testing-patterns.md) | Improving test quality beyond example-based tests, load testing |
| Vitest advanced features (workspaces, browser mode, benchmarks) | [Advanced Testing Patterns](references/advanced-testing-patterns.md) | Configuring Vitest for monorepos, browser testing, benchmarking |

---

## Coverage Strategy

```bash
# Run with coverage
vitest --coverage                    # Vitest
jest --coverage                       # Jest
pytest --cov=src --cov-report=html   # pytest
```

**Coverage rules:**
- 80% is a floor, not a ceiling — quality matters more than percentage
- Never skip error paths to improve coverage
- Untested code is unknown code — it might work, it might not
- Coverage is a tool, not a goal
- Unit test coverage: 80%+ (critical paths: 95%+)
- Integration coverage: measured by endpoint coverage
- E2E coverage: critical user journeys only (not percentage-based)

---

## Checklist: Test Quality Review

- [ ] Tests follow AAA pattern (Arrange-Act-Assert)
- [ ] Each test verifies one behavior
- [ ] Test names describe the expected behavior
- [ ] No implementation details tested (survives refactoring)
- [ ] External dependencies mocked (APIs, email, payment)
- [ ] Database tests use transaction rollback or Testcontainers
- [ ] No flaky tests (`sleep`, shared state, order dependency)
- [ ] Edge cases covered (empty, null, max, concurrent, unicode)
- [ ] Error paths tested (not just happy path)
- [ ] E2E tests use role-based locators
- [ ] Tests run in CI on every PR
- [ ] Coverage > 80% for critical business logic
- [ ] Accessibility tests run with axe-core on key pages
- [ ] Contract tests verify API consumer/provider agreement
- [ ] Property-based tests for pure functions with complex input spaces
- [ ] Mutation testing score > 60% for critical modules
- [ ] Test factories use faker for realistic, randomized data
- [ ] Performance baselines tracked with k6 or Vitest bench
- [ ] Visual regression tests for UI-critical components
- [ ] Features built as vertical slices (not horizontal layers)
- [ ] External dependencies wrapped in interfaces (SDK-style)
- [ ] Verification done through the interface, not DB queries
- [ ] System-wide test checklist (5 questions) answered for each feature
- [ ] MSW used for API mocking (not vi.mock on HTTP clients)
- [ ] Testing Library queries follow priority order (role > label > text > testId)
- [ ] Playwright tests tagged for selective CI runs (@smoke, @e2e)
- [ ] Time-dependent tests use Playwright Clock API (not real waits)
