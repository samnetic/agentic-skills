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

## Workflow

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

---

## Key Concepts Quick Reference

### Metric Types

| Type | What It Measures | When to Use |
|---|---|---|
| **Counter** | Monotonically increasing value | Counting events (requests, errors, orders) |
| **Gauge** | Value that goes up and down | Current state (connections, queue depth) |
| **Histogram** | Distribution in buckets | Latency, size distributions, percentiles |
| **Summary** | Client-side quantiles | Avoid -- prefer histograms (not aggregatable) |

### SLO Error Budget Policy

| Budget Remaining | Action |
|---|---|
| > 50% | Deploy freely, experiment, take risks |
| 20-50% | Slow down, increase review rigor |
| < 20% | Freeze non-critical deploys, focus on reliability |
| Exhausted | Stop all feature work, focus exclusively on reliability |

### Dashboard Methods

| Method | Use For | Signals |
|---|---|---|
| **RED** | Request-driven services (APIs, web) | **R**ate, **E**rrors, **D**uration |
| **USE** | Infrastructure resources (CPU, DB pool) | **U**tilization, **S**aturation, **E**rrors |
| **Golden Signals** | Google SRE approach | Latency, Traffic, Errors, Saturation |

### Health Check Types

| Check | Question | K8s Probe | Failure Action |
|---|---|---|---|
| **Liveness** | Is the process alive? | `livenessProbe` | Kill and restart |
| **Readiness** | Can it serve traffic? | `readinessProbe` | Remove from LB |
| **Startup** | Still initializing? | `startupProbe` | Wait, don't kill |

### Incident Severity

| Severity | User Impact | Response |
|---|---|---|
| **SEV1** | Complete outage or data loss | All hands, war room, exec comms |
| **SEV2** | Major feature broken, >10% users | On-call + team lead |
| **SEV3** | Minor feature broken, <10% users | On-call during business hours |
| **SEV4** | Cosmetic or minimal | Next sprint |

---

## Anti-Patterns

| Anti-Pattern | Why It's Dangerous | Fix |
|---|---|---|
| `console.log` in production | No levels, no structure, no correlation | pino (Node.js) or structlog (Python) with JSON |
| Alert on every 5xx error | Alert fatigue, engineers ignore pages | SLO-based burn rate alerts (multi-window) |
| No correlation IDs | Cannot trace requests across services | Propagate trace_id via OpenTelemetry context |
| Logging PII (emails, IPs, SSNs) | GDPR/CCPA violation, legal liability | Pino `redact` config or structlog processors |
| Metrics with unbounded labels | `user_id` as label = Prometheus OOM | Only low-cardinality labels (method, status, path) |
| Dashboard with 50+ panels | Information overload, nobody reads it | Three-level hierarchy: overview > service > component |
| SLO of 100% | Impossible, stifles deployments, zero budget | 99.9% = three nines (43 min/month). Be realistic |
| Alerting on causes, not symptoms | "CPU at 80%" misses novel failures | Alert on latency, error rate, availability |
| No runbook linked to alert | Engineer paged at 3 AM with no guidance | Every alert has a runbook URL in annotations |
| No post-mortem after incidents | Same incidents repeat, no learning | Blameless post-mortem within 48 hours |
| Health check always returns 200 | Hides dependency failures | Check actual dependencies (DB, cache, APIs) |
| Sampling 100% of traces | Huge storage cost, slow queries | Sample 1-10% normal, 100% errors and slow requests |
| Vendor-locked instrumentation | Expensive migration when switching | Use OpenTelemetry for vendor-neutral instrumentation |
| Metrics endpoint without auth | Exposes internal system details | Serve /metrics on internal port or behind auth |
| Not flushing telemetry on shutdown | Last minutes of data lost | Call `sdk.shutdown()` on SIGTERM before exit |
| Ignoring metric cardinality | 10M series = unusable Prometheus | Audit labels, set limits, use exemplars |

---

## Progressive Disclosure Map

| Topic | Reference | When to read |
|---|---|---|
| OTel SDK setup (Node.js + Python), auto-instrumentation, manual spans, context propagation, Collector config, Docker stack | [references/otel-instrumentation.md](references/otel-instrumentation.md) | Setting up OpenTelemetry, configuring the Collector, or running a local observability stack |
| pino (Node.js), structlog (Python), trace correlation, transports, log levels | [references/structured-logging.md](references/structured-logging.md) | Implementing structured logging or integrating logs with traces |
| Metric types, naming conventions, prom-client, prometheus_client, PromQL queries and pitfalls | [references/metrics-prometheus.md](references/metrics-prometheus.md) | Defining custom metrics, writing PromQL, or setting up Prometheus |
| SLI types, SLO examples, error budgets, multi-burn-rate alerting, severity levels, Alertmanager config | [references/slos-alerting.md](references/slos-alerting.md) | Defining SLOs, configuring alerts, or setting up error budget policies |
| Liveness/readiness/startup probes, K8s config, RED/USE/Golden Signals, dashboard hierarchy, Grafana JSON | [references/health-checks-dashboards.md](references/health-checks-dashboards.md) | Implementing health checks, designing dashboards, or configuring K8s probes |
| Incident severity, response workflow, IC responsibilities, status page templates, post-mortem template | [references/incident-response.md](references/incident-response.md) | Setting up incident response processes or running a post-mortem |
| Sentry setup (Node.js + Python), source maps, sensitive data scrubbing, user context | [references/error-tracking.md](references/error-tracking.md) | Integrating Sentry or configuring error tracking |

---

## Checklist

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
- [ ] Dashboard hierarchy: overview > service > component

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
