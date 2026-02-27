---
name: debugging
description: >-
  Systematic debugging and root cause analysis expertise. Use when debugging errors,
  investigating failing tests, analyzing stack traces, troubleshooting performance issues,
  diagnosing memory leaks, debugging network requests, analyzing production incidents,
  using git bisect to find regressions, profiling CPU/memory usage, debugging async code,
  investigating race conditions, reading error logs, debugging Docker containers,
  debugging database query performance, or writing post-mortem reports.
  Triggers: debug, error, bug, exception, traceback, stack trace, troubleshoot, not working,
  crash, fix, broken, undefined, null, NaN, timeout, hang, freeze, memory leak, race
  condition, flaky, intermittent, regression, post-mortem, incident, root cause.
---

# Debugging Skill

Debug systematically, not by guessing. Reproduce first, isolate second, fix third.
Every debugging session should make you smarter about the system.

---

## Core Principles

| Principle | Meaning |
|---|---|
| **Reproduce before you fix** | If you can't reproduce it, you can't verify the fix |
| **One change at a time** | Changing multiple things hides the actual cause |
| **Read the error message** | The answer is often in the first line of the error |
| **Question your assumptions** | "That can't be the problem" is where bugs hide |
| **Binary search the problem space** | Cut the search space in half with each test |
| **Leave the code better** | Add the test that would have caught this bug |

---

## Workflow: Every Debugging Session

```
1. REPRODUCE    → Get the exact error on your machine
2. ISOLATE      → Find the smallest input/path that triggers it
3. HYPOTHESIZE  → Form ONE specific hypothesis
4. TEST         → Verify or disprove with evidence
5. FIX          → Apply the minimal correct fix
6. VERIFY       → Run original reproduction + regression test
7. PREVENT      → Add test, improve error handling, document
```

**Never skip step 1.** If you can't reproduce, you need more information.

---

## Step 1: Reproduce

### Information to Gather

```markdown
## Bug Report Checklist
- [ ] Error message (exact text, full stack trace)
- [ ] Steps to reproduce (1, 2, 3...)
- [ ] Expected behavior vs actual behavior
- [ ] Environment (OS, Node version, browser, Docker?)
- [ ] When did it start? (commit, deploy, config change?)
- [ ] Frequency (always, sometimes, once?)
- [ ] Input data that triggers it
- [ ] Relevant logs (application, database, network)
```

### Reproduction Strategies

| Scenario | Strategy |
|---|---|
| Always reproducible | Write a failing test immediately |
| Only in production | Check logs, replicate data/config locally |
| Intermittent | Add logging, look for timing/race conditions |
| Only under load | Load test with k6/artillery |
| Only on specific OS/browser | Docker container or BrowserStack |
| "Works on my machine" | Check env vars, versions, data differences |

---

## Step 2: Isolate

### Binary Search the Codebase

```bash
# Git bisect — find the commit that introduced the bug
git bisect start
git bisect bad                     # Current version has the bug
git bisect good v1.2.0             # This version was fine
# Git checks out middle commit — test it
git bisect bad                     # Still broken? Mark bad
git bisect good                    # Works? Mark good
# Repeat until git finds the exact commit
git bisect reset                   # Return to original state

# Automated bisect with a test
git bisect start HEAD v1.2.0
git bisect run npm test -- --filter "test_name"
```

### Minimize the Reproduction

```
Working system with bug
    → Remove feature A → Still broken? Keep removing
    → Remove feature A → Bug gone? Feature A is involved
        → Remove half of A → Still broken?
        → Continue until you find the exact line/function
```

---

## Step 3-4: Hypothesize and Test

### Common Bug Categories

| Category | Symptoms | Investigation |
|---|---|---|
| **Null/Undefined** | `Cannot read property X of undefined` | Trace data flow backward from crash point |
| **Type mismatch** | Unexpected behavior, `NaN`, `[object Object]` | Check types at each step, add logging |
| **Async/timing** | Intermittent failures, race conditions | Look for missing `await`, shared mutable state |
| **State mutation** | Inconsistent UI, stale data | Check if state is being mutated directly |
| **Off-by-one** | Wrong number of items, boundary errors | Check loop bounds, array indexes, pagination |
| **Encoding** | Garbled text, wrong characters | Check UTF-8 everywhere, URL encoding |
| **Environment** | Works locally, fails in CI/production | Check env vars, file paths, permissions |
| **Dependency** | Broke after update | Check changelog, lock file diff |
| **Network** | Timeout, wrong response | Check request/response in network tab |
| **Database** | Wrong data, constraint violations | Check query, indexes, transactions |

