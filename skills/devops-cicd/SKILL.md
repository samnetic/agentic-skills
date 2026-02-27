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

## GitHub Actions — Workflow Patterns

### CI Pipeline (Build + Test + Scan)

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
  cancel-in-progress: true         # Cancel stale runs on same branch

permissions:
  contents: read                    # Least privilege

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 22
          cache: npm
      - run: npm ci
      - run: npm run lint
      - run: npm run typecheck

  test:
    runs-on: ubuntu-latest
    needs: lint
    services:
      postgres:
        image: postgres:17-alpine
        env:
          POSTGRES_PASSWORD: test
          POSTGRES_DB: test
        ports: ['5432:5432']
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 22
          cache: npm
      - run: npm ci
      - run: npm test -- --coverage
        env:
          DATABASE_URL: postgresql://postgres:test@localhost:5432/test
      - uses: actions/upload-artifact@v4
        if: always()
        with:
          name: coverage
          path: coverage/

  security:
    runs-on: ubuntu-latest
    permissions:
      security-events: write
    steps:
      - uses: actions/checkout@v4
      - run: npm audit --audit-level=high
      - uses: github/codeql-action/init@v3
        with:
          languages: javascript-typescript
      - uses: github/codeql-action/analyze@v3
      - name: Scan for secrets
        uses: gitleaks/gitleaks-action@v2
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}

  build:
    runs-on: ubuntu-latest
    needs: [test, security]
    permissions:
      packages: write
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
          tags: |
            ghcr.io/${{ github.repository }}:${{ github.sha }}
            ghcr.io/${{ github.repository }}:latest
          cache-from: type=gha
          cache-to: type=gha,mode=max
```

### CD Pipeline (Deploy)

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
  cancel-in-progress: false        # Never cancel a running deploy

jobs:
  deploy:
    if: ${{ github.event.workflow_run.conclusion == 'success' }}
    runs-on: ubuntu-latest
    environment: production         # Requires approval + secrets
    steps:
      - uses: actions/checkout@v4
      - name: Deploy to server
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

      - name: Notify on failure
        if: failure()
        uses: slackapi/slack-github-action@v2
        with:
          webhook: ${{ secrets.SLACK_WEBHOOK }}
          webhook-type: incoming-webhook
          payload: |
            {"text": "Deploy failed: ${{ github.server_url }}/${{ github.repository }}/actions/runs/${{ github.run_id }}"}
```

### Release Automation

```yaml
# .github/workflows/release.yml
name: Release

on:
  push:
    branches: [main]

permissions:
  contents: write
  pull-requests: write

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - uses: actions/setup-node@v4
        with:
          node-version: 22
          cache: npm
      - run: npm ci
      - name: Create release
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        run: npx semantic-release
```

---

## GitHub Actions Best Practices

| Practice | Why |
|---|---|
| Pin action versions with SHA | `@v4` can be force-pushed. `@<full-sha>` is immutable. Use Dependabot to update |
| Lint workflows with `actionlint` + `zizmor` | Catch misconfigs, injection risks, unpinned actions before merge |
| Use `permissions` block | Least privilege — don't give write-all |
| `concurrency` groups | Prevent parallel deploys, cancel stale CI runs |
| `environment` for production | Require manual approval for deploys |
| Cache dependencies | `actions/cache` or `setup-node` cache — speeds up CI |
| `if: always()` for reporting | Upload artifacts and notify even on failure |
| Matrix builds for multi-version | Test on Node 20 + 22, multiple OSes |
| `timeout-minutes` on jobs | Default 6h is too long. Set 10-15 min |
| Reusable workflows | `.github/workflows/reusable-*.yml` for shared logic |
| Repository secrets ONLY | Never hardcode tokens. Use OIDC for cloud providers |

### Caching Strategy

