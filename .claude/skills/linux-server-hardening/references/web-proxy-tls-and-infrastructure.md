# Web Proxy, TLS & Infrastructure Reference

Deep-dive configurations for Nginx/Caddy reverse proxy hardening, TLS certificate management, backup strategies, monitoring, and log management.

---

## Table of Contents

- [Nginx Reverse Proxy Hardening](#nginx-reverse-proxy-hardening)
  - [Global Configuration](#global-configuration)
  - [Virtual Host Configuration](#virtual-host-configuration)
- [Caddy (Alternative --- Automatic TLS)](#caddy-alternative----automatic-tls)
- [TLS / Certificate Management](#tls--certificate-management)
  - [Let's Encrypt + Certbot](#lets-encrypt--certbot)
  - [Certificate Security Checklist](#certificate-security-checklist)
  - [TLS Best Practices](#tls-best-practices)
- [Backup Strategies](#backup-strategies)
  - [Backup Decision Tree](#backup-decision-tree)
  - [3-2-1 Backup Rule](#3-2-1-backup-rule)
  - [borgbackup](#borgbackup)
  - [restic (Multi-Backend)](#restic-multi-backend)
  - [Automated Backup Script](#automated-backup-script)
- [Monitoring](#monitoring)
  - [Prometheus node_exporter](#prometheus-node_exporter)
  - [Key Alerts to Configure](#key-alerts-to-configure)
- [Log Management](#log-management)
  - [journald Configuration](#journald-configuration)
  - [Log Rotation](#log-rotation)
  - [Remote Log Shipping](#remote-log-shipping)
  - [Key Logs to Monitor](#key-logs-to-monitor)

---

## Nginx Reverse Proxy Hardening

### Global Configuration

Place at `/etc/nginx/nginx.conf`:

```nginx
user www-data;
worker_processes auto;
pid /run/nginx.pid;

events {
    worker_connections 1024;
    multi_accept on;
}

http {
    # --- Basic Settings ---
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    client_max_body_size 16M;
    server_tokens off;                     # Hide Nginx version

    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    # --- Logging ---
    log_format main '$remote_addr - $remote_user [$time_local] '
                    '"$request" $status $body_bytes_sent '
                    '"$http_referer" "$http_user_agent" '
                    'rt=$request_time';
    access_log /var/log/nginx/access.log main;
    error_log /var/log/nginx/error.log warn;

    # --- Rate Limiting ---
    limit_req_zone $binary_remote_addr zone=general:10m rate=10r/s;
    limit_req_zone $binary_remote_addr zone=login:10m rate=1r/s;

    # --- SSL Global ---
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305;
    ssl_prefer_server_ciphers off;
    ssl_session_timeout 1d;
    ssl_session_cache shared:SSL:10m;
    ssl_session_tickets off;
    ssl_stapling on;
    ssl_stapling_verify on;
    resolver 1.1.1.1 8.8.8.8 valid=300s;
    resolver_timeout 5s;

    include /etc/nginx/conf.d/*.conf;
    include /etc/nginx/sites-enabled/*;
}
```

### Virtual Host Configuration

Place at `/etc/nginx/sites-available/app.conf`:

```nginx
# Redirect HTTP to HTTPS
server {
    listen 80;
    listen [::]:80;
    server_name example.com www.example.com;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name example.com www.example.com;

    # --- TLS ---
    ssl_certificate /etc/letsencrypt/live/example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/example.com/privkey.pem;
    ssl_trusted_certificate /etc/letsencrypt/live/example.com/chain.pem;

    # --- Security Headers ---
    add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-Frame-Options "DENY" always;
    add_header X-XSS-Protection "0" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    add_header Permissions-Policy "camera=(), microphone=(), geolocation=(self), payment=(self)" always;
    add_header Content-Security-Policy "default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; font-src 'self'; object-src 'none'; frame-ancestors 'none'; base-uri 'self'; upgrade-insecure-requests;" always;
    add_header Cross-Origin-Opener-Policy "same-origin" always;
    add_header Cross-Origin-Embedder-Policy "require-corp" always;
    add_header Cross-Origin-Resource-Policy "same-origin" always;

    # --- Rate Limiting ---
    limit_req zone=general burst=20 nodelay;

    # --- Proxy to Application ---
    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_read_timeout 60s;
        proxy_connect_timeout 10s;
    }

    # --- Stricter rate limit on auth endpoints ---
    location /api/auth/ {
        limit_req zone=login burst=3 nodelay;
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # --- Block sensitive paths ---
    location ~ /\.(git|env|htaccess|htpasswd) {
        deny all;
        return 404;
    }
}
```

---

## Caddy (Alternative --- Automatic TLS)

```caddyfile
# /etc/caddy/Caddyfile
{
    email admin@example.com
    log {
        level WARN
    }
}

example.com {
    # Automatic HTTPS with Let's Encrypt (zero config)

    # Security headers
    header {
        Strict-Transport-Security "max-age=63072000; includeSubDomains; preload"
        X-Content-Type-Options "nosniff"
        X-Frame-Options "DENY"
        Referrer-Policy "strict-origin-when-cross-origin"
        Permissions-Policy "camera=(), microphone=(), geolocation=(self)"
        -Server                             # Remove server header
    }

    # Rate limiting
    rate_limit {remote.ip} 10r/s

    # Reverse proxy to application
    reverse_proxy localhost:3000 {
        header_up X-Real-IP {remote_host}
        header_up X-Forwarded-Proto {scheme}
    }

    # Block sensitive files
    @blocked path /.git/* /.env /.htaccess
    respond @blocked 404
}
```

---

## TLS / Certificate Management

### Let's Encrypt + Certbot

```bash
# Install certbot
sudo apt install -y certbot python3-certbot-nginx   # For Nginx
# sudo apt install -y certbot python3-certbot-apache # For Apache

# Obtain certificate (Nginx plugin handles config automatically)
sudo certbot --nginx -d example.com -d www.example.com \
    --non-interactive --agree-tos --email admin@example.com \
    --redirect --hsts --staple-ocsp

# Or standalone (if no web server running yet)
sudo certbot certonly --standalone -d example.com \
    --non-interactive --agree-tos --email admin@example.com

# Verify auto-renewal
sudo certbot renew --dry-run

# Renewal is automatic via systemd timer
sudo systemctl status certbot.timer

# Force renewal (if needed)
sudo certbot renew --force-renewal
```

### Certificate Security Checklist

```bash
# Test TLS configuration (from any machine)
# Use ssllabs.com or:
nmap --script ssl-enum-ciphers -p 443 example.com

# Verify certificate chain
openssl s_client -connect example.com:443 -servername example.com </dev/null 2>/dev/null | openssl x509 -noout -dates -subject -issuer

# Check OCSP stapling
openssl s_client -connect example.com:443 -status </dev/null 2>/dev/null | grep -A 2 "OCSP Response"
```

### TLS Best Practices

| Setting | Recommended |
|---|---|
| Minimum protocol | TLSv1.2 (TLSv1.3 preferred) |
| HSTS | `max-age=63072000; includeSubDomains; preload` |
| OCSP Stapling | Enabled |
| Session tickets | Disabled (for perfect forward secrecy) |
| Cipher preference | Server-side off (let client choose from safe list) |
| Certificate type | ECDSA P-256 (faster) or RSA 2048+ |
| Renewal | Automated, at least 30 days before expiry |

---

## Backup Strategies

### Backup Decision Tree

```
What to back up?
├── Full server disk → Snapshot (cloud provider) or dd (bare metal)
├── Databases → pg_dump / mysqldump + WAL archiving
├── Files + configs → borgbackup or restic
└── Containers → Volume backups

Which backup tool?
├── Deduplication + encryption + compression → borgbackup (fastest dedup)
├── Multi-backend (S3, B2, SFTP, local) → restic (simpler, more backends)
└── Simple file copy → rsync (no dedup, no encryption built-in)
```

### 3-2-1 Backup Rule

```
3 copies of your data
2 different storage media (local disk + remote)
1 offsite copy (different datacenter/cloud provider)
```

### borgbackup

```bash
# Install
sudo apt install -y borgbackup

# Initialize encrypted repository
borg init --encryption=repokey-blake2 /backup/borg-repo
# CRITICAL: Back up the key separately
borg key export /backup/borg-repo > /safe/borg-key-backup.txt

# Create backup
borg create --stats --progress --compression zstd,3 \
    /backup/borg-repo::'{hostname}-{now:%Y-%m-%d_%H:%M}' \
    /etc /opt/myapp /home/deploy \
    --exclude '*.tmp' \
    --exclude '/home/deploy/.cache'

# Prune old backups (keep 7 daily, 4 weekly, 6 monthly)
borg prune --stats \
    /backup/borg-repo \
    --keep-daily=7 \
    --keep-weekly=4 \
    --keep-monthly=6

# Compact repository (reclaim space from pruned archives)
borg compact /backup/borg-repo

# Verify backup integrity
borg check /backup/borg-repo

# List archives
borg list /backup/borg-repo

# Restore specific files
borg extract /backup/borg-repo::archive-name path/to/restore
```

### restic (Multi-Backend)

```bash
# Install
sudo apt install -y restic

# Initialize repository (S3 example)
export AWS_ACCESS_KEY_ID="your-key"
export AWS_SECRET_ACCESS_KEY="your-secret"
restic -r s3:s3.amazonaws.com/mybucket/backup init

# Or local repository
restic -r /backup/restic-repo init

# Create backup
restic -r /backup/restic-repo backup \
    /etc /opt/myapp /home/deploy \
    --exclude '*.tmp' \
    --tag production

# Forget old snapshots (keep 7 daily, 4 weekly, 6 monthly)
restic -r /backup/restic-repo forget \
    --keep-daily 7 \
    --keep-weekly 4 \
    --keep-monthly 6 \
    --prune

# Verify backup integrity
restic -r /backup/restic-repo check

# Restore
restic -r /backup/restic-repo restore latest --target /tmp/restore
```

### Automated Backup Script

```bash
#!/bin/bash
# /opt/scripts/backup.sh
set -euo pipefail

REPO="/backup/borg-repo"
LOG="/var/log/backup.log"
PASSPHRASE_FILE="/root/.borg-passphrase"

export BORG_PASSCOMMAND="cat $PASSPHRASE_FILE"

log() { echo "$(date -Iseconds) $*" >> "$LOG"; }

log "Backup started"

# Database dump first
sudo -u postgres pg_dump mydb | gzip > /tmp/mydb-dump.sql.gz

# Borg backup
borg create --stats --compression zstd,3 \
    "$REPO::$(hostname)-$(date +%Y-%m-%d_%H%M)" \
    /etc /opt/myapp /home/deploy /tmp/mydb-dump.sql.gz \
    --exclude '*.tmp' \
    --exclude '/home/deploy/.cache' \
    2>> "$LOG"

# Prune
borg prune --stats "$REPO" \
    --keep-daily=7 --keep-weekly=4 --keep-monthly=6 2>> "$LOG"

borg compact "$REPO" 2>> "$LOG"

# Cleanup
rm -f /tmp/mydb-dump.sql.gz

log "Backup completed"

# Verify (weekly only)
if [ "$(date +%u)" -eq 7 ]; then
    borg check "$REPO" 2>> "$LOG"
    log "Integrity check completed"
fi
```

```bash
# Schedule daily at 2 AM
# /etc/cron.d/backup
0 2 * * * root /opt/scripts/backup.sh
```

---

## Monitoring

### Prometheus node_exporter

```bash
# Install node_exporter
sudo useradd --no-create-home --shell /usr/sbin/nologin node_exporter

# Download latest release
curl -LO https://github.com/prometheus/node_exporter/releases/download/v1.8.2/node_exporter-1.8.2.linux-amd64.tar.gz
tar xzf node_exporter-1.8.2.linux-amd64.tar.gz
sudo cp node_exporter-1.8.2.linux-amd64/node_exporter /usr/local/bin/
sudo chown node_exporter:node_exporter /usr/local/bin/node_exporter
```

### /etc/systemd/system/node_exporter.service

```ini
[Unit]
Description=Prometheus Node Exporter
After=network-online.target
Wants=network-online.target

[Service]
Type=exec
User=node_exporter
Group=node_exporter
ExecStart=/usr/local/bin/node_exporter \
    --web.listen-address=127.0.0.1:9100 \
    --collector.systemd \
    --collector.processes \
    --no-collector.wifi \
    --no-collector.infiniband

# --- Security Hardening ---
ProtectSystem=strict
ProtectHome=yes
PrivateTmp=yes
PrivateDevices=yes
ProtectKernelTunables=yes
ProtectKernelModules=yes
ProtectControlGroups=yes
NoNewPrivileges=yes
CapabilityBoundingSet=
RestrictAddressFamilies=AF_INET AF_INET6 AF_UNIX
RestrictNamespaces=yes
LockPersonality=yes
MemoryDenyWriteExecute=yes
RestrictRealtime=yes
RestrictSUIDSGID=yes
SystemCallFilter=@system-service
SystemCallArchitectures=native

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now node_exporter

# Verify
curl -s http://127.0.0.1:9100/metrics | head -20
```

### Key Alerts to Configure

| Alert | Condition | Severity |
|---|---|---|
| High CPU | `rate(node_cpu_seconds_total{mode="idle"}[5m]) < 0.1` | Warning |
| Disk > 85% | `node_filesystem_avail_bytes / node_filesystem_size_bytes < 0.15` | Critical |
| Memory > 90% | `node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes < 0.1` | Critical |
| SSH login | auth.log new session detected | Info |
| Systemd unit failed | `node_systemd_unit_state{state="failed"} == 1` | Critical |
| Reboot required | `node_reboot_required == 1` | Warning |
| High load average | `node_load15 > count(node_cpu_seconds_total{mode="idle"})` | Warning |

---

## Log Management

### journald Configuration

```ini
# /etc/systemd/journald.conf.d/99-hardening.conf
[Journal]
Storage=persistent
Compress=yes
SystemMaxUse=500M
SystemMaxFileSize=50M
MaxRetentionSec=90d
ForwardToSyslog=no
RateLimitIntervalSec=30s
RateLimitBurst=10000
Seal=yes                              # Forward Secure Sealing (tamper detection)
```

```bash
sudo systemctl restart systemd-journald
```

### Log Rotation

```
# /etc/logrotate.d/myapp
/var/log/myapp/*.log {
    daily
    rotate 30
    compress
    delaycompress
    missingok
    notifempty
    create 0640 myapp myapp
    sharedscripts
    postrotate
        systemctl reload myapp.service 2>/dev/null || true
    endscript
}
```

### Remote Log Shipping

rsyslog to central server over TLS:

```
# /etc/rsyslog.d/99-remote.conf
# Ship all logs to central syslog server over TLS
action(
    type="omfwd"
    target="syslog.example.com"
    port="6514"
    protocol="tcp"
    StreamDriver="gtls"
    StreamDriverMode="1"
    StreamDriverAuthMode="x509/name"
    StreamDriverPermittedPeers="syslog.example.com"
    queue.type="LinkedList"
    queue.filename="remote_fwd"
    queue.maxDiskSpace="1g"
    queue.saveOnShutdown="on"
    action.resumeRetryCount="-1"
)
```

### Key Logs to Monitor

| Log | Path / Command | What to Watch |
|---|---|---|
| Auth | `/var/log/auth.log` or `journalctl -u sshd` | Failed logins, privilege escalation |
| Kernel | `journalctl -k` | Segfaults, OOM kills, hardware errors |
| Fail2ban | `/var/log/fail2ban.log` | Banned IPs, attack patterns |
| Nginx | `/var/log/nginx/access.log` | 4xx/5xx spikes, unusual paths |
| Firewall | `journalctl -t nftables` | Dropped packets, scan attempts |
| Unattended upgrades | `/var/log/unattended-upgrades/` | Failed updates, pending reboots |
| Cron | `/var/log/syslog` (grep CRON) | Failed jobs, unexpected schedules |
