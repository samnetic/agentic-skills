# Pagination, Filtering, Caching, and Content Negotiation

## Table of Contents

- [Pagination](#pagination)
  - [Pagination Decision Tree](#pagination-decision-tree)
  - [Cursor-Based Pagination (Recommended)](#cursor-based-pagination-recommended)
  - [Offset-Based Pagination (Simple but Limited)](#offset-based-pagination-simple-but-limited)
  - [Keyset Pagination (Performant for Large Tables)](#keyset-pagination-performant-for-large-tables)
- [Filtering, Sorting, and Field Selection](#filtering-sorting-and-field-selection)
  - [Filtering](#filtering)
  - [Sorting](#sorting)
  - [Field Selection (Sparse Fieldsets)](#field-selection-sparse-fieldsets)
  - [Implementation Pattern](#implementation-pattern)
- [API Caching](#api-caching)
  - [ETag + If-None-Match](#etag--if-none-match)
  - [Cache-Control Patterns](#cache-control-patterns)
  - [CDN-Friendly Patterns](#cdn-friendly-patterns)
- [HATEOAS](#hateoas-hypermedia-as-the-engine-of-application-state)
- [Content Negotiation](#content-negotiation)

---

## Pagination

### Pagination Decision Tree

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
