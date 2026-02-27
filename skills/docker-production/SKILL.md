---
name: docker-production
description: >-
  Enterprise-grade Docker containerization & production operations. Use whenever creating,
  editing, reviewing, or fixing Dockerfiles, compose.yaml files, .dockerignore files,
  containerizing any application, setting up CI/CD pipelines for Docker, configuring
  reverse proxies, hardening Docker hosts, or planning deployment strategies.
  Covers: multi-stage builds, Docker Hardened Images (DHI), all 13 OWASP Docker rules,
  CIS Docker Benchmark, Docker Bake (HCL), multi-platform builds, Cosign image signing,
  SBOM/SLSA attestations, supply chain security, Traefik v3/Caddy reverse proxy with TLS,
  zero-downtime deployments (docker-rollout, blue-green), Docker socket proxy, graceful
  shutdown/signal handling, daemon.json hardening, seccomp/AppArmor, auditd, rootless mode,
  volume backup strategies, Prometheus/Grafana monitoring, structured logging, and
  production runbooks. Triggers: Docker, Dockerfile, container, compose, containerize,
  docker-compose, dockerize, image build, compose.yaml, CI/CD, deploy, reverse proxy,
  Traefik, production, hardening, security scan.
---

# Docker Production Skill

Generate secure, optimized, enterprise-grade Docker configurations for any stack.
Every output aligns with the **Compose Specification** (rolling spec, no version field),
**OWASP Docker Security Cheat Sheet** (all 13 rules), **CIS Docker Benchmark v1.8**,
**SLSA Build Level 3**, and **Docker official best-practices docs**.

**Before generating ANY Docker artifact, read the relevant references:**

### Core Build References
- Security hardening → [references/SECURITY.md](references/SECURITY.md)
- Dockerfile patterns → [references/DOCKERFILE_PATTERNS.md](references/DOCKERFILE_PATTERNS.md)
- Compose patterns → [references/COMPOSE_PATTERNS.md](references/COMPOSE_PATTERNS.md)
- Language stacks → [references/LANGUAGE_STACKS.md](references/LANGUAGE_STACKS.md)

### Production Operations References
- CI/CD & Docker Bake → [references/CI_CD.md](references/CI_CD.md)
- Supply chain (signing, SBOM, attestations) → [references/SUPPLY_CHAIN.md](references/SUPPLY_CHAIN.md)
- Reverse proxy (Traefik v3, Caddy) → [references/REVERSE_PROXY.md](references/REVERSE_PROXY.md)
- Host & daemon hardening → [references/HOST_HARDENING.md](references/HOST_HARDENING.md)
- Production ops (deploy, backup, monitoring) → [references/PRODUCTION_OPS.md](references/PRODUCTION_OPS.md)

---

## Modern Docker Facts (Use These, Not Outdated Conventions)

