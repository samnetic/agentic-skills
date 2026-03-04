#!/usr/bin/env bash
set -euo pipefail

# Detects available Gemini CLI commands/flags/subcommands on the local machine.
# Supports plain text and JSON output plus required-capability checks.

SCRIPT_NAME="$(basename "$0")"
TIMEOUT_SECONDS=10
OUTPUT_MODE="text"
REQUIRE_RAW=""
HOME_OVERRIDE=""

usage() {
  cat <<'EOF'
Usage:
  detect-gemini-capabilities.sh [options]

Options:
  --json                  Output machine-readable JSON.
  --require LIST          Comma-separated capabilities that must be present.
  --timeout SECONDS       Per help command timeout (default: 10).
  --home DIR              Override HOME for probe commands.
  -h, --help              Show this help.

Capability keys:
  command.mcp
  command.extensions
  command.cache
  command.memory
  command.tools
  command.auth
  command.doctor
  command.bugreport
  flag.model
  flag.prompt
  flag.prompt_interactive
  flag.output_format
  flag.approval_mode
  flag.allowed_tools
  flag.allowed_mcp_server_names
  flag.include_directories
  flag.all_files
  flag.show_memory_usage
  flag.checkpointing
  flag.telemetry
  mcp.add
  mcp.list
  mcp.remove
  mcp.update
  mcp.test
  mcp.import
  mcp.export
  mcp.enable
  mcp.disable
  output.text
  output.json
  output.stream_json
EOF
}

die() {
  echo "[$SCRIPT_NAME] $*" >&2
  exit 1
}

have_cmd() {
  command -v "$1" >/dev/null 2>&1
}

trim() {
  local v="$1"
  # shellcheck disable=SC2001
  echo "$(echo "$v" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"
}

probe_once() {
  local cmd="$1"
  local home_val="${2:-}"
  local timeout_val="${3:-$TIMEOUT_SECONDS}"
  if [[ -n "$home_val" ]]; then
    HOME="$home_val" timeout "${timeout_val}s" bash -lc "$cmd" 2>&1 || true
  else
    timeout "${timeout_val}s" bash -lc "$cmd" 2>&1 || true
  fi
}

contains() {
  local haystack="$1"
  local needle="$2"
  grep -Fq -- "$needle" <<<"$haystack"
}

escape_json() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  s="${s//$'\n'/\\n}"
  s="${s//$'\r'/\\r}"
  s="${s//$'\t'/\\t}"
  printf '%s' "$s"
}

