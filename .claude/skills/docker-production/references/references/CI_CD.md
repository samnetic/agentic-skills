# CI/CD Pipeline Patterns

Production-grade CI/CD patterns for Docker image builds. Covers GitHub Actions (primary), Docker Bake, multi-platform builds, image scanning gates, caching, and tagging strategies.

---

## Docker Bake (Build Orchestration)

Bake is Docker's build orchestration — GA since Feb 2025. Use it for monorepos or multi-service projects. Write in HCL (most features) alongside compose.yaml.

### Basic docker-bake.hcl

```hcl
variable "TAG" {
  default = "latest"
}

variable "REGISTRY" {
  default = "ghcr.io/myorg"
}

group "default" {
  targets = ["app", "worker"]
}

target "app" {
  context    = "."
  dockerfile = "Dockerfile"
  target     = "production"
  tags       = ["${REGISTRY}/app:${TAG}", "${REGISTRY}/app:latest"]
  platforms  = ["linux/amd64", "linux/arm64"]
  labels = {
    "org.opencontainers.image.source" = "https://github.com/myorg/repo"
  }
}

target "worker" {
  context    = "./worker"
  dockerfile = "Dockerfile"
  target     = "production"
  tags       = ["${REGISTRY}/worker:${TAG}"]
  platforms  = ["linux/amd64", "linux/arm64"]
}

# Inherit for CI overrides
target "ci" {
  inherits   = ["app"]
  cache-from = ["type=registry,ref=${REGISTRY}/app:buildcache"]
  cache-to   = ["type=registry,ref=${REGISTRY}/app:buildcache,mode=max"]
}
```

### Bake with Compose (Compose as base, HCL for overrides)

Bake auto-merges `compose.yaml` + `docker-bake.hcl`:

```bash
# Build all services defined in compose.yaml with Bake overrides
docker buildx bake

# Build specific target with variable override
docker buildx bake --set TAG=v1.2.3 app

# Preview the merged config
docker buildx bake --print

# List available targets
docker buildx bake --list=targets
```

---

## GitHub Actions — Complete Production Workflow

### Single-Platform Build + Scan + Push

```yaml
name: Build, Scan, Push

on:
  push:
    branches: [main]
    tags: ["v*"]
  pull_request:
    branches: [main]

permissions:
  contents: read
  packages: write
  security-events: write

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Log in to registry
        if: github.event_name != 'pull_request'
        uses: docker/login-action@v3
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Extract metadata
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
          tags: |
            type=semver,pattern={{version}}
            type=semver,pattern={{major}}.{{minor}}
            type=sha,prefix=
            type=ref,event=branch
            type=ref,event=pr

      - name: Build and push
        uses: docker/build-push-action@v6
        with:
          context: .
          target: production
          push: ${{ github.event_name != 'pull_request' }}
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          cache-from: type=gha
          cache-to: type=gha,mode=max
          sbom: true
          provenance: mode=max

      - name: Scan with Trivy
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ steps.meta.outputs.version }}
          format: sarif
          output: trivy-results.sarif
          severity: CRITICAL,HIGH
          exit-code: "1"

      - name: Upload scan results
        if: always()
        uses: github/codeql-action/upload-sarif@v3
        with:
          sarif_file: trivy-results.sarif

      - name: Docker Scout
        if: github.event_name != 'pull_request'
        uses: docker/scout-action@v1
        with:
          command: cves,recommendations
          image: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ steps.meta.outputs.version }}
          sarif-file: scout-results.sarif
          summary: true
```

### Multi-Platform Build (amd64 + arm64)

```yaml
name: Multi-Platform Build

on:
  push:
    tags: ["v*"]

permissions:
  contents: read
  packages: write

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Set up QEMU
        uses: docker/setup-qemu-action@v3

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Log in to registry
        uses: docker/login-action@v3
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Extract metadata
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
          tags: |
            type=semver,pattern={{version}}
            type=semver,pattern={{major}}.{{minor}}

      - name: Build and push
        uses: docker/build-push-action@v6
        with:
          context: .
          target: production
          platforms: linux/amd64,linux/arm64
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          cache-from: type=gha
          cache-to: type=gha,mode=max
          sbom: true
          provenance: mode=max
```

