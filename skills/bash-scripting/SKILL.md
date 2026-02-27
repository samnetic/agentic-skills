---
name: bash-scripting
description: >-
  Modern Bash scripting and shell automation expertise. Use when writing shell scripts,
  automating tasks with bash, parsing command-line arguments, handling errors in scripts,
  processing text with awk/sed/jq, managing processes and signals, writing portable
  shell scripts, creating Docker entrypoints, writing CI/CD pipeline scripts, automating
  server provisioning, creating CLI tools in bash, file operations with proper quoting,
  using ShellCheck for linting, testing scripts with BATS, implementing retry logic,
  logging frameworks, color output, configuration file parsing, or reviewing shell script
  quality.
  Triggers: bash, shell, script, sh, zsh, awk, sed, jq, grep, find, xargs, cron,
  systemd timer, entrypoint, provisioning, automation, CLI tool, ShellCheck, BATS,
  heredoc, trap, signal, process, pipeline, pipe, redirect, subprocess.
---

# Bash Scripting Skill

Write shell scripts that are strict, quoted, readable, and testable.
Bash is a glue language — use it for automation and plumbing, not application logic.

---

## Core Principles

| Principle | Meaning |
|---|---|
| **Strict mode always** | `set -euo pipefail` in every script |
| **Quote everything** | `"$variable"` — unquoted variables are bugs |
| **Fail fast, fail loud** | Errors should stop execution with clear messages |
| **ShellCheck is mandatory** | Run on every script, fix all warnings |
| **Prefer readability** | Clear variable names, functions, comments for non-obvious logic |
| **Know when to stop** | If >100 lines or complex data structures, use Python |

---

## Script Template

Every new script starts from this template. Never write a script without strict mode and a cleanup trap.

```bash
#!/usr/bin/env bash
set -euo pipefail

# ── Constants ─────────────────────────────────────────────
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_NAME="$(basename "$0")"

# ── Color helpers ─────────────────────────────────────────
USE_COLOR=true
[[ ! -t 1 ]] && USE_COLOR=false
[[ -n "${NO_COLOR:-}" ]] && USE_COLOR=false

color() { $USE_COLOR && printf '\033[%sm' "$1" || true; }
info()  { echo "$(color '0;32')info$(color 0) $*"; }
warn()  { echo "$(color '0;33')warn$(color 0) $*" >&2; }
err()   { echo "$(color '0;31')error$(color 0) $*" >&2; }
die()   { err "$@"; exit 1; }

# ── Cleanup trap ──────────────────────────────────────────
cleanup() {
  [[ -n "${TMPDIR_SCRIPT:-}" ]] && rm -rf "$TMPDIR_SCRIPT"
}
trap cleanup EXIT

# ── Usage ─────────────────────────────────────────────────
usage() {
  cat <<EOF
Usage: $SCRIPT_NAME [options] <argument>

Options:
  -v, --verbose    Enable verbose output
  -h, --help       Show this help
EOF
  exit 0
}

# ── Argument parsing ──────────────────────────────────────
VERBOSE=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    -v|--verbose) VERBOSE=true; shift ;;
    -h|--help)    usage ;;
    --)           shift; break ;;
    -*)           die "Unknown option: $1" ;;
    *)            break ;;
  esac
done

# ── Main ──────────────────────────────────────────────────
main() {
  info "Starting $SCRIPT_NAME"
  # Your logic here
}

main "$@"
```

**Template rules:**
- `#!/usr/bin/env bash` — portable shebang (not `/bin/bash`)
- `set -euo pipefail` — always, no exceptions
- `readonly` for constants — prevent accidental mutation
- Color helpers respect `NO_COLOR` env and non-TTY output
- `cleanup` trap on `EXIT` — fires on normal exit, errors, and signals
- `main "$@"` at the bottom — keeps global scope clean

---

## Strict Mode Explained

### `set -e` — Exit on Error

