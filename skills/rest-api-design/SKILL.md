---
name: rest-api-design
description: >-
  REST API design and implementation expertise. Use when designing API endpoints,
  choosing HTTP methods and status codes, implementing pagination (cursor vs offset
  vs keyset), designing error responses (RFC 9457 Problem Details), versioning APIs
  (URL path vs header vs query param), implementing rate limiting and idempotency keys,
  designing webhook systems, creating OpenAPI/Swagger specifications, choosing between
  REST vs GraphQL vs tRPC vs gRPC, implementing HATEOAS, designing bulk operations,
  content negotiation, caching strategies for APIs, or reviewing API design quality.
  Triggers: API, REST, endpoint, route, HTTP method, status code, pagination, cursor,
  offset, error response, problem details, RFC 9457, rate limit, idempotency,
  webhook, OpenAPI, Swagger, GraphQL, tRPC, gRPC, HATEOAS, versioning, API key,
  OAuth, Bearer token, bulk operation, content negotiation, API documentation.
---

# REST API Design Skill

Design APIs that developers love. Consistent resource naming, predictable status codes,
machine-readable errors, and pagination that works at scale. An API is a contract —
treat it with the same rigor as a database schema.

---

## Core Principles

| Principle | Meaning |
|---|---|
| **Resources, not actions** | URLs are nouns (`/orders`), HTTP methods are verbs (`GET`, `POST`) |
| **Stateless** | Every request contains all information needed. No server-side session |
| **Consistent and predictable** | Same patterns everywhere. Learn one endpoint, know them all |
| **Use HTTP correctly** | Methods, status codes, headers, caching — the protocol already solved it |
| **Errors are part of the API** | Structured, machine-readable, documented error responses |
| **Design for evolution** | Additive changes are safe. Removals need versioning and deprecation |

---

## Workflow: API Design

```
1. IDENTIFY RESOURCES  -> List the domain nouns (users, orders, invoices)
2. MAP OPERATIONS      -> CRUD + custom actions per resource
3. DEFINE CONTRACTS    -> Request/response schemas, error shapes, pagination
4. WRITE OPENAPI SPEC  -> Schema-first: spec before implementation
5. MOCK + REVIEW       -> Generate mock server, get consumer feedback
6. IMPLEMENT           -> Server + client SDKs from spec
7. TEST                -> Contract tests, load tests, negative path tests
```

---

## API Style Decision Tree

```
What kind of API?
|
+-- Public API for third parties?
|   -> REST + OpenAPI 3.1
|   -> Maximum interop, any language, cacheable, well-understood
|
+-- Internal microservices (same org)?
|   -> gRPC (strongly typed, streaming, code generation)
|   -> or REST if team prefers simplicity over performance
|
+-- Frontend <-> Backend (TypeScript both sides)?
|   -> tRPC (end-to-end type safety, no code generation, no schema)
|   -> Falls back to REST if non-TS clients are added later
|
+-- Multiple clients, each needs different data shapes?
|   -> GraphQL (clients query exactly what they need)
|   -> Consider BFF (Backend For Frontend) pattern as simpler alternative
|
+-- Real-time bidirectional communication?
|   -> WebSocket (full-duplex, persistent connection)
|   -> SSE (server-to-client only, simpler, auto-reconnect)
|
+-- Simple CRUD, standard web app?
    -> REST (proven, cacheable, tooling everywhere)
```

**Key trade-offs:**

| Style | Strengths | Weaknesses |
|---|---|---|
| **REST** | Caching, HTTP tooling, universally understood | Over-fetching, under-fetching, many round trips |
| **GraphQL** | Flexible queries, single endpoint, introspection | Caching complexity, N+1 risk, query cost control |
| **tRPC** | Zero schema overhead, full TypeScript inference | TypeScript-only, tight coupling to server types |
| **gRPC** | Binary protocol, streaming, code generation | Browser support needs proxy, debugging harder |

---

## Resource Naming

### Rules

```
1. Plural nouns:             /users, /orders, /invoices
2. Kebab-case for multi-word: /line-items, /payment-methods
3. Resource IDs in path:     /users/{userId}/orders/{orderId}
4. Max 2 levels of nesting:  /users/{userId}/orders (OK)
                              /users/{id}/orders/{id}/items/{id}/comments (TOO DEEP)
5. Flatten deep nesting:     /order-items/{itemId}/comments (better)
6. No verbs in URLs:         /users (not /getUsers, not /createUser)
7. No trailing slashes:      /users (not /users/)
8. Collection = plural:      GET /users     -> list
                              GET /users/42  -> single
```