| Old / Wrong | Current / Correct |
|---|---|
| `docker-compose.yml` | **`compose.yaml`** (preferred filename since Compose v2) |
| `version: '3.8'` at top of file | **Omit entirely** — obsolete, ignored by Compose v2/v5 |
| `docker-compose up` (v1 CLI) | **`docker compose up`** (v2/v5 CLI, built into Docker) |
| `FROM node:latest` | **`FROM node:22-slim`** or **Docker Hardened Image** (`dhi.io/node`) |
| Passwords in `environment:` | **Docker secrets** mounted at `/run/secrets/` |
| `ADD . .` | **`COPY . .`** (ADD only for tar extraction) |
| Running as root | **`USER 10001:10001`** always |
| `restart: always` | **`restart: unless-stopped`** |
| No healthcheck | **`healthcheck:` on every single service** |
| Default bridge network | **Named networks with `internal: true` for backends** |
| `docker build` for multi-service | **`docker buildx bake`** (GA Feb 2025, parallel builds) |
| Mounting docker.sock to containers | **Docker socket proxy** (tecnativa/docker-socket-proxy) |
| `CMD ["npm", "start"]` | **`CMD ["node", "dist/server.js"]`** (npm swallows SIGTERM) |
| No `init: true` | **`init: true`** on every service (tini handles signals + zombies) |
| Deploy via `docker compose up -d` | **`docker rollout`** or blue-green (zero downtime) |
| `:latest` tag in production | **Pin to semver tag or `@sha256:` digest** |
| No image signing | **Cosign keyless signing** in CI/CD |
| `docker build` (no cache export) | **BuildKit cache mounts** (`--mount=type=cache`) |
| Build only for `linux/amd64` | **`--platform linux/amd64,linux/arm64`** — ARM64 is 37% cheaper on AWS Graviton |
| `FROM node:22-slim` in multi-platform | **`FROM --platform=$BUILDPLATFORM node:22-slim AS build`** — prevents QEMU during compile |
| `gcr.io/distroless/...` only | **Chainguard images** (`cgr.dev/chainguard/node:22`) — zero-CVE, nightly rebuilds, built-in SBOM |
| `start_period` only for healthchecks | **`start_interval: 3s`** for fast startup probing (Compose ≥ 2.20.2) |
| Unpublished ports accessible on LAN | **Engine v28+ blocks by default** (CVE-2025-54388) |

---

## Workflow: Every Docker Task

```
1. GATHER     → Infer from codebase; ask only what's ambiguous
2. GENERATE   → Dockerfile + .dockerignore + compose.yaml + .env.example
3. HARDEN     → Run the security checklist against every output
4. VERIFY     → Emit hadolint + Trivy + Scout + compose config commands
5. PROXY      → Add reverse proxy (Traefik/Caddy) with TLS + security middlewares
6. PIPELINE   → CI/CD: GitHub Actions or Docker Bake + scan gates + signing
7. OPERATE    → Zero-downtime deploy, backup, monitoring, host hardening
```

Steps 1–4 are **always performed** for any Docker task.
Steps 5–7 are performed when the user asks for production deployment, CI/CD, or operations guidance. Proactively suggest them when delivering a full production stack.

---

## Step 1 — Gather Context

**Infer first from files in the project.** Only ask when genuinely ambiguous.

| Signal | Infer From |
|---|---|
| Runtime (Node/Python/Go/Java/Rust/.NET/PHP/Ruby) | package.json, requirements.txt, go.mod, pom.xml, Cargo.toml, *.csproj, composer.json, Gemfile |
| Build tool (npm/yarn/pnpm/pip/poetry/uv/cargo/maven/gradle) | Lock files: package-lock.json, yarn.lock, pnpm-lock.yaml, poetry.lock, uv.lock, Cargo.lock |
| Ports | Framework defaults, config, env vars, code |
| Dependencies (DB/cache/queue) | Connection strings, imports, existing compose files |
| Persistence | Database data dirs, upload dirs |
| Target environment | Default: **production on a single server with Compose** |
| Secrets | .env files, env var references |

---

## Step 2 — Generate Artifacts

Always produce **all four** unless the user explicitly requests only one.

### A. Dockerfile

See full patterns in [references/DOCKERFILE_PATTERNS.md](references/DOCKERFILE_PATTERNS.md).

```dockerfile
# syntax=docker/dockerfile:1

# ── Build ──────────────────────────────────
FROM node:22-slim AS build
WORKDIR /app
COPY package.json package-lock.json ./
RUN --mount=type=cache,target=/root/.npm \
    npm ci --ignore-scripts
COPY . .
RUN npm run build && npm prune --omit=dev

# ── Production ─────────────────────────────
FROM node:22-slim AS production

LABEL org.opencontainers.image.source="https://github.com/org/repo"
LABEL org.opencontainers.image.description="App description"

RUN groupadd -g 10001 app && useradd -u 10001 -g app -s /bin/false -M app
WORKDIR /app

COPY --from=build --chown=10001:10001 /app/dist ./dist
COPY --from=build --chown=10001:10001 /app/node_modules ./node_modules
COPY --from=build --chown=10001:10001 /app/package.json ./

ENV NODE_ENV=production
USER 10001:10001
EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
  CMD node -e "fetch('http://localhost:3000/health').then(r=>{if(!r.ok)throw r})" || exit 1

CMD ["node", "dist/index.js"]
```