```bash
set -e
cp /nonexistent/file /tmp/  # Script exits here
echo "This never runs"
```

**Caveats with `set -e`:**

```bash
# Commands in conditions do NOT trigger set -e (by design)
if ! grep -q "pattern" file.txt; then
  echo "Not found"  # Fine — grep failure is handled
fi

# || true suppresses the error
might_fail || true   # Script continues even if might_fail exits non-zero

# local masks exit codes — declare and assign on SEPARATE lines
local result
result=$(failing_command)        # Now set -e catches the failure

# Pipelines: only the LAST command's exit code matters (without pipefail)
false | true                     # Exit code 0 without pipefail!
```

### `set -u` — Error on Undefined Variables

```bash
set -u
echo "$UNDEFINED_VAR"                 # Error: unbound variable
echo "${OPTIONAL_VAR:-default_value}" # Safe: use defaults
```

### `set -o pipefail` — Pipe Fails if Any Command Fails

```bash
set -o pipefail
false | true             # Exit code 1 (from false)
curl -s bad-url | jq .   # Fails correctly if curl fails
```

### `set -x` — Trace (Debugging Only)

```bash
# WARNING: Leaks secrets! Never leave in production scripts
set -x   # Enable selectively for debugging
debug_section
set +x   # Disable immediately after
```

---

## Argument Parsing Patterns

### Simple: while/case Loop (Preferred)

```bash
VERBOSE=false
OUTPUT_DIR="."

while [[ $# -gt 0 ]]; do
  case "$1" in
    -v|--verbose)     VERBOSE=true; shift ;;
    -o|--output)      OUTPUT_DIR="$2"; shift 2 ;;
    --output=*)       OUTPUT_DIR="${1#*=}"; shift ;;
    -h|--help)        usage ;;
    --)               shift; break ;;
    -*)               die "Unknown option: $1" ;;
    *)                break ;;
  esac
done

FILE="${1:?'Error: file argument required'}"
```

### With getopt (For Complex CLIs)

```bash
if ! OPTS=$(getopt -o 'vho:f:' --long 'verbose,help,output:,format:' -n "$SCRIPT_NAME" -- "$@"); then
  die "Invalid options. Use --help for usage."
fi
eval set -- "$OPTS"

while true; do
  case "$1" in
    -v|--verbose) VERBOSE=true; shift ;;
    -o|--output)  OUTPUT="$2"; shift 2 ;;
    -f|--format)  FORMAT="$2"; shift 2 ;;
    -h|--help)    usage; shift ;;
    --)           shift; break ;;
  esac
done
```

### Subcommand Pattern

```bash
COMMAND="${1:?'Error: command required (deploy|rollback|status)'}"
shift
case "$COMMAND" in
  deploy)   deploy_app "$@" ;;
  rollback) rollback_app "$@" ;;
  status)   show_status "$@" ;;
  *)        die "Unknown command: $COMMAND" ;;
esac
```

---

## Error Handling

```bash
# Report errors with file and line number
trap 'echo "Error on line $LINENO (exit code $?)" >&2' ERR

# Cleanup on any exit
trap cleanup EXIT

# Safe command execution — capture output and check exit code
if ! output=$(some_command 2>&1); then
  err "Command failed: $output"
  exit 1
fi

# Require commands to exist
require_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "Required command not found: $1"
}
require_cmd jq
require_cmd curl

# Retry with exponential backoff
retry() {
  local max_attempts="${1:-3}" delay="${2:-1}" attempt=1
  shift 2
  until "$@"; do
    if ((attempt >= max_attempts)); then
      err "Failed after $attempt attempts: $*"
      return 1
    fi
    warn "Attempt $attempt failed, retrying in ${delay}s..."
    sleep "$delay"
    ((attempt++))
    delay=$((delay * 2))
  done
}
retry 5 2 curl -sf "https://api.example.com/health"

# Timeout wrapper
run_with_timeout() {
  local timeout="$1"; shift
  timeout "$timeout" "$@" || {
    local ec=$?
    [[ $ec -eq 124 ]] && err "Timed out after ${timeout}: $*" || err "Failed (exit $ec): $*"
    return $ec
  }
}
```

