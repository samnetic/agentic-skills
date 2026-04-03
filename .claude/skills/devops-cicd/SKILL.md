---
name: devops-cicd
description: >-
  DevOps, CI/CD pipelines, and GitHub Actions/Workflows expertise. Use when setting up
  GitHub Actions workflows, designing CI/CD pipelines, configuring deployment strategies,
  writing workflow files (build/test/deploy), implementing GitOps patterns, setting up
  monitoring and alerting (Prometheus, Grafana), configuring Terraform/OpenTofu for
  infrastructure, implementing blue-green or canary deployments, setting up container
  registries, designing environment promotion strategies, implementing secrets management
  in CI/CD, configuring caching in pipelines, setting up matrix builds, implementing
  release automation (semantic-release, changesets), or designing observability stacks
  (logs, metrics, traces).
  Triggers: DevOps, CI/CD, GitHub Actions, workflow, pipeline, deploy, deployment,
  Terraform, infrastructure as code, IaC, monitoring, Prometheus, Grafana, alerting,
  GitOps, blue-green, canary, container registry, GHCR, semantic-release, changeset,
  observability, SLO, SLI, incident response, rollback, GitHub workflow.
license: MIT
metadata:
  author: samnetic
  version: "1.0"
---

# DevOps & CI/CD Skill

Automate everything. Deploy with confidence. Monitor everything. Recover fast.
Pipelines should be fast, reliable, and secure.

---

## Core Principles

| Principle | Meaning |
|---|---|
| **Automate relentlessly** | If you do it twice, automate it |
| **Infrastructure as code** | Everything versioned, reviewed, reproducible |
| **Shift left** | Test, scan, and validate as early as possible in the pipeline |
| **Immutable artifacts** | Build once, deploy same artifact everywhere |
| **Observability over monitoring** | Logs + metrics + traces = understanding system behavior |
| **Fast feedback loops** | CI should finish in <10 minutes |

---

## Workflow: Setting Up a CI/CD Pipeline

Follow these steps in order when building or reviewing a CI/CD pipeline.

### 1. Structure the CI Pipeline

Organize CI into waves for fast feedback. Each wave gates the next.

```
Wave 1 (<1 min):  Lint + Type check + Schema validation
Wave 2 (<5 min):  Unit tests + Build + Dependency audit
Wave 3 (<10 min): Integration tests + E2E smoke + SAST
Wave 4 (<15 min): Full E2E + Perf benchmarks + Container build
```

**Minimal CI workflow:**

```yaml
# .github/workflows/ci.yml
name: CI
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

concurrency:
  group: ci-${{ github.ref }}
  cancel-in-progress: true

permissions:
  contents: read

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: 22, cache: npm }
      - run: npm ci
      - run: npm run lint
      - run: npm run typecheck

  test:
    runs-on: ubuntu-latest
    needs: lint
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: 22, cache: npm }
      - run: npm ci
      - run: npm test -- --coverage

  build:
    runs-on: ubuntu-latest
    needs: test
    permissions: { packages: write }
    steps:
      - uses: actions/checkout@v4
      - uses: docker/setup-buildx-action@v3
      - uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      - uses: docker/build-push-action@v6
        with:
          context: .
          push: ${{ github.ref == 'refs/heads/main' }}
          tags: ghcr.io/${{ github.repository }}:${{ github.sha }}
          cache-from: type=gha
          cache-to: type=gha,mode=max
```

### 2. Configure the CD Pipeline

```yaml
# .github/workflows/deploy.yml
name: Deploy
on:
  workflow_run:
    workflows: [CI]
    types: [completed]
    branches: [main]

concurrency:
  group: deploy-production
  cancel-in-progress: false          # Never cancel a running deploy

jobs:
  deploy:
    if: ${{ github.event.workflow_run.conclusion == 'success' }}
    runs-on: ubuntu-latest
    environment: production           # Requires manual approval
    steps:
      - uses: actions/checkout@v4
      - name: Deploy and health check
        env:
          SSH_KEY: ${{ secrets.DEPLOY_SSH_KEY }}
          DEPLOY_HOST: ${{ secrets.DEPLOY_HOST }}
        run: |
          mkdir -p ~/.ssh
          echo "$SSH_KEY" > ~/.ssh/deploy_key
          chmod 600 ~/.ssh/deploy_key
          ssh -o StrictHostKeyChecking=accept-new -i ~/.ssh/deploy_key deploy@$DEPLOY_HOST << 'DEPLOY'
            cd /opt/app
            docker compose pull
            docker compose up -d --remove-orphans
            docker compose exec -T app node -e "fetch('http://localhost:3000/health').then(r => { if (!r.ok) throw new Error('Health check failed'); })"
          DEPLOY
```

