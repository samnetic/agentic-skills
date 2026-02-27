---
name: performance-optimization
description: >-
  Performance optimization expertise for frontend, backend, and database. Use when
  optimizing page load times, reducing bundle sizes, improving Core Web Vitals,
  profiling CPU/memory usage, optimizing database queries, implementing caching
  strategies (Redis, CDN, HTTP caching), reducing API response times, implementing
  lazy loading and code splitting, optimizing images and assets, connection pooling,
  N+1 query detection, implementing pagination, load testing with k6, identifying
  bottlenecks, memory optimization, reducing Time to First Byte (TTFB), or reviewing
  code for performance issues.
  Triggers: performance, optimization, slow, latency, throughput, bundle size, cache,
  caching, CDN, lazy loading, code splitting, Core Web Vitals, LCP, INP, CLS, TTFB,
  N+1, query optimization, connection pool, load test, k6, memory, profiling, bottleneck,
  speed, response time.
---

# Performance Optimization Skill

Measure first, optimize second. Never optimize without profiling data.
Premature optimization is the root of all evil — but so is shipping slow software.

---

## Core Principles

| Principle | Meaning |
|---|---|
| **Measure before optimizing** | Profile → identify bottleneck → fix → measure again |
| **Optimize the bottleneck** | Only the slowest part matters. Everything else is noise |
| **Caching is the answer** | (But only after you've measured what's slow) |
| **Less is more** | Less code, fewer requests, smaller payloads |
| **Set budgets, enforce them** | Performance budget in CI — fail builds that regress |
| **User perception matters** | Perceived speed (loading states, streaming) over raw speed |

---

## Workflow: Performance Optimization

```
1. MEASURE     → Establish baseline metrics (P50, P95, P99)
2. PROFILE     → Identify the actual bottleneck (not what you think)
3. HYPOTHESIS  → Form specific theory: "X causes Y latency because Z"
4. OPTIMIZE    → Apply the minimum change to address the bottleneck
5. VERIFY      → Measure again. Compare to baseline. Confirm improvement
6. BUDGET      → Add performance test to CI to prevent regression
```

---

## Core Web Vitals Deep Dive

### LCP — Largest Contentful Paint (Target: < 2.5s)

LCP measures when the largest visible content element finishes rendering. Usually a hero image, heading, or video poster.

**Optimization strategies (ordered by impact):**

```html
<!-- 1. Preload the LCP resource — tell the browser about it ASAP -->
<link rel="preload" as="image" href="/hero.webp" fetchpriority="high" />

<!-- 2. Use fetchpriority on the LCP element itself -->
<img src="/hero.webp" alt="Hero" fetchpriority="high" loading="eager" />

<!-- 3. Preconnect to critical third-party origins -->
<link rel="preconnect" href="https://cdn.example.com" />
<link rel="dns-prefetch" href="https://cdn.example.com" />
```

```
LCP Optimization Checklist:
├── Server response time (TTFB < 800ms)
│   ├── Use CDN for static and edge-rendered pages
│   ├── Enable HTTP/2 or HTTP/3
│   ├── Optimize server-side data fetching
│   └── Use streaming SSR (React renderToPipeableStream)
├── Resource load delay
│   ├── Inline critical CSS (< 14KB first paint)
│   ├── Preload LCP image with fetchpriority="high"
│   ├── Avoid render-blocking JavaScript in <head>
│   └── Remove unused CSS (PurgeCSS or Tailwind JIT)
├── Resource load duration
│   ├── Compress images: WebP/AVIF (30-50% smaller)
│   ├── Serve responsive sizes with srcset
│   ├── Use CDN with edge caching
│   └── Enable Brotli compression for text assets
└── Element render delay
    ├── Avoid client-side rendering for LCP content
    ├── Minimize JavaScript that must execute before LCP
    └── Avoid lazy-loading the LCP image
```

### CLS — Cumulative Layout Shift (Target: < 0.1)

