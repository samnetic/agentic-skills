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
  echo "== manager smoke in $TMP_DIR =="
  cd "$TMP_DIR"

  local release_version
  release_version="$(node -p "require('$ROOT_DIR/package.json').version")"
  bash "$ROOT_DIR/scripts/verify-release-metadata.sh" "v$release_version"
  pass "Release metadata verifier passes"

  local formula_out
  formula_out="$(mktemp)"
  bash "$ROOT_DIR/scripts/render-homebrew-formula.sh" "9.9.9" "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef" "$formula_out"
  assert_contains "$formula_out" 'url "https://github.com/samnetic/agentic-skills/archive/refs/tags/v9.9.9.tar.gz"' "Formula renderer outputs versioned URL"
  assert_contains "$formula_out" 'sha256 "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"' "Formula renderer outputs SHA256"
  rm -f "$formula_out"

  assert_eq "$(bash "$ROOT_DIR/agentic-skills.sh" version)" "1.3.0" "Manager CLI version command"
  assert_eq "$("$ROOT_DIR/bin/agentic-skills" version)" "1.3.0" "Packaged bin version command"

  bash "$ROOT_DIR/agentic-skills.sh" install --claude --skills-only --force >/tmp/agentic-skills-manager-claude-install.log

  if command -v jq >/dev/null 2>&1; then
    assert_eq "$(jq -r '.skills | length' .claude/.agentic-skills.manifest)" "25" "Skills-only manifest skills count"
    assert_eq "$(jq -r '.agents | length' .claude/.agentic-skills.manifest)" "0" "Skills-only manifest agents count"
    assert_eq "$(jq -r '.hooks' .claude/.agentic-skills.manifest)" "false" "Skills-only manifest hooks flag"
  else
    pass "jq unavailable: skipped skills-only manifest JSON assertions"
  fi

  local status_out
  status_out="$(mktemp)"
  bash "$ROOT_DIR/agentic-skills.sh" status --path .claude >"$status_out"
  assert_contains "$status_out" "Components: skills=25 agents=0 hooks=false" "Status reflects skills-only install"
  rm -f "$status_out"

  if [[ -x "$ROOT_DIR/bin/agentic-skills" ]]; then
    local bin_status_out
    bin_status_out="$(mktemp)"
    "$ROOT_DIR/bin/agentic-skills" status --path .claude >"$bin_status_out"
    assert_contains "$bin_status_out" "Components: skills=25 agents=0 hooks=false" "Packaged bin wrapper works"
    rm -f "$bin_status_out"
  else
    fail "Packaged bin wrapper exists"
  fi

  bash "$ROOT_DIR/agentic-skills.sh" doctor --path .claude >/tmp/agentic-skills-manager-claude-doctor.log
  pass "Doctor passes for skills-only install"

  bash "$ROOT_DIR/agentic-skills.sh" update --path .claude --force >/tmp/agentic-skills-manager-claude-update.log
  if command -v jq >/dev/null 2>&1; then
    assert_eq "$(jq -r '.skills | length' .claude/.agentic-skills.manifest)" "25" "Update keeps skills count"
    assert_eq "$(jq -r '.agents | length' .claude/.agentic-skills.manifest)" "0" "Update keeps agents disabled"
    assert_eq "$(jq -r '.hooks' .claude/.agentic-skills.manifest)" "false" "Update keeps hooks disabled"
  fi

  bash "$ROOT_DIR/agentic-skills.sh" self-update --source "$ROOT_DIR" --path .claude --yes --force >/tmp/agentic-skills-manager-claude-self-update.log
  if command -v jq >/dev/null 2>&1; then
    assert_eq "$(jq -r '.skills | length' .claude/.agentic-skills.manifest)" "25" "Self-update keeps skills count"
    assert_eq "$(jq -r '.agents | length' .claude/.agentic-skills.manifest)" "0" "Self-update keeps agents disabled"
  fi

  bash "$ROOT_DIR/agentic-skills.sh" uninstall --path .claude --force >/tmp/agentic-skills-manager-claude-uninstall.log
  [[ ! -f .claude/.agentic-skills.manifest ]] && pass "Skills-only uninstall removed manifest" || fail "Skills-only uninstall removed manifest"

  bash "$ROOT_DIR/agentic-skills.sh" install --opencode --hooks-only --force >/tmp/agentic-skills-manager-opencode-install.log
  if command -v jq >/dev/null 2>&1; then
    assert_eq "$(jq -r '.skills | length' .opencode/.agentic-skills.manifest)" "0" "Hooks-only manifest skills count"
    assert_eq "$(jq -r '.agents | length' .opencode/.agentic-skills.manifest)" "0" "Hooks-only manifest agents count"
    assert_eq "$(jq -r '.hooks' .opencode/.agentic-skills.manifest)" "true" "Hooks-only manifest hooks flag"
    assert_eq "$(jq -r '.plugin_files | length' .opencode/.agentic-skills.manifest)" "1" "Hooks-only manifest plugin count"
  else
    pass "jq unavailable: skipped hooks-only manifest JSON assertions"
  fi

  bash "$ROOT_DIR/agentic-skills.sh" update --path .opencode --force >/tmp/agentic-skills-manager-opencode-update.log
  [[ -f .opencode/plugins/agentic-skills-hooks.js ]] && pass "Update keeps OpenCode hook bridge plugin" || fail "Update keeps OpenCode hook bridge plugin"

  bash "$ROOT_DIR/agentic-skills.sh" uninstall --path .opencode --force >/tmp/agentic-skills-manager-opencode-uninstall.log
  [[ ! -f .opencode/.agentic-skills.manifest ]] && pass "Hooks-only uninstall removed manifest" || fail "Hooks-only uninstall removed manifest"

  echo "== manager smoke complete: pass=$pass_count fail=$fail_count =="
  [[ $fail_count -eq 0 ]]
}

run
