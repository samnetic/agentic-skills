---
name: observability
description: >-
  Production observability, monitoring, and incident response expertise for Node.js
  and Python SaaS applications. Use when instrumenting applications with OpenTelemetry,
  setting up structured logging (pino, structlog), collecting metrics with Prometheus,
  building Grafana dashboards, implementing distributed tracing, defining SLOs/SLIs and
  error budgets, configuring alerting rules, designing health check endpoints, setting
  up error tracking with Sentry, implementing correlation IDs for request tracing,
  creating runbooks for incident response, conducting blameless post-mortems, building
  APM pipelines, choosing between Datadog/Grafana Cloud/self-hosted stacks, or
  reviewing observability posture of a service.
  Triggers: observability, monitoring, logging, metrics, tracing, OpenTelemetry,
  OTel, Prometheus, Grafana, alerting, SLO, SLI, error budget, health check,
  incident, post-mortem, dashboard, Sentry, Datadog, structured logging, pino,
  structlog, correlation ID, span, distributed tracing, APM, runbook, liveness,
  readiness.
---

# Observability Skill

Understand your production systems through the three pillars: logs, metrics, and
traces. Instrument once with OpenTelemetry, ship to any backend, alert on user
impact, and respond with runbooks. Observability is not monitoring -- it is the
ability to ask arbitrary questions about your system without deploying new code.

---

## Core Principles

| Principle | Meaning |
|---|---|
| **Three pillars, correlated** | Logs, metrics, traces -- all linked via trace_id. One pillar alone is insufficient |
| **Observe, don't just monitor** | Monitoring checks known failure modes. Observability lets you explore unknown unknowns |
| **SLOs drive alerting** | Alert on user-facing impact (SLO burn rate), not on CPU at 80% |
| **Structured logging always** | JSON with consistent fields. Never printf-style strings in production |
| **Correlation IDs everywhere** | Every request gets a trace_id that flows through every service, log, and span |
| **Instrument at boundaries** | HTTP handlers, DB queries, external API calls, message consumers -- that is where latency and errors live |

---

## Observability Workflow

```
1. INSTRUMENT → Add telemetry to code (OpenTelemetry SDK)
2. COLLECT    → Ship to backends (Prometheus, Jaeger/Tempo, Loki)
3. CORRELATE  → Link logs, metrics, traces via trace_id / span_id
4. ALERT      → SLO-based alerts with burn rate windows
5. DASHBOARD  → RED method (services) + USE method (resources)
6. RESPOND    → Runbook-driven incident response
7. LEARN      → Blameless post-mortems with action items
```

**Why this order matters:**
- You cannot alert on what you do not measure
- You cannot debug without correlated telemetry
- You cannot improve without learning from incidents

---

## Decision Trees

### Choosing an Observability Backend

```
What is your scale and budget?
├─ Small team, want managed, budget available?
│  ├─ Full-stack (traces + metrics + logs + APM)? → Datadog, New Relic
│  └─ Traces + metrics focused? → Grafana Cloud, Honeycomb
├─ Want self-hosted / open source?
│  ├─ Traces → Grafana Tempo or Jaeger
│  ├─ Metrics → Prometheus + Thanos/Mimir for long-term storage
│  ├─ Logs → Grafana Loki or OpenSearch
│  └─ Dashboards → Grafana
└─ Enterprise with compliance requirements?
   └─ Datadog, Splunk, or Elastic (on-prem options available)

Always use OpenTelemetry for instrumentation — it is vendor-neutral.
Switch backends without re-instrumenting your code.
```

### What Should I Instrument?

```
Is it a boundary?
├─ Incoming HTTP/gRPC request? → Auto-instrumented by OTel
├─ Outgoing HTTP/gRPC call? → Auto-instrumented by OTel
├─ Database query? → Auto-instrumented by OTel
├─ Message queue publish/consume? → Auto-instrumented by OTel
├─ Cache (Redis) operation? → Auto-instrumented by OTel
└─ Custom business logic?
   ├─ Has latency implications? → Manual span
   ├─ Has error/success outcomes? → Manual span + status
   ├─ Needs counting (orders, signups)? → Custom metric (counter)
   └─ Has a current value (queue depth, connections)? → Custom metric (gauge)
```

---

## OpenTelemetry (Node.js)

OpenTelemetry (OTel) is the CNCF standard for vendor-neutral telemetry. Instrument once, export to any backend.

### Auto-Instrumentation Setup

```typescript
// instrumentation.ts — MUST be loaded before any other import
// Run with: node --require ./instrumentation.ts src/server.ts
// Or with: node --import ./instrumentation.ts src/server.ts (ESM)

import { NodeSDK } from '@opentelemetry/sdk-node';
import { OTLPTraceExporter } from '@opentelemetry/exporter-trace-otlp-http';
import { OTLPMetricExporter } from '@opentelemetry/exporter-metrics-otlp-http';
import { OTLPLogExporter } from '@opentelemetry/exporter-logs-otlp-http';
import { getNodeAutoInstrumentations } from '@opentelemetry/auto-instrumentations-node';
import { PeriodicExportingMetricReader } from '@opentelemetry/sdk-metrics';
import { BatchLogRecordProcessor } from '@opentelemetry/sdk-logs';
import { Resource } from '@opentelemetry/resources';
import {
  ATTR_SERVICE_NAME,
  ATTR_SERVICE_VERSION,
  ATTR_DEPLOYMENT_ENVIRONMENT_NAME,
} from '@opentelemetry/semantic-conventions';

const resource = new Resource({
  [ATTR_SERVICE_NAME]: process.env.OTEL_SERVICE_NAME ?? 'my-service',
  [ATTR_SERVICE_VERSION]: process.env.npm_package_version ?? '0.0.0',
  [ATTR_DEPLOYMENT_ENVIRONMENT_NAME]: process.env.NODE_ENV ?? 'development',
});

const collectorUrl = process.env.OTEL_EXPORTER_OTLP_ENDPOINT ?? 'http://localhost:4318';

const sdk = new NodeSDK({
  resource,
  traceExporter: new OTLPTraceExporter({
    url: `${collectorUrl}/v1/traces`,
  }),
  metricReader: new PeriodicExportingMetricReader({
    exporter: new OTLPMetricExporter({
      url: `${collectorUrl}/v1/metrics`,
    }),
    exportIntervalMillis: 15_000, // Export every 15s (default 60s)
  }),
  logRecordProcessor: new BatchLogRecordProcessor(
    new OTLPLogExporter({
      url: `${collectorUrl}/v1/logs`,
    }),
  ),
  instrumentations: [
    getNodeAutoInstrumentations({
      // Disable noisy instrumentations
      '@opentelemetry/instrumentation-fs': { enabled: false },
      '@opentelemetry/instrumentation-dns': { enabled: false },
      // Configure HTTP instrumentation
      '@opentelemetry/instrumentation-http': {
        ignoreIncomingRequestHook: (req) => {
          // Don't trace health checks — they are too noisy
          return req.url === '/healthz' || req.url === '/readyz';
        },
      },
    }),
  ],
});

sdk.start();

// Graceful shutdown — flush pending telemetry
process.on('SIGTERM', async () => {
  await sdk.shutdown();
  process.exit(0);
});
```

