# Metrics and Prometheus

## Table of Contents

- [Four Metric Types](#four-metric-types)
- [Naming Conventions](#naming-conventions)
- [Node.js with prom-client](#nodejs-with-prom-client)
- [Python with prometheus_client](#python-with-prometheus_client)
- [PromQL Essentials](#promql-essentials)
- [PromQL Pitfalls](#promql-pitfalls)

---

## Four Metric Types

| Type | What It Measures | Examples | When to Use |
|---|---|---|---|
| **Counter** | Monotonically increasing value | Total requests, errors, orders processed | Counting events that only go up |
| **Gauge** | Value that goes up and down | Active connections, queue depth, temperature | Current state / level |
| **Histogram** | Distribution of values in buckets | Request duration, response size, query time | Latency, size distributions (use for percentiles) |
| **Summary** | Similar to histogram, client-side quantiles | Request duration quantiles | Avoid -- prefer histograms (summaries cannot be aggregated across instances) |

---

## Naming Conventions

```
# Format: namespace_subsystem_name_unit
# Examples:
http_server_requests_total          # Counter — total HTTP requests
http_server_request_duration_seconds  # Histogram — request latency
http_server_active_connections       # Gauge — current connections
app_orders_created_total             # Counter — business metric
app_queue_depth                      # Gauge — queue backlog
db_pool_connections_active           # Gauge — active DB connections
db_query_duration_seconds            # Histogram — query latency

# Rules:
# - Use snake_case
# - Use base units (seconds, bytes, not milliseconds, kilobytes)
# - Counters end in _total
# - Use namespace prefix to avoid collisions
```

---

## Node.js with prom-client

```typescript
import { Registry, Counter, Histogram, Gauge, collectDefaultMetrics } from 'prom-client';

// Create a registry (avoid global default for testability)
const registry = new Registry();

// Collect default metrics (CPU, memory, event loop lag, GC)
collectDefaultMetrics({ register: registry, prefix: 'app_' });

// --- Custom metrics ---

// Counter: total HTTP requests by method, path, status
const httpRequestsTotal = new Counter({
  name: 'http_server_requests_total',
  help: 'Total HTTP requests',
  labelNames: ['method', 'path', 'status'] as const,
  registers: [registry],
});

// Histogram: request duration in seconds
const httpRequestDuration = new Histogram({
  name: 'http_server_request_duration_seconds',
  help: 'HTTP request duration in seconds',
  labelNames: ['method', 'path', 'status'] as const,
  // Buckets tuned for web APIs (50ms to 10s)
  buckets: [0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10],
  registers: [registry],
});

// Gauge: active connections
const activeConnections = new Gauge({
  name: 'http_server_active_connections',
  help: 'Number of active HTTP connections',
  registers: [registry],
});

// Business metric: orders created
const ordersCreated = new Counter({
  name: 'app_orders_created_total',
  help: 'Total orders created',
  labelNames: ['payment_method', 'plan'] as const,
  registers: [registry],
});

// --- Express middleware to record metrics ---
app.use((req, res, next) => {
  activeConnections.inc();
  const end = httpRequestDuration.startTimer();

  res.on('finish', () => {
    const path = req.route?.path ?? req.path; // Use route pattern, not actual path
    const labels = { method: req.method, path, status: String(res.statusCode) };

    httpRequestsTotal.inc(labels);
    end(labels); // Records duration with labels
    activeConnections.dec();
  });

  next();
});

// --- Expose /metrics endpoint ---
app.get('/metrics', async (_req, res) => {
  res.set('Content-Type', registry.contentType);
  res.end(await registry.metrics());
});
```

---

## Python with prometheus_client

```python
from prometheus_client import (
    Counter, Histogram, Gauge, CollectorRegistry, generate_latest,
    CONTENT_TYPE_LATEST, multiprocess, REGISTRY,
)
from fastapi import FastAPI, Request, Response
import time

# Custom metrics
http_requests_total = Counter(
    "http_server_requests_total",
    "Total HTTP requests",
    ["method", "path", "status"],
)

http_request_duration_seconds = Histogram(
    "http_server_request_duration_seconds",
    "HTTP request duration in seconds",
    ["method", "path"],
    buckets=[0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10],
)

active_connections = Gauge(
    "http_server_active_connections",
    "Number of active HTTP connections",
)

orders_created_total = Counter(
    "app_orders_created_total",
    "Total orders created",
    ["payment_method"],
)

app = FastAPI()


@app.middleware("http")
async def metrics_middleware(request: Request, call_next):
    active_connections.inc()
    start = time.perf_counter()

    response = await call_next(request)

    duration = time.perf_counter() - start
    path = request.url.path
    http_requests_total.labels(request.method, path, response.status_code).inc()
    http_request_duration_seconds.labels(request.method, path).observe(duration)
    active_connections.dec()

    return response


@app.get("/metrics")
async def metrics():
    return Response(
        content=generate_latest(REGISTRY),
        media_type=CONTENT_TYPE_LATEST,
    )
```

---

## PromQL Essentials

```promql
# --- Rate: per-second rate of counter increase over time window ---
rate(http_server_requests_total[5m])

# --- Error rate (percentage) ---
sum(rate(http_server_requests_total{status=~"5.."}[5m]))
/
sum(rate(http_server_requests_total[5m]))

# --- p99 latency from histogram ---
histogram_quantile(0.99, sum(rate(http_server_request_duration_seconds_bucket[5m])) by (le))

# --- p50 (median) latency per service ---
histogram_quantile(0.50,
  sum(rate(http_server_request_duration_seconds_bucket[5m])) by (le, service)
)

# --- Request rate per endpoint ---
sum by (path) (rate(http_server_requests_total[5m]))

# --- Increase: total count increase over time window (useful for alerts) ---
increase(http_server_requests_total{status="500"}[1h])

# --- Apdex score (satisfied < 0.1s, tolerating < 0.5s) ---
(
  sum(rate(http_server_request_duration_seconds_bucket{le="0.1"}[5m]))
  +
  sum(rate(http_server_request_duration_seconds_bucket{le="0.5"}[5m]))
) / 2
/
sum(rate(http_server_request_duration_seconds_count[5m]))
```

---

## PromQL Pitfalls

- Never use `rate()` on a gauge -- use `deriv()` or just the gauge value
- Always use `rate()` before `sum()` for counters, never `sum()` then `rate()`
- Window should be at least 4x the scrape interval (e.g., 15s scrape -> 1m window minimum)
- High cardinality labels (user_id, request_id) will explode Prometheus memory
