# Production Operations Reference

Patterns for running Docker Compose in production on a single server: zero-downtime deployments, graceful shutdown, backup strategies, monitoring, Docker socket proxy, and operational runbooks.

---

## Graceful Shutdown & Signal Handling

The #1 cause of dropped requests during deploys is improper signal handling. Docker sends SIGTERM to PID 1, waits `stop_grace_period` (default 10s), then SIGKILL.

### The PID 1 Problem

```dockerfile
# ❌ Shell form — sh is PID 1, swallows SIGTERM, app never sees it
CMD npm start

# ❌ npm/yarn wrapper — doesn't forward signals to node
CMD ["npm", "start"]

# ✅ Exec form — node is PID 1, receives SIGTERM directly
CMD ["node", "dist/server.js"]

# ✅ Best — use init: true in compose + exec form CMD
# tini as PID 1 handles: signal forwarding + zombie reaping
```

### compose.yaml Signal Config

```yaml
services:
  app:
    init: true                # tini as PID 1 (handles signals + zombies)
    stop_grace_period: 30s    # time before SIGKILL (default 10s is too short)
    # stop_signal: SIGTERM    # default; use SIGQUIT for nginx/php-fpm
```

### Entrypoint Script Pattern (When Needed)

If you need an entrypoint script (reading secrets, env setup), use `exec` to replace the shell:

```bash
#!/bin/sh
set -e

# Read secrets into env vars
if [ -f /run/secrets/db_password ]; then
  export DB_PASSWORD=$(cat /run/secrets/db_password)
fi

# Wait for dependencies (optional)
# Use depends_on with service_healthy in compose instead when possible

# CRITICAL: exec replaces this shell with the app process
# Without exec, the shell stays as PID 1 and swallows signals
exec "$@"
```

```dockerfile
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["node", "dist/server.js"]
```

### Application-Level Graceful Shutdown

```javascript
// Node.js — production graceful shutdown
const server = app.listen(3000);
let isShuttingDown = false;

const shutdown = async (signal) => {
  console.log(`Received ${signal}, starting graceful shutdown`);
  isShuttingDown = true;

  // Stop accepting new connections
  server.close(async () => {
    // Close DB connections, flush queues, etc.
    await db.end();
    console.log('Graceful shutdown complete');
    process.exit(0);
  });

  // Force exit if graceful shutdown takes too long
  setTimeout(() => process.exit(1), 25000);
};

process.on('SIGTERM', () => shutdown('SIGTERM'));
process.on('SIGINT', () => shutdown('SIGINT'));

// Health endpoint returns 503 during shutdown
app.get('/health', (req, res) => {
  if (isShuttingDown) return res.status(503).json({ status: 'shutting down' });
  res.json({ status: 'healthy' });
});
```

```python
# Python (uvicorn)
import signal, asyncio

async def shutdown(sig, loop):
    print(f"Received {sig.name}, shutting down...")
    tasks = [t for t in asyncio.all_tasks() if t is not asyncio.current_task()]
    [task.cancel() for task in tasks]
    await asyncio.gather(*tasks, return_exceptions=True)
    loop.stop()

loop = asyncio.get_event_loop()
for sig in (signal.SIGTERM, signal.SIGINT):
    loop.add_signal_handler(sig, lambda s=sig: asyncio.create_task(shutdown(s, loop)))
```

---

## Zero-Downtime Deployments

### Method 1: docker-rollout (Simplest)

