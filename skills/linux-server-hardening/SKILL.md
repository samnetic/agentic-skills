---
name: linux-server-hardening
description: >-
  Linux server administration and security hardening expertise. Use when setting up
  a VPS or bare-metal server, hardening SSH configuration, configuring firewalls
  (UFW, nftables, iptables), setting up fail2ban, managing users and sudo permissions,
  configuring systemd services with security directives, enabling unattended security
  updates, kernel hardening via sysctl, running CIS benchmark audits with Lynis,
  setting up disk encryption (LUKS), managing logs with journald and log rotation,
  configuring intrusion detection (AIDE, rkhunter), backup strategies (borgbackup,
  restic), monitoring with Prometheus node_exporter, Nginx/Caddy reverse proxy
  hardening, TLS certificate management, or preparing for compliance audits.
  Triggers: VPS, server, Linux, Ubuntu, Debian, SSH, firewall, UFW, nftables,
  iptables, fail2ban, sysctl, kernel hardening, CIS benchmark, Lynis, systemd,
  hardening, security audit, server setup, unattended-upgrades, LUKS, encryption,
  backup, rsync, borgbackup, restic, nginx, caddy, TLS, Let's Encrypt, certbot,
  node_exporter, AIDE, rkhunter, AppArmor, SELinux.
---

# Linux Server Hardening Skill

Secure servers from first boot. Harden every layer --- network, kernel, services,
authentication, monitoring. Assume every server is a target. Defense in depth is
not optional.

---

## Core Principles

| Principle | Meaning |
|---|---|
| **Least privilege** | Every user, process, and service gets minimum necessary permissions |
| **Defense in depth** | Multiple security layers --- firewall + SSH hardening + IDS + monitoring |
| **Default deny** | Block everything, explicitly allow only what is needed |
| **Immutable infrastructure where possible** | Prefer replacing servers over patching in place |
| **Automate security** | Unattended updates, automated audits, scripted provisioning |
| **Log everything, alert on anomalies** | Centralized logging with alerting for security events |

---

## Server Setup Workflow

```
1. PROVISION       -> Minimal OS install (Ubuntu 24.04 LTS / Debian 12)
2. ACCESS          -> Create deploy user, copy SSH keys, disable root login
3. SSH HARDEN      -> Key-only auth, modern ciphers, non-standard port
4. FIREWALL        -> Default deny, allow only SSH + HTTP/HTTPS
5. UPDATES         -> Enable unattended security updates
6. KERNEL          -> Apply sysctl hardening parameters
7. SERVICES        -> Harden systemd units, disable unused services
8. FAIL2BAN        -> Install and configure intrusion prevention
9. IDS             -> Set up AIDE/rkhunter for file integrity monitoring
10. TLS            -> Certbot + auto-renewal for all public endpoints
11. REVERSE PROXY  -> Nginx/Caddy with security headers
12. MONITORING     -> node_exporter + Prometheus alerting
13. BACKUP         -> Automated, encrypted, tested restores (3-2-1 rule)
14. AUDIT          -> Run Lynis, target hardening index >= 80
```

---

## Initial Server Setup

### Create Deploy User

```bash
# Connect as root (first and last time)
ssh root@YOUR_SERVER_IP

# Create deploy user with strong defaults
useradd -m -s /bin/bash -G sudo deploy
passwd -l deploy                  # Lock password (SSH key only)

# Set up SSH key authentication
mkdir -p /home/deploy/.ssh
chmod 700 /home/deploy/.ssh

# Copy your public key (run from LOCAL machine instead):
# ssh-copy-id -i ~/.ssh/id_ed25519.pub deploy@YOUR_SERVER_IP

# Or manually on the server:
cat >> /home/deploy/.ssh/authorized_keys << 'EOF'
ssh-ed25519 AAAA... your-email@example.com
EOF

chmod 600 /home/deploy/.ssh/authorized_keys
chown -R deploy:deploy /home/deploy/.ssh

# Verify login works BEFORE disabling root
# From local: ssh deploy@YOUR_SERVER_IP
```

### Disable Root Login and Password Auth