```yaml
# Node.js — cache node_modules
- uses: actions/setup-node@v4
  with:
    node-version: 22
    cache: npm                     # Caches ~/.npm

# Docker — cache layers
- uses: docker/build-push-action@v6
  with:
    cache-from: type=gha
    cache-to: type=gha,mode=max

# Python (uv) — cache uv directory
- uses: actions/setup-python@v5
  with:
    python-version: '3.13'
- uses: astral-sh/setup-uv@v5
  with:
    enable-cache: true                 # Caches ~/.cache/uv

# Rust — cache cargo registry + build
- uses: actions/cache@v4
  with:
    path: |
      ~/.cargo/registry
      ~/.cargo/git
      target/
    key: ${{ runner.os }}-cargo-${{ hashFiles('**/Cargo.lock') }}

# Custom cache
- uses: actions/cache@v4
  with:
    path: |
      ~/.cache/prisma
      node_modules/.cache
    key: ${{ runner.os }}-build-${{ hashFiles('**/package-lock.json') }}
    restore-keys: |
      ${{ runner.os }}-build-
```

---

## Reusable Workflows

Reusable workflows let you define a workflow once and call it from multiple other workflows. This eliminates duplication across repos and teams.

```yaml
# .github/workflows/reusable-deploy.yml
name: Deploy
on:
  workflow_call:
    inputs:
      environment:
        required: true
        type: string
    secrets:
      deploy_key:
        required: true

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: ${{ inputs.environment }}
    steps:
      - uses: actions/checkout@v4
      - run: ./deploy.sh
        env:
          DEPLOY_KEY: ${{ secrets.deploy_key }}
```

```yaml
# .github/workflows/deploy-staging.yml — caller workflow
name: Deploy Staging
on:
  push:
    branches: [main]

jobs:
  deploy:
    uses: ./.github/workflows/reusable-deploy.yml
    with:
      environment: staging
    secrets: inherit                    # Pass ALL org/repo secrets to reusable workflow

# .github/workflows/deploy-production.yml — another caller
name: Deploy Production
on:
  workflow_dispatch:

jobs:
  deploy:
    uses: ./.github/workflows/reusable-deploy.yml
    with:
      environment: production
    secrets: inherit                    # Simpler than listing each secret individually
```

**Reusable workflow rules:**
- Defined with `on: workflow_call` trigger
- Called with `uses:` at the job level (not step level)
- Can accept `inputs` (typed) and `secrets`
- Use `secrets: inherit` to pass all caller secrets (avoids listing each one)
- Can live in the same repo (`./.github/workflows/...`) or another repo (`org/repo/.github/workflows/...@main`)
- Caller inherits the reusable workflow's `permissions` unless explicitly overridden
- Nesting allowed up to 4 levels deep

---

## Matrix Strategy

Matrix builds run the same job across multiple configurations in parallel — different Node versions, operating systems, or any custom dimension.

```yaml
jobs:
  test:
    runs-on: ${{ matrix.os }}
    strategy:
      fail-fast: false              # Don't cancel other jobs if one fails
      matrix:
        node: [20, 22]
        os: [ubuntu-latest, macos-latest]
        exclude:
          - node: 20
            os: macos-latest        # Skip this combination
        include:
          - node: 22
            os: ubuntu-latest
            coverage: true          # Add extra variable for one combo
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: ${{ matrix.node }}
          cache: npm
      - run: npm ci
      - run: npm test
      - if: ${{ matrix.coverage }}
        run: npm test -- --coverage
```

**Matrix tips:**
- `fail-fast: false` — let all combinations finish so you see all failures at once
- `exclude` — skip specific combinations that don't make sense
- `include` — add extra variables or one-off combinations
- Use `matrix` for Node versions, OS, database versions, Python versions, etc.
- Keep matrix small — 4-6 combinations. More than that wastes CI minutes

---

## Environment Promotion Strategy

```
Feature Branch -> PR -> main -> staging -> production

PR:         Lint + Test + Security Scan (automated)
main:       Build image -> Push to registry -> Deploy to staging (automated)
staging:    Smoke tests -> Integration tests (automated)
production: Manual approval -> Deploy -> Health check -> Monitor (manual gate)
```

