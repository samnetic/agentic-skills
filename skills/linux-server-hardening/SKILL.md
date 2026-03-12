---
name: linux-server-hardening
description: >-
  Linux server administration and security hardening expertise. Use when setting up a
  VPS or bare-metal server, hardening SSH, configuring firewalls (UFW, nftables),
  setting up fail2ban, managing users and sudo, configuring systemd security directives,
  enabling unattended updates, kernel hardening via sysctl, running CIS audits with
  Lynis, disk encryption (LUKS), log management, intrusion detection (AIDE, rkhunter),
  backup strategies (borgbackup, restic), Nginx/Caddy reverse proxy hardening, TLS
  management, or preparing for compliance audits.
  Triggers: VPS, server, Linux, Ubuntu, Debian, SSH, firewall, UFW, nftables, fail2ban,
  sysctl, kernel hardening, CIS benchmark, Lynis, systemd, hardening, security audit,
  server setup, LUKS, backup, borgbackup, restic, nginx, caddy, TLS, Let's Encrypt,
  AppArmor, SELinux.
license: MIT
compatibility: Designed for Debian/Ubuntu Linux servers
metadata:
  author: samnetic
  version: "1.0"
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

## Workflow: Server Hardening (14 Steps)

Execute these steps in order for every new server. Each step links to the reference file containing full configuration details.

### 1. PROVISION --- Minimal OS Install

Install Ubuntu 24.04 LTS or Debian 12 with minimal packages. Remove any default services you will not use.

### 2. ACCESS --- Create Deploy User

```bash
useradd -m -s /bin/bash -G sudo deploy
passwd -l deploy                  # Lock password (SSH key only)
mkdir -p /home/deploy/.ssh && chmod 700 /home/deploy/.ssh
# Copy public key, then verify login BEFORE disabling root
```

Lock root: `sudo passwd -l root && sudo usermod -s /usr/sbin/nologin root`

> Full details: `references/network-and-access-security.md` -> Initial Server Setup

### 3. SSH HARDEN --- Key-Only Auth, Modern Ciphers

Create `/etc/ssh/sshd_config.d/99-hardening.conf` with these essentials:

```sshd_config
PermitRootLogin no
PasswordAuthentication no
AuthenticationMethods publickey
HostKeyAlgorithms ssh-ed25519,rsa-sha2-512,rsa-sha2-256
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com
MaxAuthTries 3
X11Forwarding no
AllowTcpForwarding no
DisableForwarding yes
LogLevel VERBOSE
AllowUsers deploy
```

Always run `sudo sshd -t` before restarting. Keep a fallback session open.

> Full config: `references/network-and-access-security.md` -> SSH Hardening

### 4. FIREWALL --- Default Deny Inbound

```bash
# UFW quick start
sudo ufw default deny incoming && sudo ufw default allow outgoing
sudo ufw allow 22/tcp comment 'SSH'
sudo ufw allow 80/tcp comment 'HTTP'
sudo ufw allow 443/tcp comment 'HTTPS'
sudo ufw limit 22/tcp
sudo ufw enable
```

> Full UFW + nftables configs: `references/network-and-access-security.md` -> Firewall Configuration

### 5. UPDATES --- Unattended Security Patches

```bash
sudo apt install -y unattended-upgrades apt-listchanges
sudo unattended-upgrade --dry-run --debug   # Verify
```

> Full config: `references/system-hardening-and-services.md` -> Unattended Upgrades

### 6. KERNEL --- sysctl Hardening

Key parameters to set in `/etc/sysctl.d/99-hardening.conf`:

| Category | Key Parameters |
|---|---|
| Anti-spoofing | `rp_filter=1`, disable source routing, disable redirects |
| SYN flood | `tcp_syncookies=1`, `tcp_max_syn_backlog=4096` |
| ASLR | `kernel.randomize_va_space=2` |
| Restrict kernel | `dmesg_restrict=1`, `kptr_restrict=2`, `ptrace_scope=2` |
| Filesystem | `protected_symlinks=1`, `protected_hardlinks=1` |

Apply with `sudo sysctl --system`.

> Full sysctl config: `references/system-hardening-and-services.md` -> Kernel Hardening