probe_smart() {
  local cmd="$1"
  local out

  out="$(probe_once "$cmd" "$HOME_OVERRIDE" "$TIMEOUT_SECONDS")"
  if [[ -n "$(trim "$out")" ]]; then
    echo "$out"
    return 0
  fi

  # In restricted environments, fallback to /tmp home can avoid ~/.gemini write errors.
  if [[ -z "$HOME_OVERRIDE" ]]; then
    out="$(probe_once "$cmd" "/tmp" "$TIMEOUT_SECONDS")"
    if [[ -n "$(trim "$out")" ]]; then
      echo "$out"
      return 0
    fi
  fi

  # Final retry with a longer timeout.
  out="$(probe_once "$cmd" "$HOME_OVERRIDE" "$((TIMEOUT_SECONDS * 2))")"
  echo "$out"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --json)
      OUTPUT_MODE="json"
      shift
      ;;
    --require)
      [[ $# -ge 2 ]] || die "--require needs a comma-separated value"
      REQUIRE_RAW="$2"
      shift 2
      ;;
    --timeout)
      [[ $# -ge 2 ]] || die "--timeout needs an integer value"
      TIMEOUT_SECONDS="$2"
      shift 2
      ;;
    --home)
      [[ $# -ge 2 ]] || die "--home needs a directory path"
      HOME_OVERRIDE="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      die "Unknown option: $1"
      ;;
  esac
done

[[ "$TIMEOUT_SECONDS" =~ ^[0-9]+$ ]] || die "--timeout must be an integer"

if ! have_cmd gemini; then
  die "gemini binary not found in PATH"
fi

VERSION_OUTPUT="$(probe_smart 'gemini --version')"
VERSION_LINE="$(trim "$(head -n1 <<<"$VERSION_OUTPUT")")"

HELP_MAIN="$(probe_smart 'gemini --help')"
HELP_MCP="$(probe_smart 'gemini mcp --help')"

declare -A CAP=()
declare -a ORDER=()

set_cap() {
  local key="$1"
  local val="$2"
  CAP["$key"]="$val"
  ORDER+=("$key")
}

is_present() {
  local content="$1"
  local token="$2"
  if contains "$content" "$token"; then
    echo "true"
  else
    echo "false"
  fi
}

set_cap "command.mcp" "$(is_present "$HELP_MAIN" "gemini mcp")"
set_cap "command.extensions" "$(is_present "$HELP_MAIN" "gemini extensions")"
set_cap "command.cache" "$(is_present "$HELP_MAIN" "gemini cache")"
set_cap "command.memory" "$(is_present "$HELP_MAIN" "gemini memory")"
set_cap "command.tools" "$(is_present "$HELP_MAIN" "gemini tools")"
set_cap "command.auth" "$(is_present "$HELP_MAIN" "gemini auth")"
set_cap "command.doctor" "$(is_present "$HELP_MAIN" "gemini doctor")"
set_cap "command.bugreport" "$(is_present "$HELP_MAIN" "gemini bugreport")"

set_cap "flag.model" "$(is_present "$HELP_MAIN" "--model")"
set_cap "flag.prompt" "$(is_present "$HELP_MAIN" "--prompt")"
set_cap "flag.prompt_interactive" "$(is_present "$HELP_MAIN" "--prompt-interactive")"
set_cap "flag.output_format" "$(is_present "$HELP_MAIN" "--output-format")"
set_cap "flag.approval_mode" "$(is_present "$HELP_MAIN" "--approval-mode")"
set_cap "flag.allowed_tools" "$(is_present "$HELP_MAIN" "--allowed-tools")"
set_cap "flag.allowed_mcp_server_names" "$(is_present "$HELP_MAIN" "--allowed-mcp-server-names")"
set_cap "flag.include_directories" "$(is_present "$HELP_MAIN" "--include-directories")"
set_cap "flag.all_files" "$(is_present "$HELP_MAIN" "--all-files")"
set_cap "flag.show_memory_usage" "$(is_present "$HELP_MAIN" "--show-memory-usage")"
set_cap "flag.checkpointing" "$(is_present "$HELP_MAIN" "--checkpointing")"
set_cap "flag.telemetry" "$(is_present "$HELP_MAIN" "--telemetry")"

set_cap "mcp.add" "$(is_present "$HELP_MCP" "gemini mcp add")"
set_cap "mcp.list" "$(is_present "$HELP_MCP" "gemini mcp list")"
set_cap "mcp.remove" "$(is_present "$HELP_MCP" "gemini mcp remove")"
set_cap "mcp.update" "$(is_present "$HELP_MCP" "gemini mcp update")"
set_cap "mcp.test" "$(is_present "$HELP_MCP" "gemini mcp test")"
set_cap "mcp.import" "$(is_present "$HELP_MCP" "gemini mcp import")"
set_cap "mcp.export" "$(is_present "$HELP_MCP" "gemini mcp export")"
set_cap "mcp.enable" "$(is_present "$HELP_MCP" "gemini mcp enable")"
set_cap "mcp.disable" "$(is_present "$HELP_MCP" "gemini mcp disable")"

set_cap "output.text" "$(is_present "$HELP_MAIN" "\"text\"")"
set_cap "output.json" "$(is_present "$HELP_MAIN" "\"json\"")"
set_cap "output.stream_json" "$(is_present "$HELP_MAIN" "\"stream-json\"")"

declare -a MISSING=()
if [[ -n "$REQUIRE_RAW" ]]; then
  IFS=',' read -r -a REQUIRED <<<"$REQUIRE_RAW"
  for req in "${REQUIRED[@]}"; do
    key="$(trim "$req")"
    [[ -n "$key" ]] || continue
    if [[ "${CAP[$key]:-}" != "true" ]]; then
      MISSING+=("$key")
    fi
  done
fi

if [[ "$OUTPUT_MODE" == "json" ]]; then
  echo "{"
  echo "  \"gemini_version\": \"$(escape_json "$VERSION_LINE")\","
  echo "  \"timeout_seconds\": $TIMEOUT_SECONDS,"
  if [[ -n "$HOME_OVERRIDE" ]]; then
    echo "  \"home_override\": \"$(escape_json "$HOME_OVERRIDE")\","
  else
    echo "  \"home_override\": null,"
  fi
  echo "  \"capabilities\": {"
  for i in "${!ORDER[@]}"; do
    key="${ORDER[$i]}"
    comma=","
    if (( i == ${#ORDER[@]} - 1 )); then
      comma=""
    fi
    echo "    \"$(escape_json "$key")\": ${CAP[$key]}$comma"
  done
  echo "  },"
  echo "  \"required\": ["
  if [[ -n "$REQUIRE_RAW" ]]; then
    for i in "${!REQUIRED[@]}"; do
      v="$(trim "${REQUIRED[$i]}")"
      [[ -n "$v" ]] || continue
      comma=","
      if (( i == ${#REQUIRED[@]} - 1 )); then
        comma=""
      fi
      echo "    \"$(escape_json "$v")\"$comma"
    done
  fi
  echo "  ],"
  echo "  \"missing_required\": ["
  for i in "${!MISSING[@]}"; do
    comma=","
    if (( i == ${#MISSING[@]} - 1 )); then
      comma=""
    fi
    echo "    \"$(escape_json "${MISSING[$i]}")\"$comma"
  done
  echo "  ]"
  echo "}"
else
  echo "Gemini Version: $VERSION_LINE"
  echo "Timeout Seconds: $TIMEOUT_SECONDS"
  if [[ -n "$HOME_OVERRIDE" ]]; then
    echo "HOME Override: $HOME_OVERRIDE"
  fi
  echo
  printf "%-38s %s\n" "Capability" "Present"
  printf "%-38s %s\n" "----------" "-------"
  for key in "${ORDER[@]}"; do
    printf "%-38s %s\n" "$key" "${CAP[$key]}"
  done
  if [[ -n "$REQUIRE_RAW" ]]; then
    echo
    if [[ ${#MISSING[@]} -eq 0 ]]; then
      echo "Required Capabilities: OK"
    else
      echo "Required Capabilities: MISSING"
      printf "  - %s\n" "${MISSING[@]}"
    fi
  fi
fi

if [[ ${#MISSING[@]} -gt 0 ]]; then
  exit 2
fi

exit 0
