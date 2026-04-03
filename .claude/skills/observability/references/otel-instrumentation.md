# OpenTelemetry Instrumentation

## Table of Contents

- [Node.js Auto-Instrumentation Setup](#nodejs-auto-instrumentation-setup)
- [Manual Span Creation (Node.js)](#manual-span-creation-nodejs)
- [Context Propagation Across Async Boundaries](#context-propagation-across-async-boundaries)
- [Python Auto-Instrumentation Setup](#python-auto-instrumentation-setup)
- [FastAPI Integration with Manual Spans](#fastapi-integration-with-manual-spans)
- [OTel Collector Configuration](#otel-collector-configuration)
- [Docker Compose Observability Stack](#docker-compose-observability-stack)

---

## Node.js Auto-Instrumentation Setup

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

---

## Manual Span Creation (Node.js)

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

---

## Context Propagation Across Async Boundaries

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

## Python Auto-Instrumentation Setup

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

---

## FastAPI Integration with Manual Spans

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

## OTel Collector Configuration

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

---

## Docker Compose Observability Stack

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