### Manual Span Creation

```typescript
import { trace, SpanStatusCode, context, SpanKind } from '@opentelemetry/api';

const tracer = trace.getTracer('my-service', '1.0.0');

// Wrap business logic in a span
async function processOrder(orderId: string, items: OrderItem[]): Promise<Order> {
  return tracer.startActiveSpan(
    'processOrder',
    { kind: SpanKind.INTERNAL },
    async (span) => {
      try {
        // Add attributes for debugging
        span.setAttribute('order.id', orderId);
        span.setAttribute('order.item_count', items.length);
        span.setAttribute('order.total_cents', calculateTotal(items));

        // Child spans are auto-linked via context
        const inventory = await checkInventory(items);
        const payment = await chargePayment(orderId, calculateTotal(items));
        const order = await createOrder(orderId, items, payment.id);

        // Add event (structured log attached to span)
        span.addEvent('order.created', {
          'order.id': orderId,
          'payment.id': payment.id,
        });

        span.setStatus({ code: SpanStatusCode.OK });
        return order;
      } catch (error) {
        span.setStatus({
          code: SpanStatusCode.ERROR,
          message: error instanceof Error ? error.message : 'Unknown error',
        });
        span.recordException(error as Error);
        throw error;
      } finally {
        span.end();
      }
    },
  );
}

// Extract current trace context (for passing to logs, external systems)
function getCurrentTraceId(): string | undefined {
  const span = trace.getActiveSpan();
  if (!span) return undefined;
  return span.spanContext().traceId;
}
```

### Context Propagation Across Async Boundaries

```typescript
import { context, trace, propagation } from '@opentelemetry/api';

// Propagate context in message queues
async function publishToQueue(queue: string, message: unknown): Promise<void> {
  const carrier: Record<string, string> = {};
  // Inject current trace context into message headers
  propagation.inject(context.active(), carrier);

  await queue.publish({
    body: JSON.stringify(message),
    headers: carrier, // Contains traceparent, tracestate
  });
}

// Restore context when consuming messages
async function consumeFromQueue(msg: QueueMessage): Promise<void> {
  // Extract trace context from message headers
  const parentContext = propagation.extract(context.active(), msg.headers);

  // Run consumer within the extracted context — links to original trace
  await context.with(parentContext, async () => {
    return tracer.startActiveSpan('process-message', async (span) => {
      try {
        await handleMessage(msg.body);
        span.setStatus({ code: SpanStatusCode.OK });
      } catch (error) {
        span.recordException(error as Error);
        span.setStatus({ code: SpanStatusCode.ERROR });
        throw error;
      } finally {
        span.end();
      }
    });
  });
}
```

---

## OpenTelemetry (Python)

### Auto-Instrumentation Setup

```python
# instrumentation.py — call configure_telemetry() at app startup, before routes load

from opentelemetry import trace, metrics
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.sdk.metrics import MeterProvider
from opentelemetry.sdk.metrics.export import PeriodicExportingMetricReader
from opentelemetry.sdk.resources import Resource, SERVICE_NAME, SERVICE_VERSION
from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter
from opentelemetry.exporter.otlp.proto.http.metric_exporter import OTLPMetricExporter
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor
from opentelemetry.instrumentation.httpx import HTTPXClientInstrumentor
from opentelemetry.instrumentation.sqlalchemy import SQLAlchemyInstrumentor
from opentelemetry.instrumentation.redis import RedisInstrumentor
import os


def configure_telemetry() -> None:
    """Configure OpenTelemetry with OTLP exporters. Call once at startup."""
    resource = Resource.create({
        SERVICE_NAME: os.getenv("OTEL_SERVICE_NAME", "my-python-service"),
        SERVICE_VERSION: os.getenv("SERVICE_VERSION", "0.0.0"),
        "deployment.environment.name": os.getenv("ENVIRONMENT", "development"),
    })

    collector_url = os.getenv("OTEL_EXPORTER_OTLP_ENDPOINT", "http://localhost:4318")

    # Traces
    trace_provider = TracerProvider(resource=resource)
    trace_provider.add_span_processor(
        BatchSpanProcessor(OTLPSpanExporter(endpoint=f"{collector_url}/v1/traces"))
    )
    trace.set_tracer_provider(trace_provider)

    # Metrics
    metric_reader = PeriodicExportingMetricReader(
        OTLPMetricExporter(endpoint=f"{collector_url}/v1/metrics"),
        export_interval_millis=15_000,
    )
    metrics.set_meter_provider(MeterProvider(resource=resource, metric_readers=[metric_reader]))

    # Auto-instrument libraries
    FastAPIInstrumentor.instrument()
    HTTPXClientInstrumentor().instrument()
    SQLAlchemyInstrumentor().instrument()
    RedisInstrumentor().instrument()
```

### FastAPI Integration with Manual Spans

```python
# main.py
from fastapi import FastAPI, Request
from opentelemetry import trace
from instrumentation import configure_telemetry

configure_telemetry()

app = FastAPI()
tracer = trace.get_tracer("my-python-service", "1.0.0")


@app.post("/orders")
async def create_order(request: Request, payload: CreateOrderRequest) -> OrderResponse:
    with tracer.start_as_current_span(
        "create_order",
        attributes={
            "order.item_count": len(payload.items),
            "order.customer_id": payload.customer_id,
        },
    ) as span:
        try:
            inventory = await check_inventory(payload.items)
            payment = await charge_payment(payload)
            order = await save_order(payload, payment.id)

            span.add_event("order.created", {"order.id": str(order.id)})
            span.set_status(trace.StatusCode.OK)
            return OrderResponse.model_validate(order)

        except InsufficientInventoryError as exc:
            span.set_status(trace.StatusCode.ERROR, str(exc))
            span.record_exception(exc)
            raise HTTPException(status_code=409, detail="Insufficient inventory")


# Middleware for correlation ID propagation
@app.middleware("http")
async def correlation_id_middleware(request: Request, call_next):
    """Ensure every request has a correlation ID, linked to the trace."""
    correlation_id = request.headers.get("x-correlation-id")
    if not correlation_id:
        span = trace.get_current_span()
        correlation_id = span.get_span_context().trace_id if span else uuid4().hex

    request.state.correlation_id = correlation_id
    response = await call_next(request)
    response.headers["x-correlation-id"] = correlation_id
    return response
```

