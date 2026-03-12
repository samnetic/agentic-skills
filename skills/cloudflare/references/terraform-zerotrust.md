# Terraform Provider and Zero Trust

## Table of Contents

- [Terraform Provider](#terraform-provider)
  - [Provider Setup](#provider-setup)
  - [DNS Resources](#dns-resources)
  - [SSL/TLS Settings](#ssltls-settings)
  - [Rate Limiting](#rate-limiting)
  - [WAF Custom Rules](#waf-custom-rules)
  - [Tunnel Resources](#tunnel-resources)
  - [R2 Bucket](#r2-bucket)
- [Zero Trust / Cloudflare Tunnels](#zero-trust--cloudflare-tunnels)
  - [Tunnel Setup](#tunnel-setup)
  - [Tunnel Configuration](#tunnel-configuration)
  - [Tunnel as a Docker Service](#tunnel-as-a-docker-service)
  - [Zero Trust Access Policies](#zero-trust-access-policies)
- [API Token Best Practices](#api-token-best-practices)

---

## Terraform Provider

### Provider Setup

```hcl
terraform {
  required_providers {
    cloudflare = { source = "cloudflare/cloudflare", version = "~> 5.0" }
  }
}
provider "cloudflare" { api_token = var.cloudflare_api_token }
```

### DNS Resources

```hcl
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
```

### SSL/TLS Settings

```hcl
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
```

### Rate Limiting

```hcl
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
```

### WAF Custom Rules

```hcl
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
```

### Tunnel Resources

```hcl
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
```

### R2 Bucket

```hcl
resource "cloudflare_r2_bucket" "assets" {
  account_id = var.cloudflare_account_id
  name       = "my-assets"
  location   = "WNAM"
}
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