```bash
# Test deploy user login first, then:
sudo passwd -l root               # Lock root password
sudo usermod -s /usr/sbin/nologin root
```

---

## SSH Hardening

### /etc/ssh/sshd_config.d/99-hardening.conf

```sshd_config
# === Authentication ===
PermitRootLogin no
PasswordAuthentication no
KbdInteractiveAuthentication no
AuthenticationMethods publickey
PubkeyAuthentication yes
MaxAuthTries 3
MaxSessions 3
LoginGraceTime 20

# === Key Algorithms (modern only) ===
HostKeyAlgorithms ssh-ed25519,rsa-sha2-512,rsa-sha2-256
PubkeyAcceptedAlgorithms ssh-ed25519,rsa-sha2-512,rsa-sha2-256

# === Ciphers (AEAD only) ===
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com
MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com
KexAlgorithms sntrup761x25519-sha512@openssh.com,curve25519-sha256,curve25519-sha256@libssh.org

# === Network ===
Port 22                           # Change to non-standard if desired (e.g. 2222)
AddressFamily inet                # IPv4 only (set to 'any' if IPv6 needed)
ListenAddress 0.0.0.0

# === Timeouts & Limits ===
ClientAliveInterval 300
ClientAliveCountMax 2
TCPKeepAlive no

# === Disable Unused Features ===
X11Forwarding no
AllowTcpForwarding no
AllowAgentForwarding no
PermitTunnel no
GatewayPorts no
PermitUserEnvironment no
DisableForwarding yes

# === Logging ===
LogLevel VERBOSE
SyslogFacility AUTH

# === Restrict to deploy user ===
AllowUsers deploy
```

```bash
# Validate config before restarting
sudo sshd -t

# Restart SSH (keep current session open as fallback)
sudo systemctl restart sshd

# Test from another terminal BEFORE closing current session
ssh deploy@YOUR_SERVER_IP
```

### SSH Key Generation (Client Side)

```bash
# Generate Ed25519 key (recommended)
ssh-keygen -t ed25519 -a 100 -C "deploy@$(hostname)" -f ~/.ssh/id_ed25519_server

# For legacy compatibility (RSA 4096)
ssh-keygen -t rsa -b 4096 -a 100 -C "deploy@$(hostname)" -f ~/.ssh/id_rsa_server
```

---

## Firewall Configuration

### Decision Tree

```
Which firewall tool?
├── Simple VPS, few rules, Ubuntu → UFW (easiest)
├── Complex rules, NAT, advanced filtering → nftables (modern, recommended)
└── Legacy systems, existing scripts → iptables (avoid for new setups)
```

### UFW (Uncomplicated Firewall)

```bash
# Install and configure
sudo apt install -y ufw

# Default policies: deny everything inbound
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Allow SSH (do this FIRST to avoid lockout)
sudo ufw allow 22/tcp comment 'SSH'

# Allow web traffic
sudo ufw allow 80/tcp comment 'HTTP'
sudo ufw allow 443/tcp comment 'HTTPS'

# Rate limit SSH (auto-deny after 6 connections in 30 seconds)
sudo ufw limit 22/tcp

# Allow specific IP for monitoring (example)
sudo ufw allow from 10.0.0.5 to any port 9100 proto tcp comment 'Prometheus node_exporter'

# Enable (will prompt -- say yes)
sudo ufw enable

# Verify
sudo ufw status verbose
sudo ufw status numbered
```

### nftables (Modern, Recommended for Complex Setups)

```bash
# /etc/nftables.conf
#!/usr/sbin/nft -f

flush ruleset

table inet filter {
    # --- Sets for dynamic management ---
    set ssh_allowed {
        type ipv4_addr
        flags interval
        elements = { 0.0.0.0/0 }      # Restrict to known IPs in production
    }

    set blocked {
        type ipv4_addr
        flags interval, timeout
        timeout 1h
    }

    chain input {
        type filter hook input priority 0; policy drop;

        # --- Connection tracking ---
        ct state established,related accept
        ct state invalid drop

        # --- Loopback ---
        iif lo accept

        # --- Drop blocked IPs ---
        ip saddr @blocked drop

        # --- ICMP (limited) ---
        ip protocol icmp icmp type { echo-request } limit rate 5/second accept

        # --- SSH (rate limited) ---
        tcp dport 22 ip saddr @ssh_allowed ct state new limit rate 4/minute accept

        # --- HTTP/HTTPS ---
        tcp dport { 80, 443 } accept

        # --- Node exporter (internal only) ---
        tcp dport 9100 ip saddr 10.0.0.0/8 accept

        # --- Log and drop everything else ---
        log prefix "[nftables-drop] " flags all counter drop
    }

    chain forward {
        type filter hook forward priority 0; policy drop;
    }

    chain output {
        type filter hook output priority 0; policy accept;
    }
}
```

