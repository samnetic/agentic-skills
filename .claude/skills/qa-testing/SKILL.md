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

## Decision Trees

### Choosing the Right Test Type

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

### TDD vs Test-After?

```
Is the requirement clear and well-defined?
├─ YES → TDD (Red-Green-Refactor) — tests guide the implementation
└─ NO
   ├─ Exploratory / prototype phase? → Spike first, then write tests before merging
   └─ Bug fix? → Write a failing test that reproduces the bug, then fix (always TDD for bugs)
```

---

## TDD Workflow (Red-Green-Refactor)

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

---

## Unit Tests (Vitest/Jest)

### Arrange-Act-Assert Pattern

```typescript
import { describe, it, expect } from 'vitest';

describe('calculateDiscount', () => {
  it('applies 10% discount for orders over $100', () => {
    // Arrange
    const order = { items: [{ price: 120, quantity: 1 }] };

    // Act
    const discount = calculateDiscount(order);

    // Assert
    expect(discount).toBe(12);
  });

  it('returns 0 for orders under $100', () => {
    const order = { items: [{ price: 50, quantity: 1 }] };
    expect(calculateDiscount(order)).toBe(0);
  });

  it('throws for negative prices', () => {
    const order = { items: [{ price: -10, quantity: 1 }] };
    expect(() => calculateDiscount(order)).toThrow('Invalid price');
  });
});
```

### Test Naming Convention

```typescript
// Pattern: "it [does something] when [condition]"
it('returns empty array when no users match the filter', () => { ... });
it('throws NotFoundError when user ID does not exist', () => { ... });
it('sends welcome email when user is created', () => { ... });
it('retries 3 times when external API returns 503', () => { ... });
```

### Mocking (Use Sparingly)

```typescript
import { vi, describe, it, expect, beforeEach } from 'vitest';

// Mock at module level
vi.mock('./email-service', () => ({
  sendEmail: vi.fn().mockResolvedValue({ id: 'msg_123' }),
}));

// Or inline
describe('UserService', () => {
  it('sends welcome email on registration', async () => {
    const emailService = { sendEmail: vi.fn().mockResolvedValue({ id: 'msg_123' }) };
    const userService = new UserService(emailService); // Dependency injection

    await userService.register({ email: 'new@test.com', name: 'New User' });

    expect(emailService.sendEmail).toHaveBeenCalledWith(
      expect.objectContaining({
        to: 'new@test.com',
        template: 'welcome',
      }),
    );
  });
});
```

**Mocking rules:**
- Mock external services (APIs, email, payment)
- Mock time (`vi.useFakeTimers()`)
- DON'T mock the thing you're testing
- DON'T mock data structures (use real objects)
- Prefer dependency injection over module mocking

---

## Integration Tests

### API Testing (Supertest)

```typescript
import request from 'supertest';
import { app } from '../src/app';

describe('POST /api/users', () => {
  it('creates a user and returns 201', async () => {
    const response = await request(app)
      .post('/api/users')
      .send({ email: 'test@example.com', name: 'Test User' })
      .expect(201);

    expect(response.body).toMatchObject({
      id: expect.any(String),
      email: 'test@example.com',
      name: 'Test User',
    });
  });

  it('returns 400 for invalid email', async () => {
    await request(app)
      .post('/api/users')
      .send({ email: 'invalid', name: 'Test' })
      .expect(400);
  });

  it('returns 409 for duplicate email', async () => {
    await request(app)
      .post('/api/users')
      .send({ email: 'existing@example.com', name: 'Duplicate' })
      .expect(409);
  });

  it('requires authentication', async () => {
    await request(app)
      .post('/api/users')
      .send({ email: 'test@example.com', name: 'Test' })
      .expect(401);
  });
});
```

### Database Testing

```typescript
import { beforeEach, afterAll } from 'vitest';

// Transaction-based isolation (fastest)
beforeEach(async () => {
  await db.query('BEGIN');
});

afterEach(async () => {
  await db.query('ROLLBACK'); // Clean slate for every test
});

afterAll(async () => {
  await db.end(); // Close pool
});
```

---

## MSW (Mock Service Worker) for API Mocking

MSW intercepts HTTP requests at the network level, providing realistic API mocking for both tests and development. Unlike `vi.mock`, it works with any HTTP client (fetch, axios, etc.) without coupling to implementation.