**10 Non-Negotiable Dockerfile Rules:**

1. **Multi-stage builds** — always separate build from runtime
2. **Non-root USER** — UID ≥ 10001 (avoids host UID overlap)
3. **HEALTHCHECK** — in every Dockerfile
4. **Minimal base** — slim, alpine, distroless, or Docker Hardened Images (DHI) for production
5. **Pinned tags** — `node:22-slim` not `node:latest`
6. **Layer order** — system deps → app deps (lock files) → source code
7. **Clean in same RUN** — `apt-get update && install && rm -rf /var/lib/apt/lists/*`
8. **COPY not ADD** — ADD only when extracting .tar archives
9. **OCI labels** — `org.opencontainers.image.source`, `.description`, `.revision`
10. **No secrets in layers** — no ARG/ENV for passwords; use `--mount=type=secret`

### B. .dockerignore

```dockerignore
.git
.gitignore
node_modules
.venv
__pycache__
vendor
target
dist
build
.env
.env.*
*.pem
*.key
*.crt
secrets/
.vscode
.idea
*.swp
.DS_Store
Dockerfile*
compose.yaml
compose*.yml
docker-compose*
.github
.gitlab-ci.yml
Jenkinsfile
README.md
docs/
tests/
test/
__tests__
*.test.*
*.spec.*
coverage/
.nyc_output
.pytest_cache
htmlcov
```

### C. compose.yaml

See full patterns in [references/COMPOSE_PATTERNS.md](references/COMPOSE_PATTERNS.md).

```yaml
# compose.yaml — NO version field (it is obsolete)

services:
  app:
    build:
      context: .
      target: production
    image: myapp:${TAG:-latest}
    restart: unless-stopped
    init: true                         # tini for proper signal handling

    # ── Security ──
    user: "10001:10001"
    read_only: true
    security_opt:
      - no-new-privileges:true
    cap_drop:
      - ALL
    tmpfs:
      - /tmp:noexec,nosuid,size=64m

    # ── Networking ──
    ports:
      - "127.0.0.1:3000:3000"
    networks:
      - frontend

    # ── Health ──
    healthcheck:
      test: ["CMD", "node", "-e", "fetch('http://localhost:3000/health').then(r=>{if(!r.ok)throw r})"]
      interval: 30s
      timeout: 5s
      retries: 3
      start_period: 30s
      start_interval: 5s              # faster probing during startup (Compose ≥ 2.20.2)

    # ── Resources ──
    deploy:
      resources:
        limits:
          cpus: "1.0"
          memory: 512M
        reservations:
          cpus: "0.25"
          memory: 128M

    # ── Dependencies ──
    depends_on:
      db:
        condition: service_healthy
        restart: true                  # restart app when db restarts (Compose ≥ 2.17)

    # ── Secrets ──
    secrets:
      - db_password
    environment:
      - NODE_ENV=production
      - DB_HOST=db
      - DB_PASSWORD_FILE=/run/secrets/db_password

    # ── Logging ──
    logging:
      driver: json-file
      options:
        max-size: "10m"
        max-file: "5"
        tag: "{{.Name}}"

  db:
    image: postgres:17-alpine
    restart: unless-stopped
    user: "999:999"
    read_only: true
    security_opt:
      - no-new-privileges:true
    cap_drop:
      - ALL
    cap_add:
      - DAC_OVERRIDE
      - FOWNER
      - SETGID
      - SETUID
    tmpfs:
      - /tmp:noexec,nosuid,size=64m
      - /run/postgresql:noexec,nosuid,size=16m
    volumes:
      - db_data:/var/lib/postgresql/data
    networks:
      - backend
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 30s
      start_interval: 3s
    secrets:
      - db_password
    environment:
      POSTGRES_PASSWORD_FILE: /run/secrets/db_password
      POSTGRES_DB: app
    deploy:
      resources:
        limits:
          cpus: "1.0"
          memory: 1G
        reservations:
          cpus: "0.25"
          memory: 256M
    logging:
      driver: json-file
      options:
        max-size: "10m"
        max-file: "5"

networks:
  frontend:
    driver: bridge
  backend:
    driver: bridge
    internal: true                     # isolated — no internet, no host access

volumes:
  db_data:
    labels:
      com.example.description: "PostgreSQL persistent data"

secrets:
  db_password:
    file: ./secrets/db_password.txt
```

