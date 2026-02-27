---
name: nodejs-engineering
description: >-
  Node.js 22+ runtime and backend development expertise. Use when building Node.js
  servers, understanding the event loop, implementing async patterns, designing
  Express 5/Fastify/Hono middleware, handling errors in Node.js, implementing graceful
  shutdown, working with streams, using worker threads, structuring Node.js projects,
  managing environment configuration, implementing health checks, setting up
  structured logging, handling process signals, optimizing Node.js performance,
  managing npm/pnpm dependencies, using built-in test runner, using node:
  protocol imports, debugging memory leaks, or reviewing Node.js backend code.
  Triggers: Node.js, node, Express, Fastify, Hono, event loop, middleware, stream,
  worker thread, cluster, npm, pnpm, graceful shutdown, SIGTERM, health check,
  structured logging, error handling, async, callback, process, runtime, backend,
  node:test, node:sqlite, AbortController, Undici, Permission Model, Bun.
---

# Node.js Engineering Skill

Build Node.js backends that handle errors gracefully, shut down cleanly, and
perform reliably under load. Understand the runtime, not just the framework.
Target Node.js 22 LTS and Node.js 24 LTS.

---

## Core Principles

| Principle | Meaning |
|---|---|
| **Understand the event loop** | Blocking it is the #1 Node.js sin |
| **Errors are not exceptional** | Design for them. Handle them. Log them |
| **Graceful shutdown always** | Handle SIGTERM, drain connections, close DB pools |
| **Streams over buffers** | Don't load 1GB files into memory |
| **Environment validation at startup** | Fail fast if config is wrong |
| **Health checks are mandatory** | Liveness and readiness probes |

---

## Event Loop — Know It Cold

```
   ┌──────────────────────────────────────┐
   │              timers                   │  ← setTimeout, setInterval
   │          (execute callbacks)          │
   ├──────────────────────────────────────┤
   │         pending callbacks             │  ← I/O callbacks deferred
   ├──────────────────────────────────────┤
   │          idle, prepare               │  ← internal use
   ├──────────────────────────────────────┤
   │              poll                     │  ← I/O events (fs, net, etc.)
   │      (retrieve new I/O events)       │     Blocks here if nothing pending
   ├──────────────────────────────────────┤
   │              check                    │  ← setImmediate callbacks
   ├──────────────────────────────────────┤
   │         close callbacks               │  ← socket.on('close'), etc.
   └──────────────────────────────────────┘

   Between EVERY phase: process microtasks
   → process.nextTick() callbacks (first)
   → Promise .then/.catch/.finally callbacks (second)
```

**Critical rules:**
- Never block the event loop with synchronous operations
- `JSON.parse()` on large payloads — use streaming JSON parser
- `crypto.pbkdf2Sync` → use `crypto.pbkdf2` (async version)
- Large loops (>10ms) → break into chunks with `setImmediate`
- CPU-intensive work → Worker threads

---

## Node.js 22 LTS & 23+ Features

