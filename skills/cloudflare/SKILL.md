---
name: cloudflare
description: >-
  Cloudflare platform expertise — DNS, CDN, security, and edge computing. Use when
  configuring Cloudflare DNS records (proxy vs DNS-only), setting SSL/TLS modes
  (always Full Strict), configuring WAF rules and managed rulesets, designing caching
  strategies (cache rules, TTLs, purge), building Cloudflare Workers and Pages,
  using R2 object storage, setting up Zero Trust and Cloudflare Tunnels, configuring
  DDoS protection and rate limiting, managing bot traffic, implementing Transform
  Rules, configuring security headers via Workers, managing DNS for email
  (SPF/DKIM/DMARC), using the Cloudflare API and Terraform provider, or reviewing
  Cloudflare configuration for security and performance.
  Triggers: Cloudflare, DNS, CDN, WAF, firewall rules, SSL, TLS, Full Strict,
  origin certificate, Workers, Pages, R2, KV, D1, Durable Objects, Zero Trust,
  Tunnel, cloudflared, DDoS, rate limiting, bot management, cache, purge,
  page rules, transform rules, DNSSEC, SPF, DKIM, DMARC, wrangler.
---

# Cloudflare Skill

Proxy everything. Encrypt everything. Cache aggressively. Protect the origin.
Cloudflare sits between users and your origin server — configure it correctly
or you create a false sense of security.

---

## Core Principles

