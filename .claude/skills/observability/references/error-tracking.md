# Error Tracking (Sentry)

## Table of Contents

- [Node.js Setup](#nodejs-setup)
- [Python Setup with FastAPI](#python-setup-with-fastapi)
- [Source Maps for Stack Traces](#source-maps-for-stack-traces)

---

## Node.js Setup

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

---

## Python Setup with FastAPI

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

---

## Source Maps for Stack Traces

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
