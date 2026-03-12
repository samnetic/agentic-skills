# Bash Tools, Recipes, and Environment Reference

## Table of Contents

- [Text Processing](#text-processing)
- [File Operations](#file-operations)
- [Process Management](#process-management)
- [Docker Entrypoints](#docker-entrypoints)
- [Testing with BATS](#testing-with-bats)
- [Cron and Systemd Timers](#cron-and-systemd-timers)
- [ShellCheck Integration](#shellcheck-integration)
- [Portability](#portability)
  - [macOS vs Linux Differences](#macos-vs-linux-differences)
  - [POSIX sh vs Bash](#posix-sh-vs-bash)
  - [Feature Detection over Version Checking](#feature-detection-over-version-checking)
- [Common Recipes](#common-recipes)

---

## Text Processing

```bash
# ── jq — JSON processing (most important tool) ──
curl -s api.example.com/users | jq '.[] | {name: .name, email: .email}'
jq -r '.items[] | select(.status == "active") | .id' data.json
jq -n --arg name "$NAME" --arg email "$EMAIL" '{name: $name, email: $email}'

# Error handling for jq
if ! result=$(jq -r '.data.id' response.json 2>&1); then die "JSON parse failed: $result"; fi
[[ "$result" != "null" ]] || die "Missing .data.id in response"

# ── awk — field extraction ──
awk -F: '{print $1, $3}' /etc/passwd           # Fields by separator
awk '$3 > 1000 {print $1}' /etc/passwd         # Filter rows
awk '{sum += $2} END {print sum}' data.txt      # Sum a column

# ── sed — substitution ──
sed 's/old/new/g' file.txt                      # Substitute
sed -i.bak 's/old/new/g' file.txt && rm file.txt.bak  # Portable in-place
sed -n '10,20p' file.txt                        # Print line range
sed '/^#/d; /^$/d' config.txt                   # Remove comments and blanks

# ── grep patterns ──
grep -rn "TODO" --include="*.sh" .              # Recursive with line numbers
grep -P '\d{3}-\d{3}-\d{4}' contacts.txt       # Perl regex
grep -rl "deprecated" --include="*.py" src/     # Files only
grep -v "^#" config.txt                         # Invert match

# ── Combining tools ──
find . -type f -exec du -h {} + | sort -rh | head -10   # Largest files
awk '{print $1}' access.log | sort -u | head -20         # Unique IPs
```

---

## File Operations

```bash
# ── Temporary files (with cleanup via trap) ──
TMPDIR_SCRIPT="$(mktemp -d)"
TMPFILE="$(mktemp)"

# ── Atomic file writes ──
atomic_write() {
  local target="$1" content="$2"
  local tmpfile
  tmpfile="$(mktemp "${target}.XXXXXX")"
  echo "$content" > "$tmpfile"
  mv "$tmpfile" "$target"   # mv is atomic on same filesystem
}

# ── Safe find with special characters ──
find . -name "*.log" -print0 | xargs -0 rm -f

while IFS= read -r -d '' file; do
  echo "Processing: $file"
done < <(find . -name "*.txt" -print0)

# ── File tests ──
[[ -f "$file" ]]    # Regular file       [[ -d "$dir" ]]     # Directory
[[ -r "$file" ]]    # Readable           [[ -w "$file" ]]    # Writable
[[ -x "$file" ]]    # Executable         [[ -s "$file" ]]    # Non-empty
[[ -L "$link" ]]    # Symlink            [[ -e "$path" ]]    # Exists (any type)
[[ "$a" -nt "$b" ]] # a is newer than b

# ── Directory operations ──
mkdir -p /opt/myapp/{bin,lib,conf,log,tmp}
rsync -avz --delete src/ dst/
```

---

## Process Management

```bash
# ── Background jobs with wait ──
pids=()
for host in "${hosts[@]}"; do
  ssh "$host" 'uptime' &
  pids+=($!)
done
failed=0
for pid in "${pids[@]}"; do
  wait "$pid" || ((failed++))
done
((failed == 0)) || die "$failed jobs failed"

# ── Parallel with xargs ──
printf '%s\n' "${urls[@]}" | xargs -P 4 -I {} curl -sfO {}

# ── Signal handling (graceful shutdown) ──
shutdown=false
trap 'shutdown=true' SIGTERM SIGINT
while ! $shutdown; do
  do_work
  sleep 1
done

# ── File locking (prevent concurrent execution) ──
exec 200>"/var/lock/myapp.lock"
flock -n 200 || die "Another instance is already running"
# Lock released automatically when script exits
```

---

## Docker Entrypoints

```bash
#!/usr/bin/env bash
set -euo pipefail

# Wait for dependencies
wait_for_service() {
  local host="$1" port="$2" timeout="${3:-30}" elapsed=0
  until nc -z "$host" "$port" 2>/dev/null; do
    ((elapsed >= timeout)) && { echo "Timeout waiting for $host:$port" >&2; exit 1; }
    echo "Waiting for $host:$port..."
    sleep 2; ((elapsed += 2))
  done
}

wait_for_service "${DB_HOST}" "${DB_PORT:-5432}"

# Read secrets from Docker secret files
[[ -f "/run/secrets/db_password" ]] && export DB_PASSWORD="$(< /run/secrets/db_password)"

# Run migrations if requested
[[ "${RUN_MIGRATIONS:-false}" == "true" ]] && npm run migrate

# Exec replaces shell (PID 1 signal handling)
exec "$@"
```

**Entrypoint rules:**
- Always end with `exec "$@"` — replaces shell with CMD process for proper signal handling
- Never use `npm start` as CMD — npm does not forward SIGTERM
- Wait for dependencies with timeout — do not loop forever
- Read secrets from `/run/secrets/` (Docker secrets), not environment variables

---

## Testing with BATS

```bash
#!/usr/bin/env bats

setup() {
  TMPDIR_TEST="$(mktemp -d)"
  export PATH="$BATS_TEST_DIRNAME/..:$PATH"
}

teardown() {
  rm -rf "$TMPDIR_TEST"
}

@test "prints usage with --help" {
  run myscript.sh --help
  [[ "$status" -eq 0 ]]
  [[ "$output" =~ "Usage:" ]]
}

@test "fails on missing argument" {
  run myscript.sh
  [[ "$status" -ne 0 ]]
  [[ "$output" =~ "required" ]]
}

@test "fails on unknown option" {
  run myscript.sh --invalid
  [[ "$status" -ne 0 ]]
  [[ "$output" =~ "Unknown option" ]]
}

@test "handles filenames with spaces" {
  echo "data" > "$TMPDIR_TEST/my file.txt"
  run myscript.sh "$TMPDIR_TEST/my file.txt"
  [[ "$status" -eq 0 ]]
}
```

```bash
# Install and run
brew install bats-core   # or: npm install -g bats
bats test/               # Run all tests
bats --tap test/         # TAP output for CI
```

---

## Cron and Systemd Timers

```bash
# /etc/cron.d/myapp — always set PATH, SHELL, MAILTO
SHELL=/bin/bash
PATH=/usr/local/bin:/usr/bin:/bin
MAILTO=ops@example.com
0 2 * * * root /opt/myapp/scripts/backup.sh >> /var/log/myapp/backup.log 2>&1

# Cron wrapper — prevents overlapping runs
#!/usr/bin/env bash
set -euo pipefail
readonly JOB_NAME="$1"; shift
exec 200>"/var/lock/cron-${JOB_NAME}.lock"
flock -n 200 || { echo "Already running: $JOB_NAME" >&2; exit 0; }
"$@"
```

**Prefer systemd timers over cron:** journald logging, randomized delay, persistence across reboots.

```ini
# /etc/systemd/system/myapp-backup.timer
[Timer]
OnCalendar=*-*-* 02:00:00
RandomizedDelaySec=300
Persistent=true
```

---

## ShellCheck Integration

```bash
# Install
apt-get install shellcheck   # Debian/Ubuntu
brew install shellcheck      # macOS

# Run
shellcheck myscript.sh
find . -name "*.sh" -exec shellcheck {} +

# Common directives
# shellcheck disable=SC2086       # Disable specific check (next line)
# shellcheck source=lib/helpers.sh # Specify source path
# shellcheck shell=bash            # Specify dialect
```

```yaml
# .github/workflows/shellcheck.yml
name: ShellCheck
on: [push, pull_request]
jobs:
  shellcheck:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: ludeeus/action-shellcheck@master
        with:
          scandir: './scripts'
          severity: warning
```

---

## Portability

### macOS vs Linux Differences

| Operation | Linux | macOS | Portable |
|---|---|---|---|
| In-place sed | `sed -i 's/a/b/'` | `sed -i '' 's/a/b/'` | `sed -i.bak 's/a/b/' && rm f.bak` |
| Date math | `date -d '1 day ago'` | `date -v-1d` | `python3 -c` or `gdate` |
| readlink -f | Built-in | Needs `greadlink` | `cd "$(dirname "$f")" && pwd` |
| stat (size) | `stat -c %s file` | `stat -f %z file` | `wc -c < file` |
| grep -P | PCRE available | Not available | `grep -E` (POSIX ERE) |
| base64 decode | `base64 -d` | `base64 -D` | `base64 --decode` |

### POSIX sh vs Bash

| Feature | POSIX sh | Bash |
|---|---|---|
| `[[ ]]` double brackets | No | Yes — always use in Bash |
| Arrays | No | `declare -a`, `declare -A` |
| `local` in functions | Not guaranteed | Yes |
| Here strings `<<<` | No | Yes |
| Process substitution `<()` | No | Yes |
| `=~` regex match | No | Yes |
| Brace expansion `{a..z}` | No | Yes |

**Rule:** `#!/usr/bin/env bash` = Bash features OK. `#!/bin/sh` = POSIX only.

### Feature Detection over Version Checking

```bash
# BAD: check version string
# GOOD: check if the feature works
if declare -A test_assoc 2>/dev/null; then
  declare -A config
else
  die "Bash 4+ required for associative arrays"
fi

for cmd in jq curl git; do
  command -v "$cmd" >/dev/null 2>&1 || die "Required: $cmd"
done
```

---

## Common Recipes

```bash
# ── Confirmation prompt ──
confirm() {
  local reply
  read -rp "${1:-Are you sure?} [y/N] " reply
  [[ "$reply" =~ ^[Yy]$ ]]
}
confirm "Deploy to production?" && deploy || info "Aborted."

# ── Spinner for long operations ──
spinner() {
  local pid="$1" chars='|/-\' i=0
  while kill -0 "$pid" 2>/dev/null; do
    printf '\r%s %s' "${chars:i++%${#chars}:1}" "${2:-Working...}"
    sleep 0.1
  done; printf '\r'
}
long_command & spinner $! "Processing..."

# ── Version comparison ──
version_gte() { printf '%s\n%s' "$1" "$2" | sort -V -C; }
version_gte "$(node -v | tr -d v)" "18.0.0" || die "Node 18+ required"

# ── Logging framework ──
readonly LOG_LEVEL="${LOG_LEVEL:-1}"  # 0=debug 1=info 2=warn 3=error
log() {
  local lvl="$1" name="$2" color="$3"; shift 3
  ((lvl >= LOG_LEVEL)) || return 0
  printf '\033[%sm%-5s\033[0m %s %s\n' "$color" "$name" "$(date -u +%FT%TZ)" "$*" >&2
}
debug() { log 0 DEBUG "0;36" "$@"; }
info()  { log 1 INFO  "0;32" "$@"; }
warn()  { log 2 WARN  "0;33" "$@"; }
error() { log 3 ERROR "0;31" "$@"; }

# ── Safe .env loading (no eval) ──
load_env() {
  local f="${1:-.env}"
  [[ -f "$f" ]] || return 0
  while IFS= read -r line; do
    [[ "$line" =~ ^[[:space:]]*#|^$ ]] && continue
    if [[ "$line" =~ ^([A-Za-z_][A-Za-z0-9_]*)=(.*) ]]; then
      local val="${BASH_REMATCH[2]}"
      val="${val#\"}"; val="${val%\"}"; val="${val#\'}"; val="${val%\'}"
      export "${BASH_REMATCH[1]}=$val"
    fi
  done < "$f"
}
```
