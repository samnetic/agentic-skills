# Debugging Tools and Techniques

Deep-dive reference for browser DevTools profiling, Console API, and Node.js memory leak detection patterns.

---

## Table of Contents

- [Browser DevTools](#browser-devtools)
  - [Performance Tab -- Profiling](#performance-tab----profiling)
  - [Network Tab -- Waterfall Analysis](#network-tab----waterfall-analysis)
  - [Memory Tab -- Leak Detection](#memory-tab----leak-detection)
- [Console API Beyond console.log](#console-api-beyond-consolelog)
- [Memory Leak Detection -- Node.js Deep Dive](#memory-leak-detection----nodejs-deep-dive)
  - [Pattern 1: Event Listener Leak](#pattern-1-event-listener-leak)
  - [Pattern 2: Closure Leak](#pattern-2-closure-leak)
  - [Pattern 3: Global Cache Without Eviction](#pattern-3-global-cache-without-eviction)
  - [Detecting Leaks with --inspect](#detecting-leaks-with---inspect)

---

## Browser DevTools

### Performance Tab -- Profiling

```
How to use the Performance tab:
1. Open DevTools -> Performance tab
2. Click Record (or Cmd+Shift+E)
3. Perform the action you want to profile
4. Click Stop
5. Analyze the flamechart:

What to look for:
+-- Long Tasks (red bars) -> JavaScript blocking the main thread > 50ms
+-- Layout Shifts (pink bars) -> CLS events -- find which element shifted
+-- Forced Reflows -> "Recalculate Style" after DOM mutation in a loop
+-- Excessive Paints -> Large repaint areas (enable Paint Flashing)
+-- JavaScript execution -> Wide bars in flamechart = hot functions

Pro tip: Enable "Screenshots" checkbox to see visual state at each point.
Pro tip: Use "Bottom-Up" tab to find which functions took the most total time.
```

### Network Tab -- Waterfall Analysis

```
Network waterfall reading guide:

|--DNS--|--Connect--|--TLS--|--TTFB--|------Content------|

DNS:     Domain resolution (should be cached after first request)
Connect: TCP handshake (HTTP/2 reuses connections)
TLS:     SSL handshake (HTTP/2 reuses connections)
TTFB:    Time to First Byte -- server processing time
Content: Download time -- depends on payload size

What to look for:
+-- Long TTFB -> Slow server. Profile backend
+-- Long Content -> Large payload. Compress or reduce
+-- Waterfall staircase -> Sequential loading. Use preload, parallel fetch
+-- Blocked requests -> Too many connections to same origin. Use HTTP/2
+-- Unnecessary requests -> Remove, cache, or defer (lazy load)

Useful filters:
- Filter by type: JS, CSS, Img, XHR/Fetch
- Filter slow: right-click -> "Sort by Duration"
- Block specific requests: right-click -> "Block request URL" (test impact)
```

### Memory Tab -- Leak Detection

```
Three memory profiling techniques:

1. Heap Snapshot (point-in-time)
   - Take snapshot -> perform action -> take another snapshot
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

---

## Console API Beyond console.log

```typescript
// console.table -- format arrays/objects as tables
console.table(users, ['id', 'name', 'role']); // Select specific columns

// console.group -- organize related logs
console.group('Processing Order #1234');
console.log('Validating...');
console.log('Charging payment...');
console.log('Sending confirmation...');
console.groupEnd();

// console.time -- measure execution time
console.time('fetchUsers');
const users = await fetchUsers();
console.timeEnd('fetchUsers'); // "fetchUsers: 142.3ms"

// console.count -- count how many times code executes
function handleClick(id: string) {
  console.count(`click-${id}`); // "click-btn1: 1", "click-btn1: 2", ...
}

// console.trace -- show call stack at this point
function suspiciousFunction() {
  console.trace('Who called me?'); // Prints full stack trace
}

// console.assert -- log only when condition is false
console.assert(user.age >= 18, 'User is underage:', user);

// console.dir -- inspect DOM elements as objects (not as HTML)
console.dir(document.querySelector('#app'), { depth: 2 });
```

---

## Memory Leak Detection -- Node.js Deep Dive

### Pattern 1: Event Listener Leak

```typescript
// BAD -- listener added on every request, never removed
app.get('/stream', (req, res) => {
  const handler = (data: Buffer) => res.write(data);
  eventEmitter.on('data', handler);
  // If the client disconnects, handler is never removed!
});

// FIX -- remove listener on connection close
app.get('/stream', (req, res) => {
  const handler = (data: Buffer) => res.write(data);
  eventEmitter.on('data', handler);
  req.on('close', () => {
    eventEmitter.off('data', handler);
  });
});
```

### Pattern 2: Closure Leak

```typescript
// BAD -- closure captures entire `bigData` object
function processData(bigData: HugeObject) {
  const id = bigData.id;
  return function callback() {
    // Only uses `id` but captures entire `bigData` in closure scope
    console.log(id);
  };
}

// FIX -- extract only what you need before creating the closure
function processData(bigData: HugeObject) {
  const id = bigData.id;
  const name = bigData.name;
  // bigData is no longer referenced after this point
  return function callback() {
    console.log(id, name);
  };
}
```

### Pattern 3: Global Cache Without Eviction

```typescript
// BAD -- cache grows forever
const cache = new Map<string, Result>();
function getCached(key: string): Result {
  if (!cache.has(key)) {
    cache.set(key, computeExpensive(key));
  }
  return cache.get(key)!;
}

// FIX -- use LRU cache with max size
import { LRUCache } from 'lru-cache';
const cache = new LRUCache<string, Result>({ max: 1000, ttl: 1000 * 60 * 5 });
```

### Detecting Leaks with --inspect

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
# 10. Sort by "# Delta" -- objects with large positive delta are leaking

# Look for:
# - (string) -- string data accumulating
# - (array) -- arrays growing without bound
# - EventEmitter -- listener count growing
# - Detached DOM nodes (in browser) -- elements removed from DOM but still referenced
```