[docker-rollout](https://github.com/wowu/docker-rollout) is a CLI plugin that does rolling updates for Docker Compose.

```bash
# Install
curl -fsSL https://github.com/wowu/docker-rollout/releases/latest/download/docker-rollout \
  -o ~/.docker/cli-plugins/docker-rollout && chmod +x ~/.docker/cli-plugins/docker-rollout

# Deploy with zero downtime
docker rollout app

# How it works:
# 1. Scales service to 2 instances
# 2. Waits for new container to pass healthcheck
# 3. Removes old container
# Requires: healthcheck on service, reverse proxy (Traefik/Caddy) in front
```

**Requirements:**
- Healthcheck defined on the service
- No `container_name:` set (prevents scaling)
- Reverse proxy (Traefik/Caddy) auto-discovers containers
- `restart: unless-stopped` (not `always`)

### Method 2: Blue-Green with Traefik

```yaml
services:
  traefik:
    image: traefik:v3.3
    command:
      - "--providers.docker=true"
      - "--providers.docker.exposedByDefault=false"
    ports: ["80:80", "443:443"]
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
    networks: [frontend]

  app:
    image: ghcr.io/myorg/app:${TAG:-latest}
    labels:
      traefik.enable: "true"
      traefik.http.routers.app.rule: "Host(`app.example.com`)"
      traefik.http.services.app.loadbalancer.server.port: "3000"
    healthcheck:
      test: ["CMD", "node", "-e", "fetch('http://localhost:3000/health').then(r=>{if(!r.ok)throw r})"]
      interval: 10s
      timeout: 5s
      retries: 3
      start_period: 30s
      start_interval: 3s
    networks: [frontend, backend]
```

**Deploy script:**
```bash
#!/bin/bash
set -euo pipefail

TAG="${1:?Usage: deploy.sh <tag>}"
export TAG

# Pull new image
docker compose pull app

# Rolling update via docker-rollout (zero downtime)
docker rollout app

# Or manual blue-green:
# docker compose up -d --no-deps --scale app=2 app
# sleep 30  # wait for healthcheck
# docker compose up -d --no-deps --scale app=1 app
```

### Method 3: Manual Scale-and-Swap

```bash
# Build new image
docker compose build app

# Scale to 2 (old + new)
docker compose up -d --no-deps --scale app=2 --no-recreate app

# Wait for new container to be healthy
until docker compose ps app | grep -q "healthy"; do sleep 2; done

# Remove old container
OLD_CONTAINER=$(docker compose ps -q app | head -1)
docker stop "$OLD_CONTAINER" && docker rm "$OLD_CONTAINER"

# Scale back to 1
docker compose up -d --no-deps --scale app=1 app
```

---

## Docker Socket Proxy

When a service MUST access the Docker API (Traefik, Watchtower, auto-discovery), NEVER mount the socket directly. Use a socket proxy.

```yaml
services:
  socket-proxy:
    image: tecnativa/docker-socket-proxy:latest
    restart: unless-stopped
    read_only: true
    security_opt: [no-new-privileges:true]
    cap_drop: [ALL]
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
    environment:
      # Deny everything by default, enable only what's needed
      CONTAINERS: 1     # Traefik needs this
      NETWORKS: 1       # Traefik needs this
      SERVICES: 0
      TASKS: 0
      POST: 0           # read-only — critical
      BUILD: 0
      COMMIT: 0
      CONFIGS: 0
      DISTRIBUTION: 0
      EXEC: 0
      IMAGES: 0
      INFO: 0
      NODES: 0
      PLUGINS: 0
      SECRETS: 0
      SWARM: 0
      SYSTEM: 0
      VOLUMES: 0
    networks:
      - socket-proxy     # isolated network

  traefik:
    image: traefik:v3.3
    command:
      - "--providers.docker.endpoint=tcp://socket-proxy:2375"
      - "--providers.docker.exposedByDefault=false"
    depends_on: [socket-proxy]
    networks:
      - socket-proxy     # only to reach socket-proxy
      - frontend
    # NO docker.sock volume mount!

networks:
  socket-proxy:
    driver: bridge
    internal: true       # no internet access for socket proxy network
```

---

## Volume Backup Strategies

### PostgreSQL — pg_dump

```yaml
services:
  backup:
    image: postgres:17-alpine
    restart: "no"
    profiles: [backup]           # only runs when explicitly invoked
    depends_on:
      db:
        condition: service_healthy
    volumes:
      - ./backups:/backups
    secrets: [db_password]
    entrypoint: >
      sh -c 'PGPASSWORD=$$(cat /run/secrets/db_password) pg_dump
      -h db -U app -d app -F c -f /backups/db_$$(date +%Y%m%d_%H%M%S).dump'
    networks: [backend]
```

```bash
# Run backup
docker compose --profile backup run --rm backup

# Restore
docker compose exec db pg_restore -U app -d app /backups/db_20260215.dump
```

### Generic Volume Backup

```bash
#!/bin/bash
# backup-volumes.sh
BACKUP_DIR="./backups/$(date +%Y%m%d)"
mkdir -p "$BACKUP_DIR"

for volume in $(docker volume ls -q --filter "label=com.example.backup=daily"); do
  docker run --rm \
    -v "${volume}:/data:ro" \
    -v "${BACKUP_DIR}:/backup" \
    alpine tar czf "/backup/${volume}.tar.gz" -C /data .
done

# Prune old backups (keep 30 days)
find ./backups -type d -mtime +30 -exec rm -rf {} +
```

### Automated Backup with Cron

```yaml
services:
  backup-cron:
    image: postgres:17-alpine
    restart: unless-stopped
    entrypoint: >
      sh -c 'while true; do
        PGPASSWORD=$$(cat /run/secrets/db_password) pg_dump -h db -U app -d app -F c
          -f /backups/db_$$(date +%Y%m%d_%H%M%S).dump &&
        find /backups -name "*.dump" -mtime +7 -delete;
        sleep 86400;
      done'
    volumes:
      - ./backups:/backups
    secrets: [db_password]
    networks: [backend]
    deploy:
      resources:
        limits: { cpus: "0.25", memory: 256M }
```

---

## Monitoring & Observability

### Prometheus + Grafana Stack

```yaml
services:
  prometheus:
    image: prom/prometheus:v2.53.0
    restart: unless-stopped
    read_only: true
    security_opt: [no-new-privileges:true]
    cap_drop: [ALL]
    user: "65534:65534"        # nobody
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml:ro
      - prometheus_data:/prometheus
    tmpfs:
      - /tmp:noexec,nosuid,size=64m
    networks: [monitoring]
    healthcheck:
      test: ["CMD", "wget", "-qO-", "http://localhost:9090/-/healthy"]
      interval: 30s
      timeout: 5s
      retries: 3
    deploy:
      resources:
        limits: { cpus: "0.5", memory: 512M }

  grafana:
    image: grafana/grafana:11.4.0
    restart: unless-stopped
    read_only: true
    security_opt: [no-new-privileges:true]
    cap_drop: [ALL]
    user: "472:472"
    volumes:
      - grafana_data:/var/lib/grafana
    tmpfs:
      - /tmp:noexec,nosuid,size=64m
    networks: [monitoring, frontend]
    environment:
      GF_SECURITY_ADMIN_PASSWORD__FILE: /run/secrets/grafana_password
    secrets: [grafana_password]
    healthcheck:
      test: ["CMD", "wget", "-qO-", "http://localhost:3000/api/health"]
      interval: 30s
      timeout: 5s
      retries: 3
    deploy:
      resources:
        limits: { cpus: "0.5", memory: 512M }

  cadvisor:
    image: gcr.io/cadvisor/cadvisor:v0.49.1
    restart: unless-stopped
    read_only: true
    security_opt: [no-new-privileges:true]
    cap_drop: [ALL]
    cap_add: [SYS_PTRACE]      # needed for process monitoring
    volumes:
      - /:/rootfs:ro
      - /var/run:/var/run:ro
      - /sys:/sys:ro
      - /var/lib/docker/:/var/lib/docker:ro
    networks: [monitoring]
    deploy:
      resources:
        limits: { cpus: "0.25", memory: 256M }

volumes:
  prometheus_data:
  grafana_data:
```

### Application Health Endpoint Pattern

```javascript
// Comprehensive health endpoint
app.get('/health', async (req, res) => {
  const checks = {};
  let healthy = true;

  // Database
  try {
    await db.query('SELECT 1');
    checks.database = 'ok';
  } catch (e) {
    checks.database = 'error';
    healthy = false;
  }

  // Redis
  try {
    await redis.ping();
    checks.redis = 'ok';
  } catch (e) {
    checks.redis = 'error';
    healthy = false;
  }

  // Memory
  const mem = process.memoryUsage();
  checks.memory_mb = Math.round(mem.rss / 1024 / 1024);

  res.status(healthy ? 200 : 503).json({
    status: healthy ? 'healthy' : 'degraded',
    checks,
    uptime: process.uptime(),
    version: process.env.APP_VERSION || 'unknown'
  });
});
```

---

## Log Aggregation

### Structured JSON Logging

Configure your app to output structured JSON to stdout:

```javascript
// Node.js — pino structured logging
const pino = require('pino');
const logger = pino({ level: 'info' });
logger.info({ event: 'request', method: 'GET', path: '/api', duration: 42 });
```

### Docker Logging Driver

```yaml
services:
  app:
    logging:
      driver: json-file
      options:
        max-size: "10m"
        max-file: "5"
        tag: "{{.Name}}"
```

For external aggregation (Loki, ELK, etc.):
```yaml
    logging:
      driver: fluentd
      options:
        fluentd-address: "localhost:24224"
        tag: "app.{{.Name}}"
```

---

## Production Runbook

### Deployment Checklist

```
1. docker compose pull                    # pull latest images
2. docker compose build                   # build app images
3. docker compose run --rm migrate        # run DB migrations
4. docker rollout app                     # zero-downtime deploy
5. docker compose ps                      # verify all healthy
6. docker compose logs -f --tail=100 app  # check for errors
```

### Emergency Rollback

```bash
# Rollback to previous image
docker compose down app
docker compose up -d app           # if previous image still cached

# Or pin to a known-good digest
TAG=v1.2.2 docker compose up -d app
```

### Diagnostics

```bash
# Check all service health
docker compose ps

# Resource usage
docker stats --no-stream

# Inspect a troubled container
docker compose logs --tail=200 app
docker compose exec app sh         # if shell available
docker debug app                   # if using DHI (no shell)

# Network connectivity
docker compose exec app wget -qO- http://db:5432 || echo "DB unreachable"

# Disk usage
docker system df
docker system prune --volumes      # CAREFUL: removes stopped + unused
```

### Maintenance

```bash
# Update base images
docker compose pull
docker compose build --pull
docker compose up -d

# Prune unused images (keep last 2 versions)
docker image prune -a --filter "until=168h"

# Rotate secrets
# 1. Update secret file
echo "new_password" > secrets/db_password.txt
# 2. Recreate secrets (compose secrets are immutable)
docker compose down
docker compose up -d
```

---

## Host Hardening Checklist

- [ ] Docker Engine updated to latest stable (v28.x or v29.x)
- [ ] Rootless Docker configured (or user namespaces enabled)
- [ ] Firewall blocks all except 80/443 (and SSH)
- [ ] SSH key-only auth, no root login
- [ ] Automatic security updates enabled on host
- [ ] Docker daemon configured for TLS if remote access needed
- [ ] No containers run with `--privileged`
- [ ] Docker socket NOT mounted (use socket-proxy if needed)
- [ ] Logging shipped to external system
- [ ] Monitoring alerts configured (disk, memory, container health)
- [ ] Automated volume backups with retention policy
- [ ] Automated image rebuilds (weekly) to pick up patches