---

## Structured Logging

### Node.js (pino)

```typescript
import pino from 'pino';
import { trace } from '@opentelemetry/api';

// --- Base logger setup ---
const logger = pino({
  level: process.env.LOG_LEVEL ?? 'info',
  // Redact sensitive fields — NEVER log passwords, tokens, PII
  redact: {
    paths: [
      'req.headers.authorization',
      'req.headers.cookie',
      'body.password',
      'body.token',
      'body.creditCard',
      '*.ssn',
      '*.email',   // Redact if GDPR requires it
    ],
    censor: '[REDACTED]',
  },
  // Customize serializers
  serializers: {
    err: pino.stdSerializers.err,
    req: pino.stdSerializers.req,
    res: pino.stdSerializers.res,
  },
  // Correlate logs with traces
  mixin() {
    const span = trace.getActiveSpan();
    if (!span) return {};
    const ctx = span.spanContext();
    return {
      trace_id: ctx.traceId,
      span_id: ctx.spanId,
      trace_flags: ctx.traceFlags,
    };
  },
  // Pretty-print in development, JSON in production
  transport: process.env.NODE_ENV === 'development'
    ? { target: 'pino-pretty', options: { colorize: true } }
    : undefined,
});

export { logger };

// --- Per-request child logger (Express middleware) ---
import { randomUUID } from 'node:crypto';

app.use((req, res, next) => {
  const requestId = req.headers['x-request-id'] as string ?? randomUUID();
  req.log = logger.child({
    requestId,
    method: req.method,
    path: req.url,
    userAgent: req.headers['user-agent'],
  });
  res.setHeader('x-request-id', requestId);
  req.log.info('request started');
  next();
});

// --- Log levels and when to use them ---
// fatal: Process is about to crash. Requires immediate human intervention.
// error: Operation failed. User impact likely. Needs investigation.
// warn:  Unexpected but handled. May indicate a problem developing.
// info:  Normal operations. Request lifecycle, deployments, config loaded.
// debug: Detailed context for debugging. Disabled in production by default.
// trace: Very verbose. Individual function calls, loop iterations.

// --- Correct usage ---
logger.fatal({ err }, 'Database connection pool exhausted, shutting down');
logger.error({ err, orderId, userId }, 'Payment processing failed');
logger.warn({ retryCount: 3, service: 'payment-api' }, 'Retrying failed request');
logger.info({ orderId, amount }, 'Order created successfully');
logger.debug({ query, params, duration }, 'Database query executed');
```

### Pino Transport Configuration

```typescript
// pino-transport.ts — multiple destinations
import pino from 'pino';

// Send different log levels to different destinations
const transport = pino.transport({
  targets: [
    {
      // All logs to stdout (for container log collection)
      target: 'pino/file',
      options: { destination: 1 }, // stdout
      level: 'info',
    },
    {
      // Error logs to separate file (for quick triage)
      target: 'pino/file',
      options: { destination: './logs/error.log', mkdir: true },
      level: 'error',
    },
    {
      // Send to Loki / log aggregation
      target: 'pino-loki',
      options: {
        host: process.env.LOKI_URL ?? 'http://localhost:3100',
        labels: { app: 'my-service', env: process.env.NODE_ENV },
        batching: true,
        interval: 5, // seconds
      },
      level: 'info',
    },
  ],
});

const logger = pino(transport);
```

### Python (structlog)

```python
import structlog
import logging
from opentelemetry import trace


def add_trace_context(
    logger: logging.Logger,
    method_name: str,
    event_dict: dict,
) -> dict:
    """Add OpenTelemetry trace context to every log entry."""
    span = trace.get_current_span()
    if span and span.get_span_context().is_valid:
        ctx = span.get_span_context()
        event_dict["trace_id"] = format(ctx.trace_id, "032x")
        event_dict["span_id"] = format(ctx.span_id, "016x")
    return event_dict


def configure_logging() -> None:
    """Configure structlog with JSON output and trace correlation."""
    structlog.configure(
        processors=[
            structlog.contextvars.merge_contextvars,        # Merge bound context
            structlog.stdlib.filter_by_level,                # Respect log levels
            structlog.stdlib.add_logger_name,                # Add logger name
            structlog.stdlib.add_log_level,                  # Add level field
            structlog.stdlib.PositionalArgumentsFormatter(), # Format positional args
            structlog.processors.TimeStamper(fmt="iso"),     # ISO 8601 timestamp
            structlog.processors.StackInfoRenderer(),        # Stack traces
            structlog.processors.UnicodeDecoder(),           # Decode bytes
            add_trace_context,                               # OTel trace correlation
            structlog.processors.JSONRenderer(),             # JSON output
        ],
        wrapper_class=structlog.stdlib.BoundLogger,
        context_class=dict,
        logger_factory=structlog.stdlib.LoggerFactory(),
        cache_logger_on_first_use=True,
    )


# Usage
log = structlog.get_logger()

# Bind context for the duration of a request (using contextvars)
structlog.contextvars.clear_contextvars()
structlog.contextvars.bind_contextvars(
    request_id="req-abc-123",
    user_id="user-456",
    tenant_id="tenant-789",
)

# All subsequent logs include bound context automatically
log.info("order.created", order_id="ord-001", item_count=3)
# Output: {"event": "order.created", "request_id": "req-abc-123",
#          "user_id": "user-456", "order_id": "ord-001", "item_count": 3,
#          "trace_id": "abc123...", "timestamp": "2026-02-25T10:00:00Z", "level": "info"}

log.error("payment.failed", order_id="ord-001", error="card_declined")
```

---

## Metrics (Prometheus)

### Four Metric Types

| Type | What It Measures | Examples | When to Use |
|---|---|---|---|
| **Counter** | Monotonically increasing value | Total requests, errors, orders processed | Counting events that only go up |
| **Gauge** | Value that goes up and down | Active connections, queue depth, temperature | Current state / level |
| **Histogram** | Distribution of values in buckets | Request duration, response size, query time | Latency, size distributions (use for percentiles) |
| **Summary** | Similar to histogram, client-side quantiles | Request duration quantiles | Avoid -- prefer histograms (summaries cannot be aggregated across instances) |

### Naming Conventions

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

### Node.js (prom-client)

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

### Python (prometheus_client)

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

### PromQL Essentials

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

**PromQL pitfalls:**
- Never use `rate()` on a gauge -- use `deriv()` or just the gauge value
- Always use `rate()` before `sum()` for counters, never `sum()` then `rate()`
- Window should be at least 4x the scrape interval (e.g., 15s scrape -> 1m window minimum)
- High cardinality labels (user_id, request_id) will explode Prometheus memory