### 3. Choose a Deployment Strategy

Use the decision tree to select the right strategy for your infrastructure.

### 4. Set Up Environment Promotion

```
Feature Branch -> PR -> main -> staging -> production

PR:         Lint + Test + Security Scan (automated)
main:       Build image -> Push to registry -> Deploy to staging (automated)
staging:    Smoke tests -> Integration tests (automated)
production: Manual approval -> Deploy -> Health check -> Monitor (manual gate)
```

### 5. Configure Monitoring

Instrument with OpenTelemetry, define SLOs, alert on SLO violations (not raw metrics). See the observability reference for full setup.

### 6. Set Up Release Automation

```yaml
# .github/workflows/release.yml
name: Release
on:
  push:
    branches: [main]
permissions: { contents: write, pull-requests: write }
jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with: { fetch-depth: 0 }
      - uses: actions/setup-node@v4
        with: { node-version: 22, cache: npm }
      - run: npm ci
      - run: npx semantic-release
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

---

## Decision Tree: Deployment Strategy

```
Traffic control available (load balancer, reverse proxy)?
├─ YES → Blue-green or canary
│   ├─ Need instant rollback, can afford 2x capacity? → Blue-green
│   └─ Want gradual rollout, minimize blast radius?   → Canary
└─ NO  → Rolling update (default for Compose / K8s)

Infrastructure as Code tool?
├─ Open-source licensing required? → OpenTofu
├─ Enterprise features needed?     → Terraform
└─ Portable CI (no YAML lock-in)? → Dagger

Observability backend?
├─ Vendor-neutral, future-proof?          → OpenTelemetry + Grafana stack
├─ Managed, minimal ops?                  → Datadog / New Relic
└─ Already have Prometheus + Grafana?     → Add OTel collector as intake