```typescript
import { http, HttpResponse } from 'msw';
import { setupServer } from 'msw/node';

// Define handlers
const handlers = [
  http.get('/api/users', () => {
    return HttpResponse.json([
      { id: 1, name: 'Alice' },
      { id: 2, name: 'Bob' },
    ]);
  }),

  http.post('/api/users', async ({ request }) => {
    const body = await request.json();
    return HttpResponse.json(
      { id: 3, ...body },
      { status: 201 },
    );
  }),

  http.get('/api/users/:id', ({ params }) => {
    return HttpResponse.json({ id: Number(params.id), name: 'Alice' });
  }),
];

const server = setupServer(...handlers);

// Lifecycle hooks
beforeAll(() => server.listen());
afterEach(() => server.resetHandlers());
afterAll(() => server.close());

// Tests use real fetch — no mocking the HTTP client
it('fetches users', async () => {
  const users = await fetchUsers(); // Uses fetch('/api/users') internally
  expect(users).toHaveLength(2);
  expect(users[0].name).toBe('Alice');
});

// Override handler for specific test (error scenario)
it('handles server errors', async () => {
  server.use(
    http.get('/api/users', () => {
      return new HttpResponse(null, { status: 500 });
    }),
  );

  await expect(fetchUsers()).rejects.toThrow('Server error');
});
```

**MSW rules:**
- Use `msw/node` for Vitest/Jest, `msw/browser` for browser tests
- Define default happy-path handlers in `handlers.ts`, override per test for errors
- MSW works with any HTTP client (fetch, axios, ky, got) — no implementation coupling
- Use `server.use()` for per-test overrides, `server.resetHandlers()` in `afterEach`
- Prefer MSW over `vi.mock` for API calls — it tests the actual HTTP layer

---

## Testing Library Best Practices

Testing Library encourages testing components the way users interact with them — through accessible roles, labels, and text, not implementation details.

### Query Priority (Most Accessible First)

```typescript
// Query priority — always prefer higher in the list:
// 1. getByRole       — accessible to everyone (buttons, links, headings, etc.)
// 2. getByLabelText  — form fields (associated <label>)
// 3. getByPlaceholderText — fallback for forms without labels
// 4. getByText       — non-interactive elements (paragraphs, spans)
// 5. getByDisplayValue — filled-in form fields
// 6. getByAltText    — images
// 7. getByTitle      — title attribute (rare)
// 8. getByTestId     — last resort (not accessible, not visible to users)

// BAD — uses test ID when accessible query exists
screen.getByTestId('submit-button');

// GOOD — uses role-based query (tests accessibility too)
screen.getByRole('button', { name: /submit/i });

// BAD — fragile CSS selector
container.querySelector('.user-name');

// GOOD — queries by visible text
screen.getByText('Alice Johnson');
```

### Common Patterns

```typescript
import { render, screen, within } from '@testing-library/react';
import userEvent from '@testing-library/user-event';

it('submits the form with user input', async () => {
  const user = userEvent.setup();
  const onSubmit = vi.fn();
  render(<ContactForm onSubmit={onSubmit} />);

  // Fill form using accessible queries
  await user.type(screen.getByLabelText(/email/i), 'test@example.com');
  await user.type(screen.getByLabelText(/message/i), 'Hello!');
  await user.click(screen.getByRole('button', { name: /send/i }));

  expect(onSubmit).toHaveBeenCalledWith({
    email: 'test@example.com',
    message: 'Hello!',
  });
});

it('shows validation errors', async () => {
  const user = userEvent.setup();
  render(<ContactForm onSubmit={vi.fn()} />);

  // Submit empty form
  await user.click(screen.getByRole('button', { name: /send/i }));

  // Check for error messages
  expect(screen.getByRole('alert')).toHaveTextContent(/email is required/i);
});

it('renders items in a list', () => {
  render(<UserList users={[{ name: 'Alice' }, { name: 'Bob' }]} />);

  const list = screen.getByRole('list');
  const items = within(list).getAllByRole('listitem');
  expect(items).toHaveLength(2);
});
```

**Testing Library rules:**
- Use `userEvent` over `fireEvent` — it simulates real user behavior (typing, clicking)
- Use `screen` over destructured queries from `render` — clearer, no stale references
- Prefer `findBy*` (async) over `getBy*` + `waitFor` for elements that appear asynchronously
- Never use `container.querySelector` — it bypasses accessibility
- Use `within()` to scope queries to a specific element

---

## E2E Tests (Playwright)

```typescript
import { test, expect } from '@playwright/test';

test.describe('User Registration', () => {
  test('completes full registration flow', async ({ page }) => {
    await page.goto('/register');

    // Fill form
    await page.getByLabel('Email').fill('newuser@test.com');
    await page.getByLabel('Password').fill('SecurePass123!');
    await page.getByLabel('Confirm Password').fill('SecurePass123!');
    await page.getByRole('button', { name: 'Create Account' }).click();

    // Verify redirect to dashboard
    await expect(page).toHaveURL('/dashboard');
    await expect(page.getByText('Welcome')).toBeVisible();
  });

  test('shows validation errors for invalid input', async ({ page }) => {
    await page.goto('/register');
    await page.getByRole('button', { name: 'Create Account' }).click();

    await expect(page.getByText('Email is required')).toBeVisible();
    await expect(page.getByText('Password is required')).toBeVisible();
  });
});
```