### Bake in GitHub Actions

```yaml
      - name: Build with Bake
        uses: docker/bake-action@v5
        with:
          files: |
            compose.yaml
            docker-bake.hcl
          targets: default
          push: true
          set: |
            *.cache-from=type=gha
            *.cache-to=type=gha,mode=max
```

---

## Image Tagging Strategy

```
Tag                     When to Use
──────────────────────────────────────────
v1.2.3                  Semver release (immutable)
v1.2                    Major.minor tracking
sha-abc1234             Every commit (traceability)
main                    Latest from main branch (mutable)
pr-42                   Pull request preview
latest                  AVOID in production (ambiguous)
```

**Golden rule:** Production deploys pin to digest or semver tag. Never `:latest`.

```bash
# Pin to digest for max reproducibility
docker pull ghcr.io/myorg/app@sha256:abc123...
```

---

## Caching Strategies

### GitHub Actions Cache (GHA)
```yaml
cache-from: type=gha
cache-to: type=gha,mode=max    # cache all layers, not just final
```
Limit: 10 GB per repo. Best for most workflows.

### Registry Cache
```yaml
cache-from: type=registry,ref=ghcr.io/myorg/app:buildcache
cache-to: type=registry,ref=ghcr.io/myorg/app:buildcache,mode=max
```
No size limit. Cache persists across workflows. Best for large teams.

### Inline Cache
```yaml
cache-from: type=registry,ref=ghcr.io/myorg/app:latest
```
Cheapest — no extra storage. Only caches final image layers.

### Local Cache (self-hosted runners)
```yaml
cache-from: type=local,src=/tmp/.buildx-cache
cache-to: type=local,dest=/tmp/.buildx-cache-new,mode=max
```

---

## Dockerfile Lint in CI

```yaml
      - name: Lint Dockerfile
        uses: hadolint/hadolint-action@v3.1.0
        with:
          dockerfile: Dockerfile
          failure-threshold: warning
```

### Hadolint Configuration (.hadolint.yaml)

```yaml
ignored:
  - DL3008    # pin apt versions (noisy for CI images)
  - DL3018    # pin apk versions

trustedRegistries:
  - docker.io
  - ghcr.io
  - gcr.io

override:
  warning:
    - DL3059    # multiple consecutive RUN
```

---

## Scan Gates (Block Vulnerable Images)

### Trivy in CI (fail on HIGH/CRITICAL)

```yaml
      - name: Trivy image scan
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: myapp:${{ github.sha }}
          severity: CRITICAL,HIGH
          exit-code: "1"           # fail the pipeline
          ignore-unfixed: true     # skip CVEs with no fix
```

### Docker Scout Policy Check

```yaml
      - name: Scout policy check
        uses: docker/scout-action@v1
        with:
          command: policy
          image: myapp:${{ github.sha }}
          exit-code: true          # fail on policy violation
```

### Trivy Config Scan (misconfigurations)

```yaml
      - name: Scan config files
        uses: aquasecurity/trivy-action@master
        with:
          scan-type: config
          scan-ref: .
          severity: CRITICAL,HIGH
          exit-code: "1"
```

---

## Automated Image Rebuilds (Weekly Security Patch)

```yaml
name: Weekly Rebuild

on:
  schedule:
    - cron: "0 4 * * 1"           # Monday 04:00 UTC
  workflow_dispatch:                # manual trigger

jobs:
  rebuild:
    runs-on: ubuntu-latest
    steps:
      # Same build steps as above
      # Rebuilds pick up patched base images automatically
```

---

## Decision: When to Use What

```
Single service, simple build     → docker build / build-push-action
Multiple services, monorepo      → docker buildx bake + HCL
Multi-platform (amd64+arm64)     → build-push-action with platforms
Complex matrix (versions × arch) → Bake with matrix targets
```