CLS measures visual stability. Layout shifts frustrate users and cause misclicks.

```html
<!-- 1. Always set explicit dimensions on images and video -->
<img src="/photo.webp" alt="Photo" width="800" height="600" />
<video width="1280" height="720" poster="/poster.webp"></video>

<!-- 2. Use aspect-ratio CSS for responsive containers -->
<style>
.video-container { aspect-ratio: 16 / 9; }
.avatar { aspect-ratio: 1; width: 48px; }
</style>

<!-- 3. Font display strategy — prevent FOIT/FOUT layout shifts -->
<style>
@font-face {
  font-family: 'CustomFont';
  src: url('/fonts/custom.woff2') format('woff2');
  font-display: optional; /* Best for CLS — uses fallback if font is slow */
}
</style>
```

**Common CLS causes and fixes:**

| Cause | Fix |
|---|---|
| Images without dimensions | Always set `width` and `height` attributes |
| Ads/embeds without reserved space | Use `min-height` placeholder or `aspect-ratio` |
| Web fonts causing FOUT | `font-display: optional` or `font-display: swap` with size-adjust |
| Dynamic content injected above viewport | Insert below the fold, or use `content-visibility: auto` |
| Late-loading CSS | Inline critical CSS, preload stylesheets |
| Animations triggering layout | Use `transform` and `opacity` only (compositor-only properties) |

### INP — Interaction to Next Paint (Target: < 200ms)

INP measures responsiveness. It captures the delay from user input (click, tap, key) to the next visual update.

```typescript
// 1. Break up long tasks with scheduler.yield()
async function processLargeList(items: Item[]) {
  for (let i = 0; i < items.length; i++) {
    processItem(items[i]);

    // Yield to the browser every 5 items so it can handle input
    if (i % 5 === 0) {
      await scheduler.yield();
    }
  }
}

// 2. Fallback for browsers without scheduler.yield()
function yieldToMain(): Promise<void> {
  if ('scheduler' in globalThis && 'yield' in scheduler) {
    return scheduler.yield();
  }
  return new Promise(resolve => setTimeout(resolve, 0));
}

// 3. Debounce expensive event handlers
function handleSearch(query: string) {
  // Don't run search on every keystroke
  clearTimeout(searchTimeout);
  searchTimeout = setTimeout(() => {
    performSearch(query);
  }, 150);
}

// 4. Use startTransition for non-urgent updates (React)
import { startTransition } from 'react';

function handleFilterChange(filter: string) {
  // Urgent: update the input field immediately
  setInputValue(filter);

  // Non-urgent: update the filtered list (can be interrupted)
  startTransition(() => {
    setFilteredItems(items.filter(item => item.name.includes(filter)));
  });
}
```

**INP optimization strategies:**

| Strategy | When to Use |
|---|---|
| `scheduler.yield()` | Breaking up loops or sequential processing > 50ms |
| `requestAnimationFrame` | Visual updates that should sync with paint |
| `requestIdleCallback` | Non-critical work (analytics, prefetching) |
| Web Workers | CPU-heavy computation (sorting, parsing, encryption) |
| `startTransition` (React) | Non-urgent state updates that can be interrupted |
| Event delegation | Many similar event handlers (use one on the parent) |
| Debounce/throttle | Frequent events (scroll, resize, input) |

---

## Frontend Performance

### Bundle Optimization

```bash
# Analyze bundle size
npx next build                     # Next.js shows route sizes
npx vite-bundle-visualizer         # Vite
npx webpack-bundle-analyzer        # Webpack

# Common wins (ordered by impact):
# 1. Tree-shaking: import { format } from 'date-fns'  NOT  import dayjs from 'dayjs'
# 2. Code splitting: dynamic import() for route-level splitting
# 3. Replace heavy libraries:
#    moment.js (300KB) → date-fns (tree-shakeable)
#    lodash (70KB) → lodash-es (tree-shakeable) or native methods
#    axios (30KB) → fetch (0KB, built-in)
```

