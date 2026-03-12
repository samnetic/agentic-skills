# Observability, Platform Engineering & Feature Flags

## Table of Contents

- [The Three Pillars of Observability](#the-three-pillars-of-observability)
- [Key Metrics — RED + USE Methods](#key-metrics--red--use-methods)
- [SLO/SLI Definitions](#slislo-definitions)
- [OpenTelemetry for Observability](#opentelemetry-for-observability)
- [Docker Scout Integration in CI](#docker-scout-integration-in-ci)
- [Platform Engineering Patterns](#platform-engineering-patterns)
- [Feature Flags Integration](#feature-flags-integration)

---

## The Three Pillars of Observability

| Pillar | Tool | What It Answers |
|---|---|---|
| **Logs** | Loki + Grafana | What happened? (events, errors, audit) |
| **Metrics** | Prometheus + Grafana | How is it performing? (latency, throughput, errors) |
| **Traces** | Jaeger / Tempo | Why is this request slow? (distributed path) |

---

## Key Metrics — RED + USE Methods

**RED Method** (request-driven services):
- **R**ate: requests per second
- **E**rrors: error rate (4xx, 5xx)
- **D**uration: latency (P50, P95, P99)

**USE Method** (resources):
- **U**tilization: CPU %, memory %, disk %
- **S**aturation: queue depth, thread pool exhaustion
- **E**rrors: hardware errors, connection refused

---

## SLI/SLO Definitions

```yaml
# Example SLO document
service: user-api
slos:
  - name: availability
    sli: "Ratio of successful HTTP responses (2xx/3xx) to total requests"
    target: 99.9%            # 8.7 hours downtime per year
    window: 30 days

  - name: latency
    sli: "P95 response time for non-batch endpoints"
    target: 200ms
    window: 30 days

  - name: freshness
    sli: "Time since last successful data sync"
    target: 5 minutes
    window: 30 days
```

---

## OpenTelemetry for Observability

Replace vendor-specific agents (Datadog agent, New Relic agent) with OpenTelemetry (OTel) — a vendor-neutral CNCF standard for traces, metrics, and logs.

```typescript
// instrumentation.ts — auto-instrument Node.js
import { NodeSDK } from '@opentelemetry/sdk-node';
import { OTLPTraceExporter } from '@opentelemetry/exporter-trace-otlp-http';
import { OTLPMetricExporter } from '@opentelemetry/exporter-metrics-otlp-http';
import { getNodeAutoInstrumentations } from '@opentelemetry/auto-instrumentations-node';
import { PeriodicExportingMetricReader } from '@opentelemetry/sdk-metrics';

const sdk = new NodeSDK({
  serviceName: 'user-api',
  traceExporter: new OTLPTraceExporter({
    url: 'http://otel-collector:4318/v1/traces',
  }),
  metricReader: new PeriodicExportingMetricReader({
    exporter: new OTLPMetricExporter({
      url: 'http://otel-collector:4318/v1/metrics',
    }),
  }),
  instrumentations: [getNodeAutoInstrumentations()],
});

sdk.start();
```

```yaml
# docker-compose.yml — OTel Collector + backends
services:
  otel-collector:
    image: otel/opentelemetry-collector-contrib:latest
    ports:
      - "4317:4317"     # gRPC
      - "4318:4318"     # HTTP
    volumes:
      - ./otel-config.yaml:/etc/otel/config.yaml

  # Send to any backend: Grafana Tempo, Jaeger, Datadog, Honeycomb, etc.
  tempo:
    image: grafana/tempo:latest
  prometheus:
    image: prom/prometheus:latest
  grafana:
    image: grafana/grafana:latest
```

**OTel benefits:**
- Vendor-neutral: switch backends without re-instrumenting
- Auto-instrumentation for HTTP, DB, gRPC, messaging
- Single collector handles traces, metrics, and logs
- CNCF graduated project — industry standard

---

## Docker Scout Integration in CI

```yaml
# Scan Docker images for vulnerabilities in CI
jobs:
  scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: docker/scout-action@v1
        with:
          command: cves,recommendations
          image: ghcr.io/${{ github.repository }}:${{ github.sha }}
          sarif-file: scout-results.sarif
          summary: true

      - uses: github/codeql-action/upload-sarif@v3
        with:
          sarif_file: scout-results.sarif
```

---

## Platform Engineering Patterns

Internal Developer Platforms (IDPs) provide self-service infrastructure to development teams.

| Component | Purpose | Tools |
|---|---|---|
| **Service catalog** | Discover and manage services | Backstage, Port, Cortex |
| **Self-service infra** | Provision environments on demand | Crossplane, Terraform modules |
| **Golden paths** | Standardized templates for new services | Backstage templates, cookiecutter |
| **Developer portal** | Single pane for docs, APIs, runbooks | Backstage, Backstage + TechDocs |
| **Score/quality gates** | Enforce standards (tests, docs, security) | Backstage scorecards, Port scorecards |

**Key principles:**
- Pave golden paths, don't build golden cages — teams can deviate when justified
- Self-service over ticket-ops — developers provision what they need without waiting
- Platform as a product — treat internal developers as customers, iterate on UX
- Thin platform layer — compose existing tools, don't build a custom PaaS

---

## Feature Flags Integration

Feature flags decouple deployment from release. Deploy code anytime, enable features when ready.

| Tool | Type | Best For |
|---|---|---|
| **LaunchDarkly** | SaaS | Enterprise, advanced targeting, analytics |
| **Unleash** | Open source / SaaS | Self-hosted, GitOps-friendly |
| **Flipt** | Open source | Lightweight, Git-backed, no external deps |
| **PostHog** | Open source / SaaS | Combined with analytics and A/B testing |
| **Environment variables** | DIY | Simple on/off, small teams |

```typescript
// Feature flag pattern (framework-agnostic)
import { getFeatureFlags } from './flags';

async function handleRequest(req: Request) {
  const flags = await getFeatureFlags(req.user);

  if (flags.isEnabled('new-checkout-flow')) {
    return newCheckoutFlow(req);
  }
  return legacyCheckoutFlow(req);
}

// Flipt example (open source, self-hosted)
import { FliptClient } from '@flipt-io/flipt';

const flipt = new FliptClient({ url: 'http://flipt:8080' });

const enabled = await flipt.evaluation.boolean({
  namespaceKey: 'default',
  flagKey: 'new-checkout-flow',
  entityId: user.id,
  context: { plan: user.plan, region: user.region },
});
```

**Feature flag rules:**
- Flags are temporary — set a TTL and clean up after rollout
- Use percentage rollouts for gradual releases (1% -> 10% -> 50% -> 100%)
- Always have a kill switch for critical features
- Store flag state externally (not in code) for instant changes
- Test both flag states in CI
