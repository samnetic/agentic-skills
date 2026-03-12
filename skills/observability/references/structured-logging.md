# Structured Logging

## Table of Contents

- [Node.js with pino](#nodejs-with-pino)
- [Pino Transport Configuration](#pino-transport-configuration)
- [Python with structlog](#python-with-structlog)
- [Log Levels Guide](#log-levels-guide)

---

## Node.js with pino

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

// --- Correct usage ---
logger.fatal({ err }, 'Database connection pool exhausted, shutting down');
logger.error({ err, orderId, userId }, 'Payment processing failed');
logger.warn({ retryCount: 3, service: 'payment-api' }, 'Retrying failed request');
logger.info({ orderId, amount }, 'Order created successfully');
logger.debug({ query, params, duration }, 'Database query executed');
```

---

## Pino Transport Configuration

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

---

## Python with structlog

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

## Log Levels Guide

| Level | When to Use | Examples |
|-------|-------------|---------|
| **fatal** | Process is about to crash. Requires immediate human intervention | Database connection pool exhausted, shutting down |
| **error** | Operation failed. User impact likely. Needs investigation | Payment processing failed |
| **warn** | Unexpected but handled. May indicate a problem developing | Retrying failed request (attempt 3/5) |
| **info** | Normal operations. Request lifecycle, deployments, config loaded | Order created successfully |
| **debug** | Detailed context for debugging. Disabled in production by default | Database query executed (with params, duration) |
| **trace** | Very verbose. Individual function calls, loop iterations | Function entry/exit, variable state |