### Custom Actions (When CRUD Is Not Enough)

```
POST /orders/{orderId}/cancel          -> Action on a resource
POST /orders/{orderId}/refund          -> Action on a resource
POST /reports/generate                 -> Trigger a process
POST /users/{userId}/verify-email      -> Action on a sub-resource

# Sub-resource pattern for non-CRUD
POST /payments/{paymentId}/capture     -> Capture an authorized payment
POST /payments/{paymentId}/void        -> Void an authorized payment
```

### Query Parameters for Filtering (Not Path Segments)

```
GET /orders?status=shipped&created_after=2025-01-01
GET /products?category=electronics&min_price=100&max_price=500
GET /users?role=admin&sort=-created_at&fields=id,name,email
```

---

## HTTP Methods

| Method | Semantics | Idempotent | Safe | Request Body | Typical Status |
|---|---|---|---|---|---|
| `GET` | Read resource(s) | Yes | Yes | No | 200 |
| `POST` | Create resource or trigger action | No | No | Yes | 201 (create), 200/202 (action) |
| `PUT` | Full replacement of resource | Yes | No | Yes | 200 or 204 |
| `PATCH` | Partial update of resource | No* | No | Yes | 200 |
| `DELETE` | Remove resource | Yes | No | No | 204 or 200 |
| `HEAD` | Same as GET but no body | Yes | Yes | No | 200 |
| `OPTIONS` | Describe communication options | Yes | Yes | No | 204 |

*PATCH is idempotent only if using JSON Merge Patch. JSON Patch operations may not be.

### Method Examples

```
# Create a user
POST /users
Content-Type: application/json
{ "email": "ada@example.com", "name": "Ada Lovelace" }
-> 201 Created
   Location: /users/usr_abc123

# Get a user
GET /users/usr_abc123
-> 200 OK
   { "id": "usr_abc123", "email": "ada@example.com", ... }

# Full replacement (PUT) — client sends the ENTIRE resource
PUT /users/usr_abc123
{ "email": "ada@example.com", "name": "Augusta Ada King" }
-> 200 OK

# Partial update (PATCH) — client sends only changed fields
PATCH /users/usr_abc123
Content-Type: application/merge-patch+json
{ "name": "Augusta Ada King" }
-> 200 OK

# Delete
DELETE /users/usr_abc123
-> 204 No Content

# POST is not always "create" — use for actions
POST /orders/ord_xyz/cancel
-> 200 OK
   { "id": "ord_xyz", "status": "cancelled" }
```

---

## Status Codes

### Decision Tree

```
Was the request successful?
|
+-- YES (2xx)
|   +-- Returning data?           -> 200 OK
|   +-- Created a new resource?   -> 201 Created (+ Location header)
|   +-- Accepted for async work?  -> 202 Accepted (+ polling URL)
|   +-- No content to return?     -> 204 No Content
|
+-- REDIRECT (3xx)
|   +-- Moved permanently?        -> 301 Moved Permanently
|   +-- Resource at different URL? -> 303 See Other (after POST)
|   +-- Not modified (cache)?     -> 304 Not Modified
|   +-- Temporary redirect?       -> 307 Temporary Redirect (preserves method)
|   +-- Permanent redirect?       -> 308 Permanent Redirect (preserves method)
|
+-- CLIENT ERROR (4xx) — caller's fault
|   +-- Malformed request?        -> 400 Bad Request
|   +-- Not authenticated?        -> 401 Unauthorized (should be "Unauthenticated")
|   +-- Authenticated but forbidden? -> 403 Forbidden
|   +-- Resource not found?       -> 404 Not Found
|   +-- HTTP method not allowed?  -> 405 Method Not Allowed (+ Allow header)
|   +-- Conflict (duplicate, state)? -> 409 Conflict
|   +-- Validation failed?        -> 422 Unprocessable Entity
|   +-- Rate limited?             -> 429 Too Many Requests (+ Retry-After)
|
+-- SERVER ERROR (5xx) — our fault
    +-- Unexpected error?         -> 500 Internal Server Error
    +-- Upstream service failed?  -> 502 Bad Gateway
    +-- Service unavailable?      -> 503 Service Unavailable (+ Retry-After)
    +-- Upstream timeout?         -> 504 Gateway Timeout
```

