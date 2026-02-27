# Host & Daemon Hardening Reference

Hardening the Docker host and daemon for production. Covers daemon.json, seccomp, AppArmor, auditd, firewall rules, rootless mode, user namespace remapping, and Docker Bench.

---

## Production daemon.json

Location: `/etc/docker/daemon.json`

```json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "5"
  },
  "storage-driver": "overlay2",
  "live-restore": true,
  "userland-proxy": false,
  "no-new-privileges": true,
  "icc": false,
  "default-ulimits": {
    "nofile": { "Name": "nofile", "Hard": 65536, "Soft": 65536 },
    "nproc": { "Name": "nproc", "Hard": 4096, "Soft": 4096 }
  },
  "default-address-pools": [
    { "base": "172.20.0.0/14", "size": 24 }
  ],
  "exec-opts": ["native.cgroupdriver=systemd"],
  "features": {
    "containerd-snapshotter": true
  },
  "builder": {
    "gc": {
      "enabled": true,
      "defaultKeepStorage": "20GB"
    }
  }
}
```

### Key Settings Explained

| Setting | Purpose | Notes |
|---|---|---|
| `live-restore: true` | Containers survive daemon restarts | Patch-level upgrades only |
| `userland-proxy: false` | Use iptables instead of userland proxy | Better performance, direct kernel routing |
| `no-new-privileges: true` | Global default for all containers | Prevents setuid escalation |
| `icc: false` | Disable inter-container communication on default bridge | Forces explicit networks |
| `log-opts.max-size/max-file` | Log rotation | Prevents disk fill from runaway logs |
| `default-ulimits` | File descriptor + process limits | Prevents fork bombs, fd exhaustion |
| `default-address-pools` | Custom subnet ranges | Avoids conflicts with VPN/corporate networks |
| `containerd-snapshotter` | Enable containerd image store | Required for `--mount type=image` (v28+) |

After changing daemon.json:
```bash
sudo systemctl restart docker
docker info  # verify settings applied
```

---

## Seccomp Profiles

Docker applies a default seccomp profile that blocks ~44 dangerous syscalls. **Never disable it** (`--security-opt seccomp=unconfined`).

### Default Profile (automatic, recommended)

```yaml
services:
  app:
    # Default seccomp profile is applied automatically
    # Just don't add: security_opt: [seccomp=unconfined]
    security_opt:
      - no-new-privileges:true
      # seccomp default is already active
```

### Custom Seccomp (High-Security Workloads)

Generate a minimal profile by tracing your app's syscalls:

```bash
# 1. Trace syscalls (run in staging, NOT production)
docker run --rm --security-opt seccomp=unconfined \
  strace -c -f -S name myapp:latest 2>&1 | tail -50

# 2. Start from Docker's default and remove unused syscalls
curl -sL https://raw.githubusercontent.com/moby/moby/master/profiles/seccomp/default.json \
  -o custom-seccomp.json

# 3. Apply custom profile
docker run --security-opt seccomp=custom-seccomp.json myapp:latest
```

In compose:
```yaml
services:
  app:
    security_opt:
      - no-new-privileges:true
      - seccomp=./seccomp/app-profile.json
```

**Recommendation:** Keep default seccomp for most workloads. Only create custom profiles for high-security containers handling sensitive data.

---

## AppArmor Profiles

Docker loads `docker-default` AppArmor profile automatically. Never disable it.

```yaml
services:
  app:
    security_opt:
      - no-new-privileges:true
      - apparmor=docker-default    # explicit, same as default
```

Verify AppArmor is active:
```bash
docker inspect --format='{{.HostConfig.SecurityOpt}}' <container>
# Or check from inside:
docker exec <container> cat /proc/1/attr/current
```

---

## User Namespace Remapping

Maps container root (UID 0) to an unprivileged host user. Even if an attacker escapes the container as root, they're unprivileged on the host.

### Enable in daemon.json

```json
{
  "userns-remap": "default"
}
```

Docker creates a `dockremap` user automatically. Verify:
```bash
id dockremap
cat /etc/subuid  # shows UID range mapping
cat /etc/subgid  # shows GID range mapping
```

**Caveats:**
- Breaks host volume mounts with strict permissions
- Incompatible with `--privileged`
- Some images may need UID adjustment
- Test thoroughly before enabling in production

### Alternative: In-Container Non-Root (Preferred)

If userns-remap is too disruptive, enforce non-root in images + compose:

```yaml
services:
  app:
    user: "10001:10001"
    read_only: true
    cap_drop: [ALL]
```

---

## Rootless Docker

Runs the entire Docker daemon as a non-root user. The strongest isolation option.