### Playwright Best Practices

| Practice | Why |
|---|---|
| Use role-based locators | `getByRole('button', { name: '...' })` — resilient to CSS changes |
| Use `getByLabel` for forms | Accessible and stable |
| Avoid `data-testid` when possible | Role/label locators test accessibility too |
| No `page.waitForTimeout()` | Use `expect().toBeVisible()` or `waitForResponse` |
| Test file per feature | Not per page — user flows cross pages |
| Parallel execution | `fullyParallel: true` in config |
| Visual regression | `expect(page).toHaveScreenshot()` for UI consistency |

### Test Tagging and Filtering

Use tags to categorize tests and run subsets in CI or locally.

```typescript
// Tag tests with @tag syntax in the test name
test('user can add item to cart @smoke @e2e', async ({ page }) => {
  await page.goto('/products');
  await page.getByRole('button', { name: 'Add to Cart' }).first().click();
  await expect(page.getByTestId('cart-count')).toHaveText('1');
});

test('user can complete checkout flow @e2e', async ({ page }) => {
  // ... full checkout test
});

test('search returns relevant results @smoke', async ({ page }) => {
  await page.goto('/');
  await page.getByPlaceholder('Search').fill('laptop');
  await page.keyboard.press('Enter');
  await expect(page.getByRole('list')).toBeVisible();
});

// Run tagged subsets:
// npx playwright test --grep @smoke          # Only smoke tests
// npx playwright test --grep @e2e            # Only E2E tests
// npx playwright test --grep-invert @slow    # Skip slow tests

// Playwright also supports tag-based annotations:
test('admin dashboard loads @admin @slow', {
  tag: ['@admin', '@slow'],
}, async ({ page }) => {
  await page.goto('/admin');
  await expect(page.getByRole('heading', { name: 'Dashboard' })).toBeVisible();
});
```

**Tagging strategy for CI:**
- `@smoke` — critical paths, run on every PR (fast)
- `@e2e` — full user journeys, run on merge to main
- `@slow` — performance-sensitive tests, run nightly
- `@flaky` — known flaky tests, quarantined and tracked

---

## Test Data Management

### Factories (Preferred over Fixtures)

```typescript
// test/factories/user.factory.ts
let counter = 0;

export function createUser(overrides: Partial<UserCreate> = {}): UserCreate {
  counter++;
  return {
    email: `user${counter}@test.com`,
    name: `Test User ${counter}`,
    role: 'user',
    ...overrides,
  };
}

// Usage
const admin = createUser({ role: 'admin' });
const users = Array.from({ length: 10 }, () => createUser());
```

### Database Seeding

```typescript
// test/seed.ts — deterministic test data
export async function seed(db: Database) {
  const org = await db.org.create({ name: 'Test Org' });
  const admin = await db.user.create({
    email: 'admin@test.com',
    orgId: org.id,
    role: 'admin',
  });
  const user = await db.user.create({
    email: 'user@test.com',
    orgId: org.id,
    role: 'user',
  });
  return { org, admin, user };
}
```

---

## Vitest — Advanced Features

### Project-Based Workspace (Monorepo Testing)

```typescript
// vitest.config.ts — use projects instead of deprecated defineWorkspace
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    projects: [
      'packages/*/vitest.config.ts',
      {
        test: {
          name: 'api',
          root: './packages/api',
          environment: 'node',
        },
      },
      {
        test: {
          name: 'web',
          root: './packages/web',
          environment: 'jsdom',
        },
      },
    ],
  },
});

// Run all projects:       vitest
// Run specific project:   vitest --project api
```

### Browser Mode

```typescript
// vitest.config.ts — run tests in a real browser
import { defineConfig } from 'vitest/config';
import { playwright } from 'vitest/browsers';

export default defineConfig({
  test: {
    browser: {
      enabled: true,
      provider: playwright(),           // Function call, not string
      instances: [
        { browser: 'chromium' },
      ],
    },
  },
});

// Browser-mode mocking (uses { spy: true } option)
import { vi } from 'vitest';
import * as module from './module.js';

vi.mock('./module.js', { spy: true });  // Spy without replacing
vi.mocked(module.method).mockReturnValue(42);
```

### vi.hoisted for Mock Setup