```typescript
// --- Always use node: protocol for built-in imports ---
import { readFile } from 'node:fs/promises';     // ALWAYS 'node:fs', not 'fs'
import { createServer } from 'node:http';         // Prevents accidental npm package shadowing
import { test, describe, it } from 'node:test';   // Built-in test runner
import { DatabaseSync } from 'node:sqlite';        // Built-in SQLite (22+)

// --- Built-in test runner (node:test) — replaces Jest/Vitest for unit tests ---
import { test, describe, it, mock, before, after } from 'node:test';
import assert from 'node:assert/strict';

describe('UserService', () => {
  it('should create a user', async () => {
    const service = new UserService(mockRepo);
    const user = await service.create({ email: 'test@example.com', name: 'Test' });
    assert.equal(user.email, 'test@example.com');
    assert.ok(user.id);
  });

  it('should reject duplicate email', async () => {
    await assert.rejects(
      () => service.create({ email: 'existing@example.com', name: 'Dup' }),
      { code: 'DUPLICATE_EMAIL' },
    );
  });
});
// Run: node --test src/**/*.test.ts

// --- Built-in SQLite (node:sqlite) — great for local state, caching, embeddings ---
// Requires: node --experimental-sqlite src/server.ts   (stability 1.1 in Node 22 LTS)
import { DatabaseSync } from 'node:sqlite';

const db = new DatabaseSync(':memory:');
db.exec('CREATE TABLE kv (key TEXT PRIMARY KEY, value TEXT) STRICT');

// Positional parameters
const insert = db.prepare('INSERT OR REPLACE INTO kv (key, value) VALUES (?, ?)');
insert.run('session:abc', JSON.stringify({ userId: '123' }));

// Named parameters (prefixed with :, @, or $)
const upsert = db.prepare('INSERT OR REPLACE INTO kv (key, value) VALUES (:key, :value)');
upsert.run({ key: 'session:xyz', value: JSON.stringify({ userId: '456' }) });

// Query methods: get() → first row, all() → all rows
const row = db.prepare('SELECT value FROM kv WHERE key = ?').get('session:abc');
const all = db.prepare('SELECT * FROM kv').all();

// IMPORTANT: All operations are synchronous — avoid in hot request paths.
// Best for: CLI tools, local caching, embedded metadata, feature flags, tests.
// For production web servers: use postgres (pg) with async pool.

// --- fetch() is stable — no more node-fetch ---
const response = await fetch('https://api.example.com/data', {
  headers: { 'Authorization': `Bearer ${token}` },
  signal: AbortSignal.timeout(5000), // Built-in timeout
});
const data = await response.json();

// --- .env file support (--env-file flag) ---
// node --env-file=.env src/server.ts
// node --env-file=.env --env-file=.env.local src/server.ts  // Multiple files, last wins
// node --env-file-if-exists=.env src/server.ts              // No error if file absent (CI/CD)

// --- process.loadEnvFile() — programmatic .env loading (Node 21.7+) ---
// Use when env file path is dynamic or loading happens in code (test setup, scripts)
process.loadEnvFile();            // Loads .env from cwd (throws if not found)
process.loadEnvFile('.env.test'); // Load a specific file

// --- node --watch (replaces nodemon) ---
// node --watch src/server.ts            # Restart on file changes
// node --watch-path=./src src/server.ts # Watch specific directory

// --- Permission Model (--experimental-permission, stable in v22.13+) ---
// node --experimental-permission --allow-fs-read=/app --allow-fs-write=/tmp src/server.ts
// Restricts: file system, child processes, worker threads, native addons, WASI
// All access DENIED by default; use --allow-* flags to grant:
//   --allow-fs-read=<path>  --allow-fs-write=<path>  --allow-child-process  --allow-worker
// Runtime check: process.permission.has('fs.write', '/tmp')  → true/false

// --- Web Crypto API (stable — globalThis.crypto.subtle) ---
// Symmetric encryption (AES-GCM)
const aesKey = await crypto.subtle.generateKey({ name: 'AES-GCM', length: 256 }, true, ['encrypt', 'decrypt']);
const iv = crypto.getRandomValues(new Uint8Array(12));
const ciphertext = await crypto.subtle.encrypt({ name: 'AES-GCM', iv }, aesKey, new TextEncoder().encode('secret'));

// Asymmetric signing (ECDSA P-256) — same API works in browsers
const { privateKey, publicKey } = await crypto.subtle.generateKey({ name: 'ECDSA', namedCurve: 'P-256' }, true, ['sign', 'verify']);
const sig = await crypto.subtle.sign({ name: 'ECDSA', hash: 'SHA-256' }, privateKey, new TextEncoder().encode('payload'));
const valid = await crypto.subtle.verify({ name: 'ECDSA', hash: 'SHA-256' }, publicKey, sig, new TextEncoder().encode('payload'));

// SHA-256 hashing
const hashBuf = await crypto.subtle.digest('SHA-256', new TextEncoder().encode('hello'));
const hashHex = Buffer.from(hashBuf).toString('hex');

// --- TypeScript without build step (22.6+ type stripping) ---
// node --strip-types src/server.ts                # Stable in 22.6+, strips types, runs directly
// node --experimental-transform-types src/server.ts  # Still experimental (Node 23+) — needed for enums/namespaces

// --- Node 23+: require() for ESM ---
// const { Hono } = require('hono');  // ESM packages can now be require()'d
// Enables gradual migration from CJS to ESM
```

### Node 24 LTS Features

```typescript
// --- URLPattern (stable) — web-standard URL matching ---
const pattern = new URLPattern({ pathname: '/users/:id' });
const match = pattern.exec('https://example.com/users/123');
console.log(match?.pathname.groups.id); // '123'

// Works for routing, middleware matching, API gateways
const apiPattern = new URLPattern({ pathname: '/api/v:version/:resource' });
const result = apiPattern.exec('https://example.com/api/v2/orders');
// result.pathname.groups → { version: '2', resource: 'orders' }

// --- import.meta.dirname / import.meta.filename (stable since Node 20.11, available in Node 22 LTS) ---
// Replaces the CJS __dirname / __filename pattern in ESM
console.log(import.meta.dirname);   // '/app/src' — directory of current module
console.log(import.meta.filename);  // '/app/src/server.ts' — full path of current module

// No more: import { fileURLToPath } from 'node:url'; const __dirname = path.dirname(fileURLToPath(import.meta.url));
// Just use import.meta.dirname directly

// --- Built-in .env file loader (stable, no flag needed) ---
// node --env-file=.env src/server.ts
// node --env-file=.env --env-file=.env.local src/server.ts  // Multiple files, last wins
// Now stable — no longer behind a flag

// --- Permission Model (stable — renamed from --experimental-permission) ---
// node --permission --allow-fs-read=/app --allow-fs-write=/tmp src/server.ts
// --experimental-permission renamed to --permission in Node 22.13+ / 23.5+
// Restricts: file system, child processes, worker threads, native addons, WASI
// NOTE: Network access is NOT restricted by the Permission Model
// Runtime API: process.permission.has('fs.read', '/home/secrets')  → true/false

// --- Glob support in node:fs (stable) ---
import { glob, globSync } from 'node:fs';

const migrations = await Array.fromAsync(glob('migrations/*.sql'));
// No more need for `fast-glob` or `globby` packages for simple cases
```

