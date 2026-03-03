#!/usr/bin/env bash
set -euo pipefail

MAX_LINES="${MAX_LINES:-24}"
ok_count=0
warn_count=0
fail_count=0

print_header() {
  echo "== $1 =="
}

have_cmd() {
  command -v "$1" >/dev/null 2>&1
}

run_probe() {
  local label="$1"
  shift

  local output rc status
  set +e
  output="$("$@" 2>&1)"
  rc=$?
  set -e

  status="OK"
  if [ "$rc" -ne 0 ]; then
    status="FAIL"
  fi

  # Known environment-specific failure observed during validation.
  if [ "$label" = "acli confluence space list probe" ] \
    && [[ "$output" == *"Activation id for cloudId null not found."* ]]; then
    status="WARN"
    rc=0
  fi

  case "$status" in
    OK) ok_count=$((ok_count + 1)) ;;
    WARN) warn_count=$((warn_count + 1)) ;;
    FAIL) fail_count=$((fail_count + 1)) ;;
  esac

  echo
  echo "### $label [$status]"
  echo "$output" | sed -n "1,${MAX_LINES}p"

  if [ "$status" = "WARN" ]; then
    echo "Note: Fallback to confluence-cli for Confluence operations."
  fi
}

print_header "Atlassian CLI Preflight"

if ! have_cmd acli; then
  echo "Missing required command: acli"
  exit 2
fi

if ! have_cmd confluence-cli; then
  echo "Missing required command: confluence-cli"
  exit 2
fi

run_probe "acli version" acli --version
run_probe "confluence-cli version" confluence-cli --version

run_probe "acli auth status" acli auth status
run_probe "acli jira auth status" acli jira auth status
run_probe "acli confluence auth status" acli confluence auth status

run_probe "acli jira project list probe" acli jira project list --limit 1 --json
run_probe "acli confluence space list probe" acli confluence space list --limit 1 --json

run_probe "confluence-cli stats probe" confluence-cli stats
run_probe "confluence-cli search probe" confluence-cli search "type=page" --cql --limit 1

echo
print_header "Summary"
echo "OK:   $ok_count"
echo "WARN: $warn_count"
echo "FAIL: $fail_count"

if [ "$fail_count" -gt 0 ]; then
  exit 1
fi
