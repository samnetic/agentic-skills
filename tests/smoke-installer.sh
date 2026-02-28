#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$(mktemp -d)"

pass_count=0
fail_count=0

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

pass() {
  pass_count=$((pass_count + 1))
  echo "PASS: $*"
}

fail() {
  fail_count=$((fail_count + 1))
  echo "FAIL: $*" >&2
}

assert_eq() {
  local actual="$1"
  local expected="$2"
  local label="$3"
  if [[ "$actual" == "$expected" ]]; then
    pass "$label ($actual)"
  else
    fail "$label (expected=$expected actual=$actual)"
  fi
}

assert_contains() {
  local file="$1"
  local pattern="$2"
  local label="$3"
  if rg -n --fixed-strings "$pattern" "$file" >/dev/null 2>&1; then
    pass "$label"
  else
    fail "$label"
  fi
}

run() {
  echo "== installer smoke in $TMP_DIR =="
  cd "$TMP_DIR"

  bash "$ROOT_DIR/install.sh" --claude --force >/tmp/agentic-skills-smoke-claude-install.log
  bash "$ROOT_DIR/install.sh" --opencode --force >/tmp/agentic-skills-smoke-opencode-install.log
  bash "$ROOT_DIR/install.sh" --codex --force >/tmp/agentic-skills-smoke-codex-install.log

  local claude_skills
  claude_skills="$(find .claude/skills -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')"
  assert_eq "$claude_skills" "25" "Claude install skill count"

  local claude_agents
  claude_agents="$(find .claude/agents -maxdepth 1 -name '*.md' -type f | wc -l | tr -d ' ')"
  assert_eq "$claude_agents" "8" "Claude install agent count"

  local claude_hooks
  claude_hooks="$(find .claude/hooks -maxdepth 1 -name '*.sh' -type f | wc -l | tr -d ' ')"
  assert_eq "$claude_hooks" "7" "Claude install hook count"

  [[ -f .claude/settings.json ]] && pass "Claude settings.json installed" || fail "Claude settings.json installed"
  [[ -f .claude/settings.local.json ]] && pass "Claude settings.local.json installed" || fail "Claude settings.local.json installed"

  local opencode_skills
  opencode_skills="$(find .opencode/skills -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')"
  assert_eq "$opencode_skills" "25" "OpenCode install skill count"

  local opencode_agents
  opencode_agents="$(find .opencode/agents -maxdepth 1 -name '*.md' -type f | wc -l | tr -d ' ')"
  assert_eq "$opencode_agents" "8" "OpenCode install agent count"

  local opencode_plugins
  opencode_plugins="$(find .opencode/plugins -maxdepth 1 -name '*.js' -type f | wc -l | tr -d ' ')"
  assert_eq "$opencode_plugins" "1" "OpenCode install plugin count"

  assert_contains ".opencode/agents/software-architect.md" "mode: subagent" "OpenCode agent conversion uses subagent mode"
  assert_contains ".opencode/agents/software-architect.md" "tools:" "OpenCode agent conversion emits tool map"

  assert_contains "codex.md" "25 expert-level domain skills + 8 specialized agents." "Codex output summary has corrected skill count"

  if command -v jq >/dev/null 2>&1; then
    local opencode_target
    opencode_target="$(jq -r '.target' .opencode/.agentic-skills.manifest)"
    assert_eq "$opencode_target" "opencode-project" "OpenCode manifest target"

    local plugin_files_len
    plugin_files_len="$(jq -r '.plugin_files | length' .opencode/.agentic-skills.manifest)"
    assert_eq "$plugin_files_len" "1" "OpenCode manifest plugin_files"
  else
    pass "jq unavailable: skipped manifest JSON assertions"
  fi

  bash "$ROOT_DIR/uninstall.sh" --path .opencode --force >/tmp/agentic-skills-smoke-opencode-uninstall.log
  bash "$ROOT_DIR/uninstall.sh" --path .claude --force >/tmp/agentic-skills-smoke-claude-uninstall.log
  bash "$ROOT_DIR/uninstall.sh" --path . --force >/tmp/agentic-skills-smoke-codex-uninstall.log

  [[ ! -f .opencode/.agentic-skills.manifest ]] && pass "OpenCode manifest removed" || fail "OpenCode manifest removed"
  [[ ! -f .claude/.agentic-skills.manifest ]] && pass "Claude manifest removed" || fail "Claude manifest removed"
  [[ ! -f ./.agentic-skills.manifest ]] && pass "Codex manifest removed" || fail "Codex manifest removed"

  echo "== installer smoke complete: pass=$pass_count fail=$fail_count =="
  [[ $fail_count -eq 0 ]]
}

run