---

## Decision Trees

### Which Framework?

```
Which framework?
├── Simple REST API → Express 5 (stable, huge ecosystem)
├── Performance-critical API → Fastify (2-5x faster than Express)
├── Multi-runtime (Edge + Node + Bun) → Hono
├── Full-stack TypeScript app → Next.js (App Router)
├── GraphQL API → Apollo Server or Yoga
├── Real-time (WebSocket) → Socket.io or ws + Hono
└── CLI tool → Commander.js or Citty
```

### Which Runtime?

```
Which runtime?
├── Production backend → Node.js 22/24 LTS (battle-tested)
├── Startup speed matters (serverless) → Bun
├── Security sandbox needed → Deno
├── Edge computing → Bun or Deno (smaller footprint)
└── Enterprise, native addons → Node.js only
```

### Which Test Runner?

```
Which test runner?
├── Simple unit tests → node:test (built-in, zero deps)
├── React/frontend component tests → Vitest
├── Full-featured with mocking → Vitest or Jest
├── E2E API tests → Vitest + Supertest
├── E2E browser tests → Playwright
└── Legacy Jest projects → Keep Jest, migrate gradually to Vitest
```

### Which Process Model?

```
Which process model?
├── I/O-bound (typical web server) → Single process (event loop handles it)
├── CPU-bound tasks (image processing, crypto) → Worker threads
├── Utilize all CPU cores → Cluster module or PM2
├── Mixed I/O + CPU → Main thread for I/O, worker pool for CPU
└── Serverless → Single invocation, no process management
```

---

## AbortController / AbortSignal Patterns

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

## Undici — Built-in HTTP Client

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

## Project Structure

```
src/
├── server.ts                  # HTTP server setup (Express/Fastify)
├── app.ts                     # Application factory (for testing)
├── config/
│   └── env.ts                 # Environment validation with Zod
├── modules/
│   └── users/
│       ├── user.router.ts     # Routes
│       ├── user.service.ts    # Business logic
│       ├── user.repository.ts # Data access
│       ├── user.schema.ts     # Zod schemas
│       └── user.errors.ts     # Domain errors
├── middleware/
│   ├── error-handler.ts       # Central error handler
│   ├── request-id.ts          # Request ID injection
│   ├── logger.ts              # Request logging
│   └── auth.ts                # Authentication
├── shared/
│   ├── errors.ts              # Error base classes
│   ├── logger.ts              # Structured logger setup
│   └── db.ts                  # Database connection
└── health.ts                  # Health check endpoint
```

---

## Graceful Shutdown (Non-Negotiable)

```typescript
import { Server } from 'node:http';

function gracefulShutdown(server: Server, cleanup: () => Promise<void>) {
  let isShuttingDown = false;

  async function shutdown(signal: string) {
    if (isShuttingDown) return;
    isShuttingDown = true;

    logger.info({ signal }, 'Shutdown signal received, draining connections...');

    // Stop accepting new connections
    server.close(async () => {
      logger.info('All connections drained');
      try {
        await cleanup(); // Close DB pools, flush logs, etc.
        logger.info('Cleanup complete, exiting');
        process.exit(0);
      } catch (err) {
        logger.error({ err }, 'Error during cleanup');
        process.exit(1);
      }
    });

    // Force shutdown after timeout
    setTimeout(() => {
      logger.error('Forced shutdown after timeout');
      process.exit(1);
    }, 30_000).unref();
  }

  process.on('SIGTERM', () => shutdown('SIGTERM'));
  process.on('SIGINT', () => shutdown('SIGINT'));

  // Catch unhandled errors (log and crash — don't swallow)
  process.on('unhandledRejection', (reason) => {
    logger.fatal({ err: reason }, 'Unhandled rejection — crashing');
    process.exit(1);
  });

  process.on('uncaughtException', (err) => {
    logger.fatal({ err }, 'Uncaught exception — crashing');
    process.exit(1);
  });
}

// Usage
const server = app.listen(config.port, () => {
  logger.info({ port: config.port }, 'Server started');
});

gracefulShutdown(server, async () => {
  await db.end();
  await redis.quit();
  await logger.flush();
});
```

