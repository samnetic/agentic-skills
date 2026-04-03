# Vertical Slice Decomposition

## What Is a Vertical Slice?

A vertical slice is a feature increment that cuts through **every layer** of the architecture — database, backend, frontend, and tests — delivering a narrow but complete piece of working functionality.

The key word is *complete*. A vertical slice is not "build the database tables" or "wire up the API." It is "a user can do X, end to end, and we have a test proving it."

---

## Horizontal vs Vertical

```
HORIZONTAL (BAD):              VERTICAL (GOOD):

Phase 1: ████████████ UI       Phase 1: █ DB+API+UI+Test (Slice A)
Phase 2: ████████████ API      Phase 2: █ DB+API+UI+Test (Slice B)
Phase 3: ████████████ DB       Phase 3: █ DB+API+UI+Test (Slice C)
Phase 4: ████████████ Tests
                               Each phase works end-to-end.
Nothing works until Phase 4.   Each phase is independently demoable.
Integration risk accumulates.  Integration risk is retired early.
```

### Why horizontal slicing fails

1. **Late integration.** Layers built in isolation rarely fit together cleanly. Bugs surface at the end when fixing them is most expensive.
2. **No demoable progress.** Stakeholders cannot see anything until all layers are complete.
3. **Blocked testing.** QA cannot test until every layer is connected.
4. **Wasted work.** If requirements change mid-build, entire layers may be discarded.

### Why vertical slicing works

1. **Early feedback.** Working software from Phase 1 means stakeholders can course-correct immediately.
2. **Continuous integration.** Every slice proves the layers work together.
3. **Incremental delivery.** Each phase adds value; the project can ship at any phase boundary.
4. **Parallel execution.** Independent slices at the same phase level can be built simultaneously by different developers or agents.

---

## How to Identify Good Slice Boundaries

A good slice boundary maps to one of:

| Boundary type | Example |
|---|---|
| **One user story** | "As a user, I can create a task" |
| **One user flow** | The complete path from clicking "New" to seeing the saved item |
| **One business capability** | Invoice generation (not "invoice model" or "invoice API") |

### Signs of a bad slice

- It only touches one layer ("create all the database tables").
- It cannot be demonstrated to a stakeholder.
- It has no acceptance criteria that a user could verify.
- The description uses implementation language ("add middleware") instead of behavior language ("users can filter by date").

---

## Slice Sizing

A slice should be completable in **1-3 days** by one developer or one coding agent.

| Too small | Right size | Too large |
|---|---|---|
| Add a single column | CRUD for one entity through all layers | Full multi-entity feature with admin panel |
| Write one unit test | One user flow with happy + error paths | Entire authentication system |
| Add a route | One integration with tests | Dashboard with 10 charts |

If a slice will take more than 3 days, split it. If it will take less than half a day, merge it with a related slice.

---

## When Slices Share Code

Some slices need the same database table, utility function, or shared component. Handle this with a **foundation slice** in Phase 0:

```
Phase 0 (Foundation + Tracer Bullet):
├─ Shared schema: users table, auth middleware
├─ Shared components: layout, error boundary
└─ Tracer bullet: one complete flow through shared foundation

Phase 1A: Slice using shared foundation
Phase 1B: Different slice using same foundation
```

Rules for foundation code:

1. Only extract into foundation what **two or more slices** actually need.
2. Do not speculatively build foundation — add shared code when the second slice needs it.
3. The foundation is part of Phase 0, tested by the tracer bullet.

---

## Examples for Common Feature Types

### CRUD Feature

```
Phase 0: Create + Read for one entity
  DB:    users table with name, email
  API:   POST /users, GET /users/:id
  UI:    Create form + detail view
  Tests: Integration test for create → read flow

Phase 1: Update + Delete
  DB:    (no change)
  API:   PUT /users/:id, DELETE /users/:id
  UI:    Edit form + delete confirmation
  Tests: Integration tests for update and delete

Phase 2: List with pagination + search
  DB:    Add index for search
  API:   GET /users?page=&q=
  UI:    List view with search bar, pagination
  Tests: Tests for pagination edge cases, empty results
```

### Dashboard

```
Phase 0: One metric, one chart, real data
  DB:    Query for total revenue (or whatever the primary metric is)
  API:   GET /dashboard/revenue
  UI:    Single chart component rendering real data
  Tests: API test + component test

Phase 1: Date range filtering + 2 more metrics
  DB:    Parameterized queries with date range
  API:   GET /dashboard/metrics?from=&to=
  UI:    Date picker + metric cards
  Tests: Tests for date range edge cases

Phase 2: Export + additional charts
  DB:    (no change)
  API:   GET /dashboard/export
  UI:    Export button + remaining chart types
  Tests: Export format validation
```

### API Integration (third-party service)

```
Phase 0: One endpoint, one transformer, one test
  DB:    Cache/log table for API responses
  API:   POST /integrations/stripe/webhook (one event type)
  Logic: Transform webhook payload → internal event
  Tests: Integration test with recorded fixture

Phase 1: Additional event types
  DB:    (extend cache schema if needed)
  API:   Handle 3-5 more webhook event types
  Logic: Transformers for each event type
  Tests: Fixture-based tests for each event type

Phase 2: Retry, error handling, monitoring
  DB:    Dead-letter table for failed events
  API:   Retry endpoint, health check
  Logic: Exponential backoff, circuit breaker
  Tests: Failure scenario tests
```

### Auth Feature

```
Phase 0: Login flow only
  DB:    users table with hashed password
  API:   POST /auth/login, POST /auth/logout
  UI:    Login form + session indicator
  Tests: Login success, login failure, logout

Phase 1: Registration
  DB:    (extend users table if needed)
  API:   POST /auth/register
  UI:    Registration form with validation
  Tests: Registration + duplicate email handling

Phase 2: Password reset + email verification
  DB:    tokens table for reset/verification
  API:   POST /auth/forgot-password, POST /auth/reset-password
  UI:    Forgot password form, reset form, verification page
  Tests: Token expiry, email sending mock
```

---

## Slice Decomposition Checklist

For each slice, verify:

- [ ] It touches ALL layers (DB, API, UI, tests)
- [ ] It is independently demoable
- [ ] It maps to a user-visible behavior, not an implementation detail
- [ ] It is sized for 1-3 days of work
- [ ] Its acceptance criteria are verifiable by a user
- [ ] Shared dependencies are in the foundation slice (Phase 0)
