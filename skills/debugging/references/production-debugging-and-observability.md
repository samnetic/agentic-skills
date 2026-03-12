# Production Debugging and Observability

Deep-dive reference for error tracking with Sentry, distributed tracing with OpenTelemetry, structured logging, feature flags for debug mode, canary deployments, and session replay.

---

## Table of Contents

- [Error Tracking with Sentry](#error-tracking-with-sentry)
  - [Setup](#setup)
  - [Breadcrumbs -- Trace Events Leading to an Error](#breadcrumbs----trace-events-leading-to-an-error)
  - [Custom Context -- Add Business Data to Errors](#custom-context----add-business-data-to-errors)
  - [Source Maps -- Readable Stack Traces in Production](#source-maps----readable-stack-traces-in-production)
  - [Release Tracking](#release-tracking)
- [Distributed Tracing](#distributed-tracing)
  - [OpenTelemetry Concepts](#opentelemetry-concepts)
  - [Correlating Logs Across Services](#correlating-logs-across-services)
  - [Trace Context Propagation](#trace-context-propagation)
- [Structured Logging for Debugging](#structured-logging-for-debugging)
- [Feature Flags for Debug Mode](#feature-flags-for-debug-mode)
- [Canary Deployments for Validation](#canary-deployments-for-validation)
- [Replay-Based Debugging](#replay-based-debugging)

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

### Breadcrumbs -- Trace Events Leading to an Error

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
    // Breadcrumbs show the trail: user logged in -> added items -> clicked checkout -> payment failed
    Sentry.captureException(error);
    throw error;
  }
}
```

### Custom Context -- Add Business Data to Errors

```typescript
// Set user context -- shows on every error for this request
Sentry.setUser({
  id: user.id,
  email: user.email,
  subscription: user.plan,
});

// Set custom tags -- filterable in Sentry dashboard
Sentry.setTag('feature', 'checkout');
Sentry.setTag('payment_provider', 'stripe');

// Set extra context -- additional data for debugging
Sentry.setExtra('cart', { items: cart.items.length, total: cart.total });

// Scoped context -- only applies to errors within this scope
Sentry.withScope((scope) => {
  scope.setTag('operation', 'bulk-import');
  scope.setExtra('batchSize', items.length);
  scope.setLevel('warning');
  // Only errors captured within this block get these tags
  Sentry.captureException(error);
});
```

### Source Maps -- Readable Stack Traces in Production

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
  +-- Span: A single operation within a trace
      +-- Name: "POST /api/orders"
      +-- Duration: 142ms
      +-- Attributes: { http.method: "POST", http.status: 200 }
      +-- Events: [{ name: "payment.charged", timestamp: ... }]
      +-- Child Spans:
          +-- "db.query SELECT orders" (35ms)
          +-- "http.client POST payment-service" (80ms)
          |   +-- "db.query INSERT payments" (20ms)
          +-- "http.client POST email-service" (15ms)

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
// traceId="abc123" -> shows ALL logs across ALL services for this request
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

## Structured Logging for Debugging

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

// Log with context -- not just a message
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

// Temporary debug logging -- controlled by env var, not code changes
if (process.env.DEBUG_ORDERS === 'true') {
  logger.debug({ order, user }, 'Full order context for debugging');
}
```

---

## Feature Flags for Debug Mode

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
// - No deploy required -- toggle via dashboard
// - No risk to other users
// - Can disable instantly if it causes issues
```

---

## Canary Deployments for Validation

```
Canary deployment strategy for debugging production issues:

1. Deploy fix to 5% of traffic (canary)
2. Monitor error rates for canary vs stable:
   - Error rate decreased? Fix is working
   - Error rate unchanged? Wrong root cause
   - Error rate increased? Fix made it worse -- rollback

Monitoring checklist for canary:
+-- Error rate (Sentry alerts per release)
+-- Latency P95 (should not increase)
+-- Business metrics (conversions, completions)
+-- Log volume (unexpected increase = new errors)

Tools: Kubernetes progressive delivery, AWS CodeDeploy, Vercel skew protection
```

---

## Replay-Based Debugging

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
// - Network requests, console logs, DOM changes -- all captured
// - No need to ask "What were you doing when it happened?"
// - Especially valuable for "cannot reproduce" bugs
```
