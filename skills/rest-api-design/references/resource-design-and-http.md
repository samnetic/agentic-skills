# Resource Design, HTTP Methods, Status Codes, and Error Responses

## Table of Contents

- [Resource Naming](#resource-naming)
  - [Rules](#rules)
  - [Custom Actions](#custom-actions-when-crud-is-not-enough)
  - [Query Parameters for Filtering](#query-parameters-for-filtering-not-path-segments)
- [HTTP Methods](#http-methods)
  - [Method Semantics](#method-semantics)
  - [Method Examples](#method-examples)
- [Status Codes](#status-codes)
  - [Decision Tree](#status-code-decision-tree)
  - [Common Mistakes](#common-mistakes)
- [Error Responses — RFC 9457 Problem Details](#error-responses--rfc-9457-problem-details)
  - [Structure](#structure)
  - [TypeScript Implementation](#typescript-implementation)
  - [Python Implementation (FastAPI)](#python-implementation-fastapi)

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

### Method Semantics

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

### Status Code Decision Tree

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

## Error Responses — RFC 9457 Problem Details

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
