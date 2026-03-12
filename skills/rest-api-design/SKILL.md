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

1. **Identify resources** — List the domain nouns (users, orders, invoices). Use plural nouns, kebab-case, max 2 levels of nesting. Custom actions use `POST /resource/{id}/action`.
2. **Map operations** — Assign HTTP methods to each resource. `GET` reads, `POST` creates or triggers actions, `PUT` replaces, `PATCH` partially updates, `DELETE` removes. Every method has a correct status code.
3. **Define contracts** — Write request/response schemas. Errors use RFC 9457 Problem Details (`application/problem+json`) with `type`, `title`, `status`, `detail`. Validation errors include field-level `errors` array.
4. **Choose pagination** — Cursor-based for infinite scroll and large datasets (recommended). Offset-based only for small datasets with page jumping. Keyset for large tables needing index performance.
5. **Write OpenAPI spec** — Schema-first for public APIs, code-first for internal. Include `operationId`, examples, error responses, and security schemes.
6. **Add security layer** — Authentication (OAuth 2.0, API keys, JWT), rate limiting with `RateLimit-*` headers, idempotency keys on POST endpoints.
7. **Mock, review, implement** — Generate mock server, get consumer feedback, implement server + client SDKs from spec, write contract and load tests.

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

## Resource Naming Quick Reference

```
1. Plural nouns:             /users, /orders, /invoices
2. Kebab-case for multi-word: /line-items, /payment-methods
3. Resource IDs in path:     /users/{userId}/orders/{orderId}
4. Max 2 levels of nesting:  /users/{userId}/orders (OK)
5. Flatten deep nesting:     /order-items/{itemId}/comments (better)
6. No verbs in URLs:         /users (not /getUsers, not /createUser)
7. No trailing slashes:      /users (not /users/)
8. Custom actions:           POST /orders/{orderId}/cancel
9. Filtering via query:      GET /orders?status=shipped&sort=-created_at
```

---

## HTTP Methods Quick Reference

| Method | Semantics | Idempotent | Safe | Typical Status |
|---|---|---|---|---|
| `GET` | Read resource(s) | Yes | Yes | 200 |
| `POST` | Create or trigger action | No | No | 201 / 200 / 202 |
| `PUT` | Full replacement | Yes | No | 200 / 204 |
| `PATCH` | Partial update | No* | No | 200 |
| `DELETE` | Remove resource | Yes | No | 204 / 200 |

*PATCH is idempotent only with JSON Merge Patch.

---

## Status Code Decision Tree

```
Was the request successful?
|
+-- YES (2xx)
|   +-- Returning data?           -> 200 OK
|   +-- Created a new resource?   -> 201 Created (+ Location header)
|   +-- Accepted for async work?  -> 202 Accepted (+ polling URL)
|   +-- No content to return?     -> 204 No Content
|
+-- CLIENT ERROR (4xx) — caller's fault
|   +-- Malformed request?        -> 400 Bad Request
|   +-- Not authenticated?        -> 401 Unauthorized
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

---

## Error Response Format (RFC 9457)

Every error response MUST use `Content-Type: application/problem+json`:

```json
{
  "type": "https://api.example.com/problems/insufficient-funds",
  "title": "Insufficient Funds",
  "status": 422,
  "detail": "Account acc_123 has $10.00 but transfer requires $50.00.",
  "instance": "/transfers/txn_abc789"
}
```

| Field | Required | Purpose |
|---|---|---|
| `type` | Yes | URI identifying the problem type (stable, documented) |
| `title` | Yes | Short human-readable summary (same for all instances of this type) |
| `status` | Yes | HTTP status code |
| `detail` | No | Human-readable explanation specific to this occurrence |
| `instance` | No | URI identifying this specific occurrence |

Validation errors extend with a field-level `errors` array:

```json
{
  "type": "https://api.example.com/problems/validation-error",
  "title": "Validation Error",
  "status": 422,
  "errors": [
    { "field": "email", "message": "Must be a valid email address", "code": "invalid_format" }
  ]
}
```

---

## Pagination Decision Tree

```
What kind of data?
|
+-- Infinite scroll / "load more" UI?
|   -> Cursor-based (recommended default)
|   -> Stable under inserts/deletes, O(1) with index
|
+-- User needs "jump to page 5"?
|   -> Offset-based (OFFSET scans rows — expensive on large tables)
|
+-- Large table + stable + performant?
|   -> Keyset (WHERE id > :last_id, O(1) with index)
|
+-- Search results with relevance?
    -> Search-after token (opaque cursor from search engine)
```

**Cursor-based response envelope:**

```typescript
interface PaginatedResponse<T> {
  data: T[];
  pagination: {
    next_cursor: string | null;  // Opaque base64 cursor
    has_more: boolean;
  };
}
```

---

## Anti-Patterns

| Anti-Pattern | Why It's Dangerous | Fix |
|---|---|---|
| Verbs in URLs (`/getUser`) | Breaks REST semantics | Use nouns + HTTP methods |
| 200 OK with `{ "error": "..." }` | Breaks HTTP clients, caching, monitoring | Proper 4xx/5xx status codes |
| Different shapes for same resource | Client must handle multiple formats | Consistent schema per resource |
| Nested URLs 3+ levels deep | Hard to maintain, ambiguous ownership | Flatten to max 2 levels |
| No pagination on list endpoints | Memory exhaustion, timeouts | Always paginate, default limit |
| OFFSET for large datasets | Scans N rows before returning | Cursor-based or keyset pagination |
| Leaking auto-increment IDs | Reveals scale, enables enumeration | UUIDs or prefixed IDs (`usr_abc`) |
| No rate limiting | DoS, abuse, runaway scripts | Rate limit by API key/IP |
| Breaking changes without versioning | Breaks all existing clients | Additive changes or version bump |
| Secrets in query parameters | Logged in access logs everywhere | Use Authorization header |
| No idempotency on POST endpoints | Duplicate payments/orders on retry | Idempotency-Key header |
| Inconsistent error format | Clients need special handling | RFC 9457 Problem Details everywhere |
| No request/response validation | Injection risk, garbage data | Zod/JSON Schema on both sides |
| 500 for client errors | False alerts, hides real server bugs | 4xx for client, 5xx for server |
| Coupling API to database schema | Schema change = API break | Separate API models from DB models |
| No Retry-After on 429/503 | Clients retry immediately | Always include Retry-After header |

---

## Progressive Disclosure Map

| Topic | Reference | When to read |
|---|---|---|
| Resource naming rules, HTTP method examples, status code details, RFC 9457 implementations (TS + Python) | `references/resource-design-and-http.md` | Designing endpoints, choosing status codes, implementing error handling |
| Cursor/offset/keyset pagination implementations, filtering/sorting patterns, ETag caching, Cache-Control, HATEOAS, content negotiation | `references/pagination-filtering-caching.md` | Implementing pagination, adding caching headers, content negotiation |
| Authentication decision trees, API keys, JWT, rate limiting (Redis), idempotency middleware, versioning strategies, webhooks (HMAC signing, retries), bulk operations | `references/security-and-operations.md` | Adding auth, rate limiting, idempotency, webhooks, or versioning |
| OpenAPI 3.1 full schema example, schema-first vs code-first, SDK generation commands | `references/openapi-specification.md` | Writing or reviewing OpenAPI specs, generating SDKs |

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