### Diagnostic Techniques

```typescript
// Strategic logging (not console.log spam)
console.log('=== DEBUG: before processOrder ===');
console.log('Input:', JSON.stringify(order, null, 2));
console.log('User:', { id: user.id, role: user.role });

const result = processOrder(order, user);

console.log('Output:', JSON.stringify(result, null, 2));
console.log('=== DEBUG: after processOrder ===');
// Clean up: remove ALL debug logs before committing

// Node.js debugging
node --inspect src/server.js      // Chrome DevTools debugger
node --inspect-brk src/server.js  // Break on first line

// Conditional breakpoints (in Chrome DevTools)
// Right-click breakpoint → "Edit breakpoint" → Add condition:
// order.total > 1000 && user.role === 'admin'
```

---

## Browser DevTools

### Performance Tab — Profiling

```
How to use the Performance tab:
1. Open DevTools → Performance tab
2. Click Record (or Cmd+Shift+E)
3. Perform the action you want to profile
4. Click Stop
5. Analyze the flamechart:

What to look for:
├── Long Tasks (red bars) → JavaScript blocking the main thread > 50ms
├── Layout Shifts (pink bars) → CLS events — find which element shifted
├── Forced Reflows → "Recalculate Style" after DOM mutation in a loop
├── Excessive Paints → Large repaint areas (enable Paint Flashing)
└── JavaScript execution → Wide bars in flamechart = hot functions

Pro tip: Enable "Screenshots" checkbox to see visual state at each point.
Pro tip: Use "Bottom-Up" tab to find which functions took the most total time.
```

### Network Tab — Waterfall Analysis

```
Network waterfall reading guide:

|--DNS--|--Connect--|--TLS--|--TTFB--|------Content------|

DNS:     Domain resolution (should be cached after first request)
Connect: TCP handshake (HTTP/2 reuses connections)
TLS:     SSL handshake (HTTP/2 reuses connections)
TTFB:    Time to First Byte — server processing time
Content: Download time — depends on payload size

What to look for:
├── Long TTFB → Slow server. Profile backend
├── Long Content → Large payload. Compress or reduce
├── Waterfall staircase → Sequential loading. Use preload, parallel fetch
├── Blocked requests → Too many connections to same origin. Use HTTP/2
└── Unnecessary requests → Remove, cache, or defer (lazy load)

Useful filters:
- Filter by type: JS, CSS, Img, XHR/Fetch
- Filter slow: right-click → "Sort by Duration"
- Block specific requests: right-click → "Block request URL" (test impact)
```

### Memory Tab — Leak Detection

```
Three memory profiling techniques:

1. Heap Snapshot (point-in-time)
   - Take snapshot → perform action → take another snapshot
   - Compare snapshots: select "Comparison" view
   - Look for: objects that grow between snapshots

2. Allocation Timeline (over time)
   - Records allocations as blue bars
   - Bars that stay are potential leaks
   - Click a bar to see what object was allocated and its retaining tree

3. Allocation Sampling (low overhead)
   - Sampling profiler for memory allocations
   - Good for production-like profiling
   - Shows which functions allocate the most memory
```

### Console API (Beyond console.log)

```typescript
// console.table — format arrays/objects as tables
console.table(users, ['id', 'name', 'role']); // Select specific columns

// console.group — organize related logs
console.group('Processing Order #1234');
console.log('Validating...');
console.log('Charging payment...');
console.log('Sending confirmation...');
console.groupEnd();

// console.time — measure execution time
console.time('fetchUsers');
const users = await fetchUsers();
console.timeEnd('fetchUsers'); // "fetchUsers: 142.3ms"

// console.count — count how many times code executes
function handleClick(id: string) {
  console.count(`click-${id}`); // "click-btn1: 1", "click-btn1: 2", ...
}

// console.trace — show call stack at this point
function suspiciousFunction() {
  console.trace('Who called me?'); // Prints full stack trace
}

// console.assert — log only when condition is false
console.assert(user.age >= 18, 'User is underage:', user);

// console.dir — inspect DOM elements as objects (not as HTML)
console.dir(document.querySelector('#app'), { depth: 2 });
```

---