---

## SLOs / SLIs / Error Budgets

### What to Measure

```
What are users experiencing?
├─ Availability → SLI: successful requests / total requests
│  └─ "successful" = non-5xx (exclude expected 4xx)
├─ Latency → SLI: requests faster than threshold / total requests
│  └─ Use multiple thresholds: p50 < 100ms, p99 < 500ms
├─ Throughput → SLI: processed items / expected items
│  └─ Background jobs completed within SLA window
├─ Correctness → SLI: correct outputs / total outputs
│  └─ Data pipeline accuracy, calculation correctness
└─ Freshness → SLI: data updated within threshold / total data
   └─ Search index staleness, cache consistency
```

### SLO Examples

| Service | SLI | SLO | Measurement Window |
|---|---|---|---|
| API Gateway | Availability (non-5xx) | 99.9% | 30-day rolling |
| Search API | p99 latency | < 200ms | 30-day rolling |
| Checkout Flow | Availability | 99.95% | 30-day rolling |
| Email Delivery | Delivery within 5 min | 99.5% | 30-day rolling |
| Data Pipeline | Freshness (< 15 min stale) | 99.0% | 7-day rolling |

### Error Budget Calculation

```
SLO = 99.9% availability (30-day window)

Total minutes in 30 days: 30 * 24 * 60 = 43,200 minutes
Error budget: 0.1% * 43,200 = 43.2 minutes of downtime allowed

Or in requests:
Total requests in 30 days: 10,000,000
Error budget: 0.1% * 10,000,000 = 10,000 failed requests allowed
```

**Error budget policy:**
- Budget remaining > 50%: Deploy freely, experiment, take risks
- Budget remaining 20-50%: Slow down, increase review rigor
- Budget remaining < 20%: Freeze non-critical deploys, focus on reliability
- Budget exhausted: Stop all feature work, focus exclusively on reliability

### Multi-Window, Multi-Burn-Rate Alerting (Google SRE)

```yaml
# Prometheus alerting rules — multi-burn-rate alert
# Detects when error budget is being consumed too fast
groups:
  - name: slo-alerts
    rules:
      # --- 2% budget consumed in 1 hour (fast burn) → Page ---
      - alert: HighErrorBudgetBurn
        expr: |
          (
            sum(rate(http_server_requests_total{status=~"5.."}[1h]))
            /
            sum(rate(http_server_requests_total[1h]))
          ) > (14.4 * 0.001)
          and
          (
            sum(rate(http_server_requests_total{status=~"5.."}[5m]))
            /
            sum(rate(http_server_requests_total[5m]))
          ) > (14.4 * 0.001)
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: "High error budget burn rate"
          description: "Burning 14.4x the error budget. 2% budget consumed in 1 hour."
          runbook: "https://wiki.internal/runbooks/high-error-rate"

      # --- 5% budget consumed in 6 hours (slow burn) → Ticket ---
      - alert: SlowErrorBudgetBurn
        expr: |
          (
            sum(rate(http_server_requests_total{status=~"5.."}[6h]))
            /
            sum(rate(http_server_requests_total[6h]))
          ) > (6 * 0.001)
          and
          (
            sum(rate(http_server_requests_total{status=~"5.."}[30m]))
            /
            sum(rate(http_server_requests_total[30m]))
          ) > (6 * 0.001)
        for: 15m
        labels:
          severity: warning
        annotations:
          summary: "Slow error budget burn rate"
          description: "Burning 6x the error budget. 5% budget consumed in 6 hours."
          runbook: "https://wiki.internal/runbooks/elevated-error-rate"

      # --- 10% budget consumed in 3 days (gradual burn) → Low-priority ticket ---
      - alert: GradualErrorBudgetBurn
        expr: |
          (
            sum(rate(http_server_requests_total{status=~"5.."}[3d]))
            /
            sum(rate(http_server_requests_total[3d]))
          ) > (1 * 0.001)
        for: 1h
        labels:
          severity: info
        annotations:
          summary: "Gradual error budget consumption"
          description: "Steady error rate consuming budget over days."
```

---

## Alerting Best Practices

### Should This Alert Page Someone?

```
Should this alert page someone at 3 AM?
├─ User-facing impact RIGHT NOW?
│  ├─ Affects >1% of users? → P1 — Page immediately
│  └─ Affects <1% of users? → P2 — Page during business hours
├─ Will cause user impact within hours?
│  ├─ Disk filling, certificate expiring? → P3 — Urgent ticket
│  └─ Error budget burning slowly? → P3 — Urgent ticket
├─ Degradation but not impacting SLO?
│  └─ Elevated latency, increased retries? → P4 — Regular ticket
└─ Informational?
   └─ Deploy completed, scaling event? → Dashboard only, NO alert
```

### Severity Levels

| Severity | Response Time | Who | Examples |
|---|---|---|---|
| **P1 — Critical** | Immediate (page) | On-call engineer | Service down, data loss, SLO breached |
| **P2 — High** | < 1 hour | On-call engineer | Major feature broken, error rate spike |
| **P3 — Medium** | < 4 hours (business) | Team queue | Degraded performance, non-critical error |
| **P4 — Low** | Next sprint | Backlog | Warning threshold, optimization needed |

### Alert Quality Rules

```
Every alert MUST have:
1. A clear, specific title (not "Server Error")
2. Current value and threshold that triggered it
3. Impact statement (what users are experiencing)
4. Runbook link (what to do RIGHT NOW)
5. Dashboard link (where to investigate)
6. Severity label (P1/P2/P3/P4)

Every alert MUST NOT:
1. Fire more than once per hour for the same issue (use grouping)
2. Auto-resolve and re-fire (flapping — add hysteresis)
3. Require investigation to determine if it is real (reduce noise)
4. Alert on causes (CPU high) — alert on symptoms (latency high)
```

### Alertmanager Configuration Example

```yaml
# alertmanager.yml
global:
  resolve_timeout: 5m

route:
  receiver: 'default'
  group_by: ['alertname', 'service']
  group_wait: 30s       # Wait before sending first notification
  group_interval: 5m    # Wait before sending update
  repeat_interval: 4h   # Wait before re-sending

  routes:
    - match:
        severity: critical
      receiver: 'pagerduty-critical'
      repeat_interval: 5m      # Re-page every 5 min until resolved
    - match:
        severity: warning
      receiver: 'slack-warnings'
      repeat_interval: 1h

receivers:
  - name: 'pagerduty-critical'
    pagerduty_configs:
      - service_key: '<PAGERDUTY_SERVICE_KEY>'
        description: '{{ .CommonAnnotations.summary }}'
        details:
          runbook: '{{ .CommonAnnotations.runbook }}'

  - name: 'slack-warnings'
    slack_configs:
      - api_url: '<SLACK_WEBHOOK_URL>'
        channel: '#alerts-warnings'
        title: '{{ .CommonAnnotations.summary }}'
        text: '{{ .CommonAnnotations.description }}'
```