```typescript
import { expect, vi } from 'vitest';
import { originalMethod } from './path/to/module.js';

// vi.hoisted runs before imports — solve the hoisting problem
const { mockedMethod } = vi.hoisted(() => {
  return { mockedMethod: vi.fn() };
});

vi.mock('./path/to/module.js', () => {
  return { originalMethod: mockedMethod };
});

mockedMethod.mockReturnValue(100);
expect(originalMethod()).toBe(100);
```

### Benchmark Mode

```typescript
// math.bench.ts
import { bench, describe } from 'vitest';

describe('sorting algorithms', () => {
  const data = Array.from({ length: 1000 }, () => Math.random());

  bench('Array.sort', () => {
    [...data].sort((a, b) => a - b);
  });

  bench('custom quicksort', () => {
    quicksort([...data]);
  });
});

// Run: vitest bench
// Compare: vitest bench --outputJson baseline.json
//          vitest bench --compare baseline.json
```

```typescript
// vitest.config.ts — benchmark configuration
export default defineConfig({
  test: {
    benchmark: {
      include: ['**/*.bench.ts'],
      outputJson: 'benchmark-results.json',
    },
  },
});
```

---

## Playwright — Advanced Features

### Clock API (Time-Dependent Tests)

The Clock API lets you control time in E2E tests — install a fake clock, fast-forward, and assert time-dependent behavior without waiting.

```typescript
test('shows countdown timer', async ({ page }) => {
  // Install fake clock at a specific time
  await page.clock.install({ time: new Date('2025-01-01T00:00:00') });
  await page.goto('/countdown');

  // Fast-forward 1 hour
  await page.clock.fastForward('01:00:00');
  await expect(page.locator('.timer')).toHaveText('23:00:00');
});

test('shows relative time correctly', async ({ page }) => {
  await page.clock.install({ time: new Date('2025-06-15T10:00:00') });
  await page.goto('/posts/1');

  // Post was created "2 hours ago" at the installed time
  await expect(page.getByText('2 hours ago')).toBeVisible();

  // Fast-forward 1 day
  await page.clock.fastForward('24:00:00');
  await expect(page.getByText('1 day ago')).toBeVisible();
});

test('session expires after inactivity', async ({ page }) => {
  await page.clock.install({ time: new Date('2025-01-01T09:00:00') });
  await page.goto('/dashboard');
  await expect(page.getByText('Welcome')).toBeVisible();

  // Fast-forward past session timeout (30 minutes)
  await page.clock.fastForward('00:31:00');

  // Trigger a UI update (clock alone won't re-render)
  await page.locator('body').click();
  await expect(page.getByText('Session expired')).toBeVisible();
});
```

**Clock API methods:**
- `page.clock.install({ time })` — install fake clock at a specific point in time
- `page.clock.fastForward(ms | timestring)` — advance time (triggers timers)
- `page.clock.setFixedTime(time)` — freeze time at a fixed point
- `page.clock.resume()` — resume real-time clock progression

### toPass for Retrying Assertions

```typescript
// Retry an assertion block until it passes (useful for eventual consistency)
await expect(async () => {
  const response = await page.request.get('/api/status');
  expect(response.status()).toBe(200);
  const data = await response.json();
  expect(data.processed).toBe(true);
}).toPass({
  timeout: 30_000,         // Max wait time
  intervals: [1000, 2000, 5000],  // Retry intervals
});
```

### API Testing with Playwright

```typescript
import { test, expect } from '@playwright/test';

test.describe('API Tests', () => {
  test('creates and retrieves a user', async ({ request }) => {
    // POST — create user
    const createResponse = await request.post('/api/users', {
      data: { email: 'test@example.com', name: 'Test User' },
    });
    expect(createResponse.ok()).toBeTruthy();
    const user = await createResponse.json();
    expect(user.id).toBeDefined();

    // GET — retrieve user
    const getResponse = await request.get(`/api/users/${user.id}`);
    expect(getResponse.ok()).toBeTruthy();
    expect(await getResponse.json()).toMatchObject({
      email: 'test@example.com',
      name: 'Test User',
    });
  });
});
```

### Component Testing (Experimental)

```typescript
import { test, expect } from '@playwright/experimental-ct-react';
import { Button } from './Button';

test.use({ colorScheme: 'dark' });

test('renders button with label', async ({ mount }) => {
  const component = await mount(<Button label="Click me" />);

  await expect(component).toContainText('Click me');
  await expect(component).toHaveScreenshot();   // Visual comparison
  await component.click();
});
```

### Accessibility Assertions