### Rollback Strategy

```bash
# Docker Compose — instant rollback to previous image
docker compose pull                    # Pull new images
docker compose up -d                   # Deploy new version

# If health check fails:
docker compose down
docker compose -f compose.yaml up -d   # Previous images still cached

# Image-based rollback (always possible)
TAG=v1.2.3 docker compose up -d       # Deploy specific version via env var
```

---

## Deployment Strategies

### Strategy Decision Tree

```
Traffic control available (load balancer, reverse proxy)?
├─ YES → Blue-green or canary
│   ├─ Need instant rollback, can afford 2x capacity? → Blue-green
│   └─ Want gradual rollout, minimize blast radius?   → Canary
└─ NO  → Rolling update (default for Compose / K8s)
```

### Rolling Update (Default for Most Setups)

```yaml
# compose.yaml — with docker-rollout plugin (zero-downtime)
# Install: docker plugin install ghcr.io/wowu/docker-rollout
services:
  app:
    image: myapp:${TAG:-latest}
    deploy:
      replicas: 2
      update_config:
        parallelism: 1           # Update one container at a time
        delay: 10s               # Wait between updates
        order: start-first       # Start new before stopping old
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 10s
      retries: 3
```

```bash
# Deploy with zero downtime
TAG=v1.2.3 docker rollout app     # Rolls one container at a time
```

### Blue-Green Deployment

```bash
#!/usr/bin/env bash
# blue-green-deploy.sh — swap between blue/green stacks
set -euo pipefail

CURRENT=$(docker compose -f compose.yaml ps --format json | jq -r '.[0].Name' | grep -o 'blue\|green')
NEXT=$([[ "$CURRENT" == "blue" ]] && echo "green" || echo "blue")

echo "Current: $CURRENT → Deploying: $NEXT"

# Start new stack
TAG="$1" docker compose -f "compose.${NEXT}.yaml" up -d --wait

# Health check new stack
for i in {1..10}; do
  if curl -sf "http://localhost:${NEXT_PORT}/health" > /dev/null; then
    echo "Health check passed"
    break
  fi
  [[ $i -eq 10 ]] && { echo "Health check failed"; docker compose -f "compose.${NEXT}.yaml" down; exit 1; }
  sleep 3
done

# Switch traffic (update reverse proxy upstream)
sed -i "s/${CURRENT}/${NEXT}/g" /etc/caddy/Caddyfile && caddy reload

# Stop old stack after drain period
sleep 30
docker compose -f "compose.${CURRENT}.yaml" down
echo "Deployed $NEXT successfully"
```

### Canary Deployment

```yaml
# Caddy / Traefik weighted routing for canary
# Route 5% of traffic to canary, 95% to stable
services:
  app-stable:
    image: myapp:v1.2.3
    deploy:
      replicas: 4
    labels:
      - "traefik.http.services.app.loadbalancer.server.weight=95"

  app-canary:
    image: myapp:v1.3.0-rc.1
    deploy:
      replicas: 1
    labels:
      - "traefik.http.services.app.loadbalancer.server.weight=5"
```

```bash
# Canary promotion: if error rate is OK after 30 min, scale up
# Monitor canary → if healthy: update stable image, remove canary
# If error rate spikes: kill canary immediately
```

---

## Terraform CI/CD Workflow