### D. Environment Template (.env.example)

```bash
# .env.example — copy to .env and fill in values
# NEVER commit .env to version control

# Application
NODE_ENV=production
PORT=3000
TAG=latest

# Database (non-sensitive only — passwords use Docker secrets)
POSTGRES_DB=app
POSTGRES_USER=app
```

---

## Step 3 — Security Audit Checklist

**Run through this for EVERY output. Fix before presenting.**

### Image Security
- [ ] Base image is official/verified, pinned to major.minor
- [ ] Consider Docker Hardened Images (DHI) for maximum CVE reduction
- [ ] Multi-stage build separates build from runtime
- [ ] Production stage is slim/alpine/distroless/DHI
- [ ] No secrets in ARG, ENV, or layers
- [ ] `.dockerignore` excludes .git, .env, secrets, node_modules, tests

### OWASP Docker Rules (all 13)
- [ ] **#0** Base images are recent/patched
- [ ] **#1** Docker socket NOT mounted
- [ ] **#2** Non-root USER (UID ≥ 10001)
- [ ] **#3** `cap_drop: ALL` + selective `cap_add` only
- [ ] **#4** `security_opt: no-new-privileges:true`
- [ ] **#5** Named networks, backends `internal: true`
- [ ] **#6** Default seccomp/AppArmor NOT disabled
- [ ] **#7** Memory + CPU limits set
- [ ] **#8** `read_only: true` + tmpfs for writable dirs
- [ ] **#9** Scanning commands emitted
- [ ] **#10** Logging at info (not debug)
- [ ] **#11** Rootless mode noted as recommendation
- [ ] **#12** Secrets via Docker secrets, not env vars
- [ ] **#13** OCI labels for provenance

### Compose Robustness
- [ ] No `version:` field
- [ ] File named `compose.yaml`
- [ ] `restart: unless-stopped` on all services
- [ ] `init: true` for proper signal handling
- [ ] `healthcheck:` on every service with `start_interval`
- [ ] `depends_on` with `condition: service_healthy`
- [ ] Ports bound to `127.0.0.1:` unless deliberately public
- [ ] Named volumes for state
- [ ] Backend networks `internal: true`
- [ ] Log rotation configured

---

## Step 4 — Verification Commands

**Always emit at the end of every Docker task:**

```bash
# ── Lint Dockerfile ──
docker run --rm -i hadolint/hadolint < Dockerfile

# ── Validate compose.yaml ──
docker compose config --quiet

# ── Build ──
docker compose build

# ── Scan image for CVEs ──
trivy image --severity HIGH,CRITICAL myapp:latest
# Or Grype (Anchore, open source — fast, no Docker Desktop needed):
grype myapp:latest --fail-on high
# Or Docker Scout (built into Docker Desktop):
docker scout cves myapp:latest
docker scout recommendations myapp:latest

# ── Scan config files for misconfigurations ──
trivy config .

# ── Test the full stack ──
docker compose up -d
docker compose ps          # all services should show "healthy"
docker compose logs -f     # watch for startup errors

# ── Teardown ──
docker compose down
```

---

## Decision Trees

### Base Image Selection

