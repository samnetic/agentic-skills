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

| # | Principle | Meaning |
|---|---|---|
| 1 | **Proxy everything HTTP** | Orange cloud on A/AAAA records — all HTTP traffic through CF |
| 2 | **Never proxy email records** | Grey cloud for MX, SPF, DKIM, DMARC — proxying breaks email |
| 3 | **Always Full (Strict) SSL** | Origin must have a valid certificate (CF Origin CA or Let's Encrypt) |
| 4 | **Hide the origin IP** | Use Tunnel or firewall to CF IPs only — never expose origin directly |
| 5 | **Cache aggressively** | But never cache authenticated or personalized content |
| 6 | **Defense in depth** | WAF + rate limiting + bot management + DDoS protection — layered |

---

## Workflow: Cloudflare Setup

### Step 1 — DNS Migration

Import records, set proxy mode per record type. Use the decision tree below.

### Step 2 — SSL/TLS

Set Full (Strict) mode. Install origin certificate. Enable HSTS.

### Step 3 — WAF

Enable managed rulesets in LOG mode. Add custom rules after 48-72h observation.

### Step 4 — Cache Strategy

Configure cache rules per content type. Set explicit Cache-Control headers at origin.

### Step 5 — Security Hardening

Add rate limiting on auth endpoints. Enable Bot Fight Mode. Configure DDoS settings.

### Step 6 — Performance

Enable Brotli, Early Hints, HTTP/3, 0-RTT. Disable Rocket Loader unless tested.

### Step 7 — Monitor

Review Security Events weekly. Set up alerts. Audit API token scopes.

---

## Decision Tree: Proxy vs DNS-Only

```
Record type?
├─ A / AAAA (web server)
│  ├─ Serves HTTP/HTTPS? → Proxied (orange cloud)
│  ├─ Non-HTTP (SSH, FTP, custom TCP) → DNS-only (grey cloud)
│  └─ Origin IP must be hidden? → Proxied + Tunnel
├─ CNAME → web service: Proxied / non-HTTP: DNS-only
├─ MX    → DNS-only ALWAYS — proxying breaks email
├─ TXT (SPF, DKIM, DMARC) → DNS-only ALWAYS
├─ SRV   → DNS-only — cannot be proxied
└─ CAA   → DNS-only — certificate authority authorization
```

---

## Decision Tree: SSL Mode

```
ALWAYS USE: Full (Strict) + origin certificate

├── Full (Strict)  → Origin has valid cert (CF Origin CA or Let's Encrypt)
│                     Encryption: Browser ↔ CF ↔ Origin (verified)
├── Full           → Self-signed cert on origin. MITM possible
├── Flexible       → NEVER — no encryption to origin, false security
└── Off            → NEVER — no encryption at all
```

---

## Decision Tree: Cache by Content Type

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

## Progressive Disclosure Map

| Topic | Reference | When to read |
|---|---|---|
| DNS records, DNSSEC, email (SPF/DKIM/DMARC), SSL/TLS origin certs, HSTS | `references/dns-email-ssl.md` | Setting up DNS, configuring email authentication, or installing origin certificates |
| WAF rules, caching strategies, cache rules, rate limiting, bot management, transform rules, performance tuning | `references/security-performance.md` | Configuring WAF rulesets, designing cache rules, setting up rate limiting or bot protection, optimizing performance |
| Workers examples, Pages deployment, R2 storage, wrangler CLI | `references/workers-pages-r2.md` | Building Workers (redirects, security headers, A/B testing, geo-routing), deploying to Pages, using R2, or running wrangler commands |
| Terraform provider (DNS, SSL, WAF, tunnels, R2), Zero Trust tunnels, Docker tunnel service, API tokens | `references/terraform-zerotrust.md` | Managing Cloudflare as infrastructure-as-code, setting up Zero Trust tunnels, or configuring API token scopes |

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