```bash
# Validate and apply
sudo nft -c -f /etc/nftables.conf    # Dry run (check syntax)
sudo nft -f /etc/nftables.conf       # Apply
sudo systemctl enable nftables

# Verify
sudo nft list ruleset
```

---

## Fail2ban Configuration

```bash
sudo apt install -y fail2ban
```

### /etc/fail2ban/jail.local

```ini
[DEFAULT]
# Ban duration (1 hour, increases on repeat offenses)
bantime = 3600
bantime.increment = true
bantime.factor = 2
bantime.maxtime = 604800

# Detection window and threshold
findtime = 600
maxretry = 5

# Action: ban via nftables (or ufw)
banaction = nftables-multiport
# banaction = ufw                   # Use this if using UFW instead

# Notifications (optional)
# destemail = admin@example.com
# sender = fail2ban@example.com
# action = %(action_mwl)s

# Ignore trusted IPs
ignoreip = 127.0.0.1/8 ::1

[sshd]
enabled = true
port = 22
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 7200

[sshd-aggressive]
enabled = true
port = 22
filter = sshd[mode=aggressive]
logpath = /var/log/auth.log
maxretry = 3
bantime = 86400

[nginx-http-auth]
enabled = true
port = http,https
filter = nginx-http-auth
logpath = /var/log/nginx/error.log
maxretry = 5

[nginx-limit-req]
enabled = true
port = http,https
filter = nginx-limit-req
logpath = /var/log/nginx/error.log
maxretry = 10

[nginx-botsearch]
enabled = true
port = http,https
filter = nginx-botsearch
logpath = /var/log/nginx/access.log
maxretry = 2
```

```bash
# Enable and start
sudo systemctl enable fail2ban
sudo systemctl start fail2ban

# Verify
sudo fail2ban-client status
sudo fail2ban-client status sshd

# Manually unban an IP
sudo fail2ban-client set sshd unbanip 1.2.3.4
```

---

## Kernel Hardening (sysctl)

### /etc/sysctl.d/99-hardening.conf

```ini
# === Network: IP Spoofing & Source Routing ===
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv6.conf.all.accept_source_route = 0
net.ipv6.conf.default.accept_source_route = 0

# === Network: ICMP Hardening ===
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1
net.ipv4.icmp_ratelimit = 100

# === Network: Disable Redirects (prevent MITM) ===
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.conf.all.secure_redirects = 0
net.ipv4.conf.default.secure_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0

# === Network: Disable IP Forwarding (unless router) ===
net.ipv4.ip_forward = 0
net.ipv6.conf.all.forwarding = 0

# === Network: SYN Flood Protection ===
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_syn_backlog = 4096
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_syn_retries = 3

# === Network: TCP Hardening ===
net.ipv4.tcp_timestamps = 0
net.ipv4.tcp_sack = 1
net.ipv4.tcp_fin_timeout = 15
net.ipv4.tcp_keepalive_time = 600
net.ipv4.tcp_keepalive_intvl = 60
net.ipv4.tcp_keepalive_probes = 5

# === Network: Disable IPv6 (if not needed) ===
# Uncomment if IPv6 is not used
# net.ipv6.conf.all.disable_ipv6 = 1
# net.ipv6.conf.default.disable_ipv6 = 1

# === Kernel: Address Space Layout Randomization ===
kernel.randomize_va_space = 2

# === Kernel: Restrict dmesg and kernel pointers ===
kernel.dmesg_restrict = 1
kernel.kptr_restrict = 2

# === Kernel: Restrict ptrace (prevent process spying) ===
kernel.yama.ptrace_scope = 2

# === Kernel: Restrict unprivileged BPF and userfaultfd ===
kernel.unprivileged_bpf_disabled = 1
kernel.unprivileged_userns_clone = 0

# === Kernel: Core dumps ===
fs.suid_dumpable = 0

# === Kernel: Restrict loading kernel modules ===
# Enable after all needed modules are loaded at boot
# kernel.modules_disabled = 1

# === File System: Harden symlink/hardlink behavior ===
fs.protected_symlinks = 1
fs.protected_hardlinks = 1
fs.protected_fifos = 2
fs.protected_regular = 2
```

