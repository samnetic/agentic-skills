# Dockerfile Patterns Reference

Authoritative patterns from Docker official build best practices, Dockerfile reference, and Docker Hardened Images. Current as of Docker Engine v28 / BuildKit.

---

## Directive: Always Start With

```dockerfile
# syntax=docker/dockerfile:1
```
Enables BuildKit features: cache mounts, secret mounts, heredocs, etc.

---

## Layer Ordering (Cache-Friendly)

```
1. Base image (FROM)
2. System-level dependencies (apt, apk — rarely changes)
3. Dependency manifests (package.json, requirements.txt, go.mod)
4. Dependency install (npm ci, pip install, go mod download)
5. Application source code (COPY . .)
6. Build step (npm run build, go build)
```

Ordering from least-changing to most-changing maximizes Docker layer cache hits.

---

## User Creation by Base Image

```dockerfile
# Debian/Ubuntu
RUN groupadd -g 10001 app && useradd -u 10001 -g app -s /bin/false -M -d /app app

# Alpine
RUN addgroup -g 10001 -S app && adduser -u 10001 -S -G app -s /sbin/nologin -h /app app

# Distroless / DHI (no shell, no adduser)
USER 10001:10001

# .NET Chiselled (pre-defined)
USER $APP_UID
```

---

## Healthcheck Patterns (Without curl)

Minimal images often lack curl. Use native runtime tools:

```dockerfile
# Node.js (fetch built-in since v18)
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
  CMD node -e "fetch('http://localhost:3000/health').then(r=>{if(!r.ok)throw r})" || exit 1

# Python
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')" || exit 1

# Go (compile static healthcheck binary in build stage)
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD ["/healthcheck"]

# Alpine (wget is included)
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
  CMD wget -qO- http://localhost:8080/health || exit 1

# TCP-only check (no HTTP endpoint)
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
  CMD ["sh", "-c", "echo > /dev/tcp/localhost/3000"]

# Distroless (no shell) — use a compiled binary
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD ["/healthcheck"]
```

---

## BuildKit Cache Mounts

Speed up repeated builds by persisting package manager caches:

```dockerfile
# syntax=docker/dockerfile:1

# Node.js
RUN --mount=type=cache,target=/root/.npm \
    npm ci --omit=dev

# Python (pip)
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install --no-cache-dir -r requirements.txt

# Go
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    go build -o /app/server .

# apt-get
RUN --mount=type=cache,target=/var/cache/apt \
    --mount=type=cache,target=/var/lib/apt \
    apt-get update && apt-get install -y --no-install-recommends <packages>
```

---

## Build-Time Secrets

For private registries, NPM tokens, etc. — secret data never persists in image layers:

```dockerfile
# syntax=docker/dockerfile:1
RUN --mount=type=secret,id=npm_token \
    NPM_TOKEN=$(cat /run/secrets/npm_token) npm ci

RUN --mount=type=secret,id=pip_conf,target=/etc/pip.conf \
    pip install -r requirements.txt
```

```bash
docker build --secret id=npm_token,src=.npmrc .
```

---

## Build Arguments vs Environment Variables

| Mechanism | When Available | In Image Layers? | Use For |
|---|---|---|---|
| `ARG` | Build time | No (but in build history via `docker history`) | Version pins, build targets |
| `ENV` | Build + runtime | Yes | Runtime config (NODE_ENV, PORT) |
| `--mount=type=secret` | Build time | **No** (safe) | NPM_TOKEN, private registry creds |
| Docker secrets | Runtime | **No** | Passwords, API keys, certs |

---

## Signal Handling (PID 1 Problem)

The container's PID 1 process receives `SIGTERM` on `docker stop`. It must handle this signal.

**Problem:** Shell form wraps in `sh -c`, which doesn't forward signals:
```dockerfile
CMD node server.js          # ❌ sh is PID 1, swallows SIGTERM
```

**Solutions:**
```dockerfile
CMD ["node", "server.js"]   # ✅ exec form: node is PID 1
```

Or in compose.yaml:
```yaml
init: true                   # ✅ tini as PID 1, forwards signals properly
stop_grace_period: 30s       # time before SIGKILL
```

---

## .dockerignore Template

**Always create.** Without it, the entire directory (including .git, node_modules, secrets) is sent as build context.

```dockerignore
# VCS
.git
.gitignore
.gitattributes

# Dependencies
node_modules
.venv
__pycache__
vendor
target
dist
build

# Secrets and env
.env
.env.*
*.pem
*.key
*.crt
secrets/

# IDE / OS
.vscode
.idea
*.swp
*.swo
.DS_Store
Thumbs.db

# Docker meta
Dockerfile*
compose.yaml
compose*.yml
docker-compose*
.dockerignore

# CI/CD
.github
.gitlab-ci.yml
Jenkinsfile
.circleci

# Docs and tests
README.md
LICENSE
CHANGELOG.md
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

---

## Image Size Reduction

1. Multi-stage build (copy only production output)
2. Slim / alpine / distroless / DHI base for production
3. `--no-install-recommends` for apt
4. `rm -rf /var/lib/apt/lists/*` in same RUN layer
5. `--no-cache-dir` for pip
6. `--omit=dev` for npm
7. `npm prune --omit=dev` after build
8. `-ldflags="-s -w"` to strip Go binaries
9. `.dockerignore` — aggressively exclude
10. Combine related RUN commands (fewer layers)

---

## OCI Labels (Standard Metadata)

```dockerfile
LABEL org.opencontainers.image.title="My App"
LABEL org.opencontainers.image.description="Description"
LABEL org.opencontainers.image.source="https://github.com/org/repo"
LABEL org.opencontainers.image.version="1.0.0"
LABEL org.opencontainers.image.revision="${VCS_REF}"
LABEL org.opencontainers.image.created="${BUILD_DATE}"
LABEL org.opencontainers.image.licenses="MIT"
```
