# SLOs, SLIs, Error Budgets, and Alerting

## Table of Contents

- [What to Measure (SLI Types)](#what-to-measure-sli-types)
- [SLO Examples](#slo-examples)
- [Error Budget Calculation](#error-budget-calculation)
- [Error Budget Policy](#error-budget-policy)
- [Multi-Window Multi-Burn-Rate Alerting](#multi-window-multi-burn-rate-alerting)
- [Should This Alert Page Someone?](#should-this-alert-page-someone)
- [Severity Levels](#severity-levels)
- [Alert Quality Rules](#alert-quality-rules)
- [Alertmanager Configuration](#alertmanager-configuration)

---

## What to Measure (SLI Types)

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

---

## SLO Examples

| Service | SLI | SLO | Measurement Window |
|---|---|---|---|
| API Gateway | Availability (non-5xx) | 99.9% | 30-day rolling |
| Search API | p99 latency | < 200ms | 30-day rolling |
| Checkout Flow | Availability | 99.95% | 30-day rolling |
| Email Delivery | Delivery within 5 min | 99.5% | 30-day rolling |
| Data Pipeline | Freshness (< 15 min stale) | 99.0% | 7-day rolling |

---

## Error Budget Calculation

```
SLO = 99.9% availability (30-day window)

Total minutes in 30 days: 30 * 24 * 60 = 43,200 minutes
Error budget: 0.1% * 43,200 = 43.2 minutes of downtime allowed

Or in requests:
Total requests in 30 days: 10,000,000
Error budget: 0.1% * 10,000,000 = 10,000 failed requests allowed
```

---

## Error Budget Policy

- Budget remaining > 50%: Deploy freely, experiment, take risks
- Budget remaining 20-50%: Slow down, increase review rigor
- Budget remaining < 20%: Freeze non-critical deploys, focus on reliability
- Budget exhausted: Stop all feature work, focus exclusively on reliability

---

## Multi-Window Multi-Burn-Rate Alerting

Based on the Google SRE approach. Detects when error budget is being consumed too fast.

```yaml
# Prometheus alerting rules — multi-burn-rate alert
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

## Should This Alert Page Someone?

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

## Severity Levels

| Severity | Response Time | Who | Examples |
|---|---|---|---|
| **P1 -- Critical** | Immediate (page) | On-call engineer | Service down, data loss, SLO breached |
| **P2 -- High** | < 1 hour | On-call engineer | Major feature broken, error rate spike |
| **P3 -- Medium** | < 4 hours (business) | Team queue | Degraded performance, non-critical error |
| **P4 -- Low** | Next sprint | Backlog | Warning threshold, optimization needed |

---

## Alert Quality Rules

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

---

## Alertmanager Configuration

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