## Common Debugging Scenarios

### Memory Leaks

```bash
# Node.js — take heap snapshots
node --inspect src/server.js
# In Chrome DevTools: Memory tab → Take Heap Snapshot
# Compare snapshots over time to find growing objects

# Common causes:
# - Event listeners not removed
# - Closures capturing large objects
# - Growing arrays/maps (caches without eviction)
# - Timers not cleared (setInterval without clearInterval)
# - Circular references preventing GC
```

### Memory Leak Detection — Node.js Deep Dive

```typescript
// Pattern 1: Event listener leak
// BAD — listener added on every request, never removed
app.get('/stream', (req, res) => {
  const handler = (data: Buffer) => res.write(data);
  eventEmitter.on('data', handler);
  // If the client disconnects, handler is never removed!
});

// FIX — remove listener on connection close
app.get('/stream', (req, res) => {
  const handler = (data: Buffer) => res.write(data);
  eventEmitter.on('data', handler);
  req.on('close', () => {
    eventEmitter.off('data', handler);
  });
});

// Pattern 2: Closure leak — closure captures more than needed
// BAD — closure captures entire `bigData` object
function processData(bigData: HugeObject) {
  const id = bigData.id;
  return function callback() {
    // Only uses `id` but captures entire `bigData` in closure scope
    console.log(id);
  };
}

// FIX — extract only what you need before creating the closure
function processData(bigData: HugeObject) {
  const id = bigData.id;
  const name = bigData.name;
  // bigData is no longer referenced after this point
  return function callback() {
    console.log(id, name);
  };
}

// Pattern 3: Global cache without eviction
// BAD — cache grows forever
const cache = new Map<string, Result>();
function getCached(key: string): Result {
  if (!cache.has(key)) {
    cache.set(key, computeExpensive(key));
  }
  return cache.get(key)!;
}

// FIX — use LRU cache with max size
import { LRUCache } from 'lru-cache';
const cache = new LRUCache<string, Result>({ max: 1000, ttl: 1000 * 60 * 5 });
```

**Detecting leaks with `--inspect`:**

```bash
# 1. Start app with inspector
node --inspect --max-old-space-size=256 src/server.js

# 2. Open chrome://inspect in Chrome
# 3. Click "inspect" under your Node.js target
# 4. Go to Memory tab
# 5. Take Heap Snapshot (baseline)
# 6. Perform the action that you suspect leaks (e.g., send 1000 requests)
# 7. Force GC: click the trash can icon in the Memory tab
# 8. Take another Heap Snapshot
# 9. Select Snapshot 2, change view to "Comparison"
# 10. Sort by "# Delta" — objects with large positive delta are leaking

# Look for:
# - (string) — string data accumulating
# - (array) — arrays growing without bound
# - EventEmitter — listener count growing
# - Detached DOM nodes (in browser) — elements removed from DOM but still referenced
```

### Slow Queries

```sql
-- PostgreSQL: Find slow queries
SELECT query, calls, mean_exec_time, total_exec_time
FROM pg_stat_statements
ORDER BY mean_exec_time DESC
LIMIT 20;

-- Explain a specific query
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT * FROM orders WHERE user_id = 42 ORDER BY created_at DESC LIMIT 10;

-- Look for: Seq Scan (missing index), Nested Loop (N+1), Sort (missing index for ORDER BY)
```

### Docker Container Debugging

```bash
# See what's happening inside a running container
docker compose logs -f app                     # Follow logs
docker compose exec app sh                     # Shell into container
docker compose exec app node -e "console.log(process.env)"  # Check env
docker compose exec app cat /etc/hosts         # Check networking

# Container won't start?
docker compose logs app 2>&1 | head -50        # Check startup errors
docker compose run --rm app sh                 # Start fresh container with shell
docker inspect $(docker compose ps -q app)     # Full container details
```

### Race Conditions

```typescript
// Symptoms: works sometimes, fails sometimes, order-dependent

// Common pattern: read-modify-write without locking
// BAD
const count = await getCount();   // Another request reads same value
await setCount(count + 1);         // Both increment from same base

// FIX: Atomic operation
await db.query('UPDATE counters SET value = value + 1 WHERE id = $1', [id]);

// FIX: Optimistic locking
const item = await db.findOne({ id, version: 5 });
const updated = await db.update({ id, version: 5 }, { ...changes, version: 6 });
if (updated.count === 0) throw new ConflictError('Item was modified');
```