---

## Error Handling

### Central Error Handler (Express 5)

```typescript
// Express 5 is now stable — key changes from Express 4:
// - Async errors automatically forwarded to error handler (no wrapper needed!)
// - Removed deprecated methods (res.json(obj, status), req.param())
// - Promises rejected in handlers are caught automatically
// - Path syntax changed: wildcard * requires name, inline regex removed (ReDoS mitigation)

import express, { type ErrorRequestHandler } from 'express';

// --- Express 5 Route Path Syntax Changes (path-to-regexp v0 → v8) ---
// BEFORE (Express 4):
//   app.get('/files/*', handler);           // Unnamed wildcard — BROKEN in Express 5
//   app.get('/users/:id(\\d+)', handler);   // Inline regex — REMOVED in Express 5
//   app.get('/items/:id?', handler);        // ? for optional — syntax changed
//
// AFTER (Express 5):
//   app.get('/files/{*filePath}', handler); // Named wildcard required
//   app.get('/users/:id', handler);         // Validate in handler with Zod instead
//   app.get('/items{/:id}', handler);       // Optional param uses braces
//
// Body parser changes:
//   express.urlencoded() now defaults extended: false (was true)
//   express.bodyParser() removed entirely
//   res.json(body, status) argument order removed — use res.status(200).json(body)
//   req.param() removed — use req.params.name, req.query.name, req.body.name

// Application error hierarchy — with Error.cause support
class AppError extends Error {
  constructor(
    message: string,
    public readonly statusCode: number = 500,
    public readonly code: string = 'INTERNAL_ERROR',
    public readonly isOperational: boolean = true,
    options?: ErrorOptions,   // { cause?: unknown } — native Error options
  ) {
    super(message, options);  // Passes cause to V8, preserved in stack traces
    this.name = this.constructor.name;
    Error.captureStackTrace(this, this.constructor);
  }
}

// --- Error.cause: chain errors to preserve context (standard since Node 16) ---
// ALWAYS pass { cause } when wrapping errors — preserves the full chain in logs.

// BAD: original error lost
// catch (err) { throw new AppError('Failed to create user'); }

// GOOD: original DB error preserved as .cause
// catch (err) { throw new AppError('Failed to create user', 500, 'DB_ERROR', true, { cause: err }); }

class DatabaseError extends AppError {
  constructor(message: string, cause: unknown) {
    super(message, 500, 'DB_ERROR', true, { cause });
  }
}

class ExternalServiceError extends AppError {
  constructor(service: string, cause: unknown) {
    super(`External service error: ${service}`, 502, 'EXTERNAL_ERROR', true, { cause });
  }
}

// Central handler — ALWAYS the last middleware
const errorHandler: ErrorRequestHandler = (err, req, res, _next) => {
  // Zod validation errors
  if (err instanceof ZodError) {
    return res.status(400).json({
      error: 'Validation failed',
      code: 'VALIDATION_ERROR',
      details: err.flatten().fieldErrors,
    });
  }

  // Known application errors
  if (err instanceof AppError) {
    if (!err.isOperational) {
      logger.fatal({ err, requestId: req.id }, 'Non-operational error');
      process.exit(1); // Let orchestrator restart
    }

    return res.status(err.statusCode).json({
      error: err.message,
      code: err.code,
    });
  }

  // Unknown errors — log and return generic message
  logger.error({ err, requestId: req.id }, 'Unexpected error');
  return res.status(500).json({
    error: 'Internal server error',
    code: 'INTERNAL_ERROR',
  });
};

// Express 5: async errors auto-forwarded — NO asyncHandler wrapper needed
router.get('/users/:id', async (req, res) => {
  const user = await userService.findById(req.params.id);
  if (!user) throw new NotFoundError('User', req.params.id);
  res.json(user);  // Thrown errors go to errorHandler automatically
});
```

### Express 4 Legacy — Async Route Wrapper

```typescript
// Only needed for Express 4. Express 5 handles this natively.
type AsyncHandler = (req: Request, res: Response, next: NextFunction) => Promise<void>;

function asyncHandler(fn: AsyncHandler): RequestHandler {
  return (req, res, next) => {
    fn(req, res, next).catch(next);
  };
}
```

---

## Environment Configuration

```typescript
import { z } from 'zod';

const EnvSchema = z.object({
  NODE_ENV: z.enum(['development', 'production', 'test']).default('development'),
  PORT: z.coerce.number().int().min(1).max(65535).default(3000),
  DATABASE_URL: z.string().url(),
  REDIS_URL: z.string().url().default('redis://localhost:6379'),
  JWT_SECRET: z.string().min(32),
  LOG_LEVEL: z.enum(['fatal', 'error', 'warn', 'info', 'debug', 'trace']).default('info'),
  CORS_ORIGINS: z.string().transform(s => s.split(',')).default('http://localhost:3000'),
});

// Validate at startup — fail fast
export const config = EnvSchema.parse(process.env);
export type Config = z.infer<typeof EnvSchema>;
```