### 7. SERVICES --- Systemd Sandboxing

Every custom service must include these directives at minimum:

```ini
ProtectSystem=strict
ProtectHome=yes
PrivateTmp=yes
NoNewPrivileges=yes
CapabilityBoundingSet=
SystemCallFilter=@system-service
SystemCallArchitectures=native
```

Target `systemd-analyze security <service>` score >= 8.

> Full template: `references/system-hardening-and-services.md` -> Systemd Service Hardening

### 8. FAIL2BAN --- Intrusion Prevention

```bash
sudo apt install -y fail2ban
```

Configure `/etc/fail2ban/jail.local` with SSH jail (maxretry=3, bantime=7200) and nginx jails.

> Full config: `references/network-and-access-security.md` -> Fail2ban Configuration

### 9. IDS --- File Integrity Monitoring

```bash
# AIDE
sudo apt install -y aide && sudo aideinit
sudo mv /var/lib/aide/aide.db.new /var/lib/aide/aide.db

# rkhunter
sudo apt install -y rkhunter
sudo rkhunter --update && sudo rkhunter --propupd
```

> Full details: `references/system-hardening-and-services.md` -> Intrusion Detection

### 10. TLS --- Certbot + Auto-Renewal

```bash
sudo apt install -y certbot python3-certbot-nginx
sudo certbot --nginx -d example.com -d www.example.com \
    --non-interactive --agree-tos --email admin@example.com \
    --redirect --hsts --staple-ocsp
sudo certbot renew --dry-run   # Verify auto-renewal
```

> Full details + best practices table: `references/web-proxy-tls-and-infrastructure.md` -> TLS / Certificate Management

### 11. REVERSE PROXY --- Security Headers

Configure Nginx or Caddy with: HSTS, X-Content-Type-Options, X-Frame-Options, CSP, Referrer-Policy, Permissions-Policy. Hide server version. Rate-limit auth endpoints separately.

> Full Nginx + Caddy configs: `references/web-proxy-tls-and-infrastructure.md` -> Nginx Reverse Proxy Hardening

### 12. MONITORING --- node_exporter + Alerts

Install Prometheus node_exporter, bind to 127.0.0.1:9100, harden with systemd directives. Configure alerts for disk > 85%, memory > 90%, failed systemd units, and reboot required.

> Full setup + alert table: `references/web-proxy-tls-and-infrastructure.md` -> Monitoring

### 13. BACKUP --- Encrypted, Tested, 3-2-1 Rule

Use borgbackup or restic with encryption. Automate daily via cron. Prune retention: 7 daily, 4 weekly, 6 monthly. Test restores monthly.

> Full borgbackup + restic + automation script: `references/web-proxy-tls-and-infrastructure.md` -> Backup Strategies

### 14. AUDIT --- Lynis Score >= 80

```bash
sudo apt install -y lynis
sudo lynis audit system --quick
```

| Hardening Index | Status | Action |
|---|---|---|
| 85-100 | Excellent | Maintain, monitor for drift |
| 70-84 | Good | Address warnings, schedule fixes |
| 55-69 | Fair | Prioritize critical suggestions |
| Below 55 | Weak | Immediate action required |

> Full Lynis guide + common fixes: `references/system-hardening-and-services.md` -> Lynis Auditing

---

## Decision Tree

```
New server setup?
├── YES → Execute all 14 workflow steps in order
└── NO → What are you hardening?
    ├── SSH access         → Steps 2-3, then 8
    ├── Network/firewall   → Steps 4, 8
    ├── Kernel/OS          → Steps 5-7
    ├── Web-facing service → Steps 10-11, then 7
    ├── Backup strategy    → Step 13
    ├── Compliance audit   → Step 14, then fix gaps
    └── Monitoring gap     → Step 12

Which firewall tool?
├── Simple VPS, few rules, Ubuntu        → UFW
├── Complex rules, NAT, advanced         → nftables
└── Legacy systems, existing scripts     → iptables (avoid for new)

Which backup tool?
├── Dedup + encryption + compression     → borgbackup
├── Multi-backend (S3, B2, SFTP)         → restic
└── Simple file sync                     → rsync

Which reverse proxy?
├── Need fine-grained control, modules   → Nginx
└── Want automatic TLS, simple config    → Caddy
```