---

## Error Tracking with Sentry

### Setup

```typescript
// Install: npm install @sentry/node @sentry/profiling-node
import * as Sentry from '@sentry/node';

Sentry.init({
  dsn: process.env.SENTRY_DSN,
  environment: process.env.NODE_ENV,     // 'production', 'staging'
  release: process.env.GIT_SHA,          // Track which release introduced errors
  tracesSampleRate: 0.1,                 // 10% of transactions for performance
  profilesSampleRate: 0.1,               // 10% of sampled transactions for profiling
  integrations: [
    Sentry.httpIntegration(),
    Sentry.expressIntegration(),
    Sentry.prismaIntegration(),          // Track DB queries
  ],
});
```

### Breadcrumbs — Trace Events Leading to an Error

```typescript
// Automatic breadcrumbs: HTTP requests, console logs, DOM clicks (browser)
// Manual breadcrumbs for business context:

async function processOrder(order: Order) {
  Sentry.addBreadcrumb({
    category: 'order',
    message: `Processing order ${order.id}`,
    level: 'info',
    data: { orderId: order.id, items: order.items.length, total: order.total },
  });

  try {
    await chargePayment(order);
  } catch (error) {
    // Breadcrumbs show the trail: user logged in → added items → clicked checkout → payment failed
    Sentry.captureException(error);
    throw error;
  }
}
```

### Custom Context — Add Business Data to Errors

```typescript
// Set user context — shows on every error for this request
Sentry.setUser({
  id: user.id,
  email: user.email,
  subscription: user.plan,
});

// Set custom tags — filterable in Sentry dashboard
Sentry.setTag('feature', 'checkout');
Sentry.setTag('payment_provider', 'stripe');

// Set extra context — additional data for debugging
Sentry.setExtra('cart', { items: cart.items.length, total: cart.total });

// Scoped context — only applies to errors within this scope
Sentry.withScope((scope) => {
  scope.setTag('operation', 'bulk-import');
  scope.setExtra('batchSize', items.length);
  scope.setLevel('warning');
  // Only errors captured within this block get these tags
  Sentry.captureException(error);
});
```

### Source Maps — Readable Stack Traces in Production

```bash
# Upload source maps during build/deploy
npx @sentry/cli sourcemaps upload \
  --release=$GIT_SHA \
  --url-prefix='~/_next/static' \
  .next/static/

# Or use the Sentry webpack/vite plugin for automatic upload:
# npm install @sentry/webpack-plugin
```

```typescript
// In next.config.js (Next.js):
import { withSentryConfig } from '@sentry/nextjs';

export default withSentryConfig(nextConfig, {
  org: 'your-org',
  project: 'your-project',
  silent: true,
  hideSourceMaps: true,  // Don't expose source maps to users
});
```

### Release Tracking

```bash
# Create a release in Sentry to track which deploy introduced errors
npx @sentry/cli releases new $GIT_SHA
npx @sentry/cli releases set-commits $GIT_SHA --auto
npx @sentry/cli releases finalize $GIT_SHA

# After deploying:
npx @sentry/cli releases deploys $GIT_SHA new -e production
```

---

## Distributed Tracing

### OpenTelemetry Concepts

```
Trace: The entire journey of a request across all services
  └── Span: A single operation within a trace
      ├── Name: "POST /api/orders"
      ├── Duration: 142ms
      ├── Attributes: { http.method: "POST", http.status: 200 }
      ├── Events: [{ name: "payment.charged", timestamp: ... }]
      └── Child Spans:
          ├── "db.query SELECT orders" (35ms)
          ├── "http.client POST payment-service" (80ms)
          │   └── "db.query INSERT payments" (20ms)
          └── "http.client POST email-service" (15ms)

Baggage: Key-value pairs propagated across service boundaries
  Example: { "user.id": "123", "feature.flag": "new-checkout" }
  Useful for: correlating logs, A/B test analysis, tenant isolation
```

### Correlating Logs Across Services

```typescript
// Inject trace ID into all log messages:
import { trace, context } from '@opentelemetry/api';

function getTraceId(): string {
  const span = trace.getSpan(context.active());
  return span?.spanContext().traceId ?? 'no-trace';
}

// In your logger:
const logger = pino({
  mixin() {
    return { traceId: getTraceId() };
  },
});

// Now all logs include traceId:
// {"level":"info","msg":"Processing order","traceId":"abc123","orderId":"42"}

// Search in your log aggregator (Grafana/Datadog/CloudWatch):
// traceId="abc123" → shows ALL logs across ALL services for this request
```