---

## Health Checks

```typescript
router.get('/health', async (req, res) => {
  const checks = {
    uptime: process.uptime(),
    timestamp: new Date().toISOString(),
    memory: process.memoryUsage(),
    checks: {
      database: await checkDatabase(),
      redis: await checkRedis(),
    },
  };

  const isHealthy = Object.values(checks.checks).every(c => c.status === 'ok');
  res.status(isHealthy ? 200 : 503).json(checks);
});

async function checkDatabase(): Promise<HealthCheck> {
  try {
    const start = performance.now();
    await db.query('SELECT 1');
    return { status: 'ok', latency: Math.round(performance.now() - start) };
  } catch (err) {
    return { status: 'error', message: (err as Error).message };
  }
}
```

---

## Structured Logging

```typescript
import pino from 'pino';

export const logger = pino({
  level: config.LOG_LEVEL,
  transport: config.NODE_ENV === 'development'
    ? { target: 'pino-pretty' }
    : undefined,
  serializers: {
    err: pino.stdSerializers.err,
    req: pino.stdSerializers.req,
    res: pino.stdSerializers.res,
  },
  redact: ['req.headers.authorization', 'req.headers.cookie'],
});

// Per-request child logger with request ID
app.use((req, res, next) => {
  req.log = logger.child({ requestId: req.id });
  next();
});
```

---

## AsyncLocalStorage — Request Context Propagation

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

## Hono — Lightweight Multi-Runtime Framework

```typescript
// Hono works on Node.js, Deno, Bun, Cloudflare Workers, Vercel, AWS Lambda
// Ideal for APIs, microservices, and edge functions
// Same code runs everywhere — write once, deploy anywhere

import { Hono } from 'hono';
import { serve } from '@hono/node-server';       // Node.js adapter
import { zValidator } from '@hono/zod-validator';
import { cors } from 'hono/cors';
import { logger } from 'hono/logger';
import { z } from 'zod';

const app = new Hono();

// Built-in middleware
app.use('*', cors());
app.use('*', logger());

// Zod validation middleware
const CreateUserSchema = z.object({
  email: z.string().email(),
  name: z.string().min(1),
});

app.post('/users', zValidator('json', CreateUserSchema), async (c) => {
  const body = c.req.valid('json');  // Typed and validated
  const user = await userService.create(body);
  return c.json(user, 201);
});

// Route groups
const api = new Hono().basePath('/api/v1');
api.route('/users', userRoutes);
api.route('/orders', orderRoutes);

// Error handling
app.onError((err, c) => {
  if (err instanceof AppError) {
    return c.json({ error: err.message, code: err.code }, err.statusCode);
  }
  return c.json({ error: 'Internal server error' }, 500);
});

// Run on Node.js
serve({ fetch: app.fetch, port: 3000 });
```

**When to choose Hono over Express/Fastify:**
- Multi-runtime deployment (same code on Edge, Node, Bun)
- Lightweight APIs and microservices
- Cloudflare Workers or edge-first architecture
- Type-safe routing with built-in validation middleware

---

## Fastify — High-Performance Framework

```typescript
import Fastify from 'fastify';

const app = Fastify({ logger: true });

// Schema-based validation (JSON Schema, compiled at startup for speed)
app.post('/users', {
  schema: {
    body: {
      type: 'object',
      required: ['email', 'name'],
      properties: {
        email: { type: 'string', format: 'email' },
        name: { type: 'string', minLength: 1 },
      },
    },
    response: {
      201: {
        type: 'object',
        properties: {
          id: { type: 'string' },
          email: { type: 'string' },
        },
      },
    },
  },
}, async (request, reply) => {
  const user = await userService.create(request.body);
  return reply.status(201).send(user);
});

// Plugins (encapsulated — each plugin gets its own scope)
app.register(import('./routes/users.js'), { prefix: '/api/users' });
app.register(import('./routes/orders.js'), { prefix: '/api/orders' });

// Decorators — extend request/reply/app
app.decorateRequest('user', null);
app.addHook('onRequest', async (request) => {
  request.startTime = performance.now();
});

// Lifecycle hooks
app.addHook('onResponse', async (request, reply) => {
  request.log.info({
    method: request.method,
    url: request.url,
    statusCode: reply.statusCode,
    responseTime: performance.now() - request.startTime,
  }, 'request completed');
});

// Graceful shutdown built in
const start = async () => {
  try {
    await app.listen({ port: 3000, host: '0.0.0.0' });
  } catch (err) {
    app.log.error(err);
    process.exit(1);
  }
};

// Fastify handles SIGTERM/SIGINT gracefully via app.close()
process.on('SIGTERM', () => app.close());
process.on('SIGINT', () => app.close());

start();
```