```
Compiled language (Go, Rust, C)?
├─ YES → Build: full SDK → Production: distroless/static or scratch
│        Go:   gcr.io/distroless/static-debian12
│        Rust: debian:bookworm-slim or scratch (if static musl)
└─ NO (interpreted)
   ├─ Node.js  → node:{version}-slim  (or DHI node if available)
   ├─ Python   → python:{version}-slim  (NOT alpine — musl breaks wheels)
   ├─ Java     → eclipse-temurin:{version}-jre-jammy
   ├─ .NET     → mcr.microsoft.com/dotnet/aspnet:{version}-noble-chiseled
   ├─ PHP      → php:{version}-fpm-alpine
   └─ Ruby     → ruby:{version}-slim

For maximum security: prefer Docker Hardened Images (DHI) or Chainguard
  → DHI: docker.io/docker/IMAGENAME:TAG  (free, Apache 2.0, 95% fewer CVEs)
  → Chainguard: cgr.dev/chainguard/node:22  (zero-CVE, rebuilt nightly, built-in SBOM)
  → Both are drop-in compatible with DockerHub image names

Multi-platform builds (always produce both architectures):
  docker buildx build --platform linux/amd64,linux/arm64 -t myapp .
  Use FROM --platform=$BUILDPLATFORM for compile stages (avoids QEMU emulation)
```

### Secrets

```
Sensitive value (password, API key, token, cert)?
├─ YES → Docker secrets  →  /run/secrets/<name>
│        App reads from file: DB_PASSWORD_FILE=/run/secrets/db_password
│        Official images support _FILE suffix: POSTGRES_PASSWORD_FILE, etc.
└─ NO  → Environment variable is fine (NODE_ENV, PORT, LOG_LEVEL)
```

### Restart Policy

```
Production   → restart: unless-stopped
Development  → restart: "no" (or omit)
One-shot     → restart: "no"  (migrations, seeds, backups)
Swarm/Stack  → deploy.restart_policy  (not the top-level restart key)
```

### Port Binding

```
Reverse proxy in front (Traefik / Caddy / nginx)?
├─ YES → "127.0.0.1:3000:3000"  (only loopback)
└─ NO  → "3000:3000"  (but strongly recommend adding reverse proxy)
```

---

## Common Patterns

### Graceful Shutdown & Signal Handling
```yaml
services:
  app:
    init: true              # tini as PID 1, forwards SIGTERM correctly
    stop_grace_period: 30s  # time before SIGKILL
```
Use exec-form CMD to receive signals: `CMD ["node", "server.js"]` (not shell form).

### Healthcheck Without curl
```dockerfile
# Node.js (fetch built-in since v18)
HEALTHCHECK CMD node -e "fetch('http://localhost:3000/health').then(r=>{if(!r.ok)throw r})" || exit 1

# Python
HEALTHCHECK CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')" || exit 1

# Go — compile a tiny healthcheck binary
HEALTHCHECK CMD ["/healthcheck"]

# Alpine (wget included)
HEALTHCHECK CMD wget -qO- http://localhost:8080/health || exit 1
```

### Read-Only Filesystem
```yaml
services:
  app:
    read_only: true
    tmpfs:
      - /tmp:noexec,nosuid,size=64m
      - /app/cache:noexec,nosuid,size=32m
```

### Build-Time Secrets (Private Registries, NPM Tokens)
```dockerfile
# syntax=docker/dockerfile:1
RUN --mount=type=secret,id=npm_token \
    NPM_TOKEN=$(cat /run/secrets/npm_token) npm ci
```
```bash
docker build --secret id=npm_token,src=.npmrc .
```

### Dev / Prod Split with Overrides
```
compose.yaml              ← production base (full hardening)
compose.override.yaml     ← dev overrides (auto-loaded by `docker compose up`)
```
Production deploy: `docker compose -f compose.yaml up -d` (skips override)

### Hot Reload in Development (compose watch)
```yaml
services:
  app:
    develop:
      watch:
        - action: sync
          path: ./src
          target: /app/src
        - action: rebuild
          path: package.json
```
```bash
docker compose watch
```

---

## Anti-Patterns

