# Security, Caching, and Performance

## Table of Contents

- [WAF Configuration](#waf-configuration)
  - [Managed Rulesets](#managed-rulesets)
  - [Custom WAF Rules](#custom-waf-rules)
  - [WAF Rollout Strategy](#waf-rollout-strategy)
- [Caching Strategies](#caching-strategies)
  - [Cache Rules (Replaces Page Rules)](#cache-rules-replaces-page-rules)
  - [Origin Cache-Control Headers](#origin-cache-control-headers)
  - [Cache Purge](#cache-purge)
- [Rate Limiting](#rate-limiting)
- [Bot Management](#bot-management)
- [Transform Rules](#transform-rules)
  - [URL Rewrites](#url-rewrites)
  - [Header Modification](#header-modification)
- [Performance Settings](#performance-settings)

---

## WAF Configuration

### Managed Rulesets

```
Dashboard → Security → WAF → Managed rules (start in LOG mode)

Cloudflare Managed Ruleset     → Core OWASP protections
Cloudflare OWASP Core Ruleset  → OWASP ModSecurity CRS
Cloudflare Leaked Credentials  → Blocks known-leaked passwords
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

## Performance Settings

```
Dashboard → Speed → Optimization

Brotli:          On (better compression than gzip)
Early Hints:     On (103 status — preloads critical assets)
HTTP/3 (QUIC):   On (faster connections, especially mobile)
0-RTT:           On (faster TLS handshake for returning visitors)
Auto Minify:     JS, CSS, HTML
WebSockets:      On (if needed)
Rocket Loader:   Off (breaks many JS frameworks — test carefully)
Polish:          Lossy/Lossless (Pro+ — image optimization)
Image Resizing:  On (Business+ — resize at edge)
```