```bash
# Apply immediately
sudo sysctl --system

# Verify specific values
sudo sysctl net.ipv4.conf.all.rp_filter
sudo sysctl kernel.randomize_va_space
```

---

## Systemd Service Hardening

Apply these directives to every custom service unit. They enforce sandboxing with
near-zero performance cost.

### Template: /etc/systemd/system/myapp.service

```ini
[Unit]
Description=My Application
After=network-online.target
Wants=network-online.target
StartLimitIntervalSec=300
StartLimitBurst=5

[Service]
Type=exec
User=myapp
Group=myapp
WorkingDirectory=/opt/myapp

ExecStart=/opt/myapp/bin/server
ExecReload=/bin/kill -HUP $MAINPID
Restart=on-failure
RestartSec=5
TimeoutStartSec=30
TimeoutStopSec=30
WatchdogSec=60

# === Filesystem Sandboxing ===
ProtectSystem=strict                  # Mount / as read-only (except /etc, /usr, /boot)
ProtectHome=yes                       # Hide /home, /root, /run/user
ReadWritePaths=/opt/myapp/data        # Explicitly allow app data directory
PrivateTmp=yes                        # Isolated /tmp for this service
PrivateDevices=yes                    # No access to /dev (except /dev/null, /dev/zero, etc.)
ProtectKernelTunables=yes             # Block writes to /proc and /sys
ProtectKernelModules=yes              # Block loading kernel modules
ProtectKernelLogs=yes                 # Block access to kernel log ring buffer
ProtectControlGroups=yes              # Block writes to cgroup filesystem
ProtectClock=yes                      # Block setting system clock
ProtectHostname=yes                   # Block changing hostname

# === Network ===
RestrictAddressFamilies=AF_INET AF_INET6 AF_UNIX
IPAddressDeny=any
IPAddressAllow=localhost              # Adjust for actual needed connectivity
# IPAddressAllow=0.0.0.0/0           # Allow all IPv4 if service needs network

# === Privilege Restriction ===
NoNewPrivileges=yes                   # Cannot gain privileges via setuid/setgid
CapabilityBoundingSet=                # Drop ALL capabilities (empty = none)
# CapabilityBoundingSet=CAP_NET_BIND_SERVICE   # Add back only if binding port < 1024
AmbientCapabilities=                  # No ambient capabilities
SecureBits=no-setuid-fixup

# === System Call Filtering ===
SystemCallFilter=@system-service      # Whitelist common service syscalls
SystemCallFilter=~@debug @mount @reboot @swap @clock @cpu-emulation @obsolete @raw-io
SystemCallArchitectures=native        # Block non-native syscalls (32-bit compat)
SystemCallErrorNumber=EPERM

# === Misc Hardening ===
LockPersonality=yes                   # Block changing execution domain
MemoryDenyWriteExecute=yes            # Block W+X memory pages (breaks JIT if needed)
RestrictRealtime=yes                  # Block real-time scheduling
RestrictSUIDSGID=yes                  # Block creating SUID/SGID files
RestrictNamespaces=yes                # Block creating new namespaces
RemoveIPC=yes                         # Remove SysV IPC on stop
PrivateUsers=yes                      # Isolated user namespace
UMask=0077                            # Restrictive file creation mask

# === Resource Limits ===
LimitNOFILE=65536
LimitNPROC=4096
MemoryMax=512M
CPUQuota=100%

# === Logging ===
StandardOutput=journal
StandardError=journal
SyslogIdentifier=myapp

[Install]
WantedBy=multi-user.target
```