### Common Mistakes

| Mistake | Why It's Wrong | Correct |
|---|---|---|
| 200 for everything + error in body | Breaks HTTP clients, caching, proxies | Use proper 4xx/5xx codes |
| 404 for authorization failures | Leaks existence of resource | 403 if existence is not sensitive |
| 401 when user is authenticated but lacks permission | 401 = "who are you?", 403 = "you can't do that" | 403 Forbidden |
| 500 for validation errors | Client can't distinguish server bug from bad input | 400 or 422 |
| 200 for DELETE | Ambiguous — did anything happen? | 204 No Content (or 200 with deleted resource) |

---

## Error Responses (RFC 9457 — Problem Details)

RFC 9457 (formerly RFC 7807) defines a standard error format. Use it for every API error.

### Structure

```json
{
  "type": "https://api.example.com/problems/insufficient-funds",
  "title": "Insufficient Funds",
  "status": 422,
  "detail": "Account acc_123 has $10.00 but transfer requires $50.00.",
  "instance": "/transfers/txn_abc789",
  "balance": 1000,
  "cost": 5000
}
```

| Field | Required | Purpose |
|---|---|---|
| `type` | Yes | URI identifying the problem type (stable, documented) |
| `title` | Yes | Short human-readable summary (same for all instances of this type) |
| `status` | Yes | HTTP status code (redundant but useful for logging) |
| `detail` | No | Human-readable explanation specific to this occurrence |
| `instance` | No | URI identifying this specific occurrence |
| *extensions* | No | Additional machine-readable fields (e.g., `balance`, `retryAfter`) |

### TypeScript Implementation

```typescript
// Content-Type: application/problem+json
interface ProblemDetail {
  type: string;
  title: string;
  status: number;
  detail?: string;
  instance?: string;
  [key: string]: unknown; // Extension fields
}

// Validation error with field-level details
interface ValidationProblem extends ProblemDetail {
  type: 'https://api.example.com/problems/validation-error';
  errors: Array<{
    field: string;
    message: string;
    code: string;
  }>;
}

// Example response
const validationError: ValidationProblem = {
  type: 'https://api.example.com/problems/validation-error',
  title: 'Validation Error',
  status: 422,
  detail: '2 fields failed validation.',
  errors: [
    { field: 'email', message: 'Must be a valid email address', code: 'invalid_format' },
    { field: 'name', message: 'Must be between 1 and 100 characters', code: 'invalid_length' },
  ],
};

// Express error handler producing RFC 9457 responses
const errorHandler: ErrorRequestHandler = (err, req, res, _next) => {
  if (err instanceof AppError) {
    return res
      .status(err.statusCode)
      .type('application/problem+json')
      .json({
        type: `https://api.example.com/problems/${err.code}`,
        title: err.title,
        status: err.statusCode,
        detail: err.message,
        instance: req.originalUrl,
        ...(err.extensions ?? {}),
      });
  }

  // Unknown errors — never leak internals
  res.status(500).type('application/problem+json').json({
    type: 'https://api.example.com/problems/internal-error',
    title: 'Internal Server Error',
    status: 500,
    instance: req.originalUrl,
  });
};
```

### Python Implementation (FastAPI)

```python
from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse

app = FastAPI()

class ProblemDetail(Exception):
    def __init__(
        self,
        type: str,
        title: str,
        status: int,
        detail: str | None = None,
        instance: str | None = None,
        **extensions,
    ):
        self.type = type
        self.title = title
        self.status = status
        self.detail = detail
        self.instance = instance
        self.extensions = extensions

@app.exception_handler(ProblemDetail)
async def problem_detail_handler(request: Request, exc: ProblemDetail):
    body = {
        "type": exc.type,
        "title": exc.title,
        "status": exc.status,
    }
    if exc.detail:
        body["detail"] = exc.detail
    if exc.instance:
        body["instance"] = exc.instance
    body.update(exc.extensions)
    return JSONResponse(
        status_code=exc.status,
        content=body,
        media_type="application/problem+json",
    )

