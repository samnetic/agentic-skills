# System Hardening & Services Reference

Deep-dive configurations for kernel sysctl tuning, systemd service sandboxing, unattended upgrades, AppArmor/SELinux, intrusion detection, and Lynis auditing.

---

## Table of Contents

- [Kernel Hardening (sysctl)](#kernel-hardening-sysctl)
- [Systemd Service Hardening](#systemd-service-hardening)
  - [Template Service Unit](#template-service-unit)
  - [Security Analysis](#security-analysis)
- [Unattended Upgrades](#unattended-upgrades)
- [Intrusion Detection](#intrusion-detection)
  - [AIDE (Advanced Intrusion Detection Environment)](#aide-advanced-intrusion-detection-environment)
  - [rkhunter (Rootkit Hunter)](#rkhunter-rootkit-hunter)
- [AppArmor (Mandatory Access Control)](#apparmor-mandatory-access-control)
- [Lynis Auditing](#lynis-auditing)
  - [Interpreting Results](#interpreting-results)
  - [Common Lynis Fixes](#common-lynis-fixes)

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

Apply these directives to every custom service unit. They enforce sandboxing with near-zero performance cost.

### Template Service Unit

Place at `/etc/systemd/system/myapp.service`:

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

### Security Analysis

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
| SSH-7408: Weak ciphers | Apply SSH hardening config (see network-and-access-security.md) |
| AUTH-9286: No password policy | `apt install libpam-pwquality`, configure `/etc/security/pwquality.conf` |
| FILE-6310: No AIDE database | Install and initialize AIDE (see above) |
| FIRE-4512: No firewall active | Enable UFW or nftables (see network-and-access-security.md) |
| KRNL-6000: sysctl hardening | Apply sysctl config (see above) |
| HRDN-7222: Compilers present | `sudo apt remove gcc g++` if not needed |
