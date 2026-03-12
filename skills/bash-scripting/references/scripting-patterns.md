# Bash Scripting Patterns Reference

## Table of Contents

- [Strict Mode Explained](#strict-mode-explained)
  - [set -e — Exit on Error](#set--e--exit-on-error)
  - [set -u — Error on Undefined Variables](#set--u--error-on-undefined-variables)
  - [set -o pipefail — Pipe Fails if Any Command Fails](#set--o-pipefail--pipe-fails-if-any-command-fails)
  - [set -x — Trace (Debugging Only)](#set--x--trace-debugging-only)
- [Argument Parsing Patterns](#argument-parsing-patterns)
  - [Simple: while/case Loop (Preferred)](#simple-whilecase-loop-preferred)
  - [With getopt (For Complex CLIs)](#with-getopt-for-complex-clis)
  - [Subcommand Pattern](#subcommand-pattern)
- [Error Handling](#error-handling)
- [Variable Best Practices](#variable-best-practices)
  - [Always Quote](#always-quote)
  - [Parameter Expansion](#parameter-expansion)
  - [Arrays](#arrays)
- [Functions](#functions)
- [Heredocs and String Handling](#heredocs-and-string-handling)

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
