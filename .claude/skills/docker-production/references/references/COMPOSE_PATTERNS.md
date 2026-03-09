# Compose Patterns Reference

Production-grade patterns aligned with the Compose Specification (rolling spec), Compose v5 CLI, and Docker Engine v28. All patterns use modern syntax — no `version:` field, `compose.yaml` filename.

---

## File Conventions

| Convention | Correct | Wrong |
|---|---|---|
| Filename | `compose.yaml` | `docker-compose.yml` |
| Version field | **Omit entirely** | `version: '3.8'` |
| CLI | `docker compose up` | `docker-compose up` |
| Spec | Compose Specification (rolling) | File format 2.x / 3.x |

---

## Service Template (Production-Hardened)

Every production service includes ALL of these sections:

```yaml
services:
  app:
    # ── Image / Build ──
    build:
      context: .
      target: production
    image: myapp:${TAG:-latest}

    # ── Lifecycle ──
    restart: unless-stopped
    init: true                          # tini for PID 1 signal handling
    stop_grace_period: 30s

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
      test: ["CMD", "<command>"]
      interval: 30s
      timeout: 5s
      retries: 3
      start_period: 30s
      start_interval: 5s               # Compose ≥ 2.20.2: probe faster during startup

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
        restart: true                   # Compose ≥ 2.17: restart when dep restarts

    # ── Configuration ──
    environment:
      NODE_ENV: production
    secrets:
      - db_password
    env_file:
      - .env                            # non-sensitive config only

    # ── Logging ──
    logging:
      driver: json-file
      options:
        max-size: "10m"
        max-file: "5"
        tag: "{{.Name}}"
```

---

## Network Patterns

### Standard App + Database
```yaml
networks:
  frontend:
    driver: bridge
  backend:
    driver: bridge
    internal: true          # no internet, no host access
```

### Three-Tier with Monitoring
```yaml
networks:
  frontend:
    driver: bridge
  backend:
    driver: bridge
    internal: true
  monitoring:
    driver: bridge
    internal: true

services:
  reverse-proxy:
    networks: [frontend]
  app:
    networks: [frontend, backend]
  db:
    networks: [backend]
  redis:
    networks: [backend]
  prometheus:
    networks: [monitoring, backend]
```

**Rule:** Databases, caches, queues → `internal: true` only. Only the app bridges frontend and backend.

---

## Volume Patterns

```yaml
volumes:
  db_data:
    driver: local
    labels:
      com.example.description: "PostgreSQL data"
      com.example.backup: "daily"

services:
  db:
    volumes:
      - db_data:/var/lib/postgresql/data
```

For dev bind mounts:
```yaml
services:
  app:
    volumes:
      - ./src:/app/src:ro               # read-only source mount
      - /app/node_modules               # anonymous vol prevents overwrite
```

---

## Secrets Patterns

### File-Based (Dev / Single Server)
```yaml
secrets:
  db_password:
    file: ./secrets/db_password.txt
  api_key:
    file: ./secrets/api_key.txt

services:
  app:
    secrets: [db_password, api_key]
    environment:
      DB_PASSWORD_FILE: /run/secrets/db_password
      API_KEY_FILE: /run/secrets/api_key
```

### Environment-Sourced
```yaml
secrets:
  db_password:
    environment: DB_PASSWORD            # reads from host env
```

### Application Secret Readers
```javascript
// Node.js
const fs = require('fs');
function readSecret(name) {
  const path = process.env[`${name}_FILE`] || `/run/secrets/${name.toLowerCase()}`;
  try { return fs.readFileSync(path, 'utf8').trim(); }
  catch { return process.env[name] || ''; }
}
```
```python
# Python
from pathlib import Path
import os
def read_secret(name: str) -> str:
    path = os.environ.get(f"{name}_FILE", f"/run/secrets/{name.lower()}")
    try: return Path(path).read_text().strip()
    except FileNotFoundError: return os.environ.get(name, "")
```

Official images with `_FILE` suffix support: PostgreSQL, MySQL, MariaDB, Redis, MongoDB, RabbitMQ, and more.

---

## Healthcheck Patterns by Service

### PostgreSQL
```yaml
healthcheck:
  test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER:-postgres} -d ${POSTGRES_DB:-postgres}"]
  interval: 10s
  timeout: 5s
  retries: 5
  start_period: 30s
  start_interval: 3s
```

### MySQL / MariaDB
```yaml
healthcheck:
  test: ["CMD", "healthcheck.sh", "--connect", "--innodb_initialized"]
  interval: 10s
  timeout: 5s
  retries: 5
  start_period: 60s
  start_interval: 5s
```

### Redis
```yaml
healthcheck:
  test: ["CMD", "redis-cli", "ping"]
  interval: 10s
  timeout: 5s
  retries: 5
  start_period: 10s
```

### MongoDB
```yaml
healthcheck:
  test: ["CMD", "mongosh", "--eval", "db.adminCommand('ping')"]
  interval: 10s
  timeout: 5s
  retries: 5
  start_period: 30s
```

### RabbitMQ
```yaml
healthcheck:
  test: ["CMD", "rabbitmq-diagnostics", "-q", "ping"]
  interval: 30s
  timeout: 10s
  retries: 5
  start_period: 60s
```