---

## Variable Best Practices

### Always Quote

```bash
name="hello world"
echo "$name"           # Correct: "hello world"
echo $name             # BUG: word-split into "hello" and "world"

files=("file one.txt" "file two.txt")
for f in "${files[@]}"; do echo "$f"; done  # Correct: each name intact
```

### Parameter Expansion

```bash
echo "${NAME:-anonymous}"         # Default if unset or empty
echo "${NAME:=anonymous}"         # Assign default if unset
echo "${DATABASE_URL:?'Required'}" # Error if unset

path="/home/user/docs/file.tar.gz"
echo "${path##*/}"                # file.tar.gz  (basename)
echo "${path%.*}"                 # /home/user/docs/file.tar  (strip last extension)
echo "${path%%.*}"                # /home/user/docs/file  (strip all extensions)

version="v1.2.3"
echo "${version#v}"               # 1.2.3  (strip prefix)
echo "${version//./-}"            # v1-2-3  (replace all dots)
echo "${#version}"                # 6  (length)
```

### Arrays

```bash
declare -a servers=("web-01" "web-02" "web-03")
declare -A config=([host]="localhost" [port]="5432" [name]="mydb")

for server in "${servers[@]}"; do echo "$server"; done  # Iterate
echo "${#servers[@]}"             # Length
servers+=("web-04")               # Append
echo "${!config[@]}"              # All keys (associative)
[[ -v config[host] ]] && echo "${config[host]}"  # Key exists check
```

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

## Functions

```bash
# Return data via stdout — capture with $()
get_config() {
  local key="$1"
  grep "^${key}=" config.txt | cut -d= -f2-
}
value="$(get_config "database_url")"

# Return status via return code
is_running() {
  local pid="$1"
  kill -0 "$pid" 2>/dev/null
}

# Error propagation
validate_input() {
  local input="$1"
  [[ -n "$input" ]] || { err "Input required"; return 1; }
  [[ "$input" =~ ^[a-zA-Z0-9_-]+$ ]] || { err "Invalid characters"; return 1; }
  [[ ${#input} -le 255 ]] || { err "Input too long (max 255)"; return 1; }
}

# Always use `local` for all variables inside functions
# Always use `readonly` for script-level constants
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

## Heredocs and String Handling

```bash
# Standard heredoc (variable expansion)
cat <<EOF
Hello $USER, today is $(date +%A).
EOF

# Quoted heredoc (NO expansion — literal output)
cat <<'EOF'
echo "$USER"   # This is literal text
EOF

# Heredoc to a file
cat > /etc/nginx/conf.d/app.conf <<EOF
server {
    listen 80;
    server_name ${DOMAIN};
}
EOF

# Indented heredoc (strip leading tabs with <<-)
generate_config() {
	cat <<-EOF
	{"host": "${DB_HOST}", "port": ${DB_PORT}}
	EOF
}