| Principle | Meaning |
|---|---|
| **Proxy everything HTTP** | Orange cloud on A/AAAA records — all HTTP traffic through CF |
| **Never proxy email records** | Grey cloud for MX, SPF, DKIM, DMARC — proxying breaks email |
| **Always Full (Strict) SSL** | Origin must have a valid certificate (CF Origin CA or Let's Encrypt) |
| **Hide the origin IP** | Use Tunnel or firewall to CF IPs only — never expose origin directly |
| **Cache aggressively** | But never cache authenticated or personalized content |
| **Defense in depth** | WAF + rate limiting + bot management + DDoS protection — layered |

---

## Setup Workflow

```
1. DNS MIGRATE   → Import records, set proxy mode per record type
2. SSL/TLS       → Full (Strict) + origin certificate + HSTS
3. WAF           → Enable managed rulesets, add custom rules
4. CACHE         → Configure cache rules, set Edge TTL and Browser TTL
5. SECURITY      → Rate limiting, bot management, DDoS settings
6. PERFORMANCE   → Brotli, Early Hints, HTTP/3, image optimization
7. MONITOR       → Analytics, alerts, audit log review
```

---

## DNS Configuration

### Proxy vs DNS-Only Decision Tree

```
Record type?
├─ A / AAAA (web server)
│  ├─ Serves HTTP/HTTPS? → Proxied (orange cloud) ✅
│  ├─ Non-HTTP (SSH, FTP, custom TCP) → DNS-only (grey cloud)
│  └─ Origin IP must be hidden? → Proxied + Tunnel
├─ CNAME → web service: Proxied ✅ / non-HTTP: DNS-only
├─ MX    → DNS-only ✅ ALWAYS — proxying breaks email
├─ TXT (SPF, DKIM, DMARC) → DNS-only ✅ ALWAYS
├─ SRV   → DNS-only — cannot be proxied
└─ CAA   → DNS-only — certificate authority authorization
```

### DNS Record Examples

```
# Web — proxied (orange cloud)
Type  Name     Content              Proxy  TTL
A     @        203.0.113.1          Yes    Auto
A     www      203.0.113.1          Yes    Auto
AAAA  @        2001:db8::1          Yes    Auto
CNAME api      origin.example.com   Yes    Auto

# Email — DNS-only (grey cloud) — NEVER proxy
MX    @        mail.example.com (pri 10)                    No  3600
TXT   @        "v=spf1 include:_spf.google.com ~all"        No  3600
TXT   google._domainkey  "v=DKIM1; k=rsa; p=MIGf..."       No  3600
TXT   _dmarc   "v=DMARC1; p=reject; ..."                   No  3600
```

### DNSSEC

```
Dashboard → DNS → DNSSEC → Enable
Then add DS record at registrar (Cloudflare provides the values)
```

---

## SSL/TLS Configuration

### SSL Mode Decision Tree

```
ALWAYS USE: Full (Strict) + origin certificate

├── Full (Strict)  → ✅ Origin has valid cert (CF Origin CA or Let's Encrypt)
│                     Encryption: Browser ↔ CF ↔ Origin (verified)
├── Full           → ⚠ Self-signed cert on origin. MITM possible
├── Flexible       → ❌ NEVER — no encryption to origin, false security
└── Off            → ❌ NEVER — no encryption at all
```

### Origin CA Certificate

```bash
# Generate: Dashboard → SSL/TLS → Origin Server → Create Certificate
# Choose RSA 2048 or ECDSA P-256, validity 15 years

# Install on origin (nginx)
server {
    listen 443 ssl;
    server_name example.com;
    ssl_certificate     /etc/nginx/ssl/cloudflare-origin.pem;
    ssl_certificate_key /etc/nginx/ssl/cloudflare-origin.key;

    # Only accept Cloudflare IPs (https://www.cloudflare.com/ips/)
    allow 173.245.48.0/20;
    allow 103.21.244.0/22;
    allow 103.22.200.0/22;
    allow 141.101.64.0/18;
    allow 108.162.192.0/18;
    allow 190.93.240.0/20;
    allow 188.114.96.0/20;
    allow 197.234.240.0/22;
    allow 198.41.128.0/17;
    allow 162.158.0.0/15;
    allow 104.16.0.0/13;
    allow 104.24.0.0/14;
    allow 172.64.0.0/13;
    allow 131.0.72.0/22;
    deny all;
}
```

### HSTS and Authenticated Origin Pulls

```
# HSTS: Dashboard → SSL/TLS → Edge Certificates → HSTS
Max-Age: 12 months | includeSubDomains: Yes | Preload: Yes | No-Sniff: Yes

# Authenticated Origin Pulls: Dashboard → SSL/TLS → Origin Server → On
# nginx: ssl_client_certificate /path/cloudflare-pull.pem; ssl_verify_client on;
```

---

## Email DNS — SPF, DKIM, DMARC

All email records MUST be DNS-only (grey cloud).

```
# SPF — authorize senders
TXT  @  "v=spf1 include:_spf.google.com ~all"           # Google Workspace
TXT  @  "v=spf1 include:_spf.google.com include:sendgrid.net ~all"  # Multiple
TXT  @  "v=spf1 -all"                                    # No-email domain

# DKIM — provided by your email service
TXT  google._domainkey  "v=DKIM1; k=rsa; p=MIGfMA0GCSq..."

# DMARC — phase rollout: none → quarantine → reject
TXT  _dmarc  "v=DMARC1; p=none; rua=mailto:dmarc@example.com; pct=100"       # Phase 1
TXT  _dmarc  "v=DMARC1; p=quarantine; rua=mailto:dmarc@example.com; pct=100" # Phase 2
TXT  _dmarc  "v=DMARC1; p=reject; rua=mailto:dmarc@example.com; pct=100"     # Phase 3
```

---

## WAF Configuration

### Managed Rulesets

```
Dashboard → Security → WAF → Managed rules (start in LOG mode)

✅ Cloudflare Managed Ruleset     → Core OWASP protections
✅ Cloudflare OWASP Core Ruleset  → OWASP ModSecurity CRS
✅ Cloudflare Leaked Credentials   → Blocks known-leaked passwords
```

### Custom WAF Rules

```
# Block malicious user agents
(http.user_agent contains "sqlmap") or (http.user_agent contains "nikto") or
(http.user_agent contains "nmap") or (http.user_agent contains "masscan")
→ Action: Block

# Protect admin — IP allowlist
(http.request.uri.path contains "/admin" and not ip.src in {203.0.113.0/24})
→ Action: Block

# Block empty user agents on API
(http.user_agent eq "" and http.request.uri.path contains "/api")
→ Action: Block

# Country-based challenge on API
(ip.geoip.country in {"CN" "RU" "KP"} and http.request.uri.path contains "/api")
→ Action: Managed Challenge

# Block dangerous HTTP methods outside API
(http.request.method in {"TRACE" "DELETE" "PUT" "PATCH"} and
  not http.request.uri.path contains "/api")
→ Action: Block
```

### WAF Rollout Strategy

```
1. Deploy in LOG mode → 2. Monitor 48-72h → 3. Review false positives →
4. Switch to Block/Challenge → 5. Monitor weekly
```

---

## Caching Strategies

### Content Type Decision Tree

```
├─ Static assets (JS, CSS, images, fonts)
│  ├─ Content hash in filename? → Edge: 1 year, Browser: 1 year (immutable)
│  └─ No hash? → Edge: 1 day, Browser: 4 hours
├─ HTML pages
│  ├─ Public (marketing, docs)? → Edge: 1 hour, Browser: 5 minutes
│  └─ Authenticated? → Bypass cache, no-store
├─ API responses
│  ├─ Public data? → Edge: 5 min, Browser: 1 min
│  └─ Private/user-specific? → Bypass cache, no-store
└─ Media (images, video from R2/S3) → Edge: 1 month, Browser: 1 week
```

### Cache Rules (Replaces Page Rules)

```
Dashboard → Caching → Cache Rules

# Rule 1: Static assets
Match: (http.request.uri.path.extension in {"js" "css" "png" "jpg" "svg" "woff2" "ico" "webp"})
Edge TTL: 1 month | Browser TTL: 1 week

# Rule 2: Hashed assets (immutable)
Match: (http.request.uri.path matches ".*\.[a-f0-9]{8,}\..*")
Edge TTL: 1 year | Browser TTL: 1 year

# Rule 3: Never cache authenticated content
Match: (http.cookie contains "session" or http.cookie contains "auth_token")
Cache eligibility: Bypass

# Rule 4: Never cache admin paths
Match: (http.request.uri.path contains "/admin" or http.request.uri.path contains "/dashboard")
Cache eligibility: Bypass
```

### Origin Cache-Control Headers

```typescript
// Express middleware — always set explicit Cache-Control from origin
const cacheHeaders: Record<string, string> = {
  static:  'public, max-age=31536000, immutable',           // hashed assets
  html:    'public, max-age=300, s-maxage=3600',             // 5 min browser, 1 hr CDN
  api:     'public, max-age=60, s-maxage=300',               // 1 min browser, 5 min CDN
  private: 'private, no-store, no-cache, must-revalidate',   // never cache
};
```

### Cache Purge

```bash
# Purge specific URLs (preferred)
curl -X POST "https://api.cloudflare.com/client/v4/zones/{zone_id}/purge_cache" \
  -H "Authorization: Bearer {api_token}" \
  -H "Content-Type: application/json" \
  --data '{"files":["https://example.com/style.css"]}'

# Purge by prefix
--data '{"prefixes":["https://example.com/images/"]}'

# Purge everything (use sparingly)
--data '{"purge_everything":true}'
```

---

## Cloudflare Workers

### Redirect Worker

```javascript
export default {
  async fetch(request) {
    const url = new URL(request.url);
    const redirects = {
      '/old-page': '/new-page',
      '/blog/legacy': '/articles',
    };
    const target = redirects[url.pathname];
    if (target) return Response.redirect(`${url.origin}${target}`, 301);
    return fetch(request);
  },
};
```

### Security Headers Worker

```javascript
export default {
  async fetch(request) {
    const response = await fetch(request);
    const headers = new Headers(response.headers);
    headers.set('Strict-Transport-Security', 'max-age=31536000; includeSubDomains; preload');
    headers.set('X-Content-Type-Options', 'nosniff');
    headers.set('X-Frame-Options', 'DENY');
    headers.set('Referrer-Policy', 'strict-origin-when-cross-origin');
    headers.set('Permissions-Policy', 'camera=(), microphone=(), geolocation=(self)');
    headers.set('Content-Security-Policy',
      "default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline'; " +
      "img-src 'self' data: https:; frame-ancestors 'none'; base-uri 'self';"
    );
    headers.delete('Server');
    headers.delete('X-Powered-By');
    return new Response(response.body, { status: response.status, headers });
  },
};
```

### Rate Limiting with KV

```javascript
// wrangler.toml: [[kv_namespaces]] binding = "RATE_LIMIT", id = "abc123"
export default {
  async fetch(request, env) {
    const ip = request.headers.get('CF-Connecting-IP');
    const key = `ratelimit:${ip}`;
    const current = parseInt(await env.RATE_LIMIT.get(key) || '0');
    const limit = 100, window = 60;

    if (current >= limit) {
      return new Response('Rate limit exceeded', {
        status: 429,
        headers: { 'Retry-After': String(window) },
      });
    }
    await env.RATE_LIMIT.put(key, String(current + 1), { expirationTtl: window });
    return fetch(request);
  },
};
```

### A/B Testing Worker

```javascript
export default {
  async fetch(request) {
    const url = new URL(request.url);
    const cookie = request.headers.get('Cookie') || '';
    let variant = cookie.match(/ab-variant=(A|B)/)?.[1];
    if (!variant) variant = Math.random() < 0.5 ? 'A' : 'B';

    if (variant === 'B' && url.pathname === '/') url.pathname = '/landing-v2';

    const response = await fetch(url.toString(), request);
    const newResponse = new Response(response.body, response);
    if (!cookie.includes('ab-variant')) {
      newResponse.headers.append('Set-Cookie',
        `ab-variant=${variant}; Path=/; Max-Age=2592000; SameSite=Lax; Secure; HttpOnly`
      );
    }
    return newResponse;
  },
};
```

### Geolocation Routing Worker

```javascript
export default {
  async fetch(request) {
    const country = request.cf?.country || 'US';
    const url = new URL(request.url);
    const regions = { US: 'us-origin', CA: 'us-origin', GB: 'eu-origin',
                      DE: 'eu-origin', JP: 'ap-origin', AU: 'ap-origin' };
    url.hostname = `${regions[country] || 'us-origin'}.example.com`;
    return fetch(url.toString(), { method: request.method, headers: request.headers, body: request.body });
  },
};
```

---

## Cloudflare Pages

### Build Configuration

```
Framework presets:
  Next.js     → Build: npx @cloudflare/next-on-pages  → Output: .vercel/output/static
  Astro       → Build: npm run build                   → Output: dist
  Remix       → Build: npm run build                   → Output: build/client
  React/Vite  → Build: npm run build                   → Output: dist

# Environment variables: Dashboard → Pages → Settings → Environment variables
# Separate production and preview values
```

### Pages Functions (Serverless API)

```javascript
// functions/api/users.js → auto-deployed as /api/users
export async function onRequestGet({ env }) {
  const users = await env.DB.prepare('SELECT * FROM users LIMIT 10').all();
  return new Response(JSON.stringify(users.results), {
    headers: { 'Content-Type': 'application/json' },
  });
}

export async function onRequestPost({ env, request }) {
  const body = await request.json();
  if (!body.name || !body.email) {
    return new Response(JSON.stringify({ error: 'Missing fields' }), { status: 400 });
  }
  await env.DB.prepare('INSERT INTO users (name, email) VALUES (?, ?)').bind(body.name, body.email).run();
  return new Response(JSON.stringify({ success: true }), { status: 201 });
}
```

---

## R2 Object Storage

### Worker Access to R2

```javascript
// wrangler.toml: [[r2_buckets]] binding = "BUCKET", bucket_name = "my-assets"
export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const key = url.pathname.slice(1);

    if (request.method === 'GET') {
      const object = await env.BUCKET.get(key);
      if (!object) return new Response('Not Found', { status: 404 });
      const headers = new Headers();
      object.writeHttpMetadata(headers);
      headers.set('ETag', object.httpEtag);
      headers.set('Cache-Control', 'public, max-age=86400');
      return new Response(object.body, { headers });
    }
    if (request.method === 'PUT') {
      await env.BUCKET.put(key, request.body, {
        httpMetadata: { contentType: request.headers.get('Content-Type') || 'application/octet-stream' },
      });
      return new Response(JSON.stringify({ key }), { status: 201 });
    }
    if (request.method === 'DELETE') {
      await env.BUCKET.delete(key);
      return new Response(null, { status: 204 });
    }
    return new Response('Method Not Allowed', { status: 405 });
  },
};
```

### R2 Lifecycle Rules

```
Dashboard → R2 → Bucket → Settings → Object lifecycle rules
Prefix: tmp/  → Delete after 1 day
Prefix: logs/ → Infrequent Access after 30 days → Delete after 90 days
```

---

## Zero Trust / Cloudflare Tunnels

### Tunnel Setup

```bash
cloudflared tunnel login
cloudflared tunnel create my-tunnel
cloudflared tunnel route dns my-tunnel app.example.com
cloudflared tunnel route dns my-tunnel internal.example.com
cloudflared tunnel run my-tunnel
```

### Tunnel Configuration

```yaml
# ~/.cloudflared/config.yml
tunnel: <TUNNEL_ID>
credentials-file: /root/.cloudflared/<TUNNEL_ID>.json

ingress:
  - hostname: app.example.com
    service: http://localhost:3000
    originRequest: { connectTimeout: 10s }
  - hostname: internal.example.com
    service: http://localhost:8080
  - hostname: ssh.example.com
    service: ssh://localhost:22
  - service: http_status:404  # catch-all — required last
```

### Tunnel as a Docker Service

```yaml
# compose.yaml
services:
  cloudflared:
    image: cloudflare/cloudflared:latest
    restart: unless-stopped
    command: tunnel --no-autoupdate run --token ${TUNNEL_TOKEN}
    networks: [frontend]
  app:
    build: .
    networks: [frontend, backend]
    # No ports exposed — traffic comes through tunnel

networks:
  frontend:
  backend:
    internal: true
```

### Zero Trust Access Policies

```
Dashboard → Zero Trust → Access → Applications

Internal Dashboard: internal.example.com
  Allow: Emails ending in @example.com + Country US + Google SSO

Staging: staging.example.com
  Allow: Group "Engineering" + Warp device posture check
```

---

## Rate Limiting

```
Dashboard → Security → WAF → Rate limiting rules

# Login: 5 req/min per IP, block 10 min
Match: (http.request.uri.path eq "/api/auth/login" and http.request.method eq "POST")

# API: 100 req/min per IP, managed challenge
Match: (http.request.uri.path contains "/api/")

# Search: 30 req/min per IP, block 2 min
Match: (http.request.uri.path eq "/api/search")
```

---

## Bot Management

```
Dashboard → Security → Bots

Bot Fight Mode (Free/Pro):
  Definitely automated → Block | Likely automated → Challenge | Verified bots → Allow

Super Bot Fight Mode (Business+):
  + Static resource protection | + JavaScript detections

Custom rules:
  (cf.bot_management.score lt 30 and http.request.uri.path contains "/pricing") → Block
  (cf.bot_management.score lt 50 and http.request.uri.path contains "/checkout") → Challenge
  (cf.bot_management.verified_bot) → Allow
```

---

## Transform Rules

Modern replacement for Page Rules (deprecated). Modify requests/responses at the edge.

### URL Rewrites

```
# Internal rewrite: /blog → /articles
Match: (http.request.uri.path eq "/blog")
Rewrite to: Static — /articles

# Dynamic: add language prefix
Match: (not starts_with(http.request.uri.path, "/en/") and ip.geoip.country eq "US")
Rewrite to: Dynamic — concat("/en", http.request.uri.path)

# Remove trailing slash
Match: (http.request.uri.path ne "/" and ends_with(http.request.uri.path, "/"))
Rewrite to: Dynamic — regex_replace(http.request.uri.path, "/$", "")
```

### Header Modification

```
# Request headers — add context for origin
Set: X-Real-IP = ip.src | X-User-Country = ip.geoip.country

# Response headers — security hardening
Set: X-Content-Type-Options = nosniff | X-Frame-Options = DENY
Set: Referrer-Policy = strict-origin-when-cross-origin
Remove: Server | X-Powered-By | X-AspNet-Version
```

---

## Terraform Provider

```hcl
terraform {
  required_providers {
    cloudflare = { source = "cloudflare/cloudflare", version = "~> 5.0" }
  }
}
provider "cloudflare" { api_token = var.cloudflare_api_token }

# DNS — web records proxied
resource "cloudflare_record" "www" {
  zone_id = var.cloudflare_zone_id
  name    = "www"
  content = "203.0.113.1"
  type    = "A"
  proxied = true
}

# DNS — email records NEVER proxied
resource "cloudflare_record" "mx" {
  zone_id  = var.cloudflare_zone_id
  name     = "@"
  content  = "mail.example.com"
  type     = "MX"
  priority = 10
  proxied  = false
  ttl      = 3600
}

resource "cloudflare_record" "spf" {
  zone_id = var.cloudflare_zone_id
  name    = "@"
  content = "v=spf1 include:_spf.google.com ~all"
  type    = "TXT"
  proxied = false
  ttl     = 3600
}

# SSL/TLS settings (v5 uses cloudflare_zone_setting per setting)
resource "cloudflare_zone_setting" "ssl" {
  zone_id    = var.cloudflare_zone_id
  setting_id = "ssl"
  value      = "strict"
}

resource "cloudflare_zone_setting" "always_use_https" {
  zone_id    = var.cloudflare_zone_id
  setting_id = "always_use_https"
  value      = "on"
}

resource "cloudflare_zone_setting" "min_tls_version" {
  zone_id    = var.cloudflare_zone_id
  setting_id = "min_tls_version"
  value      = "1.2"
}

# Rate limiting
resource "cloudflare_ruleset" "rate_limit" {
  zone_id = var.cloudflare_zone_id
  name    = "Rate limiting"
  kind    = "zone"
  phase   = "http_ratelimit"

  rules {
    action = "block"
    ratelimit {
      characteristics     = ["ip.src"]
      period              = 60
      requests_per_period = 5
      mitigation_timeout  = 600
    }
    expression  = "(http.request.uri.path eq \"/api/auth/login\" and http.request.method eq \"POST\")"
    description = "Rate limit login attempts"
    enabled     = true
  }
}

# WAF custom rules
resource "cloudflare_ruleset" "waf_custom" {
  zone_id = var.cloudflare_zone_id
  name    = "Custom WAF rules"
  kind    = "zone"
  phase   = "http_request_firewall_custom"

  rules {
    action      = "block"
    expression  = "(http.user_agent contains \"sqlmap\") or (http.user_agent contains \"nikto\")"
    description = "Block known attack tools"
    enabled     = true
  }
}

# Tunnel (v5 renamed resources)
resource "cloudflare_zero_trust_tunnel_cloudflared" "app" {
  account_id = var.cloudflare_account_id
  name       = "app-tunnel"
  secret     = var.tunnel_secret
}

resource "cloudflare_zero_trust_tunnel_cloudflared_config" "app" {
  account_id = var.cloudflare_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.app.id
  config {
    ingress_rule { hostname = "app.example.com"; service = "http://localhost:3000" }
    ingress_rule { service = "http_status:404" }
  }
}

resource "cloudflare_record" "tunnel" {
  zone_id = var.cloudflare_zone_id
  name    = "app"
  content = "${cloudflare_zero_trust_tunnel_cloudflared.app.id}.cfargotunnel.com"
  type    = "CNAME"
  proxied = true
}

# R2 bucket
resource "cloudflare_r2_bucket" "assets" {
  account_id = var.cloudflare_account_id
  name       = "my-assets"
  location   = "WNAM"
}
```

---

## Performance Settings

```
Dashboard → Speed → Optimization

✅ Brotli:          On (better compression than gzip)
✅ Early Hints:     On (103 status — preloads critical assets)
✅ HTTP/3 (QUIC):   On (faster connections, especially mobile)
✅ 0-RTT:           On (faster TLS handshake for returning visitors)
✅ Auto Minify:     JS, CSS, HTML
✅ WebSockets:      On (if needed)
✅ Rocket Loader:   Off (breaks many JS frameworks — test carefully)
✅ Polish:          Lossy/Lossless (Pro+ — image optimization)
✅ Image Resizing:  On (Business+ — resize at edge)
```

---

## Wrangler CLI Reference

```bash
# Auth
wrangler login                        # Browser OAuth
wrangler whoami                       # Check auth

# Workers
wrangler init my-worker               # New project
wrangler dev                          # Local dev (port 8787)
wrangler deploy                       # Deploy
wrangler tail                         # Live logs

# Pages
wrangler pages deploy ./dist          # Deploy static site

# R2
wrangler r2 bucket create my-bucket
wrangler r2 object put my-bucket/key --file ./file.txt

# KV
wrangler kv namespace create MY_KV
wrangler kv key put --binding MY_KV "key" "value"

# D1 (SQLite at edge)
wrangler d1 create my-db
wrangler d1 execute my-db --file schema.sql

# Secrets
wrangler secret put API_KEY           # Interactive
wrangler secret list
```

---

## API Token Best Practices

```
Dashboard → My Profile → API Tokens → Create Token

# Scoped tokens per use case (NEVER use Global API Key):
Deploy Worker:     Workers Scripts:Edit     → Specific zone
DNS Management:    DNS:Edit                 → Specific zone
Cache Purge:       Cache Purge:Purge        → Specific zone
Analytics:         Analytics:Read           → All zones

# ALWAYS set IP restrictions and TTL (expiration) on tokens
```

---

## Anti-Patterns

| Anti-Pattern | Why Dangerous | Fix |
|---|---|---|
| SSL mode "Flexible" | No encryption to origin — false security | Full (Strict) + origin cert |
| SSL mode "Full" (not Strict) | Does not verify origin cert — MITM possible | Full (Strict) |
| Proxying MX records | Breaks email delivery completely | DNS-only (grey cloud) |
| Proxying SPF/DKIM/DMARC | Breaks email authentication | DNS-only (grey cloud) |
| No origin firewall | Origin accessible directly, bypassing CF | CF IPs only + Tunnel |
| Origin IP in DNS history | Attackers bypass CF entirely | Tunnel, never expose origin IP |
| Origin IP in response headers | `Server`, `X-Served-By` leak origin | Remove via Transform Rules or Worker |
| No Cache-Control headers | CF uses defaults, may cache private data | Explicit headers on every response |
| Caching authenticated content | User A sees User B's data | Bypass cache when session cookie present |
| Workers on workers.dev in prod | No WAF, no custom domain, no DDoS | Always use custom domain |
| Over-aggressive WAF rules | Blocks legitimate users and bots | Start in Log mode, review 48-72h |
| Not enabling DNSSEC | DNS spoofing and cache poisoning | Enable + DS record at registrar |
| Using Page Rules (deprecated) | Being phased out, limited free rules | Transform Rules + Cache Rules |
| Global API Key in automation | Full account access if leaked | Scoped API tokens per use case |
| No rate limiting on auth | Brute force and credential stuffing | 5 req/min on login, block 10 min |
| Rocket Loader enabled blindly | Breaks many JavaScript frameworks | Off by default, test carefully |
| No bot management | Scrapers and scanners consume resources | Enable Bot Fight Mode minimum |
| Wildcard DNS without purpose | Catch-all records expose attack surface | Only create needed records |
| Not monitoring Security Events | Attacks go unnoticed | Review weekly, set up alerts |
| HSTS without testing subdomains | Locks out subdomains without HTTPS | Test all subdomains before preload |

---

## Checklist: Cloudflare Configuration Review

### SSL/TLS
- [ ] SSL/TLS mode is Full (Strict)
- [ ] Origin certificate installed and valid (CF Origin CA or Let's Encrypt)
- [ ] HSTS enabled with max-age 12 months, includeSubDomains, preload
- [ ] Minimum TLS version set to 1.2, TLS 1.3 enabled
- [ ] Always Use HTTPS and Automatic HTTPS Rewrites enabled
- [ ] Authenticated Origin Pulls enabled

### DNS
- [ ] DNSSEC enabled with DS record at registrar
- [ ] All HTTP-serving A/AAAA/CNAME records are proxied (orange cloud)
- [ ] Email records (MX, SPF, DKIM, DMARC) are DNS-only (grey cloud)
- [ ] SPF record correct, DKIM configured, DMARC at quarantine or reject
- [ ] No unnecessary wildcard DNS records
- [ ] CAA record restricts certificate issuance

### Security
- [ ] WAF managed rulesets enabled (CF Managed, OWASP, Leaked Credentials)
- [ ] Custom WAF rules for admin paths and known attack tools
- [ ] WAF rules tested in Log mode before enforcing
- [ ] Rate limiting on auth endpoints (5 req/min) and API endpoints
- [ ] Bot Fight Mode or Super Bot Fight Mode enabled
- [ ] DDoS protection at high sensitivity
- [ ] Security Events reviewed weekly

### Origin Protection
- [ ] Origin IP not leaked in DNS history, headers, or error pages
- [ ] Origin firewall restricts to CF IPs only, or uses Tunnel
- [ ] Origin server identity headers removed (Server, X-Powered-By)
- [ ] Direct-IP access to origin returns nothing useful

### Caching
- [ ] Cache rules defined per content type
- [ ] Static assets cached with long TTLs (hashed filenames = immutable)
- [ ] Authenticated/private content excluded from cache
- [ ] Origin sends explicit Cache-Control headers
- [ ] Cache purge strategy is URL-based (not purge-everything)

### Performance
- [ ] Brotli, HTTP/3, Early Hints, 0-RTT enabled
- [ ] Auto Minify enabled for JS, CSS, HTML
- [ ] Rocket Loader off unless tested and confirmed

### Workers / Pages
- [ ] Workers on custom domain (not workers.dev in production)
- [ ] Error handling and appropriate status codes in Workers
- [ ] Secrets not hardcoded, KV/R2/D1 bindings correct

### Infrastructure as Code
- [ ] Cloudflare resources managed via Terraform
- [ ] Scoped API tokens per use case with IP restrictions and TTL
- [ ] Terraform state stored securely (encrypted, remote backend)