### Elasticsearch / OpenSearch
```yaml
healthcheck:
  test: ["CMD-SHELL", "curl -sf http://localhost:9200/_cluster/health || exit 1"]
  interval: 30s
  timeout: 10s
  retries: 5
  start_period: 60s
```

### Node.js (without curl)
```yaml
healthcheck:
  test: ["CMD", "node", "-e", "fetch('http://localhost:3000/health').then(r=>{if(!r.ok)throw r})"]
  interval: 30s
  timeout: 5s
  retries: 3
  start_period: 30s
  start_interval: 5s
```

### Python (without curl)
```yaml
healthcheck:
  test: ["CMD", "python", "-c", "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')"]
  interval: 30s
  timeout: 5s
  retries: 3
  start_period: 30s
  start_interval: 5s
```

---

## depends_on Conditions

```yaml
services:
  app:
    depends_on:
      db:
        condition: service_healthy              # wait for healthcheck pass
        restart: true                           # restart app when db restarts
      redis:
        condition: service_started              # just wait for container start
      migration:
        condition: service_completed_successfully  # wait for one-shot task
```

### Migration Pattern
```yaml
services:
  db:
    # ... healthcheck config

  migration:
    build: .
    command: ["npm", "run", "migrate"]
    depends_on:
      db:
        condition: service_healthy
    restart: "no"                               # one-shot task

  app:
    depends_on:
      db:
        condition: service_healthy
      migration:
        condition: service_completed_successfully
```

---

## Dev / Prod Split

**compose.yaml** — production base:
```yaml
services:
  app:
    image: myapp:latest
    restart: unless-stopped
    read_only: true
    # ... full security hardening
```

**compose.override.yaml** — dev (auto-loaded by `docker compose up`):
```yaml
services:
  app:
    build:
      context: .
      target: development
    restart: "no"
    read_only: false
    volumes:
      - ./src:/app/src
    ports:
      - "3000:3000"
      - "9229:9229"                    # debug port
    environment:
      NODE_ENV: development
```

Production deploy (skips override):
```bash
docker compose -f compose.yaml up -d
```

---

## Compose Watch (Hot Reload for Dev)

```yaml
services:
  app:
    build:
      context: .
      target: development
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

Actions: `sync` (rsync files in), `sync+restart` (sync then restart container), `rebuild` (rebuild image).

---

## Reverse Proxy Patterns

### Traefik (Auto-Discovery)
```yaml
services:
  traefik:
    image: traefik:v3.3
    restart: unless-stopped
    command:
      - "--providers.docker=true"
      - "--providers.docker.exposedByDefault=false"
      - "--entrypoints.web.address=:80"
      - "--entrypoints.websecure.address=:443"
      - "--certificatesresolvers.le.acme.tlschallenge=true"
      - "--certificatesresolvers.le.acme.email=admin@example.com"
      - "--certificatesresolvers.le.acme.storage=/letsencrypt/acme.json"
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - letsencrypt:/letsencrypt
    networks: [frontend]

  app:
    labels:
      traefik.enable: "true"
      traefik.http.routers.app.rule: "Host(`app.example.com`)"
      traefik.http.routers.app.entrypoints: "websecure"
      traefik.http.routers.app.tls.certresolver: "le"
    networks: [frontend, backend]
```

⚠️ Traefik needs docker socket — mount read-only. Consider `tecnativa/docker-socket-proxy` for defense in depth.

### Caddy (Automatic HTTPS)
```yaml
services:
  caddy:
    image: caddy:2-alpine
    restart: unless-stopped
    cap_drop: [ALL]
    cap_add: [NET_BIND_SERVICE]
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile:ro
      - caddy_data:/data
      - caddy_config:/config
    networks: [frontend]
```

---

## Common Sidecar Configs (Copy-Paste Ready)

### PostgreSQL
```yaml
  db:
    image: postgres:17-alpine
    restart: unless-stopped
    read_only: true
    security_opt: [no-new-privileges:true]
    cap_drop: [ALL]
    cap_add: [DAC_OVERRIDE, FOWNER, SETGID, SETUID]
    tmpfs:
      - /tmp:noexec,nosuid,size=64m
      - /run/postgresql:noexec,nosuid,size=16m
    volumes:
      - db_data:/var/lib/postgresql/data
    networks: [backend]
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER:-postgres}"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 30s
      start_interval: 3s
    secrets: [db_password]
    environment:
      POSTGRES_DB: app
      POSTGRES_USER: app
      POSTGRES_PASSWORD_FILE: /run/secrets/db_password
    deploy:
      resources:
        limits: { cpus: "1.0", memory: 1G }
        reservations: { cpus: "0.25", memory: 256M }
    logging:
      driver: json-file
      options: { max-size: "10m", max-file: "5" }
```

### Redis
```yaml
  redis:
    image: redis:7-alpine
    restart: unless-stopped
    read_only: true
    security_opt: [no-new-privileges:true]
    cap_drop: [ALL]
    cap_add: [SETGID, SETUID]
    command: ["redis-server", "--maxmemory", "256mb", "--maxmemory-policy", "allkeys-lru"]
    volumes:
      - redis_data:/data
    networks: [backend]
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 10s
    deploy:
      resources:
        limits: { cpus: "0.5", memory: 512M }
    logging:
      driver: json-file
      options: { max-size: "10m", max-file: "5" }
```
