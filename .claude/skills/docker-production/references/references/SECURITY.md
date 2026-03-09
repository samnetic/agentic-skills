# Docker Security Hardening Reference

Controls from OWASP Docker Security Cheat Sheet (all 13 rules), CIS Docker Benchmark v1.8, and Docker Engine security docs. Updated for Docker Engine v28, Compose v5, and Docker Hardened Images (Dec 2025).

---

## Docker Hardened Images (DHI) — New Industry Baseline

Since December 2025, Docker's 1,000+ Hardened Images are **free and open source** (Apache 2.0).

**Why use DHI:**
- 95% fewer CVEs vs standard community images
- Distroless runtime (no shell, no pkg manager in prod)
- Complete SBOM with every image
- SLSA Build Level 3 provenance
- Cosign signatures for authenticity
- Built on Debian and Alpine — drop-in compatible, no lock-in

**Usage:**
```dockerfile
# Standard image → Docker Hardened Image
FROM node:22-slim              # Before
FROM docker.io/docker/node:22  # After (DHI equivalent)

FROM nginx:alpine              # Before (79.8 MB)
FROM docker.io/docker/nginx    # After  (15.7 MB, ~80% smaller)
```

**When NOT to use DHI:**
- DHI has no shell — debugging requires `docker debug` (needs Docker Desktop) or a debug sidecar
- If your build process requires shell access in the production image
- Fallback: use standard slim/alpine base with all other hardening applied

**Alternatives to DHI (also excellent):**
- **Google Distroless** — `gcr.io/distroless/static-debian12` (Go, Rust), `gcr.io/distroless/nodejs22` (Node)
- **Chainguard Images** — Wolfi-based, free developer tier at latest version, near-zero CVEs
- **Canonical Chiselled** — Ubuntu-based minimal images (great for .NET)

---

## OWASP Docker Security — All 13 Rules

### RULE #0 — Keep Host and Docker Up to Date
Containers share the host kernel. Kernel exploits (Dirty COW, Leaky Vessels CVE-2024-21626) inside a container yield host root.

- Update Docker Engine regularly (current: v28.x)
- Patch host kernel promptly
- Rebuild images weekly to pick up base image patches
- Scan with `docker scout` or `trivy` for outdated bases

### RULE #1 — Never Expose the Docker Daemon Socket
`/var/run/docker.sock` = root-equivalent access. Mounting it = container escape.

- Never mount `/var/run/docker.sock` into containers
- Never run `dockerd -H tcp://0.0.0.0:XXXX`
- If TCP required: mutual TLS only
- Audit all `volumes:` in compose.yaml for socket mounts
- If a service must access Docker API (like Traefik): mount **read-only** and use a socket proxy like `tecnativa/docker-socket-proxy`

### RULE #2 — Run as Non-Root User
Default container processes run as root. Compromise → root inside container → potential host escalation.

**Dockerfile:**
```dockerfile
RUN groupadd -g 10001 app && useradd -u 10001 -g app -s /bin/false -M app
USER 10001:10001
```

**Alpine:**
```dockerfile
RUN addgroup -g 10001 -S app && adduser -u 10001 -S -G app -s /sbin/nologin app
USER 10001:10001
```

**Distroless / DHI (no useradd):**
```dockerfile
USER 10001:10001
```

**compose.yaml:**
```yaml
user: "10001:10001"
```

**Why UID ≥ 10001?** Low UIDs overlap with host system users. Container escape with UID 1000 could map to a real host user.

### RULE #3 — Drop All Capabilities, Add Only Needed
Docker's default cap set is reduced from full root, but still too broad for most apps.

```yaml
cap_drop:
  - ALL
# Add back only what's truly needed:
# cap_add:
#   - NET_BIND_SERVICE    # ports < 1024
```

**NEVER use `privileged: true`** — grants ALL capabilities, disables seccomp, disables AppArmor.

**Common capability needs:**

| Service | Capabilities |
|---|---|
| Web app (port > 1024) | None — `cap_drop: ALL` |
| Nginx on port 80 | NET_BIND_SERVICE |
| PostgreSQL | DAC_OVERRIDE, FOWNER, SETGID, SETUID |
| Redis | SETGID, SETUID |

### RULE #4 — Prevent Privilege Escalation

```yaml
security_opt:
  - no-new-privileges:true
```

Blocks setuid/setgid escalation. **Apply to every service, no exceptions.**

### RULE #5 — Network Segmentation
Default bridge lets all containers talk. Use named networks with isolation:

```yaml
networks:
  frontend:
    driver: bridge
  backend:
    driver: bridge
    internal: true    # no internet, no host access

services:
  app:
    networks: [frontend, backend]     # bridges both
  db:
    networks: [backend]                # isolated
  redis:
    networks: [backend]                # isolated
```

**Rule:** Databases, caches, queues → `internal: true` only.

### RULE #6 — Keep Default Security Profiles
Docker applies a default seccomp profile blocking ~44 dangerous syscalls. Never disable it.