| Anti-Pattern | Why It's Dangerous | Fix |
|---|---|---|
| `FROM node:latest` | Unreproducible, surprise breaks | `FROM node:22-slim` |
| `version: '3.8'` in compose | Obsolete, causes warnings | Remove entirely |
| `docker-compose.yml` filename | Legacy v1 convention | Use `compose.yaml` |
| `docker-compose up` command | v1 CLI, deprecated since June 2023 | `docker compose up` |
| `RUN npm install` | Non-deterministic | `RUN npm ci --omit=dev` |
| No `.dockerignore` | Leaks secrets, bloats context | Always create one |
| `ADD . .` | Implicit tar/URL behavior | `COPY . .` |
| Running as root | Container escape = host root | `USER 10001:10001` |
| `privileged: true` | All caps, no seccomp, no AppArmor | Never. Use `cap_add` |
| Secrets in ENV/ARG | Visible in inspect/history | Docker secrets |
| `restart: always` | Restarts even manual stops | `unless-stopped` |
| Default bridge network | All containers see each other | Named networks |
| No healthcheck | Can't detect dead services | Always define |
| No resource limits | One container starves host | `deploy.resources.limits` |
| Mounting docker.sock | Equals host root access | Docker socket proxy |
| `seccomp: unconfined` | Disables syscall filtering | Keep defaults |
| No `init: true` | Zombie processes, signal issues | Always set |
| `CMD ["npm", "start"]` | npm doesn't forward SIGTERM | `CMD ["node", "dist/server.js"]` |
| Deploy with `docker compose up -d` | Causes downtime during restarts | `docker rollout` or blue-green |
| `:latest` tag in production | Mutable, unreproducible | Pin to semver or digest |
| No SBOM / no image signing | No supply chain assurance | Cosign + Syft in CI |
| Exposing ports directly to 0.0.0.0 | Bypasses firewall, attack surface | `127.0.0.1:port:port` + reverse proxy |
| No log rotation | Disk fill, OOM | `logging.options.max-size: 10m` |
| `stop_grace_period` too short | Dropped requests on deploy | `30s` minimum |

---

## Environment Targets

### Local Development
- `docker compose watch` for hot-reload
- Bind-mount source code
- Relax `read_only` if needed
- Keep healthchecks and networks (catches issues early)
- `restart: "no"`

### Single Server Production (Compose on a VM — most common)
- Full hardening as above
- **Reverse proxy** (Traefik v3 + Docker socket proxy) → [references/REVERSE_PROXY.md](references/REVERSE_PROXY.md)
- **TLS termination** with auto Let's Encrypt certificates
- **Security middlewares**: headers, rate limiting, IP allowlisting
- Docker secrets for all sensitive values
- Resource limits based on server capacity
- **Zero-downtime deploys** with docker-rollout → [references/PRODUCTION_OPS.md](references/PRODUCTION_OPS.md)
- **Automated volume backups** with retention policy
- Log rotation on every service + centralized shipping
- **Host hardening**: daemon.json, seccomp, auditd → [references/HOST_HARDENING.md](references/HOST_HARDENING.md)
- **CI/CD pipeline**: GitHub Actions + scan gates + signing → [references/CI_CD.md](references/CI_CD.md)
- **Supply chain**: SBOM + Cosign + provenance → [references/SUPPLY_CHAIN.md](references/SUPPLY_CHAIN.md)
- **Monitoring**: Prometheus + Grafana + cAdvisor → [references/PRODUCTION_OPS.md](references/PRODUCTION_OPS.md)
- Weekly automated image rebuilds for base image patches
- Docker Bench for Security run weekly

### Orchestrator Path (Swarm / Kubernetes)
- `deploy` section for replicas and rolling updates
- Replace Docker secrets with K8s Secrets + external vault
- K8s readiness/liveness probes replace compose healthchecks
- Network Policies replace `internal: true` networks
- Pod Security Standards replace cap_drop/read_only
- Kyverno/OPA for image signing policy enforcement
