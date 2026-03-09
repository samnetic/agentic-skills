# NFR and Fitness Function Catalog

## Common NFRs

| Attribute | Typical Metric | Example Target |
|---|---|---|
| Latency | API P95 | < 250 ms |
| Throughput | Requests/sec | >= 1000 rps |
| Availability | Uptime | >= 99.9% monthly |
| Recovery | RTO/RPO | RTO < 30 min, RPO < 5 min |
| Security | Critical vulns open | 0 in prod |
| Cost | Monthly infrastructure spend | <= budget cap |

## Fitness Function Patterns

- Load test threshold in CI for latency/throughput.
- Static dependency rule for boundary enforcement.
- Observability gate: required dashboards/alerts before release.
- Chaos or failure-injection scenario for critical dependencies.