```yaml
# .github/workflows/terraform.yml — plan on PR, apply on merge
name: Terraform

on:
  pull_request:
    paths: ['terraform/**']
  push:
    branches: [main]
    paths: ['terraform/**']

permissions:
  id-token: write       # OIDC
  contents: read
  pull-requests: write   # Post plan as PR comment

env:
  TF_DIR: terraform/environments/production

jobs:
  plan:
    if: github.event_name == 'pull_request'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ vars.TF_ROLE_ARN }}
          aws-region: us-east-1
      - uses: hashicorp/setup-terraform@v3
      - run: terraform -chdir=$TF_DIR init -input=false
      - run: terraform -chdir=$TF_DIR plan -input=false -out=tfplan
      - run: terraform -chdir=$TF_DIR show -no-color tfplan > plan.txt
      - uses: actions/github-script@v7
        with:
          script: |
            const fs = require('fs');
            const plan = fs.readFileSync('plan.txt', 'utf8');
            const body = `#### Terraform Plan\n\`\`\`\n${plan.slice(0, 60000)}\n\`\`\``;
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body,
            });

  apply:
    if: github.event_name == 'push' && github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    environment: production              # Requires approval
    steps:
      - uses: actions/checkout@v4
      - uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ vars.TF_ROLE_ARN }}
          aws-region: us-east-1
      - uses: hashicorp/setup-terraform@v3
      - run: terraform -chdir=$TF_DIR init -input=false
      - run: terraform -chdir=$TF_DIR apply -input=false -auto-approve
```

**Terraform CI rules:**
- Plan on every PR (post output as comment for review)
- Apply only on merge to main, behind an environment gate
- Use OIDC for cloud auth (no static keys)
- Lock state with DynamoDB/GCS to prevent concurrent applies
- Never `auto-approve` without an environment protection rule

---

## Monitoring & Observability

### The Three Pillars

| Pillar | Tool | What It Answers |
|---|---|---|
| **Logs** | Loki + Grafana | What happened? (events, errors, audit) |
| **Metrics** | Prometheus + Grafana | How is it performing? (latency, throughput, errors) |
| **Traces** | Jaeger / Tempo | Why is this request slow? (distributed path) |

### Key Metrics to Monitor (RED + USE)

**RED Method** (request-driven services):
- **R**ate: requests per second
- **E**rrors: error rate (4xx, 5xx)
- **D**uration: latency (P50, P95, P99)

**USE Method** (resources):
- **U**tilization: CPU %, memory %, disk %
- **S**aturation: queue depth, thread pool exhaustion
- **E**rrors: hardware errors, connection refused

### SLO/SLI Definitions

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

## Infrastructure as Code (Terraform Essentials)

```hcl
# Minimal structure
terraform/
├── environments/
│   ├── production/
│   │   ├── main.tf
│   │   └── terraform.tfvars
│   └── staging/
│       ├── main.tf
│       └── terraform.tfvars
├── modules/
│   ├── networking/
│   └── compute/
└── versions.tf

# State management — remote backend
terraform {
  backend "s3" {
    bucket         = "my-terraform-state"
    key            = "production/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"  # State locking
    encrypt        = true
  }
}
```

---

## GitHub Actions — Advanced Features

### ARM Runners and Larger Runners

```yaml
jobs:
  build-arm:
    runs-on: ubuntu-24.04-arm          # Free ARM64 runner for public repos
    steps:
      - uses: actions/checkout@v4
      - run: uname -m                  # aarch64

  build-fast:
    runs-on: ubuntu-latest-16-cores    # Larger runner (org/enterprise only)
    steps:
      - uses: actions/checkout@v4
      - run: npm ci && npm run build   # Much faster builds
```

**Available ARM runners:** `ubuntu-24.04-arm`, `ubuntu-22.04-arm`, `windows-11-arm`
**Larger runners** (paid, org/enterprise): 4/8/16/32/64-core Linux, Windows, macOS. Use for heavy builds, Docker builds, monorepo CI.

### Composite Actions (Reusable Steps)

```yaml
# .github/actions/setup-project/action.yml
name: Setup Project
description: Install dependencies and set up the project
inputs:
  node-version:
    description: Node.js version
    default: '22'
outputs:
  cache-hit:
    description: Whether the cache was hit
    value: ${{ steps.cache.outputs.cache-hit }}

runs:
  using: composite
  steps:
    - uses: actions/setup-node@v4
      with:
        node-version: ${{ inputs.node-version }}
        cache: npm
    - run: npm ci
      shell: bash
    - run: npx prisma generate
      shell: bash

