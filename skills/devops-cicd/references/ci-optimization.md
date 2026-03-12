# CI Optimization, Wave Execution & Portable Pipelines

## Table of Contents

- [Cost Optimization for CI](#cost-optimization-for-ci)
- [Conditional Jobs Based on Changed Files](#conditional-jobs-based-on-changed-files)
- [Wave-Based Parallel CI Execution](#wave-based-parallel-ci-execution)
  - [Wave Architecture](#wave-architecture)
  - [GitHub Actions Implementation](#github-actions-implementation)
- [AI Model Profiles for CI/CD](#ai-model-profiles-for-cicd)
- [Dagger — Portable CI/CD Pipelines](#dagger--portable-cicd-pipelines)

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

---

## Conditional Jobs Based on Changed Files

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