```bash
# Analyze security of a service (score 0-10, aim for 8+)
systemd-analyze security myapp.service

# Apply changes
sudo systemctl daemon-reload
sudo systemctl restart myapp.service
```

---

## Unattended Upgrades

```bash
sudo apt install -y unattended-upgrades apt-listchanges
```

### /etc/apt/apt.conf.d/50unattended-upgrades

```
Unattended-Upgrade::Allowed-Origins {
    "${distro_id}:${distro_codename}";
    "${distro_id}:${distro_codename}-security";
    "${distro_id}ESMApps:${distro_codename}-apps-security";
    "${distro_id}ESM:${distro_codename}-infra-security";
};

// Remove unused kernel packages and dependencies
Unattended-Upgrade::Remove-Unused-Kernel-Packages "true";
Unattended-Upgrade::Remove-New-Unused-Dependencies "true";
Unattended-Upgrade::Remove-Unused-Dependencies "true";

// Auto-reboot if needed (at 3 AM)
Unattended-Upgrade::Automatic-Reboot "true";
Unattended-Upgrade::Automatic-Reboot-Time "03:00";
Unattended-Upgrade::Automatic-Reboot-WithUsers "true";

// Email notifications
// Unattended-Upgrade::Mail "admin@example.com";
// Unattended-Upgrade::MailReport "on-change";

// Logging
Unattended-Upgrade::SyslogEnable "true";
Unattended-Upgrade::SyslogFacility "daemon";

// Bandwidth limit (kB/s)
// Acquire::http::Dl-Limit "1000";
```

### /etc/apt/apt.conf.d/20auto-upgrades

```
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
```

```bash
# Test (dry run)
sudo unattended-upgrade --dry-run --debug

# Verify timer
sudo systemctl status apt-daily-upgrade.timer
```

---

## Lynis Auditing

Lynis is a security auditing tool for Linux. Target a hardening index of 80 or higher.

```bash
# Install
sudo apt install -y lynis

# Or install latest from upstream
git clone https://github.com/CISOfy/lynis.git /opt/lynis
cd /opt/lynis && sudo ./lynis audit system

# Run full audit
sudo lynis audit system --quick

# Run with specific profile
sudo lynis audit system --profile /etc/lynis/custom.prf

# Run specific test group
sudo lynis audit system --tests-from-group "firewalls"
sudo lynis audit system --tests-from-group "ssh"
sudo lynis audit system --tests-from-group "authentication"
```

### Interpreting Results

| Hardening Index | Status | Action |
|---|---|---|
| 85-100 | Excellent | Maintain, monitor for drift |
| 70-84 | Good | Address warnings, schedule fixes |
| 55-69 | Fair | Prioritize critical suggestions |
| Below 55 | Weak | Immediate action required |

```bash
# Key output files
cat /var/log/lynis.log             # Full audit log
cat /var/log/lynis-report.dat      # Machine-parseable results

# Extract warnings and suggestions
grep "warning\[\]" /var/log/lynis-report.dat
grep "suggestion\[\]" /var/log/lynis-report.dat

# Schedule weekly audit via cron
# /etc/cron.d/lynis-audit
0 4 * * 0 root /usr/sbin/lynis audit system --quick --cronjob > /var/log/lynis-weekly.log 2>&1
```

### Common Lynis Fixes

| Lynis Finding | Fix |
|---|---|
| BOOT-5122: No password for GRUB | `grub-mkpasswd-pbkdf2` + update GRUB config |
| SSH-7408: Weak ciphers | Apply SSH hardening config above |
| AUTH-9286: No password policy | `apt install libpam-pwquality`, configure `/etc/security/pwquality.conf` |
| FILE-6310: No AIDE database | Install and initialize AIDE |
| FIRE-4512: No firewall active | Enable UFW or nftables |
| KRNL-6000: sysctl hardening | Apply sysctl config above |
| HRDN-7222: Compilers present | `sudo apt remove gcc g++` if not needed |

---

## Nginx Reverse Proxy Hardening

### /etc/nginx/nginx.conf (Global)

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