# Usage in workflow:
# - uses: ./.github/actions/setup-project
#   with:
#     node-version: 22
```

**Composite action rules:**
- Must specify `shell` on every `run` step
- Can reference other actions with `uses`
- Can define `outputs` to pass data back to the caller
- Keep in `.github/actions/<name>/action.yml`
- Prefer composite actions over reusable workflows for shared step sequences
- Can be published to the marketplace or shared across repos

### workflow_dispatch with Typed Inputs

```yaml
on:
  workflow_dispatch:
    inputs:
      environment:
        description: Target environment
        required: true
        type: choice
        options: [staging, production]
      version:
        description: Version to deploy (e.g. v1.2.3)
        required: true
        type: string
      dry-run:
        description: Simulate deploy without applying
        type: boolean
        default: false

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: ${{ inputs.environment }}
    steps:
      - run: echo "Deploying ${{ inputs.version }} to ${{ inputs.environment }}"
      - if: ${{ !inputs.dry-run }}
        run: ./deploy.sh --version ${{ inputs.version }}
```

### Required Workflows (Organization-Level)

Required workflows enforce org-wide policies (security scans, compliance checks) that run automatically on every repo's PRs. Configure via **Organization Settings > Actions > Required workflows**. Repos cannot skip or override them.

### OIDC for Cloud Authentication (No Static Secrets)

```yaml
# AWS — no more AWS_ACCESS_KEY_ID/AWS_SECRET_ACCESS_KEY
jobs:
  deploy:
    runs-on: ubuntu-latest
    permissions:
      id-token: write                  # Required for OIDC
      contents: read
    steps:
      - uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::123456789012:role/GitHubActionsRole
          aws-region: us-east-1
          # No static secrets needed — uses short-lived OIDC tokens

      - run: aws s3 ls                # Authenticated via OIDC

# GCP — same pattern
      - uses: google-github-actions/auth@v2
        with:
          workload_identity_provider: projects/123/locations/global/workloadIdentityPools/github/providers/repo
          service_account: deploy@project.iam.gserviceaccount.com

# Azure
      - uses: azure/login@v2
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID }}
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
```

**OIDC benefits:** No static secrets to rotate, short-lived tokens, scoped to repo/branch/environment, audit trail in cloud provider.

### GitHub Environments — Deployment Protection

```yaml
jobs:
  deploy-staging:
    runs-on: ubuntu-latest
    environment: staging               # Auto-deploys (no protection rules)
    steps:
      - run: ./deploy.sh staging

  deploy-production:
    runs-on: ubuntu-latest
    needs: deploy-staging
    environment:
      name: production
      url: https://app.example.com
    # Protection rules (configured in repo settings):
    # - Required reviewers (1-6 people must approve)
    # - Wait timer (e.g., 15 minutes delay)
    # - Branch restrictions (only main can deploy)
    # - Custom deployment protection rules (webhook-based)
    steps:
      - run: ./deploy.sh production
```

### Artifact Attestations and Build Provenance

```yaml
# Generate SLSA provenance for build artifacts
jobs:
  build:
    runs-on: ubuntu-latest
    permissions:
      id-token: write
      contents: read
      attestations: write
      packages: write
    steps:
      - uses: actions/checkout@v4
      - run: npm ci && npm run build

      # Attest a binary/archive
      - uses: actions/attest-build-provenance@v2
        with:
          subject-path: dist/app.tar.gz

      # Attest a container image
      - uses: actions/attest-build-provenance@v2
        with:
          subject-name: ghcr.io/${{ github.repository }}
          subject-digest: ${{ steps.push.outputs.digest }}
          push-to-registry: true

# Verify attestation locally:
# gh attestation verify app.tar.gz --repo owner/repo
```

### Dependabot Grouped Updates

```yaml
# .github/dependabot.yml
version: 2
updates:
  - package-ecosystem: npm
    directory: /
    schedule:
      interval: weekly
    groups:
      # Group all minor/patch updates into one PR
      production-dependencies:
        patterns: ["*"]
        update-types: [minor, patch]
      # Major updates get individual PRs for careful review
    open-pull-requests-limit: 10
    reviewers:
      - team/platform
    labels:
      - dependencies
