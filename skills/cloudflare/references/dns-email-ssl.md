# DNS, Email, and SSL/TLS Configuration

## Table of Contents

- [DNS Configuration](#dns-configuration)
  - [DNS Record Examples](#dns-record-examples)
  - [DNSSEC](#dnssec)
- [Email DNS — SPF, DKIM, DMARC](#email-dns--spf-dkim-dmarc)
- [SSL/TLS Configuration](#ssltls-configuration)
  - [Origin CA Certificate](#origin-ca-certificate)
  - [HSTS and Authenticated Origin Pulls](#hsts-and-authenticated-origin-pulls)

---

## DNS Configuration

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

## SSL/TLS Configuration

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