# Usage
@app.post("/transfers")
async def create_transfer(transfer: TransferRequest):
    if account.balance < transfer.amount:
        raise ProblemDetail(
            type="https://api.example.com/problems/insufficient-funds",
            title="Insufficient Funds",
            status=422,
            detail=f"Account {account.id} has ${account.balance / 100:.2f}.",
            balance=account.balance,
            cost=transfer.amount,
        )
```

---

## Pagination

### Decision Tree

```
What kind of data?
|
+-- Infinite scroll / "load more" UI?
|   -> Cursor-based pagination
|   -> Stable under inserts/deletes, consistent, O(1)
|
+-- User needs "jump to page 5"?
|   -> Offset-based pagination (with caveats)
|   -> Simple but expensive on large tables (OFFSET scans rows)
|
+-- Large table + stable + performant?
|   -> Keyset pagination (WHERE id > :last_id)
|   -> O(1) with index, but no random page access
|
+-- Search results with relevance?
    -> Search-after token (Elasticsearch-style)
    -> Opaque cursor from search engine
```

### Cursor-Based Pagination (Recommended)

```typescript
// Request
// GET /users?limit=20&cursor=eyJpZCI6InVzcl8xMjMiLCJjcmVhdGVkQXQiOiIyMDI1LTAxLTAxIn0=

// Response envelope
interface PaginatedResponse<T> {
  data: T[];
  pagination: {
    next_cursor: string | null;   // Opaque base64 cursor
    has_more: boolean;
  };
}

// Implementation
async function listUsers(cursor?: string, limit = 20): Promise<PaginatedResponse<User>> {
  const decoded = cursor
    ? JSON.parse(Buffer.from(cursor, 'base64url').toString())
    : null;

  const users = await db.query(`
    SELECT * FROM users
    WHERE ($1::timestamptz IS NULL OR created_at < $1)
    ORDER BY created_at DESC
    LIMIT $2
  `, [decoded?.created_at ?? null, limit + 1]);

  const hasMore = users.length > limit;
  const items = hasMore ? users.slice(0, -1) : users;
  const lastItem = items[items.length - 1];

  return {
    data: items,
    pagination: {
      next_cursor: hasMore
        ? Buffer.from(JSON.stringify({
            id: lastItem.id,
            created_at: lastItem.created_at,
          })).toString('base64url')
        : null,
      has_more: hasMore,
    },
  };
}
```

### Offset-Based Pagination (Simple but Limited)

```typescript
// GET /users?page=3&per_page=20

interface OffsetPaginatedResponse<T> {
  data: T[];
  pagination: {
    page: number;
    per_page: number;
    total_count: number;
    total_pages: number;
  };
}

// Performance degrades on large tables:
// OFFSET 100000 still scans 100,000 rows before returning results
// Use only for small datasets or admin UIs where page jumping is needed
```

### Keyset Pagination (Performant for Large Tables)

```sql
-- First page
SELECT * FROM orders
WHERE user_id = 42
ORDER BY created_at DESC, id DESC
LIMIT 20;