### Code Splitting

```tsx
// Route-level (automatic in Next.js)
// Next.js does this for every page.tsx automatically

// Component-level lazy loading
import { lazy, Suspense } from 'react';

const HeavyChart = lazy(() => import('./HeavyChart'));

function Dashboard() {
  return (
    <Suspense fallback={<ChartSkeleton />}>
      <HeavyChart data={data} />
    </Suspense>
  );
}

// Library-level (load only when needed)
async function handleExport() {
  const { exportToPdf } = await import('./pdf-exporter');
  await exportToPdf(data);
}
```

### Image Optimization

```tsx
// Next.js Image (automatic optimization)
import Image from 'next/image';

<Image
  src="/hero.jpg"
  alt="Hero"
  width={1200}
  height={630}
  priority              // Above the fold — preload
  sizes="(max-width: 768px) 100vw, 50vw"
  quality={80}          // 80 is sweet spot
/>

// Below the fold — lazy load (default)
<Image
  src="/card.jpg"
  alt="Card"
  width={400}
  height={300}
  loading="lazy"        // Default — deferred
/>
```

**Image rules:**
- WebP/AVIF format (30-50% smaller than JPEG)
- Serve responsive sizes (`sizes` attribute)
- `priority` only for above-the-fold images
- Lazy load everything else
- Use `aspect-ratio` CSS to prevent layout shift

### HTTP Caching

```
Cache-Control: public, max-age=31536000, immutable
→ Static assets with content hash (JS, CSS, images)

Cache-Control: public, max-age=0, must-revalidate
→ HTML pages (always check for updates)

Cache-Control: private, max-age=300
→ User-specific data (5 min cache)

Cache-Control: no-store
→ Sensitive data (never cache)
```

---

## Server-Side Profiling

### Node.js Profiling

```bash
# 1. Built-in V8 profiler — generates a log file for analysis
node --prof src/server.js
# Process the output into human-readable format:
node --prof-process isolate-*.log > profile.txt
# Look for: [JavaScript] section → functions with highest ticks

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
# Open chrome://inspect in Chrome → Performance tab → Record
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
- Spans with high duration → the bottleneck
- Sequential spans that could be parallel → `Promise.all` opportunity
- Many small spans to the same service → batching opportunity
- Gaps between spans → event loop blocking or GC pause

---

## React Performance

### React Compiler (React 19+)

```tsx
// React Compiler auto-memoizes components, hooks, and expressions.
// No more manual React.memo, useMemo, useCallback.

// Before React Compiler — manual memoization:
const MemoizedList = React.memo(function List({ items, onSelect }) {
  const sorted = useMemo(() => items.sort(compareFn), [items]);
  const handleSelect = useCallback((id) => onSelect(id), [onSelect]);
  return sorted.map(item => <Item key={item.id} item={item} onSelect={handleSelect} />);
});

// With React Compiler — just write normal code:
function List({ items, onSelect }) {
  const sorted = items.sort(compareFn);
  return sorted.map(item => <Item key={item.id} item={item} onSelect={onSelect} />);
}
// Compiler inserts memoization automatically where beneficial.
```

### Server Components (Zero Client JS)

```tsx
// Server Components run ONLY on the server — zero JavaScript shipped to client.
// Default in Next.js App Router. No 'use client' directive = Server Component.

// This component sends only HTML to the client (no JS bundle cost):
async function ProductList() {
  const products = await db.product.findMany(); // Direct DB access
  return (
    <ul>
      {products.map(p => <li key={p.id}>{p.name} — ${p.price}</li>)}
    </ul>
  );
}

// Only add 'use client' when you NEED interactivity:
// - Event handlers (onClick, onChange)
// - useState, useEffect, useReducer
// - Browser-only APIs (localStorage, IntersectionObserver)
```

### Suspense Boundaries for Streaming

```tsx
// Stream HTML progressively — show content as it becomes ready
import { Suspense } from 'react';

