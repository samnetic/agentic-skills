# Reverse Proxy Patterns

Production-grade reverse proxy configurations for Docker Compose. Covers Traefik v3 (recommended for Docker-native auto-discovery) and Caddy (simpler config).

---

## Decision: Traefik vs Caddy

```
Feature                    Traefik v3               Caddy v2
────────────────────────────────────────────────────────────
Docker auto-discovery      ✅ native (labels)       ❌ manual config
Let's Encrypt              ✅ ACME (HTTP/DNS/TLS)   ✅ automatic
Config style               labels + file providers  Caddyfile/JSON
Rate limiting              ✅ built-in middleware    via plugins
Canary/A-B routing         ✅ weighted round-robin   ❌
Dashboard                  ✅ built-in               ❌
Complexity                 Medium                   Low
Best for                   Dynamic Docker stacks    Simple sites/APIs
```

**Recommendation:** Traefik for Docker Compose (auto-discovers containers via labels). Caddy for simpler setups or when you prefer declarative config files.

---

## Traefik v3 — Complete Production Setup

### Traefik Service (with Socket Proxy)

```yaml
services:
  # ─── Socket Proxy (OWASP #1: never mount docker.sock directly) ───
  socket-proxy:
    image: tecnativa/docker-socket-proxy:latest
    restart: unless-stopped
    read_only: true
    cap_drop: [ALL]
    security_opt: [no-new-privileges:true]
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
    environment:
      CONTAINERS: 1
      NETWORKS: 1
      POST: 0
    networks: [socket-proxy]
    deploy:
      resources:
        limits: { cpus: "0.25", memory: 128M }

  # ─── Traefik v3 ───
  traefik:
    image: traefik:v3.3
    restart: unless-stopped
    read_only: true
    security_opt: [no-new-privileges:true]
    cap_drop: [ALL]
    cap_add: [NET_BIND_SERVICE]
    depends_on: [socket-proxy]
    command:
      # ── API / Dashboard ──
      - "--api.dashboard=true"
      - "--api.insecure=false"

      # ── Docker Provider (via socket proxy) ──
      - "--providers.docker=true"
      - "--providers.docker.endpoint=tcp://socket-proxy:2375"
      - "--providers.docker.exposedByDefault=false"
      - "--providers.docker.network=frontend"

      # ── File Provider (middlewares, TLS options) ──
      - "--providers.file.directory=/etc/traefik/dynamic"
      - "--providers.file.watch=true"

      # ── Entrypoints ──
      - "--entrypoints.web.address=:80"
      - "--entrypoints.web.http.redirections.entryPoint.to=websecure"
      - "--entrypoints.web.http.redirections.entryPoint.scheme=https"
      - "--entrypoints.websecure.address=:443"
      - "--entrypoints.websecure.http.tls.certresolver=letsencrypt"

      # ── Let's Encrypt ──
      - "--certificatesresolvers.letsencrypt.acme.email=${ACME_EMAIL}"
      - "--certificatesresolvers.letsencrypt.acme.storage=/letsencrypt/acme.json"
      - "--certificatesresolvers.letsencrypt.acme.tlschallenge=true"

      # ── Logging ──
      - "--log.level=WARN"
      - "--accesslog=true"
      - "--accesslog.filepath=/logs/access.log"
      - "--accesslog.bufferingsize=100"

    ports:
      - "80:80"
      - "443:443"
    volumes:
      - traefik_certs:/letsencrypt
      - ./traefik/dynamic:/etc/traefik/dynamic:ro
      - ./logs/traefik:/logs
    tmpfs:
      - /tmp:noexec,nosuid,size=32m
    networks:
      - socket-proxy
      - frontend
    labels:
      traefik.enable: "true"
      # Dashboard behind auth
      traefik.http.routers.dashboard.rule: "Host(`traefik.${DOMAIN}`)"
      traefik.http.routers.dashboard.service: "api@internal"
      traefik.http.routers.dashboard.entrypoints: "websecure"
      traefik.http.routers.dashboard.tls.certresolver: "letsencrypt"
      traefik.http.routers.dashboard.middlewares: "auth@file,security-headers@file,rate-limit@file"
    healthcheck:
      test: ["CMD", "traefik", "healthcheck", "--ping"]
      interval: 30s
      timeout: 5s
      retries: 3
    deploy:
      resources:
        limits: { cpus: "1.0", memory: 256M }

volumes:
  traefik_certs:

networks:
  socket-proxy:
    driver: bridge
    internal: true
  frontend:
    driver: bridge
```

### Security Headers Middleware (dynamic file provider)

Create `traefik/dynamic/security-headers.yml`:

```yaml
http:
  middlewares:
    security-headers:
      headers:
        browserXssFilter: true
        contentTypeNosniff: true
        frameDeny: true
        stsIncludeSubdomains: true
        stsPreload: true
        stsSeconds: 31536000
        customFrameOptionsValue: "SAMEORIGIN"
        referrerPolicy: "strict-origin-when-cross-origin"
        permissionsPolicy: "camera=(), microphone=(), geolocation=(), interest-cohort=()"
        customResponseHeaders:
          X-Robots-Tag: "noindex, nofollow"
          server: ""    # hide server header
```