-- Next page (use last item's values as boundary)
SELECT * FROM orders
WHERE user_id = 42
  AND (created_at, id) < ('2025-03-15T10:00:00Z', 'ord_abc')
ORDER BY created_at DESC, id DESC
LIMIT 20;

-- Requires composite index:
CREATE INDEX idx_orders_user_created ON orders (user_id, created_at DESC, id DESC);
```

---

## Filtering, Sorting, and Field Selection

### Filtering

```
# Equality
GET /orders?status=shipped

# Multiple values (OR)
GET /orders?status=shipped,delivered

# Range
GET /orders?created_after=2025-01-01&created_before=2025-12-31
GET /products?min_price=100&max_price=500

# Search
GET /users?q=ada+lovelace

# Nested field
GET /orders?customer.country=US
```

### Sorting

```
# Single field (prefix - for descending)
GET /users?sort=-created_at

# Multiple fields (comma-separated)
GET /orders?sort=-priority,created_at

# Default sort should always be defined and documented
```

### Field Selection (Sparse Fieldsets)

```
# Return only requested fields (reduces payload)
GET /users?fields=id,name,email

# Nested fields
GET /orders?fields=id,status,customer.name,total

# Expand related resources inline (avoid N+1 on client)
GET /orders?expand=customer,line_items
```

### Implementation Pattern

```typescript
// Zod schema for query parameters
const ListOrdersQuery = z.object({
  status: z.enum(['pending', 'shipped', 'delivered', 'cancelled']).optional(),
  created_after: z.coerce.date().optional(),
  created_before: z.coerce.date().optional(),
  sort: z.string().default('-created_at'),
  fields: z.string().optional().transform(s => s?.split(',')),
  cursor: z.string().optional(),
  limit: z.coerce.number().int().min(1).max(100).default(20),
});

// Parse sort parameter into SQL ORDER BY
function parseSortParam(sort: string, allowedFields: Set<string>): string {
  return sort.split(',').map(field => {
    const desc = field.startsWith('-');
    const name = desc ? field.slice(1) : field;
    if (!allowedFields.has(name)) throw new ValidationError(`Invalid sort field: ${name}`);
    return `${name} ${desc ? 'DESC' : 'ASC'}`;
  }).join(', ');
}
```

---

## API Versioning

### Decision Tree

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

## Authentication

### Decision Tree

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

### Response (Per-Item Status)

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

### HTTP Status for Batch

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

---

## OpenAPI 3.1 Specification

### Schema-First vs Code-First

```
Which approach?
|
+-- Public API with external consumers?
|   -> Schema-first (write OpenAPI spec, then implement)
|   -> Spec is the contract. Implementation follows.
|
+-- Internal API, fast iteration?
|   -> Code-first (generate spec from code annotations)
|   -> Faster development, spec stays in sync automatically.
|
+-- TypeScript + tRPC?
    -> Neither — types ARE the spec
```

### Essential Schema Example

```yaml
openapi: 3.1.0
info:
  title: Order API
  version: 1.0.0
  description: Manage customer orders
  contact:
    email: api@example.com
  license:
    name: MIT

servers:
  - url: https://api.example.com/v1
    description: Production
  - url: https://api.staging.example.com/v1
    description: Staging

paths:
  /orders:
    get:
      operationId: listOrders
      summary: List orders
      tags: [Orders]
      parameters:
        - name: status
          in: query
          schema:
            type: string
            enum: [pending, shipped, delivered, cancelled]
        - name: cursor
          in: query
          schema:
            type: string
        - name: limit
          in: query
          schema:
            type: integer
            minimum: 1
            maximum: 100
            default: 20
      responses:
        '200':
          description: Paginated list of orders
          content:
            application/json:
              schema:
                type: object
                required: [data, pagination]
                properties:
                  data:
                    type: array
                    items:
                      $ref: '#/components/schemas/Order'
                  pagination:
                    $ref: '#/components/schemas/CursorPagination'
        '401':
          $ref: '#/components/responses/Unauthorized'
        '429':
          $ref: '#/components/responses/RateLimited'

    post:
      operationId: createOrder
      summary: Create an order
      tags: [Orders]
      parameters:
        - name: Idempotency-Key
          in: header
          required: true
          schema:
            type: string
            format: uuid
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/CreateOrderRequest'
      responses:
        '201':
          description: Order created
          headers:
            Location:
              schema:
                type: string
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Order'
        '422':
          $ref: '#/components/responses/ValidationError'

components:
  schemas:
    Order:
      type: object
      required: [id, status, total, currency, created_at]
      properties:
        id:
          type: string
          example: ord_abc123
        status:
          type: string
          enum: [pending, shipped, delivered, cancelled]
        total:
          type: integer
          description: Amount in cents
          example: 5000
        currency:
          type: string
          example: usd
        created_at:
          type: string
          format: date-time

    CursorPagination:
      type: object
      required: [has_more]
      properties:
        next_cursor:
          type: [string, 'null']      # OpenAPI 3.1: use type array, not nullable
        has_more:
          type: boolean

    ProblemDetail:
      type: object
      required: [type, title, status]
      properties:
        type:
          type: string
          format: uri
        title:
          type: string
        status:
          type: integer
        detail:
          type: string
        instance:
          type: string

  responses:
    Unauthorized:
      description: Authentication required
      content:
        application/problem+json:
          schema:
            $ref: '#/components/schemas/ProblemDetail'
    RateLimited:
      description: Rate limit exceeded
      headers:
        Retry-After:
          schema:
            type: integer
      content:
        application/problem+json:
          schema:
            $ref: '#/components/schemas/ProblemDetail'
    ValidationError:
      description: Validation failed
      content:
        application/problem+json:
          schema:
            allOf:
              - $ref: '#/components/schemas/ProblemDetail'
              - type: object
                properties:
                  errors:
                    type: array
                    items:
                      type: object
                      properties:
                        field:
                          type: string
                        message:
                          type: string

  securitySchemes:
    BearerAuth:
      type: http
      scheme: bearer
      bearerFormat: JWT
    ApiKeyAuth:
      type: apiKey
      in: header
      name: X-API-Key

security:
  - BearerAuth: []
  - ApiKeyAuth: []
```

### SDK Generation

```bash
# Generate TypeScript client from OpenAPI spec
npx openapi-typescript api.yaml -o src/api-types.ts          # Types only
npx @hey-api/openapi-ts -i api.yaml -o src/client            # Full client
npx orval --input api.yaml --output src/api                   # React Query hooks

# Generate server stubs
npx openapi-generator-cli generate -i api.yaml -g nodejs-express-server -o server/
```

---

## API Caching

### ETag + If-None-Match

```typescript
import crypto from 'node:crypto';

// Generate ETag from response body
function generateETag(body: unknown): string {
  const hash = crypto
    .createHash('md5')
    .update(JSON.stringify(body))
    .digest('hex');
  return `"${hash}"`;
}

// Middleware
function conditionalGet(req: Request, res: Response, body: unknown) {
  const etag = generateETag(body);
  res.setHeader('ETag', etag);

  // Client sent If-None-Match — check if data changed
  if (req.headers['if-none-match'] === etag) {
    return res.status(304).end(); // Not Modified — no body sent
  }

  return res.json(body);
}
```

### Cache-Control Patterns

```
# Immutable static assets (hashed filenames)
Cache-Control: public, max-age=31536000, immutable

# API responses (shared data, short TTL)
Cache-Control: public, max-age=60, stale-while-revalidate=300

# User-specific data (private, short TTL)
Cache-Control: private, max-age=60

# Sensitive data (never cache)
Cache-Control: no-store

# HTML pages (always revalidate)
Cache-Control: public, max-age=0, must-revalidate
```

### CDN-Friendly Patterns

```
1. Vary header: Vary: Accept, Authorization
   Tells CDN to cache separate versions per Accept/Authorization value

2. Surrogate keys (CDN tag-based invalidation):
   Surrogate-Key: user-123 users-list
   -> Invalidate "user-123" tag when user 123 changes

3. CDN bypass for authenticated requests:
   Cache-Control: private (CDN won't cache)
   or: CDN rule to bypass cache when Authorization header is present

4. stale-while-revalidate for API responses:
   Cache-Control: public, max-age=10, stale-while-revalidate=60
   Serve stale data instantly, revalidate in background
```

---

## HATEOAS (Hypermedia as the Engine of Application State)

```json
{
  "id": "ord_abc123",
  "status": "pending",
  "total": 5000,
  "_links": {
    "self": { "href": "/orders/ord_abc123" },
    "cancel": { "href": "/orders/ord_abc123/cancel", "method": "POST" },
    "pay": { "href": "/orders/ord_abc123/pay", "method": "POST" },
    "customer": { "href": "/users/usr_xyz" }
  }
}
```

**When to use HATEOAS:**
- Public APIs with many consumers who need discoverability
- Workflow-driven APIs (state machines) where valid actions depend on state
- When you want clients to follow links, not hardcode URLs

**When to skip HATEOAS:**
- Internal APIs with known consumers
- tRPC/GraphQL (different paradigms)
- Simple CRUD APIs

---

## Content Negotiation

```
# Client requests specific format
GET /orders/ord_abc123
Accept: application/json           -> JSON response
Accept: application/xml            -> XML response (if supported)
Accept: text/csv                   -> CSV response (for exports)
Accept: application/pdf            -> PDF response (for invoices)

# Server responds with what it can provide
Content-Type: application/json

# If server can't satisfy Accept header:
406 Not Acceptable
```

```typescript
// Content negotiation in Express
router.get('/orders/:id', async (req, res) => {
  const order = await getOrder(req.params.id);

  res.format({
    'application/json': () => res.json(order),
    'text/csv': () => res.type('text/csv').send(orderToCsv(order)),
    'application/pdf': () => {
      const pdf = await generateInvoicePdf(order);
      res.type('application/pdf').send(pdf);
    },
    default: () => res.status(406).json({
      type: 'https://api.example.com/problems/not-acceptable',
      title: 'Not Acceptable',
      status: 406,
      detail: 'Supported formats: application/json, text/csv, application/pdf',
    }),
  });
});
```

---

## Anti-Patterns

| Anti-Pattern | Why It's Dangerous | Fix |
|---|---|---|
| Verbs in URLs (`/getUser`, `/createOrder`) | Breaks REST semantics, inconsistent | Use nouns + HTTP methods |
| 200 OK with `{ "error": "not found" }` | Breaks HTTP clients, caching, monitoring | Proper 4xx/5xx status codes |
| Returning different shapes for same resource | Client must handle multiple formats | Consistent response schema per resource |
| Nested URLs 3+ levels deep | Hard to maintain, ambiguous ownership | Flatten to max 2 levels |
| No pagination on list endpoints | Memory exhaustion, timeouts on large data | Always paginate, default limit |
| Using OFFSET for large datasets | Scans N rows before returning results | Cursor-based or keyset pagination |
| Leaking internal IDs (auto-increment) | Reveals scale, enables enumeration | Use UUIDs or prefixed IDs (`usr_abc`) |
| No rate limiting | DoS, abuse, runaway scripts | Rate limit by API key/IP |
| Breaking changes without versioning | Breaks all existing clients | Additive changes or version bump |
| Secrets in query parameters | Logged in access logs everywhere | Use Authorization header |
| No idempotency on POST endpoints | Duplicate payments, orders on retry | Idempotency-Key header |
| Inconsistent error format | Clients need special handling per endpoint | RFC 9457 Problem Details everywhere |
| No request/response validation | Garbage in, garbage out, injection risk | Zod/JSON Schema on both sides |
| Returning 500 for client errors | Triggers false alerts, hides real server bugs | 4xx for client errors, 5xx for server errors |
| Over-fetching (returning all fields always) | Wasted bandwidth, slow mobile clients | Field selection or GraphQL |
| Coupling API to database schema | Schema change = API break | Separate API models from DB models |
| No Retry-After on 429/503 | Clients retry immediately, making it worse | Always include Retry-After header |

---

## Checklist: API Design Review

### Resource Design
- [ ] URLs use plural nouns, no verbs
- [ ] Consistent kebab-case naming
- [ ] Max 2 levels of resource nesting
- [ ] Custom actions use `POST /resource/{id}/action` pattern

### HTTP Semantics
- [ ] Correct HTTP methods for each operation
- [ ] Status codes match semantics (not 200 for everything)
- [ ] Location header returned on 201 Created
- [ ] Allow header returned on 405 Method Not Allowed

### Error Handling
- [ ] RFC 9457 Problem Details format for all errors
- [ ] Content-Type `application/problem+json` on error responses
- [ ] Validation errors include field-level detail
- [ ] No internal stack traces or implementation details leaked

### Pagination and Filtering
- [ ] All list endpoints are paginated (default + max limit)
- [ ] Cursor-based pagination for large/real-time datasets
- [ ] Sort parameter supports ascending and descending
- [ ] Filters use query parameters, not path segments

### Security
- [ ] Authentication on all non-public endpoints
- [ ] API keys in headers, never in query strings
- [ ] Rate limiting with RateLimit-* response headers
- [ ] Idempotency-Key required on non-idempotent POST endpoints
- [ ] CORS configured with specific origins

### Versioning and Evolution
- [ ] Versioning strategy chosen and documented
- [ ] Breaking changes go through deprecation lifecycle
- [ ] Sunset and Deprecation headers on deprecated endpoints
- [ ] Additive changes preferred over version bumps

### Documentation
- [ ] OpenAPI 3.1 specification maintained
- [ ] All endpoints have operationId, summary, and examples
- [ ] Error responses documented with all possible types
- [ ] Authentication requirements documented per endpoint

### Webhooks (If Applicable)
- [ ] HMAC-SHA256 payload signing with per-subscriber secrets
- [ ] Timestamp in signature (replay attack prevention)
- [ ] Exponential backoff retry with max attempts
- [ ] Delivery status tracking and alerting on failure

### Performance
- [ ] ETag and If-None-Match for conditional requests
- [ ] Cache-Control headers appropriate per endpoint
- [ ] Bulk endpoints available for batch operations
- [ ] Response payloads are minimal (no over-fetching)