**When to choose Fastify over Express:**
- Performance matters (2-5x faster due to schema-based serialization)
- JSON Schema validation preferred over Zod middleware
- Plugin encapsulation needed (avoids middleware pollution)
- Built-in logging (pino) and validation out of the box
- TypeScript-first with excellent type inference

### Fastify 5 — TypeBox Type Provider (Idiomatic TypeScript)

```typescript
// TypeBox gives compile-time AND runtime type safety from a single schema definition.
// No type assertions — route handler params/body/reply are fully typed.

import Fastify from 'fastify';
import { TypeBoxTypeProvider } from '@fastify/type-provider-typebox';
import { Type, Static } from '@sinclair/typebox';

const app = Fastify({ logger: true }).withTypeProvider<TypeBoxTypeProvider>();

const CreateUserBody = Type.Object({
  email: Type.String({ format: 'email' }),
  name: Type.String({ minLength: 1, maxLength: 100 }),
  age: Type.Optional(Type.Integer({ minimum: 0, maximum: 150 })),
});

const UserResponse = Type.Object({
  id: Type.String(),
  email: Type.String(),
  name: Type.String(),
  createdAt: Type.String({ format: 'date-time' }),
});

// request.body is fully typed as Static<typeof CreateUserBody> — no assertions
app.post('/users', {
  schema: {
    body: CreateUserBody,
    response: { 201: UserResponse },
  },
}, async (request, reply) => {
  // request.body.email is string, request.body.age is number | undefined
  const user = await userService.create(request.body);
  return reply.status(201).send(user);
});

// Fastify 5: native diagnostics_channel tracing
// Emits lifecycle events for OpenTelemetry auto-instrumentation.
// Register: await app.register(import('@fastify/diagnostics-channel'));
// Channels: 'fastify.onRequest', 'fastify.onResponse', 'fastify.onError'
```

---

## Bun Compatibility Notes

| Feature | Node.js 22 | Bun |
|---|---|---|
| **npm compatibility** | Full | Full (faster installs) |
| **Built-in test runner** | `node:test` | `bun test` (Jest-compatible) |
| **TypeScript** | `--strip-types` (stable 22.6+) | Native, no config needed |
| **SQLite** | `node:sqlite` | `bun:sqlite` (stable, faster) |
| **Package manager** | npm/pnpm | `bun install` (10x faster) |
| **HTTP server** | `node:http` + Express/Fastify | `Bun.serve()` (fastest) |
| **Watch mode** | `node --watch` | `bun --watch` |
| **Worker threads** | Mature, stable | Supported but less mature |
| **Native addons (N-API)** | Full support | Partial support |
| **Production maturity** | Battle-tested | Growing, some edge cases |

**Use Bun when:** startup speed matters (serverless), TypeScript without config, internal tools.
**Stick with Node.js when:** production stability required, native addon dependencies, complex streams, enterprise environments.

---

## Anti-Patterns

| Anti-Pattern | Why It's Dangerous | Fix |
|---|---|---|
| `JSON.parse(hugeString)` | Blocks event loop for large payloads | Streaming JSON parser (stream-json) |
| `fs.readFileSync` in request handler | Blocks ALL requests | `fs.promises.readFile` |
| No graceful shutdown | Dropped connections, data loss | Handle SIGTERM, drain, cleanup |
| `console.log` in production | No levels, no structure, no redaction | pino or winston structured logger |
| Swallowing errors (empty catch) | Hides bugs, data corruption | Log and re-throw or handle explicitly |
| `process.on('uncaughtException', () => {})` | Keeps running in undefined state | Log and exit(1). Let orchestrator restart |
| No request timeout | Slow clients exhaust connections | `server.setTimeout(30000)` |
| `require()` in hot path | Synchronous file I/O | Import at module top level |
| Storing session in memory | Lost on restart, can't scale | Redis or database sessions |
| `new Date()` for time measurement | Millisecond precision, affected by clock drift | `performance.now()` |
| Not validating env vars at startup | Crashes at random time when var is accessed | Zod schema on startup |
| Express 4 without async error wrapper | Unhandled promise rejections | Upgrade to Express 5 (auto-catches) |
| `npm install` in production | Non-deterministic | `npm ci --omit=dev` |
| `import fs from 'fs'` | Can be shadowed by npm packages | `import fs from 'node:fs'` (always use `node:` prefix) |
| `import fetch from 'node-fetch'` | Unnecessary dependency since Node 18+ | Use global `fetch()` (built-in) |
| `nodemon` for dev watching | Extra dependency, slower | `node --watch src/server.ts` |
| `.env` parsing with `dotenv` | Extra dependency since Node 20.6+ | `node --env-file=.env src/server.ts` |
| No cancellation support | Resource leaks on timeout/shutdown | `AbortController` + `AbortSignal` patterns |
| `throw new Error(msg)` without cause | Original error context lost when wrapping | `throw new AppError(msg, 500, 'CODE', true, { cause: err })` |
| Passing `req` through call stack for requestId | Couples business logic to HTTP | `AsyncLocalStorage` for request context propagation |
| Express 5 route `app.get('/files/*', ...)` | Unnamed wildcard broken in Express 5 | `app.get('/files/{*filePath}', ...)` — named wildcard required |
| Fastify with raw JSON Schema objects | No TypeScript type inference | `@fastify/type-provider-typebox` for end-to-end type safety |