---

## Health Checks

### Three Types of Health Checks

| Check | Question | Failure Action | Kubernetes Probe |
|---|---|---|---|
| **Liveness** | Is the process alive and not deadlocked? | Kill and restart the pod | `livenessProbe` |
| **Readiness** | Can it serve traffic right now? | Remove from load balancer | `readinessProbe` |
| **Startup** | Is it still initializing? | Wait, don't kill yet | `startupProbe` |

### Node.js Implementation

```typescript
import { Router, type Request, type Response } from 'express';

interface HealthCheckResult {
  status: 'healthy' | 'degraded' | 'unhealthy';
  checks: Record<string, { status: string; latency_ms?: number; message?: string }>;
  version: string;
  uptime_seconds: number;
}

const healthRouter = Router();

// Liveness — lightweight, no dependency checks
// If this fails, the process is broken beyond repair. Restart it.
healthRouter.get('/healthz', (_req: Request, res: Response) => {
  res.status(200).json({ status: 'alive' });
});

// Readiness — checks all critical dependencies
// If this fails, stop sending traffic but don't restart.
healthRouter.get('/readyz', async (_req: Request, res: Response) => {
  const checks: HealthCheckResult['checks'] = {};
  let overall: HealthCheckResult['status'] = 'healthy';

  // Check database
  try {
    const start = performance.now();
    await db.query('SELECT 1');
    checks.database = { status: 'ok', latency_ms: Math.round(performance.now() - start) };
  } catch (err) {
    checks.database = { status: 'fail', message: (err as Error).message };
    overall = 'unhealthy';
  }

  // Check Redis
  try {
    const start = performance.now();
    await redis.ping();
    checks.redis = { status: 'ok', latency_ms: Math.round(performance.now() - start) };
  } catch (err) {
    checks.redis = { status: 'fail', message: (err as Error).message };
    overall = 'unhealthy';
  }

  // Check external API (non-critical — degraded, not unhealthy)
  try {
    const start = performance.now();
    const resp = await fetch('https://api.stripe.com/v1/health', {
      signal: AbortSignal.timeout(2000),
    });
    checks.stripe = {
      status: resp.ok ? 'ok' : 'degraded',
      latency_ms: Math.round(performance.now() - start),
    };
    if (!resp.ok) overall = overall === 'healthy' ? 'degraded' : overall;
  } catch {
    checks.stripe = { status: 'degraded', message: 'Timeout or unreachable' };
    if (overall === 'healthy') overall = 'degraded';
  }

  const result: HealthCheckResult = {
    status: overall,
    checks,
    version: process.env.npm_package_version ?? 'unknown',
    uptime_seconds: Math.round(process.uptime()),
  };

  res.status(overall === 'unhealthy' ? 503 : 200).json(result);
});

export { healthRouter };
```

### Kubernetes Probe Configuration

```yaml
# deployment.yaml
apiVersion: apps/v1
kind: Deployment
spec:
  template:
    spec:
      containers:
        - name: app
          ports:
            - containerPort: 3000
          # Startup probe — allow slow boot (migrations, cache warming)
          startupProbe:
            httpGet:
              path: /healthz
              port: 3000
            failureThreshold: 30      # 30 * 10s = 5 min max startup time
            periodSeconds: 10
          # Liveness — restart if deadlocked
          livenessProbe:
            httpGet:
              path: /healthz
              port: 3000
            periodSeconds: 15
            timeoutSeconds: 5
            failureThreshold: 3       # 3 consecutive failures = restart
          # Readiness — remove from service if dependencies are down
          readinessProbe:
            httpGet:
              path: /readyz
              port: 3000
            periodSeconds: 10
            timeoutSeconds: 5
            failureThreshold: 3
            successThreshold: 1
```

---

## Dashboard Design

### RED Method (Request-Driven Services)

Use RED for any service that receives requests (APIs, web servers, microservices).

| Signal | What to Measure | PromQL Example |
|---|---|---|
| **R**ate | Requests per second | `sum(rate(http_server_requests_total[5m]))` |
| **E**rrors | Error rate (percentage) | `sum(rate(http_server_requests_total{status=~"5.."}[5m])) / sum(rate(http_server_requests_total[5m]))` |
| **D**uration | Latency distribution | `histogram_quantile(0.99, sum(rate(http_server_request_duration_seconds_bucket[5m])) by (le))` |

### USE Method (Resources)

Use USE for infrastructure resources (CPU, memory, disk, network, DB pool).

| Signal | What to Measure | Examples |
|---|---|---|
| **U**tilization | % of capacity used | CPU usage %, memory usage %, disk usage % |
| **S**aturation | How much extra work is queued | Run queue length, swap usage, connection pool waiters |
| **E**rrors | Error count for this resource | Disk errors, network packet drops, OOM kills |

### Golden Signals (Google SRE)

| Signal | What It Tells You | Maps To |
|---|---|---|
| **Latency** | How long requests take (split success vs error) | RED Duration |
| **Traffic** | How much demand is on the system | RED Rate |
| **Errors** | What fraction of requests fail | RED Errors |
| **Saturation** | How "full" the service is | USE Saturation |

### Dashboard Hierarchy

```
Level 1 — Platform Overview
├─ Total request rate (all services)
├─ Overall error rate
├─ p99 latency (all services)
└─ Active incidents / SLO status

Level 2 — Service Dashboard (one per service)
├─ RED metrics for this service
├─ SLO burn rate
├─ Recent deployments (annotation)
└─ Top errors (error types, count)

Level 3 — Component Dashboard (DB, cache, queue)
├─ USE metrics for this resource
├─ Connection pool stats
├─ Query latency by type
└─ Slow query log
```

### Grafana Dashboard JSON Example (Service-Level)