```typescript
import { test, expect } from '@playwright/test';

test('button has correct accessible properties', async ({ page }) => {
  await page.goto('/form');

  const submitBtn = page.getByRole('button', { name: 'Submit' });

  // Built-in accessibility assertions
  await expect(submitBtn).toHaveAccessibleName('Submit');
  await expect(submitBtn).toHaveAccessibleDescription('Submit the form');
  await expect(submitBtn).toHaveRole('button');
});

// ARIA snapshot testing — validate accessibility tree structure
test('navigation has correct ARIA structure', async ({ page }) => {
  await page.goto('/');
  await expect(page.getByRole('navigation')).toMatchAriaSnapshot(`
    - navigation:
      - link "Home"
      - link "Products"
      - link "About"
  `);
});
```

### Visual Comparisons

```typescript
// Full page screenshots
await expect(page).toHaveScreenshot('homepage.png', {
  fullPage: true,
  maxDiffPixelRatio: 0.01,   // Allow 1% pixel difference
});

// Element screenshots
await expect(page.getByTestId('chart')).toHaveScreenshot('chart.png', {
  animations: 'disabled',     // Freeze animations for consistency
});

// Update snapshots: npx playwright test --update-snapshots
```

### UI Mode for Debugging

```bash
# Launch interactive UI mode — watch, debug, time-travel
npx playwright test --ui

# Trace viewer for CI failures
npx playwright test --trace on    # Record traces
npx playwright show-trace trace.zip  # View locally
```

---

## Visual Regression Testing

Visual regression testing catches unintended UI changes by comparing screenshots against approved baselines.

### Playwright Screenshot Comparison

```typescript
import { test, expect } from '@playwright/test';

// Full page visual comparison
test('homepage matches baseline', async ({ page }) => {
  await page.goto('/');
  await expect(page).toHaveScreenshot('homepage.png', {
    fullPage: true,
    maxDiffPixelRatio: 0.01,     // Allow 1% pixel difference
  });
});

// Component-level comparison
test('pricing cards match baseline', async ({ page }) => {
  await page.goto('/pricing');
  const cards = page.locator('.pricing-cards');
  await expect(cards).toHaveScreenshot('pricing-cards.png', {
    animations: 'disabled',       // Freeze CSS animations
    mask: [page.locator('.dynamic-date')],  // Mask dynamic content
  });
});

// Responsive visual testing
for (const viewport of [
  { width: 375, height: 667, name: 'mobile' },
  { width: 768, height: 1024, name: 'tablet' },
  { width: 1440, height: 900, name: 'desktop' },
]) {
  test(`homepage renders correctly on ${viewport.name}`, async ({ page }) => {
    await page.setViewportSize(viewport);
    await page.goto('/');
    await expect(page).toHaveScreenshot(`homepage-${viewport.name}.png`);
  });
}

// Update baselines:
// npx playwright test --update-snapshots
```

### Chromatic (Storybook Visual Testing)

```bash
# Install Chromatic
npm install --save-dev chromatic

# Run visual tests against Storybook
npx chromatic --project-token=<token>
```

```yaml
# CI integration — run Chromatic on every PR
jobs:
  visual-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0        # Required for Chromatic to detect changes
      - run: npm ci
      - uses: chromaui/action@latest
        with:
          projectToken: ${{ secrets.CHROMATIC_PROJECT_TOKEN }}
          exitZeroOnChanges: true   # Don't fail CI — review in Chromatic UI
```

**Visual regression strategy:**
- Use Playwright `toHaveScreenshot()` for E2E visual tests (page-level)
- Use Chromatic/Storybook for component-level visual testing (isolated)
- Mask dynamic content (dates, avatars, ads) to avoid false positives
- Run visual tests on a single OS/browser to avoid cross-platform diffs
- Review and approve visual changes explicitly — never auto-approve

---

## Testcontainers for Integration Testing

Spin up real databases, message brokers, and services in Docker for integration tests. No mocks, no shared test databases.

### Node.js (TypeScript)

```typescript
import { PostgreSqlContainer } from '@testcontainers/postgresql';
import { Client } from 'pg';
import { beforeAll, afterAll, describe, it, expect } from 'vitest';

describe('UserRepository', () => {
  let container: Awaited<ReturnType<PostgreSqlContainer['start']>>;
  let client: Client;

  beforeAll(async () => {
    container = await new PostgreSqlContainer('postgres:17-alpine').start();
    client = new Client({ connectionString: container.getConnectionUri() });
    await client.connect();

    // Run migrations
    await client.query(`
      CREATE TABLE users (
        id SERIAL PRIMARY KEY,
        email TEXT UNIQUE NOT NULL,
        name TEXT NOT NULL
      )
    `);
  }, 60_000);   // Container startup can take time

  afterAll(async () => {
    await client.end();
    await container.stop();
  });

  it('inserts and retrieves a user', async () => {
    await client.query(
      'INSERT INTO users (email, name) VALUES ($1, $2)',
      ['test@example.com', 'Test User']
    );

    const result = await client.query('SELECT * FROM users WHERE email = $1', ['test@example.com']);
    expect(result.rows[0]).toMatchObject({ email: 'test@example.com', name: 'Test User' });
  });
});
```