---

## Anti-Patterns

| Anti-Pattern | Why It's Dangerous | Fix |
|---|---|---|
| Root login via SSH | Single point of compromise for full system | `PermitRootLogin no`, use deploy user + sudo |
| Password SSH auth | Brute-forceable | Key-only: `PasswordAuthentication no` |
| `chmod 777` anything | World-writable files | Minimal permissions: `chmod 640` configs, `chmod 750` dirs |
| `sudo NOPASSWD: ALL` | Any command as root without password | Allowlist specific commands per user |
| No firewall | Every port exposed to internet | UFW/nftables with default deny |
| Firewall allows all outbound | Exfiltration goes undetected | Restrict outbound to needed ports + DNS |
| Running services as root | Compromised service = full system compromise | Dedicated service users, systemd `User=` |
| No unattended upgrades | Known CVEs remain exploitable | Enable `unattended-upgrades` |
| Shared SSH keys across servers | One compromised key = all servers | Unique key per server/user pair |
| Storing secrets in plaintext | Accessible to any user with file read | `chmod 600`, dedicated secrets management |
| No log rotation | Disk fills up, logs lost | Configure logrotate and journald limits |
| Default sysctl values | Kernel vulnerable to network attacks | Apply sysctl hardening |
| Ignoring Lynis warnings | Known vulnerabilities remain | Run Lynis monthly, address all warnings |
| No backup testing | Backups may be corrupt or incomplete | Monthly restore tests to verify |
| Self-signed TLS in production | No trust chain, MitM possible | Let's Encrypt + certbot auto-renewal |
| Disabling SELinux/AppArmor | Removes mandatory access control | Keep enabled, fix profiles instead |

---

## Progressive Disclosure Map

| Topic | Reference | When to Read |
|---|---|---|
| SSH config, key generation, deploy user setup | `references/network-and-access-security.md` | Setting up or auditing SSH access |
| UFW and nftables full configurations | `references/network-and-access-security.md` | Configuring or troubleshooting firewall rules |
| Fail2ban jails (SSH + Nginx) | `references/network-and-access-security.md` | Setting up intrusion prevention |
| User/sudo management, password policy, audit commands | `references/network-and-access-security.md` | Managing users or reviewing access controls |
| Kernel sysctl parameters (full config file) | `references/system-hardening-and-services.md` | Applying or reviewing kernel hardening |
| Systemd service hardening template | `references/system-hardening-and-services.md` | Creating or hardening a systemd service |
| Unattended upgrades configuration | `references/system-hardening-and-services.md` | Setting up automatic security patching |
| AIDE, rkhunter, AppArmor setup | `references/system-hardening-and-services.md` | Deploying file integrity or mandatory access control |
| Lynis audit guide, scoring, common fixes | `references/system-hardening-and-services.md` | Running compliance audits |
| Nginx global + vhost hardening, security headers | `references/web-proxy-tls-and-infrastructure.md` | Configuring reverse proxy |
| Caddy configuration | `references/web-proxy-tls-and-infrastructure.md` | Using Caddy instead of Nginx |
| TLS/certbot setup, best practices | `references/web-proxy-tls-and-infrastructure.md` | Managing certificates |
| borgbackup, restic, automated backup script | `references/web-proxy-tls-and-infrastructure.md` | Implementing backup strategy |
| Prometheus node_exporter + alert rules | `references/web-proxy-tls-and-infrastructure.md` | Setting up monitoring |
| journald, logrotate, remote log shipping | `references/web-proxy-tls-and-infrastructure.md` | Configuring log management |

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

### Intrusion Detection & Compliance
- [ ] AIDE or equivalent file integrity monitoring initialized
- [ ] rkhunter running scheduled scans
- [ ] AppArmor/SELinux enabled and enforcing
- [ ] Lynis audit score >= 80
- [ ] All findings documented with remediation timeline
- [ ] Server provisioning scripted and reproducible
- [ ] Change log maintained for all security-relevant modifications