```

---

## Self-Hosted Runners

When GitHub-hosted runners are not enough (cost, performance, network access, special hardware), use self-hosted runners.

### When to Use Self-Hosted Runners

| Use Case | Why |
|---|---|
| **Private network access** | CI needs to reach internal databases, APIs, or registries |
| **GPU/specialized hardware** | ML training, hardware-in-the-loop testing |
| **Cost reduction** | High CI volume makes GitHub-hosted runners expensive |
| **Large builds** | Need more CPU/RAM/disk than largest GitHub-hosted runner |
| **Compliance** | Data must stay within your infrastructure |

### Best Practices

```yaml
# Use labels to target specific runner capabilities
jobs:
  build:
    runs-on: [self-hosted, linux, x64, gpu]  # Match runner labels
    timeout-minutes: 30                        # Always set timeout
    steps:
      - uses: actions/checkout@v4
      - run: ./build.sh
```

**Security hardening for self-hosted runners:**
- **Never use self-hosted runners on public repos** — any fork can run code on your runner
- Run runners in **ephemeral mode** (`--ephemeral`) — fresh environment per job
- Use **container-based isolation** (run jobs inside Docker or Kubernetes pods)
- Keep runners **patched and updated** — automate OS and runner updates
- Use **runner groups** to restrict which repos can use which runners
- Monitor runner activity and set **resource limits** (CPU, memory, disk)
- Prefer **Actions Runner Controller (ARC)** for Kubernetes-based auto-scaling

### Actions Runner Controller (ARC) — Kubernetes Auto-Scaling

```yaml
# Kubernetes-based auto-scaling runners
# Install ARC with Helm:
# helm install arc \
#   --namespace arc-systems \
#   oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set-controller

# Runner scale set configuration
apiVersion: actions.github.com/v1alpha1
kind: AutoscalingRunnerSet
metadata:
  name: ci-runners
spec:
  githubConfigUrl: "https://github.com/org/repo"
  minRunners: 1
  maxRunners: 10
  template:
    spec:
      containers:
        - name: runner
          image: ghcr.io/actions/actions-runner:latest
          resources:
            requests:
              cpu: "2"
              memory: "4Gi"
            limits:
              cpu: "4"
              memory: "8Gi"
```

---

## Dagger — Portable CI/CD Pipelines

Dagger lets you write CI/CD pipelines as code (TypeScript, Go, Python) that run identically locally and in any CI system. No more YAML debugging in CI.

```typescript
// dagger/src/index.ts — Dagger module using the SDK
import { dag, Container, Directory, object, func } from "@dagger.io/dagger";

@object()
class Ci {
  @func()
  async build(source: Directory): Promise<Container> {
    // Build environment with caching
    const deps = dag
      .container()
      .from("node:22-slim")
      .withDirectory("/src", source)
      .withMountedCache("/root/.npm", dag.cacheVolume("npm"))
      .withWorkdir("/src")
      .withExec(["npm", "ci"]);

    // Build production
    return deps.withExec(["npm", "run", "build"]);
  }

  @func()
  async test(source: Directory): Promise<string> {
    const deps = dag
      .container()
      .from("node:22-slim")
      .withDirectory("/src", source)
      .withMountedCache("/root/.npm", dag.cacheVolume("npm"))
      .withWorkdir("/src")
      .withExec(["npm", "ci"]);

    return deps
      .withExec(["npm", "run", "test"])
      .stdout();
  }

  @func()
  async publishImage(source: Directory, tag: string): Promise<string> {
    const build = await this.build(source);
    return build
      .withEntrypoint(["node", "dist/server.js"])
      .publish(`ghcr.io/myorg/myapp:${tag}`);
  }
}
```

```yaml
# Use in any CI — GitHub Actions, GitLab, Jenkins, etc.
# .github/workflows/ci.yml
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: dagger/dagger-for-github@v7
        with:
          verb: call
          args: build --source .