### Rate Limiting Middleware

Create `traefik/dynamic/rate-limit.yml`:

```yaml
http:
  middlewares:
    rate-limit:
      rateLimit:
        average: 100     # requests per second
        burst: 50        # burst capacity
        period: 1s
    rate-limit-strict:
      rateLimit:
        average: 10
        burst: 20
        period: 1s
```

### Basic Auth Middleware

Create `traefik/dynamic/auth.yml`:

```yaml
http:
  middlewares:
    auth:
      basicAuth:
        users:
          - "${TRAEFIK_DASHBOARD_AUTH}"
        # Generate with: htpasswd -nB admin
```

### TLS Options

Create `traefik/dynamic/tls-options.yml`:

```yaml
tls:
  options:
    default:
      minVersion: VersionTLS12
      sniStrict: true
      cipherSuites:
        - TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384
        - TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384
        - TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305
        - TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305
    modern:
      minVersion: VersionTLS13
```

---

## Adding Services Behind Traefik

```yaml
services:
  app:
    image: ghcr.io/myorg/app:v1.2.3
    restart: unless-stopped
    read_only: true
    security_opt: [no-new-privileges:true]
    cap_drop: [ALL]
    user: "10001:10001"
    init: true
    stop_grace_period: 30s
    # NO ports: section — Traefik routes via internal network
    labels:
      traefik.enable: "true"
      traefik.http.routers.app.rule: "Host(`app.${DOMAIN}`)"
      traefik.http.routers.app.entrypoints: "websecure"
      traefik.http.routers.app.tls.certresolver: "letsencrypt"
      traefik.http.routers.app.middlewares: "security-headers@file,rate-limit@file"
      traefik.http.services.app.loadbalancer.server.port: "3000"
      traefik.http.services.app.loadbalancer.healthCheck.path: "/health"
      traefik.http.services.app.loadbalancer.healthCheck.interval: "10s"
    healthcheck:
      test: ["CMD", "node", "-e", "fetch('http://localhost:3000/health').then(r=>{if(!r.ok)throw r})"]
      interval: 10s
      timeout: 5s
      retries: 3
      start_period: 30s
      start_interval: 3s
    networks: [frontend, backend]
    deploy:
      resources:
        limits: { cpus: "1.0", memory: 512M }
```

**Key patterns:**
- No `ports:` section — containers not directly exposed
- Traefik discovers services via labels on the `frontend` network
- Backend services (DB, Redis) stay on `backend` network only
- Middlewares applied per-router via labels
- Healthcheck path exposed to Traefik for load balancing

---

## Caddy — Alternative Setup

```yaml
services:
  caddy:
    image: caddy:2.9-alpine
    restart: unless-stopped
    read_only: true
    security_opt: [no-new-privileges:true]
    cap_drop: [ALL]
    cap_add: [NET_BIND_SERVICE]
    ports:
      - "80:80"
      - "443:443"
      - "443:443/udp"    # HTTP/3
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile:ro
      - caddy_data:/data
      - caddy_config:/config
    networks: [frontend]
    healthcheck:
      test: ["CMD", "wget", "-qO-", "http://localhost:2019/config/"]
      interval: 30s
      timeout: 5s
      retries: 3
    deploy:
      resources:
        limits: { cpus: "0.5", memory: 256M }

volumes:
  caddy_data:
  caddy_config:
```

### Caddyfile

```
{
    email {$ACME_EMAIL}
}

app.example.com {
    reverse_proxy app:3000 {
        health_uri /health
        health_interval 10s
    }
    header {
        Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"
        X-Content-Type-Options "nosniff"
        X-Frame-Options "DENY"
        Referrer-Policy "strict-origin-when-cross-origin"
        -Server
    }
    rate_limit {
        zone dynamic_zone {
            key {remote_host}
            events 100
            window 1s
        }
    }
}
```

---

## IP Allowlisting (Internal Services)

```yaml
    labels:
      traefik.http.middlewares.internal-only.ipallowlist.sourcerange: "10.0.0.0/8,172.16.0.0/12,192.168.0.0/16"
      traefik.http.routers.admin.middlewares: "internal-only@docker,security-headers@file"
```

---

## Middleware Chains (Reusable Combos)

Create `traefik/dynamic/chains.yml`:

```yaml
http:
  middlewares:
    secure-chain:
      chain:
        middlewares:
          - security-headers@file
          - rate-limit@file
    admin-chain:
      chain:
        middlewares:
          - auth@file
          - security-headers@file
          - rate-limit-strict@file
```

Use in labels:
```yaml
    labels:
      traefik.http.routers.app.middlewares: "secure-chain@file"
```
