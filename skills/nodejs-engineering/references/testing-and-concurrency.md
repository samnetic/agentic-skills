# Testing and Concurrency Reference

## Table of Contents

- [Unit Tests with node:test](#unit-tests-with-nodetest)
- [MockTimers for Time-Dependent Code](#mocktimers-for-time-dependent-code)
- [HTTP Endpoint Tests with Supertest](#http-endpoint-tests-with-supertest)
- [Integration Tests with Testcontainers](#integration-tests-with-testcontainers)
- [AbortController and AbortSignal Patterns](#abortcontroller-and-abortsignal-patterns)
- [Undici Built-in HTTP Client](#undici-built-in-http-client)
- [AsyncLocalStorage Request Context](#asynclocalstorage-request-context)
- [Streams](#streams)
- [Worker Threads](#worker-threads)

---

## Unit Tests with node:test

```typescript
import { test, describe, it, mock, before, after, beforeEach } from 'node:test';
import assert from 'node:assert/strict';

describe('UserService', () => {
  let service: UserService;
  let mockRepo: any;

  beforeEach(() => {
    // Create mock with node:test built-in mocking
    mockRepo = {
      findByEmail: mock.fn(async (email: string) => null),
      create: mock.fn(async (data: any) => ({ id: 'user-1', ...data })),
    };
    service = new UserService(mockRepo);
  });

  it('should create a user with valid data', async () => {
    // Arrange
    const input = { email: 'test@example.com', name: 'Test User' };

    // Act
    const user = await service.create(input);

    // Assert
    assert.equal(user.email, 'test@example.com');
    assert.equal(user.name, 'Test User');
    assert.ok(user.id);
    assert.equal(mockRepo.create.mock.callCount(), 1);
    assert.deepEqual(mockRepo.create.mock.calls[0].arguments[0], input);
  });

  it('should reject duplicate email', async () => {
    // Arrange — mock returns existing user
    mockRepo.findByEmail.mock.mockImplementation(async () => ({ id: 'existing' }));

    // Act & Assert
    await assert.rejects(
      () => service.create({ email: 'taken@example.com', name: 'Dup' }),
      { code: 'DUPLICATE_EMAIL' },
    );
  });

  it('should hash password before storing', async () => {
    const input = { email: 'a@b.com', name: 'A', password: 'secret123' };
    await service.create(input);

    const storedData = mockRepo.create.mock.calls[0].arguments[0];
    assert.notEqual(storedData.password, 'secret123'); // Password was hashed
    assert.ok(storedData.password.startsWith('$argon2'));
  });
});

// Run: node --test src/**/*.test.ts
// Run with coverage (stable in Node 22.13+): node --test --test-coverage src/**/*.test.ts
// Coverage thresholds (exits 1 if not met):
//   node --test --test-coverage --test-coverage-lines=80 --test-coverage-branches=70 --test-coverage-functions=90 src/**/*.test.ts
// Multiple reporters: node --test --test-reporter=spec --test-reporter-destination=stdout --test-reporter=junit --test-reporter-destination=results.xml src/**/*.test.ts
// Exclude from coverage: node --test --test-coverage --test-coverage-exclude=src/generated/** src/**/*.test.ts
// Run specific file: node --test src/modules/users/user.service.test.ts
// Watch mode: node --test --watch src/**/*.test.ts
// Update snapshots: node --test --test-update-snapshots src/**/*.test.ts
// Filter by name: node --test --test-name-pattern="should create" src/**/*.test.ts
```

---

## MockTimers for Time-Dependent Code

```typescript
// --- MockTimers: test time-dependent code without waiting (stable in Node 23.1+) ---
test('should retry after delay', async (t) => {
  t.mock.timers.enable({ apis: ['setTimeout', 'Date'] });

  let callCount = 0;
  const retry = () => { setTimeout(() => callCount++, 1000); };

  retry();
  assert.equal(callCount, 0);         // Not called yet

  t.mock.timers.tick(1000);            // Advance virtual time — no actual waiting
  assert.equal(callCount, 1);          // Now called
  // Timers auto-restored after test
});

test('Date mocking for deterministic timestamps', (t) => {
  t.mock.timers.enable({ apis: ['Date'], now: new Date('2025-01-01T00:00:00Z').getTime() });

  assert.equal(new Date().toISOString(), '2025-01-01T00:00:00.000Z');
});
```

---

## HTTP Endpoint Tests with Supertest

```typescript
import { test, describe, before, after } from 'node:test';
import assert from 'node:assert/strict';
import request from 'supertest';
import { createApp } from '../app.js';

describe('POST /api/users', () => {
  let app: Express.Application;

  before(async () => {
    app = await createApp({ database: testDbUrl });
  });

  after(async () => {
    await cleanupTestDb();
  });

  test('creates user with valid data', async () => {
    const res = await request(app)
      .post('/api/users')
      .send({ email: 'new@example.com', name: 'New User' })
      .expect(201);

    assert.equal(res.body.email, 'new@example.com');
    assert.ok(res.body.id);
  });

  test('returns 400 for invalid email', async () => {
    const res = await request(app)
      .post('/api/users')
      .send({ email: 'not-an-email', name: 'Bad' })
      .expect(400);

    assert.equal(res.body.code, 'VALIDATION_ERROR');
  });

  test('returns 409 for duplicate email', async () => {
    await request(app).post('/api/users').send({ email: 'dup@test.com', name: 'First' });
    const res = await request(app)
      .post('/api/users')
      .send({ email: 'dup@test.com', name: 'Second' })
      .expect(409);

    assert.equal(res.body.code, 'DUPLICATE_EMAIL');
  });
});
```

---

## Integration Tests with Testcontainers

```typescript
import { test, describe, before, after } from 'node:test';
import { PostgreSqlContainer, type StartedPostgreSqlContainer } from '@testcontainers/postgresql';
import { createApp } from '../app.js';

describe('User API (integration)', () => {
  let container: StartedPostgreSqlContainer;
  let app: Express.Application;

  before(async () => {
    // Spin up real PostgreSQL in Docker — no mocks
    container = await new PostgreSqlContainer('postgres:16-alpine')
      .withDatabase('testdb')
      .start();

    app = await createApp({
      databaseUrl: container.getConnectionUri(),
    });

    // Run migrations
    await runMigrations(container.getConnectionUri());
  }, { timeout: 30_000 });

  after(async () => {
    await container.stop();
  });

  test('full user lifecycle', async () => {
    // Create
    const created = await request(app)
      .post('/api/users')
      .send({ email: 'int@test.com', name: 'Integration' })
      .expect(201);

    // Read
    await request(app)
      .get(`/api/users/${created.body.id}`)
      .expect(200);

    // Update
    await request(app)
      .patch(`/api/users/${created.body.id}`)
      .send({ name: 'Updated' })
      .expect(200);

    // Delete
    await request(app)
      .delete(`/api/users/${created.body.id}`)
      .expect(204);
  });
});
```

---

## AbortController and AbortSignal Patterns

```typescript
// Cancellable fetch with timeout
async function fetchWithTimeout(url: string, timeoutMs: number): Promise<Response> {
  return fetch(url, { signal: AbortSignal.timeout(timeoutMs) });
}

// Compose multiple abort reasons
function createRequestSignal(timeoutMs: number, shutdownSignal: AbortSignal): AbortSignal {
  return AbortSignal.any([
    AbortSignal.timeout(timeoutMs),
    shutdownSignal,
  ]);
}

// Cancellable long-running operation
async function processQueue(signal: AbortSignal): Promise<void> {
  while (!signal.aborted) {
    const item = await queue.dequeue();
    if (signal.aborted) break;
    await processItem(item);
  }
}

// Usage with graceful shutdown
const shutdownController = new AbortController();
process.on('SIGTERM', () => shutdownController.abort());

await processQueue(shutdownController.signal);
```

---

## Undici Built-in HTTP Client

```typescript
import { request, Agent } from 'undici';

// Undici is built into Node.js and powers global fetch()
// Use it directly for advanced HTTP client features

// Connection pooling with keep-alive
const agent = new Agent({
  keepAliveTimeout: 30_000,
  keepAliveMaxTimeout: 60_000,
  connections: 10,                 // Max connections per origin
  pipelining: 1,                   // HTTP pipelining
});

const { statusCode, headers, body } = await request('https://api.example.com/data', {
  method: 'GET',
  headers: { 'Authorization': `Bearer ${token}` },
  dispatcher: agent,
  signal: AbortSignal.timeout(5000),
});

const data = await body.json();

// Streaming response body (efficient for large payloads)
for await (const chunk of body) {
  process.stdout.write(chunk);
}
```

---

## AsyncLocalStorage Request Context

```typescript
// AsyncLocalStorage lets you propagate request context (requestId, userId, etc.)
// through the entire call stack WITHOUT passing it as a parameter.
// Essential for structured logging, tracing, and multi-tenant isolation.

import { AsyncLocalStorage } from 'node:async_hooks';

interface RequestContext {
  requestId: string;
  userId?: string;
  tenantId?: string;
}

export const requestContext = new AsyncLocalStorage<RequestContext>();

// Middleware: create context at the start of each request
app.use((req, res, next) => {
  const ctx: RequestContext = {
    requestId: req.headers['x-request-id'] as string ?? crypto.randomUUID(),
    userId: req.user?.id,
  };
  // All code called within this callback (including async) can access ctx
  requestContext.run(ctx, next);
});

// Access context ANYWHERE in the call stack — no parameter drilling needed
export function getCurrentRequestId(): string | undefined {
  return requestContext.getStore()?.requestId;
}

// Integration with pino: auto-attach requestId to every log line
import pino from 'pino';
const baseLogger = pino({ level: 'info' });

export function getLogger() {
  const ctx = requestContext.getStore();
  return ctx ? baseLogger.child({ requestId: ctx.requestId }) : baseLogger;
}

// Usage in a service — no req parameter needed
async function findUser(id: string) {
  getLogger().info({ id }, 'Finding user');  // requestId auto-attached
  return db.query('SELECT * FROM users WHERE id = $1', [id]);
}
```

---

## Streams

```typescript
import { pipeline } from 'node:stream/promises';
import { createReadStream, createWriteStream } from 'node:fs';
import { createGzip } from 'node:zlib';
import { Transform } from 'node:stream';

// File processing without loading into memory
await pipeline(
  createReadStream('input.csv'),
  new Transform({
    transform(chunk, encoding, callback) {
      const processed = processChunk(chunk.toString());
      callback(null, processed);
    },
  }),
  createGzip(),
  createWriteStream('output.csv.gz'),
);

// Streaming HTTP response
app.get('/export', asyncHandler(async (req, res) => {
  res.setHeader('Content-Type', 'text/csv');
  res.setHeader('Transfer-Encoding', 'chunked');

  const cursor = db.query('SELECT * FROM large_table').stream();
  for await (const row of cursor) {
    res.write(formatCsvRow(row));
  }
  res.end();
}));
```

---

## Worker Threads

```typescript
import { Worker, isMainThread, parentPort, workerData } from 'node:worker_threads';

// --- Basic pattern: offload heavy computation ---
if (isMainThread) {
  // Main thread — spawn worker for CPU-bound task
  const worker = new Worker(new URL(import.meta.url), {
    workerData: { task: 'hash-passwords', passwords: batch },
  });

  worker.on('message', (result) => console.log('Result:', result));
  worker.on('error', (err) => console.error('Worker error:', err));
  worker.on('exit', (code) => {
    if (code !== 0) console.error(`Worker stopped with exit code ${code}`);
  });
} else {
  // Worker thread — runs in parallel, has its own event loop
  const result = heavyComputation(workerData);
  parentPort!.postMessage(result);
}

// --- structuredClone — deep cloning for worker thread data passing ---
// postMessage() uses structured clone algorithm internally. Available globally since Node 17.
const original = { date: new Date(), map: new Map([['k', 'v']]), set: new Set([1, 2]) };
const clone = structuredClone(original);  // Proper deep clone — Date stays Date, Map stays Map
// Unlike JSON.parse(JSON.stringify(...)): handles Date, Map, Set, circular refs, ArrayBuffer

// Transfer ownership of ArrayBuffer (zero-copy — no cloning overhead):
const buffer = new ArrayBuffer(1024 * 1024);  // 1MB
worker.postMessage({ buffer }, [buffer]);       // buffer moved, not copied — sender loses access

// --- Worker pool pattern (reuse workers, avoid spawn overhead) ---
import { Worker } from 'node:worker_threads';

class WorkerPool {
  private workers: Worker[] = [];
  private queue: Array<{ data: unknown; resolve: Function; reject: Function }> = [];
  private freeWorkers: Worker[] = [];

  constructor(private workerPath: string, private poolSize: number) {
    for (let i = 0; i < poolSize; i++) {
      const worker = new Worker(workerPath);
      worker.on('message', (result) => {
        const next = this.queue.shift();
        if (next) {
          worker.postMessage(next.data);
          worker.once('message', next.resolve);
        } else {
          this.freeWorkers.push(worker);
        }
      });
      this.freeWorkers.push(worker);
    }
  }

  async run(data: unknown): Promise<unknown> {
    const worker = this.freeWorkers.pop();
    if (worker) {
      return new Promise((resolve, reject) => {
        worker.once('message', resolve);
        worker.once('error', reject);
        worker.postMessage(data);
      });
    }
    return new Promise((resolve, reject) => {
      this.queue.push({ data, resolve, reject });
    });
  }
}

// Usage: const pool = new WorkerPool('./hash-worker.js', os.cpus().length);
// const hash = await pool.run({ password: 'secret' });
```

**When to use Worker Threads vs Cluster:**
- **Worker Threads**: Share memory (SharedArrayBuffer), CPU tasks within one process
- **Cluster**: Multiple processes, each handles HTTP requests, uses more memory
- **Rule of thumb**: Worker threads for CPU tasks, cluster for scaling HTTP