# String comparison — always use [[ ]] in Bash
[[ "$str" == "value" ]]      # Exact
[[ "$str" == *.log ]]        # Glob
[[ "$str" =~ ^[0-9]+$ ]]    # Regex
[[ -z "$str" ]]              # Empty
[[ -n "$str" ]]              # Non-empty
[[ "${str,,}" == "value" ]]  # Case-insensitive (Bash 4+)
```

---

## Decision Tree: When to Use Bash

```
Need a script?
├── Simple automation (<100 lines) .................. Bash
├── Glue between CLI tools (pipe, compose) .......... Bash
├── Docker entrypoint ............................... Bash (minimal)
├── CI/CD pipeline steps (simple) ................... Bash
├── File renaming, backup, cleanup .................. Bash
├── Server provisioning (simple) .................... Bash
│
├── Complex data structures (dicts, classes) ........ Python
├── Error handling beyond exit codes ................ Python
├── HTTP/JSON/API calls (complex) ................... Python (or curl + jq for simple)
├── Cross-platform requirement ...................... Python
├── >100 lines with business logic .................. Python
├── CI/CD pipeline steps (complex) .................. Python
├── Interactive TUI .................................. Python (rich) or Go
└── Performance-critical CLI tool ................... Go or Rust
```

**Rule of thumb:** If you're reaching for associative arrays, complex string parsing, or nested data structures in Bash, switch to Python.

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

# CI integration
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

---

## Anti-Patterns

| Anti-Pattern | Why It's Dangerous | Fix |
|---|---|---|
| No `set -euo pipefail` | Errors silently ignored, undefined vars expand to empty | Always set strict mode |
| Unquoted variables `$var` | Word splitting, glob expansion, security vulnerabilities | Always `"$var"` |
| Parsing `ls` output | Breaks on spaces, newlines, special chars in filenames | Use `find -print0` or globs |
| `cat file \| grep` | Useless use of cat | `grep pattern file` directly |
| `echo "$password"` | Visible in `ps`, process list, logs | Use files or env vars |
| `eval "$user_input"` | Code injection, arbitrary execution | Never eval untrusted input |
| `cd` without error check | Script continues in wrong directory | `cd /path \|\| die "cd failed"` |
| `kill -9` as first resort | No chance for graceful cleanup | SIGTERM first, SIGKILL after timeout |
| Backticks `` `cmd` `` | Hard to nest, hard to read | Use `$(cmd)` |
| `[ ]` single brackets | No regex, no glob, quoting pitfalls | Use `[[ ]]` in Bash |
| No cleanup trap | Temp files, lock files left behind | `trap cleanup EXIT` |
| `while read` without `IFS=` | Leading/trailing whitespace stripped | `while IFS= read -r line` |
| Hardcoded paths | Breaks across environments | Use `$SCRIPT_DIR`, variables, config |
| `for f in $(find ...)` | Breaks on whitespace in filenames | `find -print0 \| while read -d ''` |
| Ignoring ShellCheck warnings | Known bug patterns remain | Fix all, disable only with comment |
| `source .env` without validation | Arbitrary code execution from .env | Parse with `while read` + regex |
| `local var=$(cmd)` | `local` masks the exit code of `cmd` | Declare and assign on separate lines |
| `set -x` left in production | Leaks secrets to logs and stderr | Use only during debugging, remove after |

---

## Checklist: Shell Script Review

- [ ] Shebang is `#!/usr/bin/env bash` (not `/bin/bash` or `/bin/sh`)
- [ ] `set -euo pipefail` is the first line after shebang
- [ ] All variables are quoted: `"$var"`, `"${array[@]}"`
- [ ] `readonly` used for constants, `local` used in functions
- [ ] `trap cleanup EXIT` handles temporary files and lock files
- [ ] Argument parsing handles `--help`, `-h`, unknown options, and `--`
- [ ] Error messages go to stderr (`>&2`)
- [ ] Functions use `local` for all variables
- [ ] `command -v` used to check for required tools at startup
- [ ] `find` uses `-print0` with `xargs -0` or `read -d ''`
- [ ] No parsing of `ls` output
- [ ] No `eval` with user-provided input
- [ ] ShellCheck passes with zero warnings
- [ ] BATS tests exist for critical paths
- [ ] Color output respects `NO_COLOR` env and non-TTY detection
- [ ] Secrets are never echoed or logged
- [ ] In-place `sed` is portable (`sed -i.bak ... && rm *.bak`)
- [ ] Exit codes are meaningful (0 = success, 1 = general error, 2 = usage error)
- [ ] Long scripts (>100 lines) have been evaluated for rewrite in Python
- [ ] Script works correctly when run from any working directory (uses `$SCRIPT_DIR`)
