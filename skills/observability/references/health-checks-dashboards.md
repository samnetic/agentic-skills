# Health Checks and Dashboard Design

## Table of Contents

- [Three Types of Health Checks](#three-types-of-health-checks)
- [Node.js Health Check Implementation](#nodejs-health-check-implementation)
- [Kubernetes Probe Configuration](#kubernetes-probe-configuration)
- [RED Method (Request-Driven Services)](#red-method-request-driven-services)
- [USE Method (Resources)](#use-method-resources)
- [Golden Signals (Google SRE)](#golden-signals-google-sre)
- [Dashboard Hierarchy](#dashboard-hierarchy)
- [Grafana Dashboard JSON Example](#grafana-dashboard-json-example)

---

## Three Types of Health Checks

| Check | Question | Failure Action | Kubernetes Probe |
|---|---|---|---|
| **Liveness** | Is the process alive and not deadlocked? | Kill and restart the pod | `livenessProbe` |
| **Readiness** | Can it serve traffic right now? | Remove from load balancer | `readinessProbe` |
| **Startup** | Is it still initializing? | Wait, don't kill yet | `startupProbe` |

---

## Node.js Health Check Implementation

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

---

## Kubernetes Probe Configuration

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

## RED Method (Request-Driven Services)

Use RED for any service that receives requests (APIs, web servers, microservices).

| Signal | What to Measure | PromQL Example |
|---|---|---|
| **R**ate | Requests per second | `sum(rate(http_server_requests_total[5m]))` |
| **E**rrors | Error rate (percentage) | `sum(rate(http_server_requests_total{status=~"5.."}[5m])) / sum(rate(http_server_requests_total[5m]))` |
| **D**uration | Latency distribution | `histogram_quantile(0.99, sum(rate(http_server_request_duration_seconds_bucket[5m])) by (le))` |

---

## USE Method (Resources)

Use USE for infrastructure resources (CPU, memory, disk, network, DB pool).

| Signal | What to Measure | Examples |
|---|---|---|
| **U**tilization | % of capacity used | CPU usage %, memory usage %, disk usage % |
| **S**aturation | How much extra work is queued | Run queue length, swap usage, connection pool waiters |
| **E**rrors | Error count for this resource | Disk errors, network packet drops, OOM kills |

---

## Golden Signals (Google SRE)

| Signal | What It Tells You | Maps To |
|---|---|---|
| **Latency** | How long requests take (split success vs error) | RED Duration |
| **Traffic** | How much demand is on the system | RED Rate |
| **Errors** | What fraction of requests fail | RED Errors |
| **Saturation** | How "full" the service is | USE Saturation |

---

## Dashboard Hierarchy

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

---

## Grafana Dashboard JSON Example

Service-level RED dashboard:

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