```

**Why Dagger:**
- Test CI pipeline locally before pushing (`dagger call test --source .`)
- Automatic caching with content-addressed cache volumes
- No vendor lock-in — same pipeline runs in GitHub, GitLab, Jenkins, CircleCI
- Type-safe pipelines (TypeScript, Go, Python SDKs)

---

## OpenTofu — BSL-Free Terraform Alternative

OpenTofu is a community fork of Terraform, created after HashiCorp switched to the Business Source License (BSL). It is a drop-in replacement maintained by the Linux Foundation.

```hcl
# Switch from Terraform to OpenTofu — just change the binary
# terraform init  -> tofu init
# terraform plan  -> tofu plan
# terraform apply -> tofu apply

# Same HCL syntax, same providers, same state format
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# OpenTofu-specific features:
# - Client-side state encryption (built-in, no wrapper needed)
# - Early variable/local evaluation
# - Provider-defined functions
```

| | Terraform | OpenTofu |
|---|---|---|
| License | BSL 1.1 (source-available) | MPL 2.0 (true open source) |
| Maintained by | HashiCorp/IBM | Linux Foundation |
| State encryption | Enterprise only | Built-in |
| Provider compatibility | Full | Full (same registry) |
| Migration | N/A | Drop-in replacement |

**When to choose OpenTofu:** If you need true open-source licensing, client-side state encryption without paying for Enterprise, or want community governance.

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

## Cost Optimization for CI

| Strategy | Savings | How |
|---|---|---|
| **Aggressive caching** | 30-60% time | Cache npm, Docker layers, Prisma, Turborepo |
| **Skip unchanged** | 20-50% runs | `paths` filter, `dorny/paths-filter` for conditional jobs |
| **Cancel stale runs** | 10-30% minutes | `concurrency: cancel-in-progress: true` |
| **Spot/preemptible runners** | 60-90% cost | Self-hosted with AWS Spot, GCP Preemptible |
| **ARM runners** | 37% cheaper | `ubuntu-24.04-arm` — free for public repos, cheaper for private |
| **Smaller images** | 20-40% time | Alpine/distroless base images, multi-stage builds |
| **Parallelize tests** | 30-50% time | Vitest `--pool=threads`, Playwright `--shard`, matrix builds |
| **Larger runners** | Variable | Fewer minutes but higher per-minute cost — benchmark first |

```yaml
# Skip CI for docs-only changes
on:
  push:
    branches: [main]
    paths-ignore:
      - 'docs/**'
      - '*.md'
      - '.vscode/**'

# Conditional jobs based on changed files
jobs:
  changes:
    runs-on: ubuntu-latest
    outputs:
      backend: ${{ steps.filter.outputs.backend }}
      frontend: ${{ steps.filter.outputs.frontend }}
    steps:
      - uses: dorny/paths-filter@v3
        id: filter
        with:
          filters: |
            backend:
              - 'src/api/**'
              - 'src/lib/**'
            frontend:
              - 'src/app/**'
              - 'src/components/**'

  test-backend:
    needs: changes
    if: ${{ needs.changes.outputs.backend == 'true' }}
    runs-on: ubuntu-latest
    steps:
      - run: npm run test:api
```

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

---

## AI Model Profiles for CI/CD

When using AI agents in your CI/CD pipeline (code review, test generation, PR descriptions), use model profiles to balance quality, speed, and cost:

### Model Profile Strategy

| Profile | Model Tier | Use Case | Cost |
|---|---|---|---|
| **Quality** | Opus/GPT-4o | Architecture review, security audit, complex code review | $$$ |
| **Balanced** | Sonnet/GPT-4o-mini | Standard PR review, test generation, documentation | $$ |
| **Budget** | Haiku/GPT-4o-mini | Linting fixes, formatting, simple code generation | $ |

### CI Pipeline Integration

```yaml
# .github/workflows/ai-review.yml
jobs:
  quick-check:
    # Budget model for fast feedback
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: AI lint check
        env:
          MODEL: haiku  # fast, cheap
        run: npx ai-review --model $MODEL --check lint

  full-review:
    # Quality model for thorough review
    if: github.event.pull_request.base.ref == 'main'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: AI code review
        env:
          MODEL: opus  # thorough, expensive
        run: npx ai-review --model $MODEL --check security,architecture