### Python (pytest)

```python
import pytest
from testcontainers.postgres import PostgresContainer
import psycopg2

@pytest.fixture(scope="module")
def postgres():
    with PostgresContainer("postgres:17-alpine") as pg:
        yield pg

@pytest.fixture
def db_connection(postgres):
    conn = psycopg2.connect(postgres.get_connection_url())
    conn.autocommit = True
    yield conn
    conn.close()

def test_insert_user(db_connection):
    cursor = db_connection.cursor()
    cursor.execute("CREATE TABLE IF NOT EXISTS users (id SERIAL, email TEXT)")
    cursor.execute("INSERT INTO users (email) VALUES (%s)", ("test@example.com",))
    cursor.execute("SELECT email FROM users")
    assert cursor.fetchone()[0] == "test@example.com"
```

### Snapshot and Restore (Fast Test Isolation)

```typescript
// Take snapshot after seeding — restore between tests (faster than recreating)
const container = await new PostgreSqlContainer('postgres:17-alpine').start();
// ... run migrations and seed data ...
await container.snapshot();

// Between tests:
await container.restoreSnapshot();  // Instant rollback to seeded state
```

---

## Contract Testing with Pact

Verify that API consumers and providers agree on the contract (request/response shapes) without running full E2E tests.

```typescript
// Consumer test — defines expected API contract
import { PactV4, MatchersV3 } from '@pact-foundation/pact';

const provider = new PactV4({
  consumer: 'frontend-app',
  provider: 'user-api',
});

describe('User API Contract', () => {
  it('returns user by ID', async () => {
    await provider
      .addInteraction()
      .given('user 123 exists')
      .uponReceiving('a request for user 123')
      .withRequest('GET', '/api/users/123')
      .willRespondWith(200, (builder) => {
        builder
          .headers({ 'Content-Type': 'application/json' })
          .jsonBody({
            id: MatchersV3.integer(123),
            email: MatchersV3.email(),
            name: MatchersV3.string('Test User'),
          });
      })
      .executeTest(async (mockServer) => {
        const response = await fetch(`${mockServer.url}/api/users/123`);
        const user = await response.json();
        expect(user.id).toBe(123);
      });
  });
});

// Provider verification — run against real provider
// pact-provider-verifier --provider-base-url http://localhost:3000
//   --pact-broker-base-url https://pact-broker.example.com
```

---

## Property-Based Testing

Instead of writing specific examples, define properties that must always hold. The framework generates hundreds of random inputs.

### JavaScript/TypeScript (fast-check)

```typescript
import { fc, test as fcTest } from '@fast-check/vitest';
import { describe } from 'vitest';

describe('sort', () => {
  fcTest.prop([fc.array(fc.integer())])('output is sorted', (arr) => {
    const sorted = [...arr].sort((a, b) => a - b);
    for (let i = 1; i < sorted.length; i++) {
      expect(sorted[i]).toBeGreaterThanOrEqual(sorted[i - 1]);
    }
  });

  fcTest.prop([fc.array(fc.integer())])('preserves length', (arr) => {
    expect([...arr].sort((a, b) => a - b)).toHaveLength(arr.length);
  });

  fcTest.prop([fc.array(fc.integer())])('preserves elements', (arr) => {
    const sorted = [...arr].sort((a, b) => a - b);
    expect(sorted).toEqual(expect.arrayContaining(arr));
  });
});

// Useful generators:
// fc.string(), fc.uuid(), fc.emailAddress(), fc.date()
// fc.record({ name: fc.string(), age: fc.nat(120) })
// fc.oneof(fc.constant('admin'), fc.constant('user'))
```

### Python (Hypothesis)

```python
from hypothesis import given, strategies as st

@given(st.lists(st.integers()))
def test_sort_is_idempotent(xs):
    assert sorted(sorted(xs)) == sorted(xs)

@given(st.text(min_size=1), st.text(min_size=1))
def test_concat_length(a, b):
    assert len(a + b) == len(a) + len(b)
```

---

## Mutation Testing (Stryker)

Mutation testing modifies your source code (mutants) and checks if tests catch the changes. If a mutant survives, your tests have a gap.