---

## Worker Threads — CPU-Intensive Work

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

---

## Testing Node.js Applications

### Unit Tests with node:test

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

### HTTP Endpoint Tests with Supertest

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

### Integration Tests with Testcontainers

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

## Security Patterns

### Cryptography with node:crypto

Two crypto APIs: **Web Crypto** (`crypto.subtle`) for cross-runtime portability (shown in features section above), and the **legacy `node:crypto`** below for sync operations and specific algorithms.

```typescript
import { randomBytes, scrypt, timingSafeEqual, createHash } from 'node:crypto';

// --- Password hashing (scrypt — built-in, no dependency needed) ---
async function hashPassword(password: string): Promise<string> {
  const salt = randomBytes(16).toString('hex');
  return new Promise((resolve, reject) => {
    scrypt(password, salt, 64, (err, derivedKey) => {
      if (err) reject(err);
      resolve(`${salt}:${derivedKey.toString('hex')}`);
    });
  });
}

async function verifyPassword(password: string, hash: string): Promise<boolean> {
  const [salt, key] = hash.split(':');
  return new Promise((resolve, reject) => {
    scrypt(password, salt, 64, (err, derivedKey) => {
      if (err) reject(err);
      // Timing-safe comparison — prevents timing attacks
      resolve(timingSafeEqual(Buffer.from(key, 'hex'), derivedKey));
    });
  });
}

// --- Secure random tokens ---
function generateToken(bytes = 32): string {
  return randomBytes(bytes).toString('base64url'); // URL-safe, no padding
}

// --- HMAC for webhook signature verification ---
import { createHmac } from 'node:crypto';

function verifyWebhookSignature(payload: string, signature: string, secret: string): boolean {
  const expected = createHmac('sha256', secret).update(payload).digest('hex');
  return timingSafeEqual(Buffer.from(signature), Buffer.from(expected));
}
```

### Security Middleware

```typescript
import helmet from 'helmet';
import rateLimit from 'express-rate-limit';

// --- Helmet — sets security HTTP headers ---
app.use(helmet());
// Sets: Content-Security-Policy, X-Content-Type-Options, X-Frame-Options,
//       Strict-Transport-Security, X-XSS-Protection, etc.

// --- Rate limiting ---
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100,                   // 100 requests per window per IP
  standardHeaders: true,      // Return rate limit info in headers
  legacyHeaders: false,
  message: { error: 'Too many requests', code: 'RATE_LIMIT_EXCEEDED' },
});
app.use('/api/', limiter);

// Stricter limit for auth endpoints
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 5,
  message: { error: 'Too many login attempts', code: 'RATE_LIMIT_EXCEEDED' },
});
app.use('/api/auth/login', authLimiter);

// --- Input validation with Zod (at the boundary) ---
import { z } from 'zod';

const CreateUserSchema = z.object({
  email: z.string().email().max(255).toLowerCase().trim(),
  name: z.string().min(1).max(100).trim(),
  age: z.number().int().min(0).max(150).optional(),
});

// Validate in middleware or route handler
router.post('/users', (req, res, next) => {
  const result = CreateUserSchema.safeParse(req.body);
  if (!result.success) {
    return res.status(400).json({
      error: 'Validation failed',
      details: result.error.flatten().fieldErrors,
    });
  }
  req.body = result.data; // Replace with validated + transformed data
  next();
});
```

### Preventing Prototype Pollution

```typescript
// --- Freeze prototypes in sensitive code ---
// Prototype pollution: attacker injects __proto__ or constructor.prototype
// via JSON input to modify Object behavior globally

// NEVER trust raw JSON.parse output for object spread/merge
// Always validate with Zod/JSON Schema BEFORE using

// BAD: Deep merge without protection
function unsafeMerge(target: any, source: any) {
  for (const key of Object.keys(source)) {
    target[key] = source[key]; // __proto__ injection possible!
  }
}

// GOOD: Use Object.create(null) for dictionaries
const safeDict = Object.create(null); // No prototype chain
safeDict['key'] = 'value'; // Safe — no __proto__ to pollute

// GOOD: Validate keys explicitly
function safeMerge(target: Record<string, unknown>, source: Record<string, unknown>) {
  for (const key of Object.keys(source)) {
    if (key === '__proto__' || key === 'constructor' || key === 'prototype') continue;
    target[key] = source[key];
  }
}

// BEST: Use Zod — strips unknown keys and validates types
const schema = z.object({ name: z.string(), email: z.string().email() });
const safeData = schema.parse(untrustedInput); // __proto__ keys are stripped
```