```yaml
# NEVER DO THIS:
security_opt:
  - seccomp:unconfined     # disables all filtering
  - apparmor:unconfined    # disables MAC
```

If an app needs a blocked syscall: create a custom seccomp profile adding only that syscall.

### RULE #7 — Set Resource Limits
Without limits, one container can starve the host (DoS).

```yaml
deploy:
  resources:
    limits:
      cpus: "1.0"
      memory: 512M
    reservations:
      cpus: "0.25"
      memory: 128M
```

Additional protections: `--pids-limit=200` (fork bomb prevention), ulimits for file descriptors.

### RULE #8 — Read-Only Filesystem

```yaml
read_only: true
tmpfs:
  - /tmp:noexec,nosuid,size=64m
```

Prevents runtime code injection. Use tmpfs with `noexec` for temporary writable paths.

### RULE #9 — Scan Images in CI/CD

```bash
# Dockerfile lint
docker run --rm -i hadolint/hadolint < Dockerfile

# Image CVE scan
trivy image --severity HIGH,CRITICAL --exit-code 1 myapp:latest

# Config misconfig scan
trivy config .

# Docker Scout (native, built into Docker Desktop)
docker scout cves myapp:latest
docker scout recommendations myapp:latest
```

### RULE #10 — Logging at Info Level
Debug logging can expose credentials, tokens, PII.

```yaml
logging:
  driver: json-file
  options:
    max-size: "10m"
    max-file: "5"
    tag: "{{.Name}}"
```

### RULE #11 — Consider Rootless Mode
Docker daemon itself runs without root. Even a container escape doesn't yield host root.

```bash
dockerd-rootless-setuptool.sh install
docker context use rootless
```

Trade-offs: low-port binding needs workarounds, overlayfs on some kernels.

### RULE #12 — Docker Secrets for Sensitive Data
Environment variables are visible via `docker inspect` and in process listings.

```yaml
secrets:
  db_password:
    file: ./secrets/db_password.txt

services:
  app:
    secrets: [db_password]
    environment:
      DB_PASSWORD_FILE: /run/secrets/db_password
```

**Reading secrets in app code:**
```javascript
// Node.js
const password = require('fs').readFileSync('/run/secrets/db_password', 'utf8').trim();
```
```python
# Python
password = open('/run/secrets/db_password').read().strip()
```

Many official images support `_FILE` suffix natively: `POSTGRES_PASSWORD_FILE`, `MYSQL_ROOT_PASSWORD_FILE`, `REDIS_PASSWORD_FILE`.

### RULE #13 — Supply Chain Security

- Use official / verified publisher base images (or DHI)
- Enable Docker Content Trust: `export DOCKER_CONTENT_TRUST=1`
- Generate SBOM: `docker sbom myapp:latest`
- Sign images with cosign/Sigstore
- OCI labels for provenance:
```dockerfile
LABEL org.opencontainers.image.source="https://github.com/org/repo"
LABEL org.opencontainers.image.revision="${VCS_REF}"
LABEL org.opencontainers.image.created="${BUILD_DATE}"
```

---

## CIS Docker Benchmark Alignment

| CIS | Control | Implementation |
|---|---|---|
| 4.1 | Trusted base images | Official, DHI, or verified publisher |
| 4.2 | No unnecessary packages | Slim/distroless, multi-stage |
| 4.5 | Content Trust | `DOCKER_CONTENT_TRUST=1` |
| 4.6 | HEALTHCHECK | In Dockerfile AND compose.yaml |
| 4.9 | COPY not ADD | Always |
| 4.10 | No secrets in Dockerfile | Secrets via runtime mount |
| 5.2 | SELinux/AppArmor | Keep defaults |
| 5.3 | Restrict caps | `cap_drop: ALL` |
| 5.4 | No privileged | Never |
| 5.7 | Port mapping | `127.0.0.1:` binding |
| 5.10 | Memory limits | `deploy.resources.limits.memory` |
| 5.11 | CPU limits | `deploy.resources.limits.cpus` |
| 5.12 | Read-only rootfs | `read_only: true` |
| 5.15 | No-new-privileges | `security_opt` |
| 5.25 | Network restriction | Named networks, `internal: true` |
| 5.26 | Health check | Every service |
| 5.28 | PIDs limit | `--pids-limit` |
| 5.31 | No socket mount | Never expose daemon socket |

---

## Threat Model

```
Attack Vector              → Control
──────────────────────────────────────────
Container escape (kernel)  → Patch host+Docker, rootless mode, DHI
Privilege escalation       → Non-root, cap_drop ALL, no-new-privileges
Lateral movement           → Network segmentation, internal networks
Resource exhaustion        → Memory/CPU/PIDs limits, restart policy
Secret exposure            → Docker secrets, not env vars
Supply chain attack        → DHI/trusted bases, Content Trust, scanning
Runtime code injection     → Read-only FS, tmpfs noexec
Docker socket escape       → Never mount /var/run/docker.sock
Image vulnerabilities      → Trivy/Scout scanning in CI, weekly rebuilds
```