Self-hosted runners?
├─ Public repo?         → NO (security risk)
├─ Private network/GPU? → YES with ephemeral mode + ARC
└─ Cost reduction?      → YES with spot instances + auto-scaling
```

---

## GitHub Actions Best Practices

| Practice | Why |
|---|---|
| Pin action versions with SHA | `@v4` can be force-pushed; `@<full-sha>` is immutable |
| Lint workflows with `actionlint` + `zizmor` | Catch misconfigs and injection risks before merge |
| Use `permissions` block | Least privilege — don't give write-all |
| `concurrency` groups | Prevent parallel deploys, cancel stale CI runs |
| `environment` for production | Require manual approval for deploys |
| Cache dependencies | `actions/cache` or `setup-node` cache — speeds up CI |
| `timeout-minutes` on jobs | Default 6h is too long; set 10-15 min |
| OIDC for cloud auth | No static AWS/GCP/Azure keys; short-lived tokens |
| Reusable workflows | `.github/workflows/reusable-*.yml` for shared logic |
| Composite actions | Shared step sequences in `.github/actions/<name>/action.yml` |
| `if: always()` for reporting | Upload artifacts and notify even on failure |

---

## Anti-Patterns

| Anti-Pattern | Why It's Dangerous | Fix |
|---|---|---|
| `GITHUB_TOKEN` with full permissions | Over-privileged CI | `permissions` block with least privilege |
| No concurrency control on deploys | Parallel deploys cause corruption | `concurrency` groups |
| Secrets in workflow logs | Exposed in CI output | `add-mask`, audit log output |
| `npm install` in CI | Non-deterministic | `npm ci` |
| No timeout on jobs | Stuck jobs burn minutes | `timeout-minutes: 15` |
| Deploy without health check | Broken deploys go unnoticed | Health check after every deploy |
| No rollback plan | Stuck with broken version | Tag images, keep N-1 available |
| Manual infrastructure changes | Drift, unreproducible | Everything through Terraform/IaC |
| Alert on everything | Alert fatigue, ignore real issues | Alert on SLO violations, not metrics |
| No staging environment | Test in production | Always deploy to staging first |
| Static cloud credentials in CI | Long-lived keys can leak | OIDC federation for AWS/GCP/Azure |
| Vendor-locked observability | Expensive migration, lock-in | OpenTelemetry for vendor-neutral instrumentation |
| Feature flags left forever | Dead code, confusion | Set TTL, clean up after full rollout |
| No artifact attestation | Unverifiable supply chain | `actions/attest-build-provenance` |

---

## Progressive Disclosure Map

| Topic | Reference | When to read |
|---|---|---|
| CI/CD/Release workflow templates | [references/github-actions.md](references/github-actions.md) | Setting up or reviewing GitHub Actions workflows, caching, matrix builds |
| Reusable workflows & composite actions | [references/github-actions.md](references/github-actions.md) | Reducing duplication across repos or teams |
| OIDC, environments, attestations | [references/github-actions.md](references/github-actions.md) | Hardening CI security, supply chain, cloud auth |
| Self-hosted runners & ARC | [references/github-actions.md](references/github-actions.md) | Need private network, GPU, cost reduction, or Kubernetes auto-scaling |
| Blue-green, canary, rolling deploys | [references/deployment-strategies.md](references/deployment-strategies.md) | Choosing or implementing a deployment strategy |
| Terraform/OpenTofu CI/CD & IaC | [references/deployment-strategies.md](references/deployment-strategies.md) | Setting up infrastructure as code with CI integration |
| Environment promotion & rollback | [references/deployment-strategies.md](references/deployment-strategies.md) | Designing promotion flow or rollback procedures |
| Observability (OTel, RED/USE, SLOs) | [references/observability-platform.md](references/observability-platform.md) | Instrumenting services, defining SLOs, setting up monitoring |
| Platform engineering & feature flags | [references/observability-platform.md](references/observability-platform.md) | Building an internal developer platform or decoupling deploy from release |
| CI cost optimization & wave execution | [references/ci-optimization.md](references/ci-optimization.md) | Reducing CI minutes/cost or speeding up feedback loops |
| Dagger portable pipelines | [references/ci-optimization.md](references/ci-optimization.md) | Escaping YAML lock-in, testing pipelines locally |
| AI model profiles in CI | [references/ci-optimization.md](references/ci-optimization.md) | Integrating AI-powered code review or generation in pipelines |

---

## Checklist: DevOps/CI-CD Review

- [ ] CI pipeline: lint -> test -> security scan -> build (in order)
- [ ] Workflow files linted: `actionlint` + `zizmor`
- [ ] Actions pinned to full SHA (not `@v4` tags)
- [ ] `permissions` set to least privilege in workflow
- [ ] `concurrency` groups prevent parallel deploys
- [ ] Dependency caching configured (npm, Docker layers)
- [ ] Security scanning: dependencies + SAST + secrets
- [ ] Docker images tagged with commit SHA (not just `latest`)
- [ ] Production deploy requires manual approval (`environment` gate)
- [ ] Health check runs after every deploy
- [ ] Rollback procedure documented and tested
- [ ] Monitoring covers RED metrics (rate, errors, duration)
- [ ] Alerts based on SLOs, not raw metrics
- [ ] Infrastructure managed as code (Terraform/OpenTofu)
- [ ] Secrets in GitHub Secrets or vault (never in code)
- [ ] OIDC federation for cloud auth (no static keys)
- [ ] Artifact attestations for supply chain security
- [ ] Dependabot grouped updates configured
- [ ] OpenTelemetry for vendor-neutral observability
- [ ] Feature flags for decoupling deploy from release
- [ ] CI organized in waves (fast feedback first)
- [ ] Composite actions / reusable workflows for shared logic
- [ ] Self-hosted runners secured (ephemeral, isolated, private repos only)