```bash
# Install Stryker for JS/TS
npm install --save-dev @stryker-mutator/core @stryker-mutator/vitest-runner

# stryker.config.mjs
export default {
  testRunner: 'vitest',
  mutate: ['src/**/*.ts', '!src/**/*.test.ts', '!src/**/*.spec.ts'],
  reporters: ['html', 'clear-text', 'progress'],
  thresholds: { high: 80, low: 60, break: 50 },
  // Incremental mode — only test changed files
  incremental: true,
};

# Run: npx stryker run
# Output: mutation score, surviving mutants, and which lines need better tests
```

| Mutation Score | Meaning |
|---|---|
| 80%+ | Excellent — tests catch most code changes |
| 60-80% | Good — some gaps to address |
| <60% | Significant testing gaps |

---

## Test Fixture Patterns — Factories with Faker

```typescript
// test/factories/user.factory.ts
import { faker } from '@faker-js/faker';

interface UserCreate {
  email: string;
  name: string;
  role: 'admin' | 'user';
  createdAt: Date;
}

export function buildUser(overrides: Partial<UserCreate> = {}): UserCreate {
  return {
    email: faker.internet.email(),
    name: faker.person.fullName(),
    role: 'user',
    createdAt: faker.date.recent(),
    ...overrides,
  };
}

// Builder pattern for complex objects
export function userBuilder() {
  let data: Partial<UserCreate> = {};
  return {
    asAdmin: () => { data.role = 'admin'; return userBuilder(); },
    withEmail: (email: string) => { data.email = email; return userBuilder(); },
    build: () => buildUser(data),
  };
}

// Usage:
const user = buildUser();                             // Random user
const admin = buildUser({ role: 'admin' });           // Random admin
const specific = userBuilder().asAdmin().withEmail('a@b.com').build();
const batch = Array.from({ length: 50 }, () => buildUser());
```

---

## Performance Testing with k6

```javascript
// load-test.js — run with: k6 run load-test.js
import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  stages: [
    { duration: '30s', target: 20 },   // Ramp up to 20 users
    { duration: '1m',  target: 20 },   // Hold at 20 users
    { duration: '30s', target: 100 },  // Spike to 100 users
    { duration: '1m',  target: 100 },  // Hold at 100
    { duration: '30s', target: 0 },    // Ramp down
  ],
  thresholds: {
    http_req_duration: ['p(95)<200'],   // 95% of requests < 200ms
    http_req_failed: ['rate<0.01'],     // <1% error rate
  },
};

export default function () {
  const res = http.get('http://localhost:3000/api/users');

  check(res, {
    'status is 200': (r) => r.status === 200,
    'response time < 200ms': (r) => r.timings.duration < 200,
    'body has users': (r) => JSON.parse(r.body).length > 0,
  });

  sleep(1);  // Think time between requests
}
```

```yaml
# Run k6 in CI (GitHub Actions)
jobs:
  load-test:
    runs-on: ubuntu-latest
    services:
      app:
        image: ghcr.io/${{ github.repository }}:${{ github.sha }}
        ports: ['3000:3000']
    steps:
      - uses: grafana/k6-action@v0.3.1
        with:
          filename: load-test.js
          flags: --out json=results.json
      - uses: actions/upload-artifact@v4
        with:
          name: k6-results
          path: results.json
```

---

## Accessibility Testing Automation

### axe-core with Playwright

```typescript
import { test, expect } from '@playwright/test';
import AxeBuilder from '@axe-core/playwright';

test.describe('Accessibility', () => {
  test('homepage has no a11y violations', async ({ page }) => {
    await page.goto('/');

    const results = await new AxeBuilder({ page }).analyze();
    expect(results.violations).toEqual([]);
  });

  test('form page meets WCAG AA', async ({ page }) => {
    await page.goto('/contact');

    const results = await new AxeBuilder({ page })
      .withTags(['wcag2a', 'wcag2aa', 'wcag22aa'])  // WCAG 2.2 AA
      .exclude('.third-party-widget')                  // Skip third-party
      .analyze();

    expect(results.violations).toEqual([]);
  });

  test('keyboard navigation works', async ({ page }) => {
    await page.goto('/');

    // Tab through interactive elements
    await page.keyboard.press('Tab');
    await expect(page.getByRole('link', { name: 'Home' })).toBeFocused();

    await page.keyboard.press('Tab');
    await expect(page.getByRole('link', { name: 'Products' })).toBeFocused();
  });
});
```

### Playwright Built-in Accessibility Assertions

