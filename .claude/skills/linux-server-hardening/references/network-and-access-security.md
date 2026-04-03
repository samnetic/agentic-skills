# Network & Access Security Reference

Deep-dive configurations for SSH hardening, firewall setup, fail2ban intrusion prevention, and user/sudo management.

---

## Table of Contents

- [Initial Server Setup](#initial-server-setup)
  - [Create Deploy User](#create-deploy-user)
  - [Disable Root Login and Password Auth](#disable-root-login-and-password-auth)
- [SSH Hardening](#ssh-hardening)
  - [sshd_config Hardening](#sshd_config-hardening)
  - [SSH Key Generation (Client Side)](#ssh-key-generation-client-side)
- [Firewall Configuration](#firewall-configuration)
  - [UFW (Uncomplicated Firewall)](#ufw-uncomplicated-firewall)
  - [nftables (Modern, Recommended for Complex Setups)](#nftables-modern-recommended-for-complex-setups)
- [Fail2ban Configuration](#fail2ban-configuration)
- [User Management & sudo](#user-management--sudo)
  - [Principle of Least Privilege for sudo](#principle-of-least-privilege-for-sudo)
  - [User Audit Commands](#user-audit-commands)

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

### sshd_config Hardening

Place this file at `/etc/ssh/sshd_config.d/99-hardening.conf`:

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

### Firewall Decision Tree

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
