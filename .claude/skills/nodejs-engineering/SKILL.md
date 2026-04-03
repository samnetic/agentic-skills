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
license: MIT
metadata:
  author: samnetic
  version: "1.0"
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

## Workflow

### 1. Bootstrap the Project

- Set `"type": "module"` in package.json for ESM
- Use `node:` protocol for all built-in imports (`node:fs`, `node:crypto`, `node:test`)
- Validate all environment variables at startup with Zod schema — fail fast
- Use `node --env-file=.env` instead of dotenv package
- Use `node --watch` instead of nodemon for development

```typescript
import { z } from 'zod';

const EnvSchema = z.object({
  NODE_ENV: z.enum(['development', 'production', 'test']).default('development'),
  PORT: z.coerce.number().int().min(1).max(65535).default(3000),
  DATABASE_URL: z.string().url(),
  JWT_SECRET: z.string().min(32),
  LOG_LEVEL: z.enum(['fatal', 'error', 'warn', 'info', 'debug', 'trace']).default('info'),
});

export const config = EnvSchema.parse(process.env);
```

### 2. Structure the Application

```
src/
├── server.ts              # HTTP server setup
├── app.ts                 # Application factory (for testing)
├── config/env.ts          # Environment validation with Zod
├── modules/<domain>/      # Feature modules (router, service, repository, schema, errors)
├── middleware/             # Error handler, request ID, logger, auth
├── shared/                # Error base classes, logger, DB connection
└── health.ts              # Health check endpoint
```

### 3. Implement Graceful Shutdown

Every Node.js server MUST handle shutdown signals. Stop accepting connections, drain in-flight requests, close DB pools, flush logs, then exit.

```typescript
process.on('SIGTERM', () => shutdown('SIGTERM'));
process.on('SIGINT', () => shutdown('SIGINT'));

// Unhandled errors: log and crash — never swallow
process.on('unhandledRejection', (reason) => {
  logger.fatal({ err: reason }, 'Unhandled rejection — crashing');
  process.exit(1);
});
```

### 4. Set Up Error Handling

- Create `AppError` hierarchy with `statusCode`, `code`, `isOperational` fields
- ALWAYS pass `{ cause: err }` when wrapping errors to preserve the chain
- Central error handler as the LAST Express middleware
- Express 5: async errors auto-forwarded (no wrapper needed)
- Non-operational errors: log and crash — let the orchestrator restart

### 5. Add Observability

- Structured logging with pino (never `console.log` in production)
- Per-request child loggers with request ID
- `AsyncLocalStorage` for request context propagation (no parameter drilling)
- Health check endpoint that verifies database and external dependencies

### 6. Implement Business Logic

- Validate input at the boundary with Zod
- Use streams for large data (file processing, exports, large query results)
- Use `AbortController`/`AbortSignal` for cancellable operations and timeouts
- Offload CPU-intensive work to Worker threads (never block the event loop)
- Use `fetch()` (built-in) with `AbortSignal.timeout()` for HTTP calls

### 7. Write Tests

- **Unit tests**: `node:test` (built-in, zero deps) with `assert` from `node:assert/strict`
- **HTTP endpoint tests**: Supertest against the app factory
- **Integration tests**: Testcontainers for real database testing
- Run: `node --test src/**/*.test.ts`
- Coverage: `node --test --test-coverage --test-coverage-lines=80`

### 8. Production Deployment

- `npm ci --omit=dev` in Dockerfile (not `npm install`)
- `node dist/server.js` as CMD (not `npm start`)
- Helmet middleware for security headers
- Rate limiting on auth and public endpoints
- Request timeout configured on the server
- Passwords hashed with scrypt/argon2, timing-safe comparison for secrets

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
| `new Date()` for time measurement | Millisecond precision, clock drift | `performance.now()` |
| Not validating env vars at startup | Crashes at random time | Zod schema on startup |
| Express 4 without async error wrapper | Unhandled promise rejections | Upgrade to Express 5 (auto-catches) |
| `npm install` in production | Non-deterministic | `npm ci --omit=dev` |
| `import fs from 'fs'` | Can be shadowed by npm packages | `import fs from 'node:fs'` |
| `import fetch from 'node-fetch'` | Unnecessary dependency since Node 18+ | Use global `fetch()` (built-in) |
| `nodemon` for dev watching | Extra dependency, slower | `node --watch src/server.ts` |
| `.env` parsing with `dotenv` | Extra dependency since Node 20.6+ | `node --env-file=.env` |
| No cancellation support | Resource leaks on timeout/shutdown | `AbortController` + `AbortSignal` |
| `throw new Error(msg)` without cause | Original context lost when wrapping | `{ cause: err }` in Error options |
| Passing `req` through call stack | Couples business logic to HTTP | `AsyncLocalStorage` for context |
| Express 5 `app.get('/files/*', ...)` | Unnamed wildcard broken in Express 5 | `app.get('/files/{*filePath}', ...)` |
| Fastify with raw JSON Schema objects | No TypeScript type inference | `@fastify/type-provider-typebox` |

---

## Progressive Disclosure Map

| Topic | Reference | When to read |
|---|---|---|
| Event loop, Node 22/24 features, ESM migration, Bun | [references/runtime-and-features.md](references/runtime-and-features.md) | Understanding runtime internals, migrating CJS to ESM, evaluating Bun vs Node |
| Express 5, Fastify, Hono, project structure, env config, logging, health checks | [references/frameworks-and-middleware.md](references/frameworks-and-middleware.md) | Setting up a new server, choosing a framework, implementing middleware |
| Graceful shutdown, error hierarchy, crypto, security middleware, prototype pollution | [references/error-handling-and-security.md](references/error-handling-and-security.md) | Implementing error handling, adding security layers, writing shutdown logic |
| node:test, Supertest, Testcontainers, AbortController, Undici, AsyncLocalStorage, streams, workers | [references/testing-and-concurrency.md](references/testing-and-concurrency.md) | Writing tests, implementing async patterns, handling concurrency |

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
- [ ] CPU-intensive work offloaded to Worker threads
- [ ] Passwords hashed with scrypt/argon2 (not MD5/SHA)
- [ ] Timing-safe comparison for secrets (`timingSafeEqual`)
- [ ] Helmet middleware enabled for security headers
- [ ] Rate limiting on auth and public endpoints
- [ ] Input validated with Zod at the boundary
- [ ] ESM with `"type": "module"`, file extensions on relative imports
- [ ] `Error.cause` used when wrapping errors
- [ ] `AsyncLocalStorage` used for request context (not parameter drilling)
- [ ] Tests exist: unit (node:test), integration (Supertest), E2E where appropriate
