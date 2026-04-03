# Authentication, Rate Limiting, Idempotency, Versioning, Webhooks, and Bulk Operations

## Table of Contents

- [Authentication](#authentication)
  - [Auth Decision Tree](#auth-decision-tree)
  - [API Key Best Practices](#api-key-best-practices)
  - [JWT Best Practices](#jwt-best-practices)
- [Rate Limiting](#rate-limiting)
  - [Response Headers](#response-headers)
  - [Algorithm Comparison](#algorithm-comparison)
  - [Redis Sliding Window Implementation](#redis-sliding-window-implementation)
  - [Tiered Rate Limits](#tiered-rate-limits)
- [Idempotency Keys (IETF Draft)](#idempotency-keys-ietf-draft)
  - [Server-Side Implementation](#server-side-implementation)
  - [Client-Side Usage](#client-side-usage)
- [API Versioning](#api-versioning)
  - [Versioning Decision Tree](#versioning-decision-tree)
  - [Comparison](#comparison)
  - [Versioning Best Practices](#versioning-best-practices)
  - [Sunset and Deprecation Headers](#sunset-and-deprecation-headers)
- [Bulk Operations](#bulk-operations)
  - [Batch Endpoint Pattern](#batch-endpoint-pattern)
  - [Implementation Guidelines](#implementation-guidelines)
- [Webhooks](#webhooks)
  - [Registration API](#registration-api)
  - [Payload Signing (HMAC-SHA256)](#payload-signing-hmac-sha256)
  - [Retry with Exponential Backoff](#retry-with-exponential-backoff)
  - [Delivery Status Tracking](#delivery-status-tracking)

---

## Authentication

### Auth Decision Tree

```
Who is calling the API?
|
+-- Third-party developers (public API)?
|   +-- User data access? -> OAuth 2.0 + PKCE
|   +-- Service-to-service? -> OAuth 2.0 Client Credentials
|   +-- Simple, low-risk? -> API Keys (in header, not query string)
|
+-- First-party frontend (SPA/mobile)?
|   -> HTTP-only session cookie (SPA)
|   -> OAuth 2.0 + PKCE (mobile)
|   -> Short-lived JWT + refresh token rotation
|
+-- Internal microservices?
|   -> mTLS (mutual TLS) for service mesh
|   -> JWT signed by internal CA (service-to-service)
|
+-- Webhooks (your server calling theirs)?
    -> HMAC-SHA256 signature on payload
    -> Shared secret per subscriber
```

### API Key Best Practices

```
1. Prefix keys for identification:  sk_live_abc123 (secret), pk_live_abc123 (public)
2. Send in header, NEVER query string:  Authorization: Bearer sk_live_abc123
   (Query strings are logged in access logs, browser history, proxies)
3. Hash keys in database:  Store SHA-256(key), not the key itself
4. Support rotation:  Allow multiple active keys, revoke old ones
5. Scope keys:  Read-only vs read-write, per-resource permissions
```

### JWT Best Practices

```typescript
// Short-lived access token (15 min) + longer refresh token (7 days)
const accessToken = jwt.sign(
  { sub: user.id, role: user.role, scope: 'read write' },
  process.env.JWT_SECRET,
  {
    algorithm: 'HS256',     // or RS256 for public/private key pair
    expiresIn: '15m',
    issuer: 'api.example.com',
    audience: 'api.example.com',
  },
);

// Always validate: algorithm, issuer, audience, expiration
const decoded = jwt.verify(token, secret, {
  algorithms: ['HS256'],   // Whitelist — prevents algorithm confusion attack
  issuer: 'api.example.com',
  audience: 'api.example.com',
});
```

---

## Rate Limiting

### Response Headers

```
HTTP/1.1 200 OK
RateLimit-Limit: 100           # Max requests in window
RateLimit-Remaining: 42        # Requests left in current window
RateLimit-Reset: 1710000000    # Unix timestamp when window resets

# When rate limited:
HTTP/1.1 429 Too Many Requests
Retry-After: 30                # Seconds until client should retry
RateLimit-Limit: 100
RateLimit-Remaining: 0
RateLimit-Reset: 1710000000
Content-Type: application/problem+json

{
  "type": "https://api.example.com/problems/rate-limited",
  "title": "Rate Limit Exceeded",
  "status": 429,
  "detail": "You have exceeded 100 requests per minute. Try again in 30 seconds.",
  "retryAfter": 30
}
```

### Algorithm Comparison

| Algorithm | How It Works | Pros | Cons |
|---|---|---|---|
| **Fixed Window** | Count per time window (e.g., 100/min) | Simple, low memory | Burst at window boundary (2x) |
| **Sliding Window** | Weighted count across current + previous window | Smooth, fair | Slightly more memory |
| **Token Bucket** | Tokens added at fixed rate, consumed per request | Allows bursts, smooth | Tuning complexity |
| **Leaky Bucket** | Requests queued and processed at fixed rate | Constant output rate | Delays all requests |

### Redis Sliding Window Implementation

```typescript
async function checkRateLimit(
  key: string,
  limit: number,
  windowMs: number,
): Promise<{ allowed: boolean; remaining: number; resetAt: number }> {
  const now = Date.now();
  const windowStart = now - windowMs;

  // Atomic sliding window with Redis sorted set
  const pipeline = redis.pipeline();
  pipeline.zremrangebyscore(key, 0, windowStart);    // Remove old entries
  pipeline.zadd(key, now, `${now}:${Math.random()}`); // Add current request
  pipeline.zcard(key);                                 // Count in window
  pipeline.expire(key, Math.ceil(windowMs / 1000));    // Auto-cleanup

  const results = await pipeline.exec();
  const count = results[2][1] as number;

  return {
    allowed: count <= limit,
    remaining: Math.max(0, limit - count),
    resetAt: Math.ceil((now + windowMs) / 1000),
  };
}

// Middleware
async function rateLimitMiddleware(req: Request, res: Response, next: NextFunction) {
  const key = `ratelimit:${req.ip}`;
  const { allowed, remaining, resetAt } = await checkRateLimit(key, 100, 60_000);

  res.setHeader('RateLimit-Limit', '100');
  res.setHeader('RateLimit-Remaining', String(remaining));
  res.setHeader('RateLimit-Reset', String(resetAt));

  if (!allowed) {
    return res.status(429).type('application/problem+json').json({
      type: 'https://api.example.com/problems/rate-limited',
      title: 'Rate Limit Exceeded',
      status: 429,
      retryAfter: Math.ceil((resetAt * 1000 - Date.now()) / 1000),
    });
  }

  next();
}
```

### Tiered Rate Limits

```
Free tier:      60 req/min,   1,000 req/day
Pro tier:      300 req/min,  50,000 req/day
Enterprise:  1,000 req/min, unlimited/day

Per-endpoint overrides:
  POST /ai/completions:   10 req/min (expensive)
  GET  /users:           300 req/min (cheap)
```

---

## Idempotency Keys (IETF Draft)

Idempotency keys allow clients to safely retry requests without creating duplicates.
Critical for payment APIs, order creation, or any non-idempotent operation.

```
POST /payments
Idempotency-Key: pay_req_8a3b2c1d
Content-Type: application/json

{ "amount": 5000, "currency": "usd", "customer": "cus_abc" }
```

### Server-Side Implementation

```typescript
// Store idempotency key -> response mapping
interface IdempotencyRecord {
  key: string;
  status: 'processing' | 'complete';
  statusCode: number;
  body: unknown;
  createdAt: Date;
}

async function idempotencyMiddleware(req: Request, res: Response, next: NextFunction) {
  const key = req.headers['idempotency-key'] as string;

  // Only required for non-idempotent methods
  if (['GET', 'PUT', 'DELETE', 'HEAD', 'OPTIONS'].includes(req.method)) {
    return next();
  }

  if (!key) {
    return res.status(400).type('application/problem+json').json({
      type: 'https://api.example.com/problems/missing-idempotency-key',
      title: 'Missing Idempotency Key',
      status: 400,
      detail: 'POST requests require an Idempotency-Key header.',
    });
  }

  // Check for existing response
  const existing = await redis.get(`idempotency:${key}`);
  if (existing) {
    const record: IdempotencyRecord = JSON.parse(existing);

    if (record.status === 'processing') {
      // Another request with the same key is in flight
      return res.status(409).type('application/problem+json').json({
        type: 'https://api.example.com/problems/idempotency-conflict',
        title: 'Request In Progress',
        status: 409,
        detail: 'A request with this idempotency key is already being processed.',
      });
    }

    // Return cached response
    return res.status(record.statusCode).json(record.body);
  }

  // Mark as processing (lock)
  await redis.set(`idempotency:${key}`, JSON.stringify({ status: 'processing' }), 'EX', 86400);

  // Capture the response
  const originalJson = res.json.bind(res);
  res.json = function (body: unknown) {
    redis.set(
      `idempotency:${key}`,
      JSON.stringify({
        key,
        status: 'complete',
        statusCode: res.statusCode,
        body,
        createdAt: new Date(),
      }),
      'EX',
      86400, // Keep for 24 hours
    );
    return originalJson(body);
  };

  next();
}
```

### Client-Side Usage

```typescript
// Generate a unique key per logical operation (NOT per retry)
async function createPayment(amount: number): Promise<Payment> {
  const idempotencyKey = crypto.randomUUID();

  const response = await fetch('/payments', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Idempotency-Key': idempotencyKey,
    },
    body: JSON.stringify({ amount }),
  });

  // Safe to retry with the SAME key on network failure
  if (!response.ok && response.status >= 500) {
    return retry(() => fetch('/payments', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Idempotency-Key': idempotencyKey, // Same key = same result
      },
      body: JSON.stringify({ amount }),
    }));
  }

  return response.json();
}
```

---

## API Versioning

### Versioning Decision Tree

```
Who are the consumers?
|
+-- Public/external developers?
|   -> URL path versioning: /v1/users
|   -> Most visible, easiest to understand, cacheable by CDN
|
+-- Internal services (same org)?
|   -> Header versioning: Accept: application/vnd.example.v2+json
|   -> or no versioning — just use additive changes
|
+-- Rapid iteration, few consumers?
    -> Query parameter: /users?version=2
    -> or no versioning at all
```

### Comparison

| Strategy | Example | Pros | Cons |
|---|---|---|---|
| **URL path** | `/v1/users` | Clear, cacheable, easy routing | URL changes, multiple code paths |
| **Header** | `Accept: application/vnd.api.v2+json` | Clean URLs, content negotiation | Hidden, harder to test (curl) |
| **Query param** | `/users?version=2` | Easy to test | Breaks caching, non-standard |
| **No versioning** | Additive changes only | Simplest | Must never remove/rename fields |

### Versioning Best Practices

```
1. Default to additive changes (no version bump needed):
   - Add new fields to responses (old clients ignore them)
   - Add new optional query parameters
   - Add new endpoints
   - Add new enum values (if client handles unknown values)

2. Version bump required (breaking changes):
   - Remove or rename a field
   - Change a field's type
   - Change endpoint URL
   - Change authentication mechanism
   - Change error response format

3. Deprecation workflow:
   a. Add Sunset header:  Sunset: Sat, 01 Mar 2026 00:00:00 GMT
   b. Add Deprecation header: Deprecation: true
   c. Document migration path
   d. Log usage of deprecated endpoints (monitor adoption)
   e. Remove after sunset date
```

### Sunset and Deprecation Headers

```typescript
// Middleware for deprecated endpoints
function deprecated(sunsetDate: string) {
  return (req: Request, res: Response, next: NextFunction) => {
    res.setHeader('Deprecation', 'true');
    res.setHeader('Sunset', new Date(sunsetDate).toUTCString());
    res.setHeader('Link', '</v2/users>; rel="successor-version"');

    // Log usage for migration tracking
    logger.warn({
      event: 'deprecated_endpoint_used',
      path: req.path,
      client: req.headers['x-api-key'] ?? 'unknown',
      sunset: sunsetDate,
    });

    next();
  };
}

router.get('/v1/users', deprecated('2026-06-01'), listUsersV1);
```

---

## Bulk Operations

### Batch Endpoint Pattern

```
POST /users/batch
Content-Type: application/json

{
  "operations": [
    { "method": "POST", "body": { "email": "a@example.com", "name": "Alice" } },
    { "method": "POST", "body": { "email": "b@example.com", "name": "Bob" } },
    { "method": "POST", "body": { "email": "invalid", "name": "Charlie" } }
  ]
}
```

**Response (Per-Item Status):**

```json
{
  "results": [
    { "index": 0, "status": 201, "body": { "id": "usr_a1", "email": "a@example.com" } },
    { "index": 1, "status": 201, "body": { "id": "usr_b2", "email": "b@example.com" } },
    { "index": 2, "status": 422, "body": {
      "type": "https://api.example.com/problems/validation-error",
      "title": "Validation Error",
      "status": 422,
      "errors": [{ "field": "email", "message": "Invalid email format", "code": "invalid_format" }]
    }}
  ],
  "summary": { "total": 3, "succeeded": 2, "failed": 1 }
}
```

**HTTP Status for Batch:**

```
All succeeded    -> 200 OK
Some failed      -> 207 Multi-Status (check individual results)
All failed       -> 422 or 400 (if all share the same error)
Too many items   -> 413 Content Too Large
```

### Implementation Guidelines

```
1. Set a max batch size:  100 items per request (configurable)
2. Process atomically OR individually:
   - Atomic: all-or-nothing in a transaction
   - Individual: each item succeeds/fails independently (more common)
3. Return per-item status: index, HTTP status, body/error
4. Idempotency keys per batch: one key for the entire batch
5. Rate limit on items, not just requests:
   batch of 100 = 100 towards rate limit, not 1
```

---

## Webhooks

### Registration API

```
POST /webhooks
{
  "url": "https://consumer.example.com/webhooks/orders",
  "events": ["order.created", "order.shipped", "order.delivered"],
  "secret": null
}

Response:
201 Created
{
  "id": "wh_abc123",
  "url": "https://consumer.example.com/webhooks/orders",
  "events": ["order.created", "order.shipped", "order.delivered"],
  "secret": "whsec_k7d9f2a1b3c4e5...",
  "status": "active",
  "created_at": "2025-03-15T10:00:00Z"
}
```

### Payload Signing (HMAC-SHA256)

```typescript
import crypto from 'node:crypto';

// Sender: sign the payload
function signWebhookPayload(payload: string, secret: string, timestamp: number): string {
  const signedContent = `${timestamp}.${payload}`;
  return crypto
    .createHmac('sha256', secret)
    .update(signedContent)
    .digest('hex');
}

// Headers sent with every webhook delivery
function buildWebhookHeaders(payload: string, secret: string): Record<string, string> {
  const timestamp = Math.floor(Date.now() / 1000);
  const signature = signWebhookPayload(payload, secret, timestamp);

  return {
    'Content-Type': 'application/json',
    'Webhook-Id': crypto.randomUUID(),
    'Webhook-Timestamp': String(timestamp),
    'Webhook-Signature': `v1=${signature}`,
  };
}

// Receiver: verify the signature
function verifyWebhookSignature(
  payload: string,
  signature: string,
  secret: string,
  timestamp: number,
  toleranceSeconds = 300, // 5 minute tolerance
): boolean {
  // Reject old timestamps (replay attack protection)
  const age = Math.abs(Math.floor(Date.now() / 1000) - timestamp);
  if (age > toleranceSeconds) return false;

  const expected = signWebhookPayload(payload, secret, timestamp);
  const received = signature.replace('v1=', '');

  // Constant-time comparison (prevents timing attacks)
  return crypto.timingSafeEqual(
    Buffer.from(expected, 'hex'),
    Buffer.from(received, 'hex'),
  );
}
```

### Retry with Exponential Backoff

```
Attempt 1: Immediately
Attempt 2: 30 seconds
Attempt 3: 2 minutes
Attempt 4: 15 minutes
Attempt 5: 2 hours
Attempt 6: 8 hours (final attempt)

After all retries fail:
- Mark webhook as "failing"
- Notify the subscriber (email or dashboard alert)
- After 3 consecutive days of failure, disable the webhook
```

### Delivery Status Tracking

```typescript
// Track every delivery attempt
interface WebhookDelivery {
  id: string;
  webhook_id: string;
  event_type: string;
  payload: unknown;
  status: 'pending' | 'delivered' | 'failed' | 'exhausted';
  attempts: Array<{
    attempted_at: string;
    status_code: number | null;
    response_body: string | null;   // First 1KB only
    duration_ms: number;
    error: string | null;
  }>;
  next_retry_at: string | null;
}

// Consumer endpoint expectations:
// 1. Return 2xx within 30 seconds (or it's a failure)
// 2. Process asynchronously if work is slow (ack fast, process later)
// 3. Handle duplicates (use Webhook-Id for deduplication)
```
