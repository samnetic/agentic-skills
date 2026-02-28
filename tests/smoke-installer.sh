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

assert_le() {
  local actual="$1"
  local maximum="$2"
  local label="$3"
  if [[ "$actual" -le "$maximum" ]]; then
    pass "$label ($actual <= $maximum)"
  else
    fail "$label (expected <=$maximum actual=$actual)"
  fi
}

assert_contains() {
  local file="$1"
  local pattern="$2"
  local label="$3"
  if command -v rg >/dev/null 2>&1; then
    if rg -n --fixed-strings "$pattern" "$file" >/dev/null 2>&1; then
      pass "$label"
    else
      fail "$label"
    fi
  else
    if grep -F -- "$pattern" "$file" >/dev/null 2>&1; then
      pass "$label"
    else
      fail "$label"
    fi
  fi
}

run() {
  echo "== installer smoke in $TMP_DIR =="
  cd "$TMP_DIR"

  bash "$ROOT_DIR/install.sh" --claude --force >/tmp/agentic-skills-smoke-claude-install.log
  bash "$ROOT_DIR/install.sh" --opencode --force >/tmp/agentic-skills-smoke-opencode-install.log
  bash "$ROOT_DIR/install.sh" --codex --force >/tmp/agentic-skills-smoke-codex-install.log
  bash "$ROOT_DIR/install.sh" --codex-md --force >/tmp/agentic-skills-smoke-codex-md-install.log

  local claude_skills
  claude_skills="$(find .claude/skills -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')"
  assert_eq "$claude_skills" "25" "Claude install skill count"

  local claude_agents
  claude_agents="$(find .claude/agents -maxdepth 1 -name '*.md' -type f | wc -l | tr -d ' ')"
  assert_eq "$claude_agents" "9" "Claude install agent count"

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
  assert_eq "$opencode_agents" "9" "OpenCode install agent count"

  local opencode_plugins
  opencode_plugins="$(find .opencode/plugins -maxdepth 1 -name '*.js' -type f | wc -l | tr -d ' ')"
  assert_eq "$opencode_plugins" "1" "OpenCode install plugin count"

  assert_contains ".opencode/agents/software-architect.md" "mode: subagent" "OpenCode agent conversion uses subagent mode"
  assert_contains ".opencode/agents/software-architect.md" "tools:" "OpenCode agent conversion emits tool map"

  local codex_skills
  codex_skills="$(find .codex/skills -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')"
  assert_eq "$codex_skills" "25" "Codex install skill count"

  local codex_agents
  codex_agents="$(find .codex/agents -maxdepth 1 -name '*.md' -type f | wc -l | tr -d ' ')"
  assert_eq "$codex_agents" "9" "Codex install agent count"

  local codex_desc_len
  codex_desc_len="$(awk '
    BEGIN { delim = 0; in_desc = 0; text = "" }
    /^---[[:space:]]*$/ { delim++; if (delim > 1) exit; next }
    delim == 1 {
      if ($0 ~ /^description:[[:space:]]*>-/) { in_desc = 1; next }
      if (in_desc == 1) {
        if ($0 ~ /^[[:space:]]{2,}[^[:space:]].*/) {
          sub(/^[[:space:]]+/, "", $0)
          text = text (text ? " " : "") $0
          next
        }
        if ($0 ~ /^[a-zA-Z0-9_-]+:/) { in_desc = 0 }
      }
    }
    END { print length(text) }
  ' .codex/skills/nextjs-react/SKILL.md)"
  assert_le "$codex_desc_len" "1024" "Codex skill description is within parser limit"

  assert_contains "codex.md" "25 expert-level domain skills + 9 specialized agents." "Codex markdown export summary has corrected skill count"

  if command -v jq >/dev/null 2>&1; then
    local opencode_target
    opencode_target="$(jq -r '.target' .opencode/.agentic-skills.manifest)"
    assert_eq "$opencode_target" "opencode-project" "OpenCode manifest target"

    local plugin_files_len
    plugin_files_len="$(jq -r '.plugin_files | length' .opencode/.agentic-skills.manifest)"
    assert_eq "$plugin_files_len" "1" "OpenCode manifest plugin_files"

    mkdir -p merge-case/.claude
    cat > merge-case/.claude/settings.json <<'EOF'
{"permissions":{"allow":["Bash(echo:*)"]}}
EOF
    cat > merge-case/.claude/settings.local.json <<'EOF'
{"permissions":{"allow":["Bash(ls:*)"]}}
EOF

    (
      cd merge-case
      bash "$ROOT_DIR/install.sh" --claude --hooks-only --force >/tmp/agentic-skills-smoke-claude-merge.log
    )

    assert_contains "merge-case/.claude/settings.json" "\"hooks\"" "Claude settings.json auto-merge adds hooks block"
    assert_contains "merge-case/.claude/settings.json" "hooks/stop.sh" "Claude settings.json auto-merge adds stop hook"
    assert_contains "merge-case/.claude/settings.json" "Bash(echo:*)" "Claude settings.json auto-merge preserves existing permissions"
    assert_contains "merge-case/.claude/settings.local.json" "hooks/stop.sh" "Claude settings.local.json auto-merge adds stop hook"
  else
    pass "jq unavailable: skipped manifest and settings auto-merge assertions"
  fi

  bash "$ROOT_DIR/uninstall.sh" --path .opencode --force >/tmp/agentic-skills-smoke-opencode-uninstall.log
  bash "$ROOT_DIR/uninstall.sh" --path .claude --force >/tmp/agentic-skills-smoke-claude-uninstall.log
  bash "$ROOT_DIR/uninstall.sh" --path .codex --force >/tmp/agentic-skills-smoke-codex-uninstall.log
  bash "$ROOT_DIR/uninstall.sh" --path . --force >/tmp/agentic-skills-smoke-codex-md-uninstall.log

  [[ ! -f .opencode/.agentic-skills.manifest ]] && pass "OpenCode manifest removed" || fail "OpenCode manifest removed"
  [[ ! -f .claude/.agentic-skills.manifest ]] && pass "Claude manifest removed" || fail "Claude manifest removed"
  [[ ! -f .codex/.agentic-skills.manifest ]] && pass "Codex manifest removed" || fail "Codex manifest removed"
  [[ ! -f ./.agentic-skills.manifest ]] && pass "Codex markdown manifest removed" || fail "Codex markdown manifest removed"

  echo "== installer smoke complete: pass=$pass_count fail=$fail_count =="
  [[ $fail_count -eq 0 ]]
}

run
