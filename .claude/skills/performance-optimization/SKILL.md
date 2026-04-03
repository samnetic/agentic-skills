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
license: MIT
metadata:
  author: samnetic
  version: "1.0"
---

# Performance Optimization Skill

Measure first, optimize second. Never optimize without profiling data.
Premature optimization is the root of all evil — but so is shipping slow software.

---

## Core Principles

| # | Principle | Meaning |
|---|---|---|
| 1 | **Measure before optimizing** | Profile, identify bottleneck, fix, measure again |
| 2 | **Optimize the bottleneck** | Only the slowest part matters. Everything else is noise |
| 3 | **Caching is the answer** | But only after you have measured what is slow |
| 4 | **Less is more** | Less code, fewer requests, smaller payloads |
| 5 | **Set budgets, enforce them** | Performance budget in CI — fail builds that regress |
| 6 | **User perception matters** | Perceived speed (loading states, streaming) over raw speed |

---

## Workflow: Performance Optimization

1. **MEASURE** — Establish baseline metrics (P50, P95, P99)
   - Use browser DevTools Lighthouse, WebPageTest, or server APM
   - Record current Core Web Vitals: LCP, CLS, INP
   - Capture server-side latency percentiles per endpoint

2. **PROFILE** — Identify the actual bottleneck (not what you think)
   - Frontend: DevTools Performance tab, bundle analyzer
   - Backend Node.js: `clinic.js`, `0x`, `--inspect` flamegraphs
   - Backend Python: `py-spy`, `scalene`, `cProfile`
   - Database: `EXPLAIN (ANALYZE, BUFFERS)` on slow queries
   - Cross-service: OpenTelemetry distributed tracing

3. **HYPOTHESIS** — Form a specific theory
   - Template: "X causes Y latency because Z"
   - Attach profiling evidence to the hypothesis

4. **OPTIMIZE** — Apply the minimum change to address the bottleneck
   - Pick from the Decision Tree below
   - Apply one change at a time to isolate impact

5. **VERIFY** — Measure again, compare to baseline, confirm improvement
   - Run the same measurement from Step 1
   - Accept only if improvement exceeds measurement noise (>5%)

6. **BUDGET** — Add performance test to CI to prevent regression
   - Bundle size limit in build pipeline
   - k6 or similar load test with threshold assertions
   - Lighthouse CI for Core Web Vitals

---

## Decision Tree: What to Optimize

```
Is the problem frontend or backend?

FRONTEND
├── Slow initial load?
│   ├── Large bundle → Code splitting, tree-shaking, lazy imports
│   ├── Render-blocking resources → Inline critical CSS, defer scripts
│   ├── Slow TTFB → CDN, edge rendering, streaming SSR
│   └── Large images → WebP/AVIF, responsive sizes, lazy loading
├── Poor Core Web Vitals?
│   ├── LCP > 2.5s → Preload LCP resource, fetchpriority="high", optimize TTFB
│   ├── CLS > 0.1 → Explicit dimensions, aspect-ratio, font-display:optional
│   └── INP > 200ms → Break long tasks (scheduler.yield), Web Workers, debounce
├── Slow interactions / rerenders?
│   ├── React: React Compiler (auto-memo), lift state down, composition pattern
│   ├── React: Server Components for non-interactive content
│   └── React: Suspense boundaries for streaming slow data
└── Too many requests?
    └── HTTP caching headers, CDN, stale-while-revalidate

BACKEND
├── Slow database queries?
│   ├── N+1 queries → JOIN, batch loading, DataLoader
│   ├── Missing indexes → EXPLAIN ANALYZE, add composite/covering indexes
│   ├── Full table scans → Add WHERE clauses, LIMIT, cursor pagination
│   └── Slow complex queries → Materialized views, denormalization
├── Slow API responses?
│   ├── No caching → Cache-aside with Redis + TTL
│   ├── Sequential operations → Promise.all for parallel execution
│   ├── Expensive computation → Background jobs, precomputation
│   └── Connection overhead → Connection pooling (DB + HTTP keep-alive)
├── High load / scaling issues?
│   ├── Connection exhaustion → Tune pool size: (cores * 2) + 1
│   ├── Memory pressure → Stream large datasets, pagination
│   └── CPU saturation → Worker threads, horizontal scaling
└── Cross-service latency?
    └── OpenTelemetry tracing → Find sequential spans, batching opportunities
```

---

## Response Time Budget

