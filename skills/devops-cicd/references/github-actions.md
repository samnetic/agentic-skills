# GitHub Actions — Workflows, Best Practices & Advanced Features

## Table of Contents

- [CI Pipeline (Build + Test + Scan)](#ci-pipeline-build--test--scan)
- [CD Pipeline (Deploy)](#cd-pipeline-deploy)
- [Release Automation](#release-automation)
- [Best Practices](#best-practices)
- [Caching Strategy](#caching-strategy)
- [Reusable Workflows](#reusable-workflows)
- [Matrix Strategy](#matrix-strategy)
- [Advanced Features](#advanced-features)
  - [ARM Runners and Larger Runners](#arm-runners-and-larger-runners)
  - [Composite Actions](#composite-actions)
  - [workflow_dispatch with Typed Inputs](#workflow_dispatch-with-typed-inputs)
  - [Required Workflows](#required-workflows)
  - [OIDC for Cloud Authentication](#oidc-for-cloud-authentication)
  - [GitHub Environments — Deployment Protection](#github-environments--deployment-protection)
  - [Artifact Attestations and Build Provenance](#artifact-attestations-and-build-provenance)
  - [Dependabot Grouped Updates](#dependabot-grouped-updates)
- [Self-Hosted Runners](#self-hosted-runners)
  - [When to Use Self-Hosted Runners](#when-to-use-self-hosted-runners)
  - [Security Hardening](#security-hardening)
  - [Actions Runner Controller (ARC)](#actions-runner-controller-arc--kubernetes-auto-scaling)

---

## CI Pipeline (Build + Test + Scan)

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

---

## CD Pipeline (Deploy)

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

---

## Release Automation

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

## Best Practices

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

---

## Caching Strategy

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

## Advanced Features

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

### Composite Actions

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

### Required Workflows

Required workflows enforce org-wide policies (security scans, compliance checks) that run automatically on every repo's PRs. Configure via **Organization Settings > Actions > Required workflows**. Repos cannot skip or override them.

### OIDC for Cloud Authentication

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

### When to Use Self-Hosted Runners

| Use Case | Why |
|---|---|
| **Private network access** | CI needs to reach internal databases, APIs, or registries |
| **GPU/specialized hardware** | ML training, hardware-in-the-loop testing |
| **Cost reduction** | High CI volume makes GitHub-hosted runners expensive |
| **Large builds** | Need more CPU/RAM/disk than largest GitHub-hosted runner |
| **Compliance** | Data must stay within your infrastructure |

### Security Hardening

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