```typescript
// Assert accessible name, description, and role
await expect(page.getByTestId('submit-btn')).toHaveAccessibleName('Submit form');
await expect(page.getByTestId('submit-btn')).toHaveAccessibleDescription('Submits the contact form');
await expect(page.getByTestId('submit-btn')).toHaveRole('button');

// ARIA snapshot — validate full accessibility tree
await expect(page.getByRole('navigation')).toMatchAriaSnapshot(`
  - navigation:
    - link "Home"
    - link "Products"
    - link "About"
`);
```

---

## Vertical-Slice TDD

Build features as **thin vertical slices** through ALL layers of the stack, not horizontal slices (all DB first, then all API, then all UI).

### Why Vertical Slices?

| Horizontal Slices (BAD) | Vertical Slices (GOOD) |
|---|---|
| Build all DB models first | Build one complete feature end-to-end |
| Then all API endpoints | User can see/use the feature after each slice |
| Then all UI components | Integration issues found immediately |
| Integration happens last | Each slice is independently deployable |

### The Tracer Bullet Pattern

```
Slice 1: "User can create an account"
  -> DB: users table + migration
  -> API: POST /register endpoint
  -> UI: Registration form
  -> Test: E2E test for full registration flow

Slice 2: "User can log in"
  -> DB: sessions table
  -> API: POST /login endpoint
  -> UI: Login form + redirect
  -> Test: E2E test for login flow

NOT: "Build all database tables" -> "Build all API endpoints" -> "Build all UI"
```

### TDD Within a Vertical Slice

For each slice, apply Red-Green-Refactor:
1. Write a failing E2E/integration test for the user-facing behavior
2. Write failing unit tests for the business logic
3. Implement the minimum code to pass (all layers)
4. Refactor while tests stay green
5. The slice is "done" when the E2E test passes

---

## Designing for Testability: SDK-Style Interfaces

### Principle: Every External Dependency Gets an Interface

Instead of importing SDKs directly, wrap them in interfaces you control:

```typescript
// BAD — direct SDK usage, hard to mock
import { S3Client, PutObjectCommand } from '@aws-sdk/client-s3';

export async function uploadFile(key: string, body: Buffer) {
  const client = new S3Client({});
  await client.send(new PutObjectCommand({ Bucket: 'my-bucket', Key: key, Body: body }));
}

// GOOD — interface-based, easy to mock
interface FileStorage {
  upload(key: string, body: Buffer): Promise<void>;
  download(key: string): Promise<Buffer>;
  delete(key: string): Promise<void>;
}

class S3Storage implements FileStorage {
  constructor(private client: S3Client, private bucket: string) {}
  async upload(key: string, body: Buffer) {
    await this.client.send(new PutObjectCommand({ Bucket: this.bucket, Key: key, Body: body }));
  }
  // ...
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

## Verify Through the Interface

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

Why: If you change the database schema, the BAD test breaks even though behavior is correct. The GOOD test survives refactoring.

---

## System-Wide Test Checklist

Before marking a feature as fully tested, answer these 5 questions:

1. **What fires?** — What events, webhooks, notifications, or side effects does this action trigger? Are those tested?
2. **Real chain?** — Does the test exercise the real chain of components, or are critical parts mocked away? Can you reduce mocking?
3. **Orphaned state?** — If this operation fails halfway, is there orphaned state (dangling records, partial writes)? Is that tested?
4. **Other interfaces?** — Is this feature accessible through other interfaces (API, CLI, webhook, background job)? Are those paths tested?
5. **Error alignment?** — Do error messages match what users see? Are error codes/types tested, not just happy paths?

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
| No contract tests between services | Consumer/provider drift undetected | Pact for API contract verification |
| Only example-based tests | Misses edge cases you didn't think of | Property-based testing (fast-check, Hypothesis) |
| No mutation testing | High coverage with weak assertions | Stryker to find surviving mutants |
| No accessibility testing | Ship inaccessible UIs to production | axe-core + Playwright a11y assertions |
| Hardcoded test data | Brittle, doesn't find edge cases | Faker-based factories |
| `getByTestId` as first choice | Doesn't test accessibility, fragile | Testing Library query priority (role > label > text > testId) |

---

## Coverage Strategy

```bash
# Run with coverage
vitest --coverage                    # Vitest
jest --coverage                       # Jest
pytest --cov=src --cov-report=html   # pytest

# Coverage targets (pragmatic)
# Unit test coverage: 80%+ (critical paths: 95%+)
# Integration coverage: measured by endpoint coverage
# E2E coverage: critical user journeys only (not percentage-based)
```

**Coverage rules:**
- 80% is a floor, not a ceiling — quality matters more than percentage
- Never skip error paths to improve coverage
- Untested code is unknown code — it might work, it might not
- Coverage is a tool, not a goal

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