export default function DashboardPage() {
  return (
    <main>
      <h1>Dashboard</h1>

      {/* Fast — renders immediately */}
      <UserGreeting />

      {/* Slow data — streams in when ready */}
      <Suspense fallback={<StatsSkeleton />}>
        <StatsPanel />   {/* async Server Component */}
      </Suspense>

      <Suspense fallback={<ActivitySkeleton />}>
        <RecentActivity /> {/* async Server Component */}
      </Suspense>
    </main>
  );
}

// Each Suspense boundary streams independently.
// User sees the page progressively, not a blank screen.
```

### Avoiding Unnecessary Rerenders

```tsx
// 1. Lift state down — keep state close to where it's used
// BAD: entire page rerenders on search input change
function Page() {
  const [search, setSearch] = useState('');
  return (
    <div>
      <SearchInput value={search} onChange={setSearch} />
      <ExpensiveTree />  {/* Rerenders on every keystroke */}
    </div>
  );
}

// GOOD: isolate the state into its own component
function Page() {
  return (
    <div>
      <SearchSection />    {/* Contains its own state */}
      <ExpensiveTree />    {/* Never rerenders from search */}
    </div>
  );
}

// 2. Composition pattern — pass components as children
function Layout({ children }: { children: React.ReactNode }) {
  const [sidebarOpen, setSidebarOpen] = useState(false);
  return (
    <div>
      <Sidebar open={sidebarOpen} onToggle={() => setSidebarOpen(!sidebarOpen)} />
      {children}  {/* children don't rerender when sidebarOpen changes */}
    </div>
  );
}

// 3. use() hook for lazy data (React 19+)
import { use } from 'react';

function Comments({ commentsPromise }: { commentsPromise: Promise<Comment[]> }) {
  const comments = use(commentsPromise);  // Suspends until resolved
  return comments.map(c => <Comment key={c.id} comment={c} />);
}
```

---

## Backend Performance

### Response Time Budget

```
Total response time: 200ms budget

├── Network (client→server):  20ms
├── Middleware:                 5ms
├── Auth/validation:          10ms
├── Business logic:           15ms
├── Database queries:        100ms  ← Usually the bottleneck
├── External API calls:       30ms  ← Second bottleneck
├── Serialization:            10ms
└── Network (server→client):  10ms
```

### Database Query Optimization

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

#### N+1 Detection and Fix

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

#### Query Plan Analysis

```sql
-- Always use EXPLAIN ANALYZE on slow queries:
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT * FROM orders WHERE user_id = 42 ORDER BY created_at DESC LIMIT 10;

-- What to look for in the plan:
-- Seq Scan          → Missing index. Add one on the filtered column
-- Nested Loop       → Potential N+1. Consider JOIN or batch query
-- Sort              → Missing index for ORDER BY. Add composite index
-- Hash Join         → OK for large datasets. Check if smaller table fits memory
-- Bitmap Index Scan → Index is being used but not perfectly. May be OK
-- Index Only Scan   → Best case. Everything served from index (covering index)

-- Covering index — includes all columns the query needs:
CREATE INDEX idx_orders_user_date ON orders (user_id, created_at DESC)
  INCLUDE (total, status);
-- Now "SELECT total, status FROM orders WHERE user_id = X ORDER BY created_at DESC"
-- is an Index Only Scan — never touches the table heap
```

#### Connection Pool Tuning

```typescript
// Optimal pool size formula (from PostgreSQL wiki):
// connections = (core_count * 2) + effective_spindle_count
// For SSD: effective_spindle_count = 1
// Example: 4-core server → (4 * 2) + 1 = 9 connections

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

#### Prepared Statements

```typescript
// Prepared statements — parse SQL once, execute many times
// Most ORMs do this automatically. For raw SQL:

// node-postgres — prepared statement:
const result = await pool.query({
  name: 'get-user-orders',  // Named → prepared on first call, reused after
  text: 'SELECT * FROM orders WHERE user_id = $1 ORDER BY created_at DESC LIMIT $2',
  values: [userId, limit],
});

// Benefits:
// 1. Parse and plan SQL once, not on every call
// 2. Better execution plans (PostgreSQL can optimize for parameter patterns)
// 3. Protection against SQL injection
```