```json
{
  "title": "Order Service — RED Dashboard",
  "uid": "order-service-red",
  "panels": [
    {
      "title": "Request Rate",
      "type": "timeseries",
      "targets": [{
        "expr": "sum(rate(http_server_requests_total{service=\"order-service\"}[5m]))",
        "legendFormat": "req/s"
      }],
      "gridPos": { "h": 8, "w": 8, "x": 0, "y": 0 }
    },
    {
      "title": "Error Rate (%)",
      "type": "timeseries",
      "targets": [{
        "expr": "100 * sum(rate(http_server_requests_total{service=\"order-service\",status=~\"5..\"}[5m])) / sum(rate(http_server_requests_total{service=\"order-service\"}[5m]))",
        "legendFormat": "error %"
      }],
      "fieldConfig": {
        "defaults": {
          "thresholds": {
            "steps": [
              { "color": "green", "value": null },
              { "color": "yellow", "value": 1 },
              { "color": "red", "value": 5 }
            ]
          }
        }
      },
      "gridPos": { "h": 8, "w": 8, "x": 8, "y": 0 }
    },
    {
      "title": "Latency (p50, p90, p99)",
      "type": "timeseries",
      "targets": [
        {
          "expr": "histogram_quantile(0.50, sum(rate(http_server_request_duration_seconds_bucket{service=\"order-service\"}[5m])) by (le))",
          "legendFormat": "p50"
        },
        {
          "expr": "histogram_quantile(0.90, sum(rate(http_server_request_duration_seconds_bucket{service=\"order-service\"}[5m])) by (le))",
          "legendFormat": "p90"
        },
        {
          "expr": "histogram_quantile(0.99, sum(rate(http_server_request_duration_seconds_bucket{service=\"order-service\"}[5m])) by (le))",
          "legendFormat": "p99"
        }
      ],
      "fieldConfig": {
        "defaults": { "unit": "s" }
      },
      "gridPos": { "h": 8, "w": 8, "x": 16, "y": 0 }
    }
  ]
}
```

---

## Incident Response

### Severity Classification

| Severity | User Impact | Response | Examples |
|---|---|---|---|
| **SEV1** | Complete outage or data loss | All hands, war room, exec comms | Service down, data corruption, security breach |
| **SEV2** | Major feature broken, >10% users affected | On-call + team lead, customer comms | Payment failing, auth broken, major degradation |
| **SEV3** | Minor feature broken, <10% users affected | On-call during business hours | Non-critical feature broken, slow performance |
| **SEV4** | Cosmetic or minimal impact | Next sprint | UI glitch, minor inconvenience |

### Incident Response Workflow

```
1. DETECT    → Alert fires or user reports issue
2. TRIAGE    → Assign severity, notify incident commander
3. MITIGATE  → Stop the bleeding (rollback, feature flag, scale up)
4. DIAGNOSE  → Find root cause using correlated telemetry
5. FIX       → Deploy permanent fix
6. VERIFY    → Confirm fix resolved the issue, SLOs recovering
7. COMMS     → Status page update, customer notification
8. LEARN     → Schedule post-mortem within 48 hours
```

### Incident Commander Responsibilities

```
The Incident Commander (IC) does NOT debug.
The IC is a coordinator:

1. Declare the incident and severity
2. Create the incident channel (#inc-YYYY-MM-DD-short-description)
3. Assign roles:
   - IC: Coordinates, makes decisions
   - Tech Lead: Drives investigation and fix
   - Comms Lead: Updates status page, stakeholders
4. Set a timer for regular status updates (every 15 min for SEV1)
5. Decide: mitigate first (rollback) or diagnose first
6. Escalate if not making progress within 30 minutes
7. Declare resolved when SLOs are back to normal
8. Schedule post-mortem
```

### Communication Template (Status Page)

```markdown
## [Investigating] Elevated error rates on Checkout API

**Impact:** ~5% of checkout attempts are failing with timeout errors.
**Start time:** 2026-02-25 14:32 UTC
**Current status:** Investigating. The on-call team has been paged and is
investigating elevated 503 errors on the checkout service.
**Customer impact:** Some users may experience failed checkout attempts.
Please retry in a few minutes.
**Next update:** In 15 minutes or when we have more information.

---

## [Identified] Root cause identified — database connection pool exhaustion

**Update:** Root cause identified as database connection pool exhaustion
caused by a slow query introduced in deploy v2.14.3.
**Mitigation:** Rolling back to v2.14.2.
**ETA to resolution:** ~10 minutes for rollback to complete.

---

## [Resolved] Checkout API restored to normal

**Resolution:** Rolled back to v2.14.2 at 15:01 UTC. All error rates
have returned to normal. SLOs are within target.
**Duration:** 29 minutes
**Follow-up:** Post-mortem scheduled for 2026-02-27.
```

### Blameless Post-Mortem Template

```markdown
# Post-Mortem: [Title of Incident]

**Date:** 2026-02-25
**Severity:** SEV2
**Duration:** 29 minutes (14:32 - 15:01 UTC)
**Authors:** [Names]
**Status:** Action items in progress

## Summary
One-paragraph summary of what happened, what the impact was, and how it
was resolved.

## Impact
- **Users affected:** ~5% of checkout attempts (estimated 1,200 users)
- **Revenue impact:** ~$18,000 in delayed orders (all recovered after fix)
- **SLO impact:** Error budget consumed: 3.2% (30-day window)
- **Duration:** 29 minutes

## Timeline (all times UTC)
| Time | Event |
|------|-------|
| 14:30 | Deploy v2.14.3 rolled out (contained slow query) |
| 14:32 | Alert: HighErrorBudgetBurn fired (P1) |
| 14:34 | IC declared, #inc-2026-02-25-checkout created |
| 14:38 | Identified: connection pool exhaustion via DB dashboard |
| 14:42 | Root cause: new query missing index, holding connections |
| 14:45 | Decision: rollback v2.14.3 → v2.14.2 |
| 14:51 | Rollback deployed |
| 15:01 | Error rates returned to normal, incident resolved |

## Root Cause
Deploy v2.14.3 introduced a new database query in the checkout flow that
was missing an index. The query took 8-12 seconds under load, exhausting
the connection pool (max 20 connections). Once the pool was exhausted,
new requests timed out with 503 errors.

## Detection
Detected by multi-burn-rate SLO alert within 2 minutes of impact starting.

## Resolution
Rolled back to v2.14.2 which did not contain the problematic query.

## What Went Well
- Alert fired quickly (2 minutes after impact)
- Rollback procedure was well-documented and fast
- IC was assigned within 2 minutes

## What Went Wrong
- No query performance testing in CI
- Missing index was not caught in code review
- Connection pool metrics were not on the service dashboard

## Action Items
| Action | Owner | Priority | Ticket |
|--------|-------|----------|--------|
| Add slow query detection to CI pipeline | @backend-team | P2 | JIRA-1234 |
| Add DB connection pool metrics to service dashboard | @platform | P2 | JIRA-1235 |
| Create index on orders.customer_id + status | @backend-team | P1 | JIRA-1236 |
| Add connection pool exhaustion runbook | @sre | P3 | JIRA-1237 |
| Review all queries added in last 30 days for missing indexes | @backend-team | P2 | JIRA-1238 |

## Lessons Learned
- Database queries need performance testing, not just correctness testing
- Connection pool size should be monitored and alerted on
- Every deploy should have a fast rollback path
```