### Trace Context Propagation

```typescript
// Trace context is automatically propagated via HTTP headers:
// traceparent: 00-{traceId}-{spanId}-{flags}
// Example: traceparent: 00-abc123-def456-01

// OpenTelemetry auto-instrumentation handles this for:
// - HTTP clients (fetch, axios, node:http)
// - Database drivers (pg, mysql, mongodb)
// - Message queues (RabbitMQ, Kafka, SQS)
// - gRPC calls

// For custom propagation (e.g., in a queue consumer):
import { propagation, context } from '@opentelemetry/api';

// Producer: inject trace context into message headers
const headers: Record<string, string> = {};
propagation.inject(context.active(), headers);
await queue.publish({ data: payload, headers });

// Consumer: extract trace context from message headers
const ctx = propagation.extract(context.active(), message.headers);
context.with(ctx, () => {
  // Spans created here are linked to the original trace
  processMessage(message.data);
});
```

---

## Debugging Production

### Structured Logging for Debugging

```typescript
// Structured logs are searchable and correlatable.
// Always include context that helps debugging.

import pino from 'pino';

const logger = pino({
  level: process.env.LOG_LEVEL ?? 'info',
  formatters: {
    level: (label) => ({ level: label }),  // "info" not 30
  },
});

// Log with context — not just a message
logger.info({
  event: 'order.processed',
  orderId: order.id,
  userId: user.id,
  total: order.total,
  itemCount: order.items.length,
  duration: Date.now() - startTime,
}, 'Order processed successfully');

// Log errors with full context
logger.error({
  event: 'payment.failed',
  orderId: order.id,
  provider: 'stripe',
  errorCode: error.code,
  err: error,  // pino serializes Error objects (message, stack, code)
}, 'Payment processing failed');

// Temporary debug logging — controlled by env var, not code changes
if (process.env.DEBUG_ORDERS === 'true') {
  logger.debug({ order, user }, 'Full order context for debugging');
}
```

### Feature Flags for Debug Mode

```typescript
// Enable verbose logging for specific users/requests without a deploy:
import { getFeatureFlag } from './feature-flags';

async function handleRequest(req: Request) {
  const debugMode = await getFeatureFlag('debug-verbose', {
    userId: req.userId,
    percentage: 0,  // Off by default, enable for specific users
  });

  if (debugMode) {
    logger.debug({ headers: req.headers, body: req.body }, 'Request details');
  }

  // Process request normally...

  if (debugMode) {
    logger.debug({ response, queries: db.queryLog }, 'Response details');
  }
}

// Benefits:
// - Enable debug logging for one user in production
// - No deploy required — toggle via dashboard
// - No risk to other users
// - Can disable instantly if it causes issues
```

### Canary Deployments for Validation

```
Canary deployment strategy for debugging production issues:

1. Deploy fix to 5% of traffic (canary)
2. Monitor error rates for canary vs stable:
   - Error rate decreased? Fix is working
   - Error rate unchanged? Wrong root cause
   - Error rate increased? Fix made it worse — rollback

Monitoring checklist for canary:
├── Error rate (Sentry alerts per release)
├── Latency P95 (should not increase)
├── Business metrics (conversions, completions)
└── Log volume (unexpected increase = new errors)

Tools: Kubernetes progressive delivery, AWS CodeDeploy, Vercel skew protection
```

### Replay-Based Debugging

```typescript
// Record and replay user sessions to reproduce bugs without guessing.
// Tools: Sentry Session Replay, LogRocket, FullStory

// Sentry Session Replay setup:
Sentry.init({
  dsn: process.env.SENTRY_DSN,
  replaysSessionSampleRate: 0.1,    // 10% of sessions
  replaysOnErrorSampleRate: 1.0,    // 100% of sessions with errors
  integrations: [
    Sentry.replayIntegration({
      maskAllText: false,            // Set to true for PII compliance
      blockAllMedia: false,
    }),
  ],
});

// Benefits:
// - See exactly what the user did before the error
// - Network requests, console logs, DOM changes — all captured
// - No need to ask "What were you doing when it happened?"
// - Especially valuable for "cannot reproduce" bugs
```

---