### /etc/nginx/sites-available/app.conf (Virtual Host)

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

### Caddy (Alternative --- Automatic TLS)

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

### Decision Tree

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

## User Management & sudo

### Principle of Least Privilege for sudo

```bash
# /etc/sudoers.d/deploy
# Specific command allowlist -- NOT blanket NOPASSWD: ALL

# Application management
deploy ALL=(root) NOPASSWD: /usr/bin/systemctl restart myapp.service
deploy ALL=(root) NOPASSWD: /usr/bin/systemctl reload myapp.service
deploy ALL=(root) NOPASSWD: /usr/bin/systemctl status myapp.service

# Docker (if needed)
deploy ALL=(root) NOPASSWD: /usr/bin/docker compose -f /opt/myapp/compose.yaml *

# Log viewing
deploy ALL=(root) NOPASSWD: /usr/bin/journalctl -u myapp.service *

# Package updates (controlled)
deploy ALL=(root) NOPASSWD: /usr/bin/apt update
deploy ALL=(root) NOPASSWD: /usr/bin/apt upgrade -y
```

```bash
# Validate sudoers syntax (always use visudo)
sudo visudo -c -f /etc/sudoers.d/deploy

# Password policy -- /etc/security/pwquality.conf
# minlen = 14
# dcredit = -1
# ucredit = -1
# lcredit = -1
# ocredit = -1
# maxrepeat = 3
# gecoscheck = 1
# dictcheck = 1

# Account lockout -- /etc/pam.d/common-auth
# auth required pam_faillock.so preauth deny=5 unlock_time=900
# auth required pam_faillock.so authfail deny=5 unlock_time=900
```

### User Audit Commands

```bash
# List all users with login shells
awk -F: '$7 !~ /(nologin|false)/ {print $1}' /etc/passwd

# List sudo users
getent group sudo

# Check for empty passwords
sudo awk -F: '($2 == "" || $2 == "!") {print $1}' /etc/shadow

# Check for UID 0 (root-equivalent) accounts
awk -F: '$3 == 0 {print $1}' /etc/passwd

# List recently logged-in users
last -10

# List failed login attempts
sudo lastb -10
```

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

### Remote Log Shipping (rsyslog to Central Server)

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

---

## Intrusion Detection

### AIDE (Advanced Intrusion Detection Environment)

```bash
# Install
sudo apt install -y aide

# Initialize database (takes several minutes)
sudo aideinit

# Move new database into place
sudo mv /var/lib/aide/aide.db.new /var/lib/aide/aide.db

# Run a check
sudo aide --check

# After legitimate changes, update the database
sudo aide --update
sudo mv /var/lib/aide/aide.db.new /var/lib/aide/aide.db
```

### rkhunter (Rootkit Hunter)

```bash
# Install
sudo apt install -y rkhunter

# Update definitions
sudo rkhunter --update
sudo rkhunter --propupd

# Run scan
sudo rkhunter --check --skip-keypress

# Schedule daily scan
# /etc/cron.d/rkhunter
0 5 * * * root /usr/bin/rkhunter --check --cronjob --report-warnings-only >> /var/log/rkhunter-daily.log 2>&1
```

---

## AppArmor (Mandatory Access Control)

```bash
# Check status
sudo aa-status

# Install utilities
sudo apt install -y apparmor-utils

# Put a profile in enforce mode
sudo aa-enforce /etc/apparmor.d/usr.sbin.nginx

# Put in complain mode (logs violations without blocking)
sudo aa-complain /etc/apparmor.d/usr.sbin.nginx

# Generate profile for a new application
sudo aa-genprof /opt/myapp/bin/server
```

---

## Anti-Patterns