---

## Error Tracking (Sentry)

### Node.js Setup

```typescript
import * as Sentry from '@sentry/node';
import { nodeProfilingIntegration } from '@sentry/profiling-node';

Sentry.init({
  dsn: process.env.SENTRY_DSN,
  environment: process.env.NODE_ENV,
  release: process.env.npm_package_version,  // Correlate errors with releases
  integrations: [
    nodeProfilingIntegration(),               // Performance profiling
  ],
  // Capture 10% of transactions for performance monitoring
  tracesSampleRate: process.env.NODE_ENV === 'production' ? 0.1 : 1.0,
  profilesSampleRate: 0.1,
  // Filter out noisy errors
  ignoreErrors: [
    'AbortError',                  // Expected cancellations
    'ECONNRESET',                  // Client disconnects
    /^NetworkError/,               // Transient network issues
  ],
  // Scrub sensitive data before sending
  beforeSend(event) {
    if (event.request?.headers) {
      delete event.request.headers['authorization'];
      delete event.request.headers['cookie'];
    }
    return event;
  },
});

// Express error handler — must be AFTER all routes and other middleware
app.use(Sentry.expressErrorHandler());

// Add user context (after auth middleware)
app.use((req, res, next) => {
  if (req.user) {
    Sentry.setUser({
      id: req.user.id,
      email: req.user.email,     // Only if GDPR allows
      segment: req.user.plan,    // Business context
    });
  }
  next();
});

// Add custom context to errors
async function processOrder(orderId: string): Promise<void> {
  Sentry.setTag('order.id', orderId);
  Sentry.addBreadcrumb({
    category: 'order',
    message: `Processing order ${orderId}`,
    level: 'info',
  });

  try {
    await chargePayment(orderId);
  } catch (error) {
    Sentry.captureException(error, {
      extra: {
        orderId,
        paymentProvider: 'stripe',
        retryCount: 3,
      },
    });
    throw error;
  }
}
```

### Python Setup with FastAPI

```python
import sentry_sdk
from sentry_sdk.integrations.fastapi import FastApiIntegration
from sentry_sdk.integrations.sqlalchemy import SqlalchemyIntegration

sentry_sdk.init(
    dsn=os.getenv("SENTRY_DSN"),
    environment=os.getenv("ENVIRONMENT", "development"),
    release=os.getenv("SERVICE_VERSION", "0.0.0"),
    integrations=[
        FastApiIntegration(),
        SqlalchemyIntegration(),
    ],
    traces_sample_rate=0.1 if os.getenv("ENVIRONMENT") == "production" else 1.0,
    profiles_sample_rate=0.1,
    # Scrub sensitive data
    before_send=scrub_sensitive_data,
)


def scrub_sensitive_data(event, hint):
    """Remove sensitive fields before sending to Sentry."""
    if "request" in event and "headers" in event["request"]:
        headers = event["request"]["headers"]
        for sensitive in ("authorization", "cookie", "x-api-key"):
            headers.pop(sensitive, None)
    return event


# Add user context in middleware
@app.middleware("http")
async def sentry_user_context(request: Request, call_next):
    if hasattr(request.state, "user"):
        sentry_sdk.set_user({
            "id": request.state.user.id,
            "email": request.state.user.email,
        })
    response = await call_next(request)
    return response


# Capture custom errors with context
def process_payment(order_id: str, amount: int) -> None:
    sentry_sdk.set_tag("order_id", order_id)
    sentry_sdk.add_breadcrumb(
        category="payment",
        message=f"Charging {amount} for order {order_id}",
        level="info",
    )

    try:
        stripe.charges.create(amount=amount, currency="usd")
    except stripe.error.CardError as exc:
        with sentry_sdk.push_scope() as scope:
            scope.set_extra("order_id", order_id)
            scope.set_extra("amount", amount)
            scope.set_extra("decline_code", exc.code)
            sentry_sdk.capture_exception(exc)
        raise
```

### Source Maps for Stack Traces

```typescript
// Upload source maps during build/deploy
// package.json
{
  "scripts": {
    "build": "tsc && npm run sentry:sourcemaps",
    "sentry:sourcemaps": "sentry-cli sourcemaps inject ./dist && sentry-cli sourcemaps upload --release=$npm_package_version ./dist"
  }
}

// Or in CI/CD:
// npx @sentry/cli sourcemaps upload --auth-token=$SENTRY_AUTH_TOKEN \
//   --org=my-org --project=my-project --release=$VERSION ./dist
```

---

## OpenTelemetry Collector Configuration

```yaml
# otel-collector-config.yaml — production configuration
receivers:
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317
      http:
        endpoint: 0.0.0.0:4318

processors:
  # Batch telemetry to reduce network calls
  batch:
    send_batch_size: 1000
    timeout: 10s

  # Add metadata to all telemetry
  resource:
    attributes:
      - key: deployment.environment
        value: production
        action: upsert

  # Sample traces to reduce volume (keep 10% of traces, but 100% of errors)
  tail_sampling:
    policies:
      - name: errors-always
        type: status_code
        status_code: { status_codes: [ERROR] }
      - name: slow-requests
        type: latency
        latency: { threshold_ms: 1000 }
      - name: probabilistic
        type: probabilistic
        probabilistic: { sampling_percentage: 10 }

  # Drop sensitive attributes
  attributes:
    actions:
      - key: http.request.header.authorization
        action: delete
      - key: http.request.header.cookie
        action: delete

exporters:
  # Traces to Grafana Tempo
  otlp/tempo:
    endpoint: tempo:4317
    tls:
      insecure: true

  # Metrics to Prometheus
  prometheusremotewrite:
    endpoint: http://prometheus:9090/api/v1/write

  # Logs to Grafana Loki
  loki:
    endpoint: http://loki:3100/loki/api/v1/push

service:
  pipelines:
    traces:
      receivers: [otlp]
      processors: [batch, resource, tail_sampling, attributes]
      exporters: [otlp/tempo]
    metrics:
      receivers: [otlp]
      processors: [batch, resource]
      exporters: [prometheusremotewrite]
    logs:
      receivers: [otlp]
      processors: [batch, resource, attributes]
      exporters: [loki]
```

### Docker Compose Stack