```bash
# Install rootless Docker
dockerd-rootless-setuptool.sh install

# Verify
docker info | grep -i rootless
# Should show: Security Options: rootlesskit
```

**Trade-offs:**
- No privileged containers
- Limited networking (no low-port binding without `setcap`)
- Some storage drivers unavailable
- Ideal for single-tenant CI runners or high-security workloads

---

## Auditing with auditd

Monitor Docker daemon and socket activity:

```bash
# Install auditd
sudo apt-get install auditd

# Add Docker audit rules
sudo tee /etc/audit/rules.d/docker.rules << 'EOF'
-w /usr/bin/docker -p rwxa -k docker
-w /usr/bin/dockerd -p rwxa -k docker
-w /var/run/docker.sock -p rwxa -k docker
-w /etc/docker -p rwxa -k docker
-w /etc/docker/daemon.json -p rwxa -k docker
-w /usr/lib/systemd/system/docker.service -p rwxa -k docker
-w /var/lib/docker -p rwxa -k docker
EOF

# Reload rules
sudo auditctl -R /etc/audit/rules.d/docker.rules

# Check audit logs
sudo ausearch -k docker --interpret
```

---

## Firewall Rules

Only expose ports 80, 443, and SSH. Docker manipulates iptables directly, which can bypass UFW.

### Option 1: Docker + UFW Fix

```bash
# /etc/docker/daemon.json
{
  "iptables": true,
  "ip-forward": true
}

# Prevent Docker from bypassing UFW
sudo tee /etc/ufw/after.rules >> << 'EOF'
# BEGIN DOCKER UFW FIX
*filter
:DOCKER-USER - [0:0]
-A DOCKER-USER -j RETURN -s 10.0.0.0/8
-A DOCKER-USER -j RETURN -s 172.16.0.0/12
-A DOCKER-USER -j RETURN -s 192.168.0.0/16
-A DOCKER-USER -j DROP -p tcp -m tcp --dport 0:65535
COMMIT
# END DOCKER UFW FIX
EOF

sudo ufw reload
```

### Option 2: Bind to 127.0.0.1 (Recommended)

```yaml
services:
  app:
    # Only bind to loopback — Traefik connects via Docker network
    ports:
      - "127.0.0.1:3000:3000"

  db:
    # No ports exposed at all — backend network only
    networks: [backend]
```

---

## Docker Bench for Security

Official CIS benchmark scanner for Docker hosts:

```bash
# Run the audit
docker run --rm --net host --pid host --userns host \
  --cap-add audit_control \
  -e DOCKER_CONTENT_TRUST=$DOCKER_CONTENT_TRUST \
  -v /var/lib:/var/lib:ro \
  -v /var/run/docker.sock:/var/run/docker.sock:ro \
  -v /usr/lib/systemd:/usr/lib/systemd:ro \
  -v /etc:/etc:ro \
  --label docker_bench_security \
  docker/docker-bench-security

# Review results and fix WARN items
# Focus on: daemon config, container runtime, Docker files
```

**Run weekly** as part of your security audit process. Aim for zero WARN on:
- Section 1: Host Configuration
- Section 2: Docker Daemon Configuration
- Section 4: Container Images and Build File
- Section 5: Container Runtime

---

## Complete Host Hardening Checklist

### Docker Engine
- [ ] Docker Engine v28+ or v29+ (latest stable)
- [ ] `daemon.json` hardened (see above)
- [ ] `live-restore: true` for zero-downtime daemon upgrades
- [ ] `no-new-privileges: true` as daemon default
- [ ] `icc: false` to disable default bridge communication
- [ ] Log rotation configured (`max-size`, `max-file`)
- [ ] Default ulimits set (nofile, nproc)
- [ ] Custom address pools to avoid network conflicts

### Kernel & OS
- [ ] Automatic security updates enabled
- [ ] auditd monitoring Docker socket and binaries
- [ ] Firewall blocks all except 80/443/SSH
- [ ] Docker socket permissions: `root:docker`, mode 660
- [ ] SSH key-only auth, root login disabled
- [ ] Separate partition for `/var/lib/docker`

### Runtime Defaults
- [ ] Default seccomp profile active (never `unconfined`)
- [ ] Default AppArmor profile active (never `unconfined`)
- [ ] User namespace remapping OR strict non-root in all containers
- [ ] Rootless Docker for high-security workloads
- [ ] No containers run with `--privileged`
- [ ] No containers mount Docker socket (use socket proxy)

### Monitoring & Maintenance
- [ ] Docker Bench for Security run weekly
- [ ] Host monitoring (CPU, memory, disk, Docker daemon health)
- [ ] Centralized log shipping
- [ ] Automated image rebuilds (weekly security patches)
- [ ] Docker system prune scheduled (unused images, build cache)