| Anti-Pattern | Why It's Dangerous | Fix |
|---|---|---|
| Root login via SSH | Single point of compromise for full system | `PermitRootLogin no`, use deploy user + sudo |
| Password SSH auth | Brute-forceable | Key-only: `PasswordAuthentication no` |
| `chmod 777` anything | World-writable files | Minimal permissions: `chmod 640` for configs, `chmod 750` for dirs |
| `sudo NOPASSWD: ALL` | Any command as root without password | Allowlist specific commands per user |
| No firewall | Every port exposed to internet | UFW/nftables with default deny |
| Firewall allows all outbound | Exfiltration goes undetected | Restrict outbound to needed ports + DNS |
| Running services as root | Compromised service = full system compromise | Dedicated service users, systemd `User=` |
| No unattended upgrades | Known CVEs remain exploitable | Enable `unattended-upgrades` |
| Shared SSH keys across servers | One compromised key = all servers compromised | Unique key per server/user pair |
| Storing secrets in plaintext | Accessible to any user with file read | `chmod 600`, dedicated secrets management |
| No log rotation | Disk fills up, logs lost | Configure logrotate and journald limits |
| Default sysctl values | Kernel vulnerable to known network attacks | Apply sysctl hardening |
| Ignoring Lynis warnings | Known vulnerabilities remain | Run Lynis monthly, address all warnings |
| No backup testing | Backups may be corrupt or incomplete | Monthly restore tests to verify |
| Self-signed TLS in production | No trust chain, MitM possible | Let's Encrypt + certbot auto-renewal |
| Disabling SELinux/AppArmor | Removes mandatory access control | Keep enabled, fix profiles instead |

---

## Review Checklist

### Access Control
- [ ] Root login disabled (`PermitRootLogin no`)
- [ ] Password authentication disabled (SSH keys only)
- [ ] SSH uses modern ciphers and key algorithms
- [ ] SSH rate limited (fail2ban + firewall)
- [ ] Deploy user has minimal sudo permissions (command allowlist)
- [ ] No accounts with empty passwords
- [ ] No extra UID 0 accounts besides root

### Network
- [ ] Firewall enabled with default deny inbound policy
- [ ] Only ports 22, 80, 443 open (plus monitoring if needed)
- [ ] Fail2ban active on SSH and web endpoints
- [ ] Internal services bound to 127.0.0.1 or private network only
- [ ] Outbound traffic restricted to necessary destinations

### Kernel & System
- [ ] sysctl hardening applied (IP spoofing, SYN flood, redirects)
- [ ] ASLR enabled (`kernel.randomize_va_space = 2`)
- [ ] Core dumps disabled for SUID binaries
- [ ] Unnecessary services disabled (`systemctl list-unit-files --state=enabled`)
- [ ] Compilers removed if not needed

### Services
- [ ] Every custom service has systemd hardening directives
- [ ] `systemd-analyze security` score >= 8 for critical services
- [ ] Services run as dedicated non-root users
- [ ] `NoNewPrivileges=yes` on all services
- [ ] `ProtectSystem=strict` and `PrivateTmp=yes` on all services

### Updates & Patching
- [ ] Unattended security upgrades enabled and verified
- [ ] Automatic reboot configured for kernel updates
- [ ] All packages up to date (`apt list --upgradable` empty)

### TLS & Web
- [ ] TLS 1.2+ only, strong cipher suites
- [ ] HSTS with `includeSubDomains` and `preload`
- [ ] Certificates auto-renewed (certbot timer active)
- [ ] Security headers configured (CSP, X-Frame-Options, Permissions-Policy)
- [ ] Nginx/Caddy version hidden (`server_tokens off`)

### Monitoring & Logging
- [ ] node_exporter running and scraped by Prometheus
- [ ] Alerts configured for disk, CPU, memory, failed services
- [ ] Journald persistence enabled with size limits
- [ ] Log rotation configured for all application logs
- [ ] Auth logs monitored for anomalies

### Backup & Recovery
- [ ] Automated backups running daily (3-2-1 rule)
- [ ] Backups encrypted (borg repokey or restic encryption)
- [ ] Restore procedure documented and tested monthly
- [ ] Database dumps included in backup

### Intrusion Detection
- [ ] AIDE or equivalent file integrity monitoring initialized
- [ ] rkhunter running scheduled scans
- [ ] AppArmor/SELinux enabled and enforcing
- [ ] Lynis audit score >= 80

### Compliance
- [ ] Lynis audit run monthly with results tracked
- [ ] All findings documented with remediation timeline
- [ ] Server provisioning scripted and reproducible
- [ ] Change log maintained for all security-relevant modifications