### Caching Strategies

```
Request → CDN Cache → Application Cache → Database
          (seconds)    (seconds-minutes)    (source of truth)

Cache-Aside Pattern:
1. Check cache
2. Cache miss → query DB → store in cache → return
3. Cache hit → return cached data

Write-Through:
1. Write to DB
2. Update/invalidate cache
3. Return

Cache Invalidation:
- Time-based: TTL (simplest, eventual consistency)
- Event-based: Invalidate on write (more complex, more consistent)
- Tag-based: Invalidate by category (revalidateTag in Next.js)
```

### Caching Strategies Decision Tree

```
What to cache?
├── Static assets (JS/CSS/images) → CDN + immutable headers + cache busting
├── API responses (same data for all) → CDN + stale-while-revalidate
├── User-specific data → Redis/Memcached + short TTL
├── Expensive computations → Application cache + cache-aside pattern
├── Database queries → Query cache or materialized views
└── Full pages (SSG) → CDN + ISR
```

**stale-while-revalidate pattern:**

```
Cache-Control: public, max-age=60, stale-while-revalidate=300

Timeline:
0-60s:   Serve from cache (fresh)
60-360s: Serve stale from cache immediately, revalidate in background
360s+:   Cache expired, fetch fresh response

Result: Users always get instant response. Data is at most 5 min stale.
```

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

### Connection Pooling

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

### Pagination (Never Use OFFSET for Large Tables)

```typescript
// Cursor-based pagination (O(1) regardless of page)
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

## Load Testing

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

---

## Anti-Patterns

| Anti-Pattern | Why It's Dangerous | Fix |
|---|---|---|
| Optimizing without measuring | Fixing the wrong thing | Profile first, optimize second |
| N+1 database queries | Linear scaling of queries with data | JOIN, batch loading, DataLoader |
| Loading entire table | Memory + network waste | Pagination (cursor-based) |
| No caching | Same expensive computation repeated | Cache-aside with Redis + TTL |
| Synchronous operations in hot path | Blocks event loop (Node.js) | async/await, worker threads |
| Unbounded queries | `SELECT * FROM users` returns 1M rows | Always LIMIT, always paginate |
| Bundle everything | Ship unused code to browser | Code splitting, tree-shaking |
| Large unoptimized images | Largest performance killer for web | WebP/AVIF, responsive sizes, lazy loading |
| No performance budget | Gradual degradation goes unnoticed | CI checks for bundle size, load time |
| Pre-mature optimization | Complexity without evidence of need | Profile first. Optimize bottlenecks only |

---

## Checklist: Performance Review

- [ ] Baseline metrics established (P50, P95, P99 latency)
- [ ] Database queries profiled (EXPLAIN ANALYZE on slow queries)
- [ ] No N+1 queries (check ORM logs)
- [ ] Pagination implemented (cursor-based for large datasets)
- [ ] Caching strategy defined (what to cache, TTL, invalidation)
- [ ] Connection pooling configured (DB, HTTP)
- [ ] Frontend bundle analyzed (no unnecessary dependencies)
- [ ] Images optimized (WebP/AVIF, responsive, lazy loaded)
- [ ] HTTP caching headers set (static assets immutable, HTML must-revalidate)
- [ ] Load test exists and runs before major releases
- [ ] Performance budget in CI (fail build on regression)
- [ ] Core Web Vitals within targets (LCP <2.5s, CLS <0.1, INP <200ms)
- [ ] Server-side profiling done (clinic.js / py-spy for hot paths)
- [ ] React Server Components used for non-interactive content
- [ ] Suspense boundaries used for streaming slow data
- [ ] Distributed tracing enabled for cross-service performance visibility
