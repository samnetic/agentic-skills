# Frameworks and Middleware Reference

## Table of Contents

- [Project Structure](#project-structure)
- [Express 5 Error Handling](#express-5-error-handling)
- [Express 4 Legacy Async Wrapper](#express-4-legacy-async-wrapper)
- [Fastify High-Performance Framework](#fastify-high-performance-framework)
- [Fastify 5 TypeBox Type Provider](#fastify-5-typebox-type-provider)
- [Hono Multi-Runtime Framework](#hono-multi-runtime-framework)
- [Environment Configuration](#environment-configuration)
- [Health Checks](#health-checks)
- [Structured Logging](#structured-logging)

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

## Express 5 Error Handling

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

---

## Express 4 Legacy Async Wrapper

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

## Fastify High-Performance Framework

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

---

## Fastify 5 TypeBox Type Provider

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

## Hono Multi-Runtime Framework

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