---

## ESM Migration Guide (CJS to ESM)

### Step-by-Step Migration

```jsonc
// 1. Set "type": "module" in package.json
{
  "name": "my-app",
  "type": "module",         // ← This makes .js files ESM by default
  "engines": { "node": ">=22" }
}
```

```typescript
// 2. Update imports — use file extensions and node: protocol

// BEFORE (CJS)
const express = require('express');
const { readFile } = require('fs/promises');
const config = require('./config');

// AFTER (ESM)
import express from 'express';
import { readFile } from 'node:fs/promises';    // Always node: prefix
import { config } from './config.js';            // File extension REQUIRED in ESM
```

```typescript
// 3. Replace __dirname / __filename

// BEFORE (CJS)
const configPath = path.join(__dirname, 'config.json');

// AFTER (ESM) — Node 22+
const configPath = path.join(import.meta.dirname, 'config.json');

// AFTER (ESM) — Node 20 (older approach, still works)
import { fileURLToPath } from 'node:url';
const __dirname = path.dirname(fileURLToPath(import.meta.url));
```

```typescript
// 4. Replace require.resolve with import.meta.resolve

// BEFORE
const templatePath = require.resolve('my-templates/default.html');

// AFTER
const templatePath = import.meta.resolve('my-templates/default.html');
```

```typescript
// 5. Replace module.exports with export

// BEFORE (CJS)
module.exports = { createApp };
module.exports.config = config;

// AFTER (ESM)
export { createApp };
export { config };
export default createApp; // Only if you had module.exports = singleThing
```

```jsonc
// 6. Update tsconfig.json for ESM
{
  "compilerOptions": {
    "module": "NodeNext",
    "moduleResolution": "NodeNext",
    "target": "ES2022",
    "outDir": "dist",
    "rootDir": "src",
    "verbatimModuleSyntax": true  // Forces explicit import type
  }
}
```

### Migration Checklist

- [ ] Set `"type": "module"` in package.json
- [ ] Add `.js` extension to all relative imports
- [ ] Replace `require()` with `import`
- [ ] Replace `module.exports` with `export`
- [ ] Replace `__dirname`/`__filename` with `import.meta.dirname`/`import.meta.filename`
- [ ] Replace `require.resolve()` with `import.meta.resolve()`
- [ ] Update `tsconfig.json` to use `"module": "NodeNext"`
- [ ] Replace `fs` with `node:fs` (all built-in imports use `node:` prefix)
- [ ] Test that all dependencies support ESM (most do as of 2025)
- [ ] Update test runner config if needed

---

## Checklist: Node.js Code Review

- [ ] Graceful shutdown handles SIGTERM and SIGINT
- [ ] Unhandled rejections and uncaught exceptions crash the process
- [ ] Environment variables validated at startup with Zod
- [ ] Health check endpoint exists and checks dependencies
- [ ] Structured logging (pino) — no console.log
- [ ] Central error handler is the last Express middleware
- [ ] Express 5 used (async errors auto-forwarded) or asyncHandler wrapper in Express 4
- [ ] No synchronous I/O in request handlers
- [ ] Streams used for large data (files, exports)
- [ ] Request timeout configured
- [ ] All built-in imports use `node:` protocol (`node:fs`, `node:crypto`, etc.)
- [ ] Global `fetch()` used instead of `node-fetch` dependency
- [ ] `AbortController`/`AbortSignal` used for cancellable operations
- [ ] `node --watch` used in development (not nodemon)
- [ ] `--env-file=.env` used instead of dotenv package
- [ ] `npm ci --omit=dev` in Dockerfile (not `npm install`)
- [ ] `node dist/server.js` as CMD (not `npm start`)
- [ ] CPU-intensive work offloaded to Worker threads (not blocking event loop)
- [ ] Passwords hashed with scrypt/argon2 (not MD5/SHA)
- [ ] Timing-safe comparison for secrets (`timingSafeEqual`)
- [ ] Helmet middleware enabled for security headers
- [ ] Rate limiting on auth and public endpoints
- [ ] Input validated with Zod at the boundary — no raw user input
- [ ] ESM with `"type": "module"`, file extensions on relative imports
- [ ] `Error.cause` used when wrapping errors — original context preserved
- [ ] `AsyncLocalStorage` used for request context (not parameter drilling)
- [ ] Tests exist: unit (node:test), integration (Supertest), E2E where appropriate