```
Total response time: 200ms budget

├── Network (client to server):  20ms
├── Middleware:                    5ms
├── Auth/validation:             10ms
├── Business logic:              15ms
├── Database queries:           100ms  <-- Usually the bottleneck
├── External API calls:          30ms  <-- Second bottleneck
├── Serialization:               10ms
└── Network (server to client):  10ms
```

---

## Core Web Vitals Targets

| Metric | Good | Needs Improvement | Poor |
|---|---|---|---|
| **LCP** (Largest Contentful Paint) | < 2.5s | 2.5s - 4.0s | > 4.0s |
| **CLS** (Cumulative Layout Shift) | < 0.1 | 0.1 - 0.25 | > 0.25 |
| **INP** (Interaction to Next Paint) | < 200ms | 200ms - 500ms | > 500ms |

**Quick fixes by metric:**

| Metric | Top 3 Fixes |
|---|---|
| **LCP** | 1) Preload LCP image with `fetchpriority="high"` 2) CDN + HTTP/2 3) Inline critical CSS |
| **CLS** | 1) Set `width`/`height` on all images 2) `font-display: optional` 3) Reserve space for ads/embeds |
| **INP** | 1) `scheduler.yield()` to break long tasks 2) `startTransition` for non-urgent updates 3) Debounce inputs |

---

## HTTP Caching Quick Reference

```
Cache-Control: public, max-age=31536000, immutable
  -> Static assets with content hash (JS, CSS, images)

Cache-Control: public, max-age=0, must-revalidate
  -> HTML pages (always check for updates)

Cache-Control: public, max-age=60, stale-while-revalidate=300
  -> API responses (serve stale, revalidate in background)

Cache-Control: private, max-age=300
  -> User-specific data (5 min cache)

Cache-Control: no-store
  -> Sensitive data (never cache)
```

---

## Caching Strategy Decision Tree

```
What to cache?
├── Static assets (JS/CSS/images) -> CDN + immutable headers + cache busting
├── API responses (same data for all) -> CDN + stale-while-revalidate
├── User-specific data -> Redis/Memcached + short TTL
├── Expensive computations -> Application cache + cache-aside pattern
├── Database queries -> Query cache or materialized views
└── Full pages (SSG) -> CDN + ISR (Incremental Static Regeneration)

Cache invalidation strategy?
├── Time-based: TTL (simplest, eventual consistency)
├── Event-based: Invalidate on write (more complex, more consistent)
└── Tag-based: Invalidate by category (revalidateTag in Next.js)
```

---

## N+1 Query Detection Quick Reference

```typescript
// BAD — N+1 (100 users = 101 queries):
const users = await prisma.user.findMany();
for (const user of users) {
  const posts = await prisma.post.findMany({ where: { userId: user.id } });
}

// GOOD — single query with include:
const users = await prisma.user.findMany({
  include: { posts: { take: 5, orderBy: { createdAt: 'desc' } } },
});
```

---

## Anti-Patterns

| Anti-Pattern | Why It Is Dangerous | Fix |
|---|---|---|
| Optimizing without measuring | Fixing the wrong thing | Profile first, optimize second |
| N+1 database queries | Linear scaling of queries with data | JOIN, batch loading, DataLoader |
| Loading entire table | Memory + network waste | Pagination (cursor-based) |
| No caching | Same expensive computation repeated | Cache-aside with Redis + TTL |
| Synchronous operations in hot path | Blocks event loop (Node.js) | async/await, worker threads |
| Unbounded queries | `SELECT *` returns 1M rows | Always LIMIT, always paginate |
| Bundle everything | Ship unused code to browser | Code splitting, tree-shaking |
| Large unoptimized images | Largest performance killer for web | WebP/AVIF, responsive sizes, lazy loading |
| No performance budget | Gradual degradation goes unnoticed | CI checks for bundle size, load time |
| Premature optimization | Complexity without evidence of need | Profile first. Optimize bottlenecks only |

---

## Progressive Disclosure Map

| Topic | Reference | When to Read |
|---|---|---|
| Core Web Vitals (LCP, CLS, INP), bundle optimization, code splitting, image optimization, React performance patterns | `references/frontend-performance.md` | Optimizing page load, bundle size, Core Web Vitals, React rendering |
| Server-side profiling, database query optimization, caching with Redis, connection pooling, pagination, load testing with k6 | `references/backend-performance.md` | Optimizing API response times, database queries, caching, load testing |

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
