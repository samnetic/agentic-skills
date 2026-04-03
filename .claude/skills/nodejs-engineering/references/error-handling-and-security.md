# Error Handling and Security Reference

## Table of Contents

- [Graceful Shutdown](#graceful-shutdown)
- [Error Hierarchy with Error.cause](#error-hierarchy-with-errorcause)
- [Cryptography with node:crypto](#cryptography-with-nodecrypto)
- [Security Middleware](#security-middleware)
- [Preventing Prototype Pollution](#preventing-prototype-pollution)

---

## Graceful Shutdown

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

## Error Hierarchy with Error.cause

```typescript
// Application error hierarchy — with Error.cause support
class AppError extends Error {
  constructor(
    message: string,
    public readonly statusCode: number = 500,
    public readonly code: string = 'INTERNAL_ERROR',
    public readonly isOperational: boolean = true,
    options?: ErrorOptions,
  ) {
    super(message, options);
    this.name = this.constructor.name;
    Error.captureStackTrace(this, this.constructor);
  }
}

// ALWAYS pass { cause } when wrapping errors
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
```

---

## Cryptography with node:crypto

Two crypto APIs: **Web Crypto** (`crypto.subtle`) for cross-runtime portability, and the **legacy `node:crypto`** below for sync operations and specific algorithms.

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

---

## Security Middleware

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

---

## Preventing Prototype Pollution

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
