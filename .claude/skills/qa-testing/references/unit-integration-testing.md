# Unit & Integration Testing Reference

## Table of Contents

- [Unit Tests (Vitest/Jest)](#unit-tests-vitestjest)
  - [Arrange-Act-Assert Pattern](#arrange-act-assert-pattern)
  - [Mocking (Use Sparingly)](#mocking-use-sparingly)
- [MSW (Mock Service Worker)](#msw-mock-service-worker)
- [Testing Library Best Practices](#testing-library-best-practices)
  - [Query Priority](#query-priority)
  - [Common Patterns](#common-patterns)
- [Integration Tests](#integration-tests)
  - [API Testing (Supertest)](#api-testing-supertest)
  - [Database Testing](#database-testing)
- [Testcontainers](#testcontainers)
  - [Node.js (TypeScript)](#nodejs-typescript)
  - [Python (pytest)](#python-pytest)
  - [Snapshot and Restore](#snapshot-and-restore)
- [Contract Testing with Pact](#contract-testing-with-pact)
- [Test Data Management](#test-data-management)
  - [Factories (Preferred over Fixtures)](#factories-preferred-over-fixtures)
  - [Database Seeding](#database-seeding)
  - [Factories with Faker](#factories-with-faker)

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

## MSW (Mock Service Worker)

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

### Query Priority

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

## Testcontainers

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

### Snapshot and Restore

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

### Factories with Faker

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