```yaml
# docker-compose.observability.yaml — local observability stack
services:
  otel-collector:
    image: otel/opentelemetry-collector-contrib:latest
    command: ["--config=/etc/otel/config.yaml"]
    ports:
      - "4317:4317"   # gRPC
      - "4318:4318"   # HTTP
    volumes:
      - ./otel-collector-config.yaml:/etc/otel/config.yaml

  prometheus:
    image: prom/prometheus:latest
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.retention.time=30d'
      - '--web.enable-remote-write-receiver'

  tempo:
    image: grafana/tempo:latest
    ports:
      - "3200:3200"   # Tempo query
      - "4317"        # OTLP gRPC (internal)
    command: ["-config.file=/etc/tempo/config.yaml"]

  loki:
    image: grafana/loki:latest
    ports:
      - "3100:3100"

  grafana:
    image: grafana/grafana:latest
    ports:
      - "3000:3000"
    environment:
      GF_AUTH_ANONYMOUS_ENABLED: "true"
      GF_AUTH_ANONYMOUS_ORG_ROLE: Admin
    volumes:
      - ./grafana-datasources.yaml:/etc/grafana/provisioning/datasources/datasources.yaml
```

---

## Anti-Patterns

| Anti-Pattern | Why It's Dangerous | Fix |
|---|---|---|
| `console.log` in production | No levels, no structure, no correlation, no redaction | pino (Node.js) or structlog (Python) with JSON output |
| Alert on every 5xx error | Alert fatigue -- engineers ignore pages, miss real incidents | SLO-based burn rate alerts (multi-window) |
| No correlation IDs | Cannot trace a request across services, logs are disconnected | Propagate trace_id via OpenTelemetry context |
| Logging PII (emails, IPs, SSNs) | GDPR/CCPA violation, legal liability, breach amplification | Pino `redact` config or structlog processors |
| Metrics with unbounded labels | `user_id` as label = millions of time series = Prometheus OOM | Only use low-cardinality labels (method, status, endpoint pattern) |
| Dashboard with 50+ panels | Information overload, nobody reads it, slow to load | Three-level hierarchy: overview -> service -> component |
| SLO of 100% | Impossible to achieve, stifles deployments, zero error budget | 99.9% is three nines (43 min/month). Set realistic targets |
| Alerting on causes, not symptoms | "CPU at 80%" misses novel failures; CPU at 80% might be fine | Alert on latency, error rate, availability (user-facing symptoms) |
| No runbook linked to alert | Engineer gets paged at 3 AM with no guidance on what to do | Every alert has a runbook URL in annotations |
| No post-mortem after incidents | Same incidents repeat, no organizational learning | Blameless post-mortem within 48 hours, track action items |
| Health check that always returns 200 | Hides real dependency failures, load balancer sends traffic to broken pods | Check actual dependencies (DB, cache, critical APIs) |
| Sampling 100% of traces | Huge storage cost, slow queries, unnecessary in production | Sample 1-10% of normal traces, 100% of errors and slow requests |
| Vendor-locked instrumentation | Expensive migration when switching from Datadog to Grafana | Use OpenTelemetry for vendor-neutral instrumentation |
| Metrics endpoint without authentication | Exposes internal system details to attackers | Serve /metrics on internal port or behind auth |
| Logging request/response bodies | Massive log volume, potential PII exposure, storage cost | Log only in debug mode or for specific error investigation |
| Not flushing telemetry on shutdown | Last minutes of data lost, gaps in traces | Call `sdk.shutdown()` on SIGTERM before `process.exit()` |
| Ignoring metric cardinality | 10M time series = Prometheus unusable, bills explode | Audit label values, set cardinality limits, use exemplars for high-cardinality data |

---

## Checklist: Observability Review

### Instrumentation
- [ ] OpenTelemetry SDK initialized before application code loads
- [ ] Auto-instrumentation enabled for HTTP, DB, cache, message queue
- [ ] Manual spans added for critical business operations (order processing, payments)
- [ ] Span attributes include relevant business context (order_id, user_id, plan)
- [ ] Context propagation configured for async operations (queues, background jobs)
- [ ] Telemetry flushed on graceful shutdown (SIGTERM handler calls `sdk.shutdown()`)
- [ ] Health check endpoints excluded from tracing (avoid noise)

### Logging
- [ ] Structured JSON logging in production (pino / structlog)
- [ ] Correlation: every log includes trace_id and span_id
- [ ] Per-request context: request_id, user_id, method, path
- [ ] Sensitive fields redacted (authorization, password, PII)
- [ ] Log levels used correctly (error for failures, warn for handled issues, info for lifecycle)
- [ ] No `console.log` in production code

### Metrics
- [ ] RED metrics for all request-driven services (rate, errors, duration)
- [ ] USE metrics for resources (CPU, memory, DB pool, disk)
- [ ] Custom business metrics (orders created, payments processed, signups)
- [ ] Metric naming follows convention (namespace_subsystem_name_unit)
- [ ] No high-cardinality labels (no user_id, request_id, email as label values)
- [ ] Histogram buckets tuned for expected latency range
- [ ] Default runtime metrics collected (GC, event loop lag, memory)

### SLOs and Alerting
- [ ] SLOs defined for critical user journeys (availability, latency)
- [ ] SLIs measured and reported on dashboards
- [ ] Error budget tracked and visible to the team
- [ ] Multi-window, multi-burn-rate alerts configured (not simple threshold)
- [ ] Every alert has: severity, runbook link, dashboard link, impact statement
- [ ] P1 alerts page on-call; P3/P4 create tickets
- [ ] Alert fatigue reviewed: no alert fires more than once/day without action

### Health Checks
- [ ] Liveness probe: lightweight, no dependency checks (`/healthz`)
- [ ] Readiness probe: checks DB, cache, critical dependencies (`/readyz`)
- [ ] Startup probe: allows time for slow initialization
- [ ] Health check responses include version and dependency status
- [ ] Kubernetes probes configured with appropriate thresholds

### Dashboards
- [ ] Platform overview dashboard exists (request rate, error rate, latency)
- [ ] Per-service RED dashboards exist
- [ ] Resource dashboards use USE method
- [ ] Deploy annotations on time-series graphs
- [ ] Dashboard hierarchy: overview -> service -> component

### Incident Response
- [ ] Incident severity classification defined (SEV1-SEV4)
- [ ] On-call rotation established with escalation policy
- [ ] Runbooks exist for all P1/P2 alert scenarios
- [ ] Blameless post-mortem process defined and followed
- [ ] Post-mortem action items tracked to completion
- [ ] Communication templates ready (status page, internal, customer)

### Error Tracking
- [ ] Sentry (or equivalent) configured with release tracking
- [ ] Source maps uploaded for minified/compiled code
- [ ] Sensitive data scrubbed before sending (beforeSend hook)
- [ ] User context attached (id, plan) for impact assessment
- [ ] Noisy errors filtered (AbortError, ECONNRESET)
- [ ] Alert rules configured in Sentry for new/regressed issues