```

**Key principle:** Use the cheapest model that produces acceptable results for each task. Reserve expensive models for high-stakes reviews (security, architecture, production deploys).

---

## Wave-Based Parallel CI Execution

Instead of running all CI checks sequentially, organize them into waves. Each wave runs checks in parallel. Later waves only run if earlier waves pass.

### Wave Architecture

```
Wave 1 (Fast Feedback — <1 min):
  ├── Lint (ESLint, Prettier)
  ├── Type check (tsc --noEmit)
  └── Schema validation

Wave 2 (Core Tests — <5 min):
  ├── Unit tests
  ├── Build check
  └── Dependency audit

Wave 3 (Integration — <10 min):
  ├── Integration tests
  ├── E2E smoke tests
  └── Security scan (SAST)

Wave 4 (Full Validation — <15 min):
  ├── Full E2E suite
  ├── Performance benchmarks
  ├── Container build + scan
  └── AI code review (quality model)
```

### GitHub Actions Implementation

```yaml
name: CI Waves

on: pull_request

jobs:
  # Wave 1 — Fast feedback
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npm ci && npm run lint

  typecheck:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npm ci && npx tsc --noEmit

  # Wave 2 — Core tests (depends on Wave 1)
  unit-tests:
    needs: [lint, typecheck]
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npm ci && npm test

  build:
    needs: [lint, typecheck]
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npm ci && npm run build

  # Wave 3 — Integration (depends on Wave 2)
  integration:
    needs: [unit-tests, build]
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:17-alpine
        env:
          POSTGRES_PASSWORD: test
        ports: ['5432:5432']
    steps:
      - uses: actions/checkout@v4
      - run: npm ci && npm run test:integration

  # Wave 4 — Full validation (depends on Wave 3)
  e2e:
    needs: [integration]
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npm ci && npx playwright install --with-deps && npm run test:e2e
```

**Benefits:**
- Fast feedback: lint/type errors caught in <1 minute
- Cost savings: expensive checks (E2E, security scan) only run if basic checks pass
- Clear failure isolation: developers know exactly which wave failed

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
| No Dependabot grouped updates | PR noise from individual updates | Group minor/patch updates |
| Feature flags left forever | Dead code, confusion | Set TTL, clean up after full rollout |
| No artifact attestation | Unverifiable supply chain | `actions/attest-build-provenance` |

---

## Checklist: DevOps/CI-CD Review

- [ ] CI pipeline: lint -> test -> security scan -> build (in order)
- [ ] Workflow files linted: `actionlint .github/workflows/` + `zizmor .github/workflows/`
- [ ] Actions pinned to full SHA (not `@v4` tags): `uses: actions/checkout@<sha>`
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
- [ ] OIDC federation for cloud auth (no static AWS/GCP/Azure keys)
- [ ] Artifact attestations for supply chain security
- [ ] Dependabot grouped updates configured (reduce PR noise)
- [ ] OpenTelemetry for vendor-neutral observability
- [ ] Feature flags for decoupling deploy from release
- [ ] Docker Scout or equivalent image scanning in CI
- [ ] Conditional jobs skip unchanged code paths
- [ ] Composite actions for shared step sequences
- [ ] CI organized in waves (fast feedback first, expensive checks last)
- [ ] Each wave depends on the previous wave passing
- [ ] AI model profiles configured (quality/balanced/budget per task)
- [ ] Reusable workflows for shared deploy/build logic
- [ ] Matrix strategy for multi-version/multi-OS testing
- [ ] Self-hosted runners secured (ephemeral, isolated, private repos only)
