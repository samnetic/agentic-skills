# Backend Performance Reference

## Table of Contents

- [Server-Side Profiling](#server-side-profiling)
  - [Node.js Profiling](#nodejs-profiling)
  - [Python Profiling](#python-profiling)
  - [Distributed Tracing with OpenTelemetry](#distributed-tracing-with-opentelemetry)
- [Database Query Optimization](#database-query-optimization)
  - [N+1 Detection and Fix](#n1-detection-and-fix)
  - [Query Plan Analysis](#query-plan-analysis)
  - [Connection Pool Tuning](#connection-pool-tuning)
  - [Prepared Statements](#prepared-statements)
- [Caching Strategies](#caching-strategies)
  - [Cache-Aside Pattern with Redis](#cache-aside-pattern-with-redis)
  - [Stale-While-Revalidate](#stale-while-revalidate)
- [Connection Pooling](#connection-pooling)
- [Pagination](#pagination)
- [Load Testing with k6](#load-testing-with-k6)

---

## Server-Side Profiling

### Node.js Profiling

```bash
# 1. Built-in V8 profiler — generates a log file for analysis
node --prof src/server.js
# Process the output into human-readable format:
node --prof-process isolate-*.log > profile.txt
# Look for: [JavaScript] section -> functions with highest ticks

# 2. clinic.js — all-in-one diagnostic suite
npx clinic doctor -- node src/server.js
# Generates HTML report: identifies event loop delays, GC pressure, I/O issues

npx clinic flame -- node src/server.js
# Generates interactive flamegraph — drill into hot functions

npx clinic bubbleprof -- node src/server.js
# Visualizes async operations — find async bottlenecks

# 3. 0x — lightweight flamegraph generator
npx 0x src/server.js
# Produces an interactive flamegraph in the browser
# Wide bars = functions consuming the most CPU time

# 4. Node.js built-in diagnostics
node --inspect src/server.js
# Open chrome://inspect in Chrome -> Performance tab -> Record
# Captures: function timings, GC pauses, event loop utilization
```

### Python Profiling

```bash
# 1. cProfile — built-in, low overhead
python -m cProfile -s cumulative app.py
# Sort by: cumulative (total time including subcalls)
# Look for: functions with highest tottime (self time)

# 2. py-spy — sampling profiler, attach to running process
pip install py-spy
py-spy top --pid 12345              # Live top-like view
py-spy record -o profile.svg -- python app.py   # Flamegraph SVG

# 3. scalene — CPU + memory + GPU profiler
pip install scalene
scalene app.py
# Shows: CPU time, memory allocation, memory copying per line
# Highlights lines that allocate the most memory
```

### Distributed Tracing with OpenTelemetry

```typescript
// Setup OpenTelemetry tracing for a Node.js service
import { NodeSDK } from '@opentelemetry/sdk-node';
import { getNodeAutoInstrumentations } from '@opentelemetry/auto-instrumentations-node';
import { OTLPTraceExporter } from '@opentelemetry/exporter-trace-otlp-http';

const sdk = new NodeSDK({
  traceExporter: new OTLPTraceExporter({
    url: 'http://jaeger:4318/v1/traces',
  }),
  instrumentations: [getNodeAutoInstrumentations()],
  serviceName: 'order-service',
});
sdk.start();

// Custom spans for business-critical operations
import { trace } from '@opentelemetry/api';

const tracer = trace.getTracer('order-service');

async function processOrder(orderId: string) {
  return tracer.startActiveSpan('processOrder', async (span) => {
    span.setAttribute('order.id', orderId);
    try {
      await validateOrder(orderId);      // Auto-creates child span
      await chargePayment(orderId);      // Auto-creates child span
      await sendConfirmation(orderId);   // Auto-creates child span
      span.setStatus({ code: SpanStatusCode.OK });
    } catch (error) {
      span.setStatus({ code: SpanStatusCode.ERROR, message: error.message });
      span.recordException(error);
      throw error;
    } finally {
      span.end();
    }
  });
}
```

**What to look for in traces:**
- Spans with high duration — the bottleneck
- Sequential spans that could be parallel — `Promise.all` opportunity
- Many small spans to the same service — batching opportunity
- Gaps between spans — event loop blocking or GC pause

---

## Database Query Optimization

```sql
-- N+1 Problem: 1 query for users + N queries for posts
-- BAD (100 users = 101 queries):
SELECT * FROM users LIMIT 100;
-- For each user:
SELECT * FROM posts WHERE user_id = ?;

-- GOOD (2 queries):
SELECT * FROM users LIMIT 100;
SELECT * FROM posts WHERE user_id IN (1, 2, 3, ...);

-- BEST (1 query with JOIN):
SELECT u.*, p.title, p.created_at
FROM users u
LEFT JOIN LATERAL (
  SELECT * FROM posts WHERE user_id = u.id
  ORDER BY created_at DESC LIMIT 5
) p ON true
LIMIT 100;
```

### N+1 Detection and Fix

```typescript
// ORM-level: Prisma — use include/select to batch load
// BAD — triggers N+1:
const users = await prisma.user.findMany();
for (const user of users) {
  const posts = await prisma.post.findMany({ where: { userId: user.id } });
}

// GOOD — single query with include:
const users = await prisma.user.findMany({
  include: { posts: { take: 5, orderBy: { createdAt: 'desc' } } },
});

// DataLoader pattern (for GraphQL or batch scenarios):
import DataLoader from 'dataloader';

const postLoader = new DataLoader(async (userIds: string[]) => {
  const posts = await prisma.post.findMany({
    where: { userId: { in: [...userIds] } },
  });
  // Return posts grouped by userId, in the same order as input
  return userIds.map(id => posts.filter(p => p.userId === id));
});

// Usage — automatically batches and deduplicates within a tick:
const userPosts = await postLoader.load(userId);
```

### Query Plan Analysis

```sql
-- Always use EXPLAIN ANALYZE on slow queries:
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT * FROM orders WHERE user_id = 42 ORDER BY created_at DESC LIMIT 10;

-- What to look for in the plan:
-- Seq Scan          -> Missing index. Add one on the filtered column
-- Nested Loop       -> Potential N+1. Consider JOIN or batch query
-- Sort              -> Missing index for ORDER BY. Add composite index
-- Hash Join         -> OK for large datasets. Check if smaller table fits memory
-- Bitmap Index Scan -> Index is being used but not perfectly. May be OK
-- Index Only Scan   -> Best case. Everything served from index (covering index)

-- Covering index — includes all columns the query needs:
CREATE INDEX idx_orders_user_date ON orders (user_id, created_at DESC)
  INCLUDE (total, status);
-- Now "SELECT total, status FROM orders WHERE user_id = X ORDER BY created_at DESC"
-- is an Index Only Scan — never touches the table heap
```

### Connection Pool Tuning

```typescript
// Optimal pool size formula (from PostgreSQL wiki):
// connections = (core_count * 2) + effective_spindle_count
// For SSD: effective_spindle_count = 1
// Example: 4-core server -> (4 * 2) + 1 = 9 connections

const pool = new Pool({
  connectionString: DATABASE_URL,
  max: 10,                       // Match server capacity
  min: 2,                        // Keep some connections warm
  idleTimeoutMillis: 30000,      // Close idle connections after 30s
  connectionTimeoutMillis: 5000, // Fail fast if can't connect
  statement_timeout: 30000,      // Kill queries running > 30s
});

// Monitor pool health:
pool.on('error', (err) => logger.error('Pool error', err));
pool.on('connect', () => metrics.increment('db.pool.connect'));
pool.on('remove', () => metrics.increment('db.pool.remove'));

// Log pool stats periodically:
setInterval(() => {
  logger.info('Pool stats', {
    total: pool.totalCount,
    idle: pool.idleCount,
    waiting: pool.waitingCount,
  });
}, 60000);
```

### Prepared Statements

```typescript
// Prepared statements — parse SQL once, execute many times
// Most ORMs do this automatically. For raw SQL:

// node-postgres — prepared statement:
const result = await pool.query({
  name: 'get-user-orders',  // Named -> prepared on first call, reused after
  text: 'SELECT * FROM orders WHERE user_id = $1 ORDER BY created_at DESC LIMIT $2',
  values: [userId, limit],
});

// Benefits:
// 1. Parse and plan SQL once, not on every call
// 2. Better execution plans (PostgreSQL can optimize for parameter patterns)
// 3. Protection against SQL injection
```

---

## Caching Strategies

### Cache-Aside Pattern with Redis

```typescript
// Redis cache-aside pattern
async function getUser(id: string): Promise<User> {
  const cacheKey = `user:${id}`;

  // Check cache
  const cached = await redis.get(cacheKey);
  if (cached) return JSON.parse(cached);

  // Cache miss — query DB
  const user = await db.user.findUnique({ where: { id } });
  if (!user) throw new NotFoundError('User', id);

  // Store in cache with TTL
  await redis.setex(cacheKey, 300, JSON.stringify(user)); // 5 min TTL

  return user;
}

// Invalidate on write
async function updateUser(id: string, data: UpdateUser): Promise<User> {
  const user = await db.user.update({ where: { id }, data });
  await redis.del(`user:${id}`); // Invalidate cache
  return user;
}
```

### Stale-While-Revalidate

```
Cache-Control: public, max-age=60, stale-while-revalidate=300

Timeline:
0-60s:   Serve from cache (fresh)
60-360s: Serve stale from cache immediately, revalidate in background
360s+:   Cache expired, fetch fresh response

Result: Users always get instant response. Data is at most 5 min stale.
```

---

## Connection Pooling

```typescript
// Database connection pool
const pool = new Pool({
  connectionString: DATABASE_URL,
  max: 20,                    // Max connections (match server capacity)
  idleTimeoutMillis: 30000,   // Close idle connections after 30s
  connectionTimeoutMillis: 5000, // Fail fast if can't connect
});

// HTTP keep-alive for external APIs
import { Agent } from 'node:http';
const agent = new Agent({
  keepAlive: true,
  maxSockets: 50,             // Max concurrent to same host
  maxFreeSockets: 10,         // Idle sockets to keep
});
```

---

## Pagination

```typescript
// Cursor-based pagination (O(1) regardless of page)
// NEVER use OFFSET for large tables — it scans and discards rows
async function listUsers(cursor?: string, limit = 20) {
  const users = await db.user.findMany({
    take: limit + 1,           // Fetch one extra to check hasMore
    ...(cursor && {
      skip: 1,
      cursor: { id: cursor },
    }),
    orderBy: { createdAt: 'desc' },
  });

  const hasMore = users.length > limit;
  const items = hasMore ? users.slice(0, -1) : users;
  const nextCursor = hasMore ? items[items.length - 1].id : null;

  return { items, nextCursor, hasMore };
}
```

---

## Load Testing with k6

```javascript
// k6 load test script
import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  stages: [
    { duration: '1m', target: 50 },    // Ramp up
    { duration: '3m', target: 50 },    // Steady state
    { duration: '1m', target: 100 },   // Stress
    { duration: '1m', target: 0 },     // Ramp down
  ],
  thresholds: {
    http_req_duration: ['p(95)<200'],   // 95% under 200ms
    http_req_failed: ['rate<0.01'],     // <1% error rate
  },
};

export default function () {
  const res = http.get('http://localhost:3000/api/users');
  check(res, {
    'status is 200': (r) => r.status === 200,
    'response time < 200ms': (r) => r.timings.duration < 200,
  });
  sleep(1);
}
```

```bash
# Run load test
k6 run loadtest.js
k6 run --out json=results.json loadtest.js   # Export results
```
