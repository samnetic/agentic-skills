#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_PROJECT="$(mktemp -d)"
TMP_HOME="$(mktemp -d)"
TMP_XDG_DATA="$(mktemp -d)"
TMP_XDG_CONFIG="$(mktemp -d)"

pass_count=0
warn_count=0
fail_count=0

cleanup() {
  rm -rf "$TMP_PROJECT" "$TMP_HOME" "$TMP_XDG_DATA" "$TMP_XDG_CONFIG"
}
trap cleanup EXIT

pass() {
  pass_count=$((pass_count + 1))
  echo "PASS: $*"
}

warn() {
  warn_count=$((warn_count + 1))
  echo "WARN: $*"
}

fail() {
  fail_count=$((fail_count + 1))
  echo "FAIL: $*" >&2
}

run_capture() {
  local cmd="$1"
  local outfile="$2"
  set +e
  bash -lc "$cmd" >"$outfile" 2>&1
  local ec=$?
  set -e
  echo "$ec"
}

assert_cmd() {
  local cmd="$1"
  if command -v "$cmd" >/dev/null 2>&1; then
    pass "$cmd is installed"
  else
    fail "$cmd is installed"
  fi
}

check_version() {
  local cmd="$1"
  local outfile
  outfile="$(mktemp)"
  local ec
  ec="$(run_capture "$cmd --version" "$outfile")"
  if [[ "$ec" -eq 0 ]]; then
    pass "$cmd --version"
  else
    warn "$cmd --version failed (exit=$ec)"
  fi
  rm -f "$outfile"
}

run() {
  echo "== cli smoke =="

  assert_cmd claude
  assert_cmd codex
  assert_cmd opencode

  check_version claude
  check_version codex
  check_version opencode

  cd "$TMP_PROJECT"
  bash "$ROOT_DIR/install.sh" --codex --force >/tmp/agentic-skills-cli-codex-install.log
  local codex_skill_count codex_agent_count
  codex_skill_count="$(find .codex/skills -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')"
  codex_agent_count="$(find .codex/agents -maxdepth 1 -name '*.md' -type f | wc -l | tr -d ' ')"
  if [[ "$codex_skill_count" == "25" && "$codex_agent_count" == "9" ]]; then
    pass "codex project install created skills/agents registry files"
  else
    fail "codex project install created skills/agents registry files"
  fi

  local claude_agents_out
  claude_agents_out="$(mktemp)"
  local ec
  ec="$(run_capture "cd '$ROOT_DIR' && timeout 30s claude agents" "$claude_agents_out")"
  if rg -n "Project agents:" "$claude_agents_out" >/dev/null 2>&1; then
    pass "claude agents lists project agents"
  elif rg -n "Not logged in|Please run /login" "$claude_agents_out" >/dev/null 2>&1; then
    warn "claude agents requires login"
  else
    fail "claude agents unexpected output (exit=$ec)"
  fi
  rm -f "$claude_agents_out"

  local claude_prompt_out
  claude_prompt_out="$(mktemp)"
  ec="$(run_capture "cd '$ROOT_DIR' && timeout 45s claude --setting-sources user,project,local -p 'Reply with exactly: CLAUDE_OK'" "$claude_prompt_out")"
  if rg -n "CLAUDE_OK" "$claude_prompt_out" >/dev/null 2>&1; then
    pass "claude -p completed model response"
  elif [[ "$ec" -eq 124 ]]; then
    warn "claude -p timed out waiting for model response"
  elif rg -n "Not logged in|Please run /login|auth|API key|permission denied|Unable to connect|stream error|timed out" "$claude_prompt_out" >/dev/null 2>&1; then
    warn "claude -p hit auth/network issues after startup"
  elif rg -n "unknown option|unknown argument|Usage:" "$claude_prompt_out" >/dev/null 2>&1; then
    fail "claude -p is not supported by installed CLI"
  elif [[ "$ec" -eq 0 ]]; then
    warn "claude -p completed without explicit completion marker"
  else
    fail "claude -p unexpected output (exit=$ec)"
  fi
  rm -f "$claude_prompt_out"

  local codex_out
  codex_out="$(mktemp)"
  ec="$(run_capture "cd '$TMP_PROJECT' && timeout 45s codex exec --skip-git-repo-check 'In this repo, list directory names under ./.codex/skills only. Return exactly one line in this format: SKILLS:name1,name2,... sorted alphabetically with no spaces.'" "$codex_out")"
  if rg -n "OpenAI Codex" "$codex_out" >/dev/null 2>&1; then
    pass "codex exec starts session"
  fi
  if rg -n "SKILLS:" "$codex_out" >/dev/null 2>&1; then
    pass "codex exec returned skill listing response"
  elif rg -n "Not logged in|Reconnecting|stream disconnected|error sending request|Unable to connect|timed out" "$codex_out" >/dev/null 2>&1; then
    warn "codex exec hit auth/network issues after startup"
  elif rg -n "OpenAI Codex" "$codex_out" >/dev/null 2>&1; then
    warn "codex exec returned without explicit completion marker"
  else
    fail "codex exec did not reach session startup"
  fi
  rm -f "$codex_out"

  cd "$TMP_PROJECT"
  bash "$ROOT_DIR/install.sh" --opencode --force >/tmp/agentic-skills-cli-opencode-install.log

  local opencode_agents_out
  opencode_agents_out="$(mktemp)"
  ec="$(run_capture "cd '$TMP_PROJECT' && XDG_DATA_HOME='$TMP_XDG_DATA' XDG_CONFIG_HOME='$TMP_XDG_CONFIG' HOME='$TMP_HOME' timeout 35s opencode agent list" "$opencode_agents_out")"
  if rg -n "Configuration is invalid" "$opencode_agents_out" >/dev/null 2>&1; then
    fail "opencode agent list rejects generated agents"
  elif rg -n "software-architect \\(subagent\\)|pr-reviewer \\(subagent\\)" "$opencode_agents_out" >/dev/null 2>&1; then
    pass "opencode agent list recognizes converted subagents"
  else
    warn "opencode agent list output did not include expected subagents (exit=$ec)"
  fi
  rm -f "$opencode_agents_out"

  local opencode_run_out
  opencode_run_out="$(mktemp)"
  ec="$(run_capture "cd '$TMP_PROJECT' && XDG_DATA_HOME='$TMP_XDG_DATA' XDG_CONFIG_HOME='$TMP_XDG_CONFIG' HOME='$TMP_HOME' timeout 35s opencode run 'Ping' --print-logs --log-level DEBUG" "$opencode_run_out")"
  if rg -n "agentic-skills-hooks.js loading plugin" "$opencode_run_out" >/dev/null 2>&1; then
    pass "opencode run loads agentic-skills hook bridge plugin"
  else
    fail "opencode run did not load agentic-skills hook bridge plugin"
  fi
  if rg -n "Was there a typo in the url or port|Unable to connect|stream error" "$opencode_run_out" >/dev/null 2>&1; then
    warn "opencode run hit provider/network issues after startup"
  fi
  rm -f "$opencode_run_out"

  bash "$ROOT_DIR/uninstall.sh" --path .opencode --force >/tmp/agentic-skills-cli-opencode-uninstall.log
  bash "$ROOT_DIR/uninstall.sh" --path .codex --force >/tmp/agentic-skills-cli-codex-uninstall.log

  echo "== cli smoke complete: pass=$pass_count warn=$warn_count fail=$fail_count =="
  [[ $fail_count -eq 0 ]]
}

run