## Post-Mortem Template

```markdown
# Incident Post-Mortem: [Title]

## Summary
- **Date**: YYYY-MM-DD
- **Duration**: X hours/minutes
- **Severity**: Critical / High / Medium
- **Impact**: [What users experienced]

## Timeline
| Time | Event |
|------|-------|
| 14:00 | Deploy v2.3.1 to production |
| 14:05 | Error rate spikes to 30% |
| 14:10 | Alert fires, on-call acknowledged |
| 14:15 | Root cause identified: missing DB migration |
| 14:20 | Rolled back to v2.3.0 |
| 14:22 | Error rate returns to normal |

## Root Cause
[Detailed technical explanation]

## What Went Well
- Alert fired within 5 minutes
- Rollback procedure worked smoothly

## What Went Wrong
- Migration not included in deploy checklist
- No pre-deploy validation of DB schema

## Action Items
| Action | Owner | Deadline |
|--------|-------|----------|
| Add migration check to CI | @dev | Next sprint |
| Add deploy checklist to runbook | @ops | This week |
| Add integration test for new endpoint | @dev | Next sprint |

## Lessons Learned
[What we learned that applies beyond this incident]
```

---

## Scientific Debugging

### The Falsifiability Principle

Every hypothesis MUST be falsifiable — you need to define what evidence would DISPROVE your hypothesis, not just what would confirm it.

```
Hypothesis: "The bug is caused by a race condition in the payment service"

Falsifiable prediction: "If I add a mutex around the payment processing,
the bug will stop occurring under concurrent load"

If the bug persists WITH the mutex -> hypothesis is disproven -> move on

If the bug stops WITH the mutex -> hypothesis is supported (not proven)
-> Now find the specific race condition
```

### One Variable at a Time

Never change two things between tests. If you change the input AND the config, you can't tell which fixed the bug.

```
Test 1: Original input + original config -> Bug present
Test 2: Modified input + original config -> Bug present? (isolates input)
Test 3: Original input + modified config -> Bug present? (isolates config)
```

### Cognitive Biases in Debugging

| Bias | How It Hurts | Counter |
|---|---|---|
| **Confirmation bias** | Only looking for evidence that supports your theory | Actively try to disprove your hypothesis |
| **Anchoring** | First idea sticks, ignore alternatives | Write down 3 hypotheses before testing any |
| **Recency bias** | Blame the last change you made | Use git bisect, not intuition |
| **Availability bias** | "Last time it was X, so it must be X again" | Start fresh, don't assume same root cause |
| **Sunk cost** | "I've spent hours on this theory, it must be right" | Time spent does not equal correctness. Abandon failing hypotheses |

---

## Anti-Patterns

| Anti-Pattern | Why It's Dangerous | Fix |
|---|---|---|
| Guessing without reproducing | Fixes wrong thing, wastes time | Reproduce first, always |
| Changing multiple things at once | Can't tell what fixed it | One change at a time |
| "It works now" without understanding why | Bug will return | Find and understand root cause |
| Leaving debug logging in code | Noise in production, possible data leak | Clean up before commit |
| Debugging in production | Risk of making it worse | Reproduce locally, add logging |
| Ignoring intermittent failures | They always get worse | Investigate race conditions, timing |
| "The tests pass so it's fine" | Tests might not cover the bug scenario | Write the missing test |
| Blaming the framework/library | 99% of the time it's your code | Check your code first |
| No post-mortem for outages | Same bugs repeat | Document and create action items |
| Fixing symptoms, not root cause | Whack-a-mole debugging | Ask "why" five times |

---

## Checklist: After Every Bug Fix

- [ ] Root cause identified and understood (not just symptoms)
- [ ] Fix is minimal and correct (no unrelated changes)
- [ ] Regression test added (fails without fix, passes with fix)
- [ ] All debug code removed (console.log, debug flags)
- [ ] Related code reviewed for similar issues
- [ ] Post-mortem written (if production incident)
- [ ] Action items created (if systemic issue)
- [ ] Error handling improved (if error was swallowed/unclear)
- [ ] Hypothesis was falsifiable (defined what would disprove it)
- [ ] Only one variable changed between debugging tests
- [ ] At least 2 alternative hypotheses considered before deep-diving
- [ ] Error tracking configured with proper context (Sentry breadcrumbs, tags)
- [ ] Structured logs include enough context to debug without reproducing
