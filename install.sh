#!/usr/bin/env bash
set -euo pipefail

# ── Agentic Skills Installer ──────────────────────────────────────────────────
# Interactive multi-platform installer for 25 skills, 9 agents, and 7 hooks.
# Supports Claude Code (project/global), OpenCode (project/global), Cursor, and Codex CLI.
#
# Usage: bash install.sh [options]
# Run with --help for full usage information.
# ──────────────────────────────────────────────────────────────────────────────

VERSION="1.3.0"
REPO_URL="https://github.com/samnetic/agentic-skills.git"
HOOK_SETTINGS_URL="https://raw.githubusercontent.com/samnetic/agentic-skills/main/.claude/settings.local.json"

# ── Remote pipe detection ────────────────────────────────────────────────────
# When piped via `curl ... | bash`, $0 is "bash" and there's no local repo.
# Clone to a temp directory, re-run the script from there, then clean up.

_cleanup_tmp() { [[ -n "${_TMP_CLONE:-}" ]] && rm -rf "$_TMP_CLONE"; }

if [[ ! -f "$0" ]] || [[ "$(basename "$0")" == "bash" ]] || [[ "$(basename "$0")" == "sh" ]]; then
  _TMP_CLONE="$(mktemp -d)"
  trap _cleanup_tmp EXIT
  echo "  Fetching agentic-skills..."
  if ! git clone --depth 1 --quiet "$REPO_URL" "$_TMP_CLONE" 2>/dev/null; then
    echo "  ✗ Failed to clone $REPO_URL" >&2
    exit 1
  fi
  exec bash "$_TMP_CLONE/install.sh" "$@"
fi

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

# ── Color / output helpers ────────────────────────────────────────────────────

USE_COLOR=true
[[ -n "${NO_COLOR:-}" ]] && USE_COLOR=false
[[ ! -t 1 ]] && USE_COLOR=false

color() {
  if $USE_COLOR; then
    case "$1" in
      green)  printf '\033[0;32m' ;;
      yellow) printf '\033[0;33m' ;;
      red)    printf '\033[0;31m' ;;
      cyan)   printf '\033[0;36m' ;;
      bold)   printf '\033[1m' ;;
      dim)    printf '\033[2m' ;;
      reset)  printf '\033[0m' ;;
    esac
  fi
}

info()    { echo "  $(color green)✓$(color reset) $*"; }
warn()    { echo "  $(color yellow)⚠$(color reset) $*"; }
err()     { echo "  $(color red)✗$(color reset) $*" >&2; }
header()  { echo "  $(color bold)$*$(color reset)"; }

banner() {
  echo ""
  echo "  $(color cyan)╭──────────────────────────────────────╮$(color reset)"
  echo "  $(color cyan)│$(color reset)  $(color bold)Agentic Skills$(color reset)                      $(color cyan)│$(color reset)"
  echo "  $(color cyan)│$(color reset)  25 skills · 9 agents · 7 hooks      $(color cyan)│$(color reset)"
  echo "  $(color cyan)╰──────────────────────────────────────╯$(color reset)"
  echo ""
}

# ── OpenCode agent conversion helpers ────────────────────────────────────────

map_opencode_tool() {
  local token
  token="$(echo "$1" | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]')"
  case "$token" in
    read) echo "read" ;;
    write) echo "write" ;;
    edit) echo "edit" ;;
    bash) echo "bash" ;;
    list) echo "list" ;;
    glob) echo "glob" ;;
    grep) echo "grep" ;;
    webfetch|websearch) echo "webfetch" ;;
    task) echo "task" ;;
    todowrite) echo "todowrite" ;;
    todoread) echo "todoread" ;;
    *) echo "" ;;
  esac
}

extract_agent_description() {
  local src="$1"
  awk '
    BEGIN { in_desc = 0; text = "" }
    /^description:[[:space:]]*>-/ { in_desc = 1; next }
    in_desc == 1 {
      if ($0 ~ /^[[:space:]]{2,}[^[:space:]].*/) {
        gsub(/^[[:space:]]+/, "", $0)
        text = text (text ? " " : "") $0
        next
      }
      if ($0 ~ /^[a-zA-Z0-9_-]+:/) {
        in_desc = 0
      }
    }
    END { print text }
  ' "$src"
}

write_opencode_agent() {
  local src="$1"
  local dst="$2"
  local slug description tools_raw safe_description mapped raw_tool tool_name
  slug="$(basename "$src" .md)"
  description="$(extract_agent_description "$src")"
  if [[ -z "$description" ]]; then
    description="Specialized subagent: $slug"
  fi
  safe_description="${description//\"/\\\"}"

  tools_raw="$(awk '/^tools:/ {sub(/^tools:[[:space:]]*/, ""); print; exit}' "$src")"
  declare -A tools_enabled=()
  if [[ -n "$tools_raw" ]]; then
    local -a raw_tools
    IFS=',' read -r -a raw_tools <<< "$tools_raw"
    for raw_tool in "${raw_tools[@]}"; do
      mapped="$(map_opencode_tool "$raw_tool")"
      [[ -n "$mapped" ]] && tools_enabled["$mapped"]=true
    done
  fi

  # Ensure minimum navigation capabilities even when source tool mapping is empty.
  if [[ ${#tools_enabled[@]} -eq 0 ]]; then
    tools_enabled["read"]=true
    tools_enabled["glob"]=true
    tools_enabled["grep"]=true
  fi

  {
    echo "---"
    echo "description: \"$safe_description\""
    echo "mode: subagent"
    echo "tools:"
    for tool_name in bash read write edit list glob grep webfetch task todowrite todoread; do
      if [[ -n "${tools_enabled[$tool_name]:-}" ]]; then
        echo "  $tool_name: true"
      fi
    done
    echo "---"
    echo ""
    awk '
      BEGIN { delim = 0 }
      /^---[[:space:]]*$/ { delim++; next }
      delim >= 2 { print }
    ' "$src"
  } > "$dst"
}

merge_claude_hook_settings() {
  local settings_file="$1"
  local settings_src="$2"
  local settings_name="$3"
  local tmp

  if ! command -v jq >/dev/null 2>&1; then
    warn "$settings_name exists — auto-merge requires jq."
    warn "Install jq or merge hooks manually from:"
    echo "    $HOOK_SETTINGS_URL"
    return 1
  fi

  if ! jq empty "$settings_file" >/dev/null 2>&1; then
    warn "$settings_name exists but is not valid JSON — merge hooks manually from:"
    echo "    $HOOK_SETTINGS_URL"
    return 1
  fi

  tmp="$(mktemp)"
  if jq -s '
      .[0] as $dst
      | .[1] as $src
      | ($dst + {hooks: ($dst.hooks // {})})
      | reduce (($src.hooks // {}) | keys_unsorted[]) as $event (
          .;
          .hooks[$event] = (
            ((.hooks[$event] // []) + (($src.hooks[$event] // [])))
            | unique_by(tojson)
          )
        )
    ' "$settings_file" "$settings_src" > "$tmp"; then
    mv "$tmp" "$settings_file"
    info "Hook configuration merged into $settings_name"
    return 0
  fi

  rm -f "$tmp"
  warn "Failed to auto-merge hooks in $settings_name — merge manually from:"
  echo "    $HOOK_SETTINGS_URL"
  return 1
}

# ── Defaults ──────────────────────────────────────────────────────────────────

TARGET=""
INSTALL_SKILLS=true
INSTALL_AGENTS=true
INSTALL_HOOKS=true
DRY_RUN=false
FORCE=false
INTERACTIVE=true

# Track exactly what was installed so manifest data is precise.
MANIFEST_SKILLS=()
MANIFEST_AGENTS=()
MANIFEST_HOOKS=false
MANIFEST_HOOK_SCRIPTS=()
MANIFEST_PLUGIN_FILES=()

# ── CLI argument parsing ──────────────────────────────────────────────────────

usage() {
  cat <<'EOF'
Usage: install.sh [options]

Targets:
  --claude              Install to .claude/ in current directory (default)
  --claude-global       Install to ~/.claude/
  --opencode            Install to .opencode/ in current directory
  --opencode-global     Install to ~/.config/opencode/
  --cursor              Install to .cursor/rules/
  --codex               Append to codex.md

Components:
  --skills-only         Only install skills
  --agents-only         Only install agents
  --hooks-only          Only install hooks
  --no-skills           Skip skills
  --no-agents           Skip agents
  --no-hooks            Skip hooks/plugins

Options:
  --dry-run             Show what would be installed, don't write files
  --force               Overwrite without prompting
  --no-color            Disable colored output
  --help                Show this message
EOF
  exit 0
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --claude)        TARGET="claude-project"; INTERACTIVE=false; shift ;;
    --claude-global) TARGET="claude-global";  INTERACTIVE=false; shift ;;
    --opencode)      TARGET="opencode-project"; INTERACTIVE=false; shift ;;
    --opencode-global) TARGET="opencode-global"; INTERACTIVE=false; shift ;;
    --cursor)        TARGET="cursor";         INTERACTIVE=false; shift ;;
    --codex)         TARGET="codex";          INTERACTIVE=false; shift ;;
    --skills-only)   INSTALL_SKILLS=true; INSTALL_AGENTS=false; INSTALL_HOOKS=false; INTERACTIVE=false; shift ;;
    --agents-only)   INSTALL_SKILLS=false; INSTALL_AGENTS=true; INSTALL_HOOKS=false; INTERACTIVE=false; shift ;;
    --hooks-only)    INSTALL_SKILLS=false; INSTALL_AGENTS=false; INSTALL_HOOKS=true; INTERACTIVE=false; shift ;;
    --no-skills)     INSTALL_SKILLS=false; INTERACTIVE=false; shift ;;
    --no-agents)     INSTALL_AGENTS=false; INTERACTIVE=false; shift ;;
    --no-hooks)      INSTALL_HOOKS=false; INTERACTIVE=false; shift ;;
    --dry-run)       DRY_RUN=true; shift ;;
    --force)         FORCE=true; INTERACTIVE=false; shift ;;
    --no-color)      USE_COLOR=false; shift ;;
    --help)          usage ;;
    *)               err "Unknown option: $1"; echo ""; usage ;;
  esac
done

# Default target if none specified via flags
[[ -z "$TARGET" ]] && TARGET="claude-project"

# ── Validate source repo ─────────────────────────────────────────────────────

if [[ ! -d "$REPO_DIR/skills" ]]; then
  err "Cannot find skills/ directory in $REPO_DIR"
  err "Make sure you're running this script from the agentic-skills repo."
  exit 1
fi

if [[ ! -d "$REPO_DIR/agents" ]]; then
  err "Cannot find agents/ directory in $REPO_DIR"
  exit 1
fi

# ── Collect source data ──────────────────────────────────────────────────────

SKILL_DIRS=()
while IFS= read -r d; do
  SKILL_DIRS+=("$d")
done < <(find "$REPO_DIR/skills" -mindepth 1 -maxdepth 1 -type d | sort)

AGENT_FILES=()
while IFS= read -r f; do
  AGENT_FILES+=("$f")
done < <(find "$REPO_DIR/agents" -maxdepth 1 -name '*.md' -type f | sort)

SKILL_COUNT=${#SKILL_DIRS[@]}
AGENT_COUNT=${#AGENT_FILES[@]}

# ── Interactive mode ──────────────────────────────────────────────────────────

if $INTERACTIVE && [[ -t 0 ]]; then
  banner

  header "Install to:"
  echo ""
  echo "    $(color bold)1.$(color reset) Claude Code — this project    $(color dim).claude/$(color reset)"
  echo "    $(color bold)2.$(color reset) Claude Code — global           $(color dim)~/.claude/$(color reset)"
  echo "    $(color bold)3.$(color reset) OpenCode — this project        $(color dim).opencode/$(color reset)"
  echo "    $(color bold)4.$(color reset) OpenCode — global              $(color dim)~/.config/opencode/$(color reset)"
  echo "    $(color bold)5.$(color reset) Cursor — this project          $(color dim).cursor/rules/$(color reset)"
  echo "    $(color bold)6.$(color reset) Codex CLI — this project       $(color dim)codex.md$(color reset)"
  echo ""
  printf "  Select [1]: "
  read -r choice
  choice="${choice:-1}"

  case "$choice" in
    1) TARGET="claude-project" ;;
    2) TARGET="claude-global" ;;
    3) TARGET="opencode-project" ;;
    4) TARGET="opencode-global" ;;
    5) TARGET="cursor" ;;
    6) TARGET="codex" ;;
    *) err "Invalid choice: $choice"; exit 1 ;;
  esac

  echo ""
  header "Components:"
  echo ""
  echo "    $(color green)[✓]$(color reset) Skills   $SKILL_COUNT domain expertise guides"
  echo "    $(color green)[✓]$(color reset) Agents   $AGENT_COUNT specialized AI agents"
  echo "    $(color green)[✓]$(color reset) Hooks    7 command hook scripts"
  echo ""
  printf "  Install all? [Y/n]: "
  read -r confirm
  confirm="${confirm:-Y}"
  if [[ "$confirm" =~ ^[Nn] ]]; then
    echo ""
    echo "  Aborted."
    exit 0
  fi
fi

# ── Resolve target path ──────────────────────────────────────────────────────

case "$TARGET" in
  claude-project)
    TARGET_BASE=".claude"
    TARGET_LABEL="Claude Code (project)"
    ;;
  claude-global)
    TARGET_BASE="$HOME/.claude"
    TARGET_LABEL="Claude Code (global)"
    ;;
  opencode-project)
    TARGET_BASE=".opencode"
    TARGET_LABEL="OpenCode (project)"
    ;;
  opencode-global)
    TARGET_BASE="$HOME/.config/opencode"
    TARGET_LABEL="OpenCode (global)"
    ;;
  cursor)
    TARGET_BASE=".cursor/rules"
    TARGET_LABEL="Cursor (project)"
    ;;
  codex)
    TARGET_BASE="."
    TARGET_LABEL="Codex CLI"
    ;;
esac

# ── Dry-run preamble ─────────────────────────────────────────────────────────

if $DRY_RUN; then
  echo ""
  header "Dry run — nothing will be written"
  echo ""
  echo "  Target: $(color bold)$TARGET_LABEL$(color reset)"
  echo "  Path:   $(color dim)$TARGET_BASE$(color reset)"
  echo ""
  if $INSTALL_SKILLS; then
    echo "  Skills ($SKILL_COUNT):"
    for d in "${SKILL_DIRS[@]}"; do
      name="$(basename "$d")"
      if [[ "$TARGET" == "cursor" ]]; then
        echo "    → $TARGET_BASE/$name.md"
      elif [[ "$TARGET" == "codex" ]]; then
        echo "    → codex.md (appended)"
      else
        echo "    → $TARGET_BASE/skills/$name/SKILL.md"
      fi
    done
    echo ""
  fi
  if $INSTALL_AGENTS; then
    echo "  Agents ($AGENT_COUNT):"
    for f in "${AGENT_FILES[@]}"; do
      name="$(basename "$f")"
      if [[ "$TARGET" == "cursor" ]]; then
        echo "    → $TARGET_BASE/$name"
      elif [[ "$TARGET" == "codex" ]]; then
        echo "    → codex.md (appended)"
      else
        echo "    → $TARGET_BASE/agents/$name"
      fi
    done
    echo ""
  fi
  if $INSTALL_HOOKS; then
    if [[ "$TARGET" == claude-* ]]; then
      echo "  Hooks: 7 command scripts"
      for hook_script in "$REPO_DIR/.claude/hooks/"*.sh; do
        [ -f "$hook_script" ] && echo "    → $TARGET_BASE/hooks/$(basename "$hook_script")"
      done
      echo "    → $TARGET_BASE/settings.json"
      echo "    → $TARGET_BASE/settings.local.json"
    elif [[ "$TARGET" == opencode-* ]]; then
      echo "  Hooks: OpenCode plugin bridge"
      if [[ -f "$REPO_DIR/.opencode/plugins/agentic-skills-hooks.js" ]]; then
        echo "    → $TARGET_BASE/plugins/agentic-skills-hooks.js"
      else
        echo "    → (plugin source missing: .opencode/plugins/agentic-skills-hooks.js)"
      fi
    else
      echo "  Hooks: skipped (only supported for Claude Code and OpenCode)"
    fi
    echo ""
  fi
  echo "  Manifest: $TARGET_BASE/.agentic-skills.manifest"
  echo ""
  exit 0
fi

# ── Install: Claude Code (project or global) ─────────────────────────────────

install_claude() {
  local base="$1"
  local skills_installed=0
  local agents_installed=0

  echo ""
  header "Installing to $base/ ..."
  echo ""

  # Skills
  if $INSTALL_SKILLS; then
    mkdir -p "$base/skills"
    for d in "${SKILL_DIRS[@]}"; do
      name="$(basename "$d")"
      mkdir -p "$base/skills/$name"
      cp "$d/SKILL.md" "$base/skills/$name/SKILL.md"
      # Copy reference subdirectories if they exist (e.g., docker-production/references/)
      if [ -d "$d/references" ]; then
        cp -r "$d/references" "$base/skills/$name/references"
      fi
      MANIFEST_SKILLS+=("$name")
      skills_installed=$((skills_installed + 1))
    done
    info "$skills_installed skills installed"
  fi

  # Agents
  if $INSTALL_AGENTS; then
    mkdir -p "$base/agents"
    for f in "${AGENT_FILES[@]}"; do
      local agent_name
      agent_name="$(basename "$f")"
      cp "$f" "$base/agents/"
      MANIFEST_AGENTS+=("$agent_name")
      agents_installed=$((agents_installed + 1))
    done
    info "$agents_installed agents installed"
  fi

  # Hook scripts
  if $INSTALL_HOOKS; then
    local hooks_installed=0
    mkdir -p "$base/hooks/logs" "$base/hooks/backups"
    for hook_script in "$REPO_DIR/.claude/hooks/"*.sh; do
      if [[ -f "$hook_script" ]]; then
        cp "$hook_script" "$base/hooks/"
        MANIFEST_HOOK_SCRIPTS+=("$(basename "$hook_script")")
        hooks_installed=$((hooks_installed + 1))
      fi
    done
    chmod +x "$base/hooks/"*.sh 2>/dev/null || true
    info "$hooks_installed hook scripts installed"
    if [[ $hooks_installed -gt 0 ]]; then
      MANIFEST_HOOKS=true
    fi

    # settings.json + settings.local.json
    local settings_src="$REPO_DIR/.claude/settings.local.json"
    local settings_file
    for settings_file in "$base/settings.json" "$base/settings.local.json"; do
      local settings_name
      settings_name="$(basename "$settings_file")"
      if [[ ! -f "$settings_file" ]] && [[ -f "$settings_src" ]]; then
        cp "$settings_src" "$settings_file"
        info "Hook configuration written to $settings_name"
      elif [[ ! -f "$settings_file" ]]; then
        warn "Source settings.local.json not found — skipped $settings_name"
      elif grep -q "hooks/stop.sh" "$settings_file" 2>/dev/null; then
        info "Hooks already present in $settings_name"
      else
        merge_claude_hook_settings "$settings_file" "$settings_src" "$settings_name" || true
      fi
    done
  fi

  # Manifest
  write_manifest "$base"
}

# ── Install: OpenCode (project or global) ────────────────────────────────────

install_opencode() {
  local base="$1"
  local skills_installed=0
  local agents_installed=0

  echo ""
  header "Installing to $base/ ..."
  echo ""

  # Skills
  if $INSTALL_SKILLS; then
    mkdir -p "$base/skills"
    for d in "${SKILL_DIRS[@]}"; do
      name="$(basename "$d")"
      mkdir -p "$base/skills/$name"
      cp "$d/SKILL.md" "$base/skills/$name/SKILL.md"
      if [[ -d "$d/references" ]]; then
        cp -r "$d/references" "$base/skills/$name/references"
      fi
      MANIFEST_SKILLS+=("$name")
      skills_installed=$((skills_installed + 1))
    done
    info "$skills_installed skills installed"
  fi

  # Agents
  if $INSTALL_AGENTS; then
    mkdir -p "$base/agents"
    for f in "${AGENT_FILES[@]}"; do
      local agent_name
      agent_name="$(basename "$f")"
      write_opencode_agent "$f" "$base/agents/$agent_name"
      MANIFEST_AGENTS+=("$agent_name")
      agents_installed=$((agents_installed + 1))
    done
    info "$agents_installed agents installed"
  fi

  # Hook bridge plugin
  if $INSTALL_HOOKS; then
    local plugin_src="$REPO_DIR/.opencode/plugins/agentic-skills-hooks.js"
    local plugin_dst_dir="$base/plugins"
    if [[ -f "$plugin_src" ]]; then
      mkdir -p "$plugin_dst_dir"
      cp "$plugin_src" "$plugin_dst_dir/"
      MANIFEST_PLUGIN_FILES+=("agentic-skills-hooks.js")
      MANIFEST_HOOKS=true
      info "OpenCode hook bridge plugin installed"
    else
      warn "OpenCode hook bridge plugin missing — skipped"
    fi
  fi

  write_manifest "$base"
}

# ── Install: Cursor ───────────────────────────────────────────────────────────

install_cursor() {
  local base="$1"
  local skills_installed=0
  local agents_installed=0

  echo ""
  header "Installing to $base/ ..."
  echo ""

  mkdir -p "$base"

  # Skills — each SKILL.md becomes <skill-name>.md
  if $INSTALL_SKILLS; then
    for d in "${SKILL_DIRS[@]}"; do
      name="$(basename "$d")"
      cp "$d/SKILL.md" "$base/$name.md"
      MANIFEST_SKILLS+=("$name")
      skills_installed=$((skills_installed + 1))
    done
    info "$skills_installed skills installed"
  fi

  # Agents — copy as-is
  if $INSTALL_AGENTS; then
    for f in "${AGENT_FILES[@]}"; do
      local agent_name
      agent_name="$(basename "$f")"
      cp "$f" "$base/"
      MANIFEST_AGENTS+=("$agent_name")
      agents_installed=$((agents_installed + 1))
    done
    info "$agents_installed agents installed"
  fi

  # Hooks not supported for Cursor
  if $INSTALL_HOOKS; then
    warn "Hooks are only supported for Claude Code and OpenCode — skipped"
  fi

  write_manifest "$base"
}

# ── Install: Codex CLI ────────────────────────────────────────────────────────

install_codex() {
  local outfile="codex.md"
  local skills_installed=0
  local agents_installed=0

  echo ""
  header "Installing to $outfile ..."
  echo ""

  # Start fresh or append
  if [[ -f "$outfile" ]] && ! $FORCE; then
    if grep -q "Agentic Skills" "$outfile" 2>/dev/null; then
      warn "codex.md already contains Agentic Skills content"
      warn "Use --force to overwrite, or remove the existing content first"
      exit 1
    fi
  fi

  {
    echo "# Agentic Skills"
    echo ""
    echo "> 25 expert-level domain skills + 9 specialized agents."
    echo ""

    # Skills
    if $INSTALL_SKILLS; then
      for d in "${SKILL_DIRS[@]}"; do
        name="$(basename "$d")"
        echo "---"
        echo ""
        echo "## Skill: $name"
        echo ""
        cat "$d/SKILL.md"
        echo ""
        MANIFEST_SKILLS+=("$name")
        skills_installed=$((skills_installed + 1))
      done
    fi

    # Agents
    if $INSTALL_AGENTS; then
      for f in "${AGENT_FILES[@]}"; do
        name="$(basename "$f" .md)"
        MANIFEST_AGENTS+=("$(basename "$f")")
        echo "---"
        echo ""
        echo "## Agent: $name"
        echo ""
        cat "$f"
        echo ""
        agents_installed=$((agents_installed + 1))
      done
    fi
  } > "$outfile"

  $INSTALL_SKILLS && info "$skills_installed skills installed"
  $INSTALL_AGENTS && info "$agents_installed agents installed"

  if $INSTALL_HOOKS; then
    warn "Hooks are only supported for Claude Code and OpenCode — skipped"
  fi

  write_manifest "."
}

# ── Manifest ──────────────────────────────────────────────────────────────────

json_array_strings() {
  local out=""
  local item
  for item in "$@"; do
    if [[ -n "$out" ]]; then
      out="$out, \"$item\""
    else
      out="\"$item\""
    fi
  done
  printf '%s' "$out"
}

write_manifest() {
  local base="$1"
  local manifest="$base/.agentic-skills.manifest"
  local timestamp
  timestamp="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
  local skill_names agent_names hook_script_names plugin_file_names
  local hooks_val="false"
  skill_names="$(json_array_strings "${MANIFEST_SKILLS[@]}")"
  agent_names="$(json_array_strings "${MANIFEST_AGENTS[@]}")"
  hook_script_names="$(json_array_strings "${MANIFEST_HOOK_SCRIPTS[@]}")"
  plugin_file_names="$(json_array_strings "${MANIFEST_PLUGIN_FILES[@]}")"
  if $MANIFEST_HOOKS; then
    hooks_val="true"
  fi

  cat > "$manifest" <<EOF
{
  "version": "$VERSION",
  "installed_at": "$timestamp",
  "source": "$REPO_DIR",
  "target": "$TARGET",
  "target_path": "$(cd "$base" 2>/dev/null && pwd || echo "$base")",
  "skills": [$skill_names],
  "agents": [$agent_names],
  "hooks": $hooks_val,
  "hook_scripts": [$hook_script_names],
  "plugin_files": [$plugin_file_names]
}
EOF

  info "Manifest saved"
}

# ── Dispatch ──────────────────────────────────────────────────────────────────

case "$TARGET" in
  claude-project) install_claude "$TARGET_BASE" ;;
  claude-global)  install_claude "$TARGET_BASE" ;;
  opencode-project) install_opencode "$TARGET_BASE" ;;
  opencode-global)  install_opencode "$TARGET_BASE" ;;
  cursor)         install_cursor "$TARGET_BASE" ;;
  codex)          install_codex ;;
esac

# ── Done ──────────────────────────────────────────────────────────────────────

echo ""
case "$TARGET" in
  claude-*) info "Done! Restart Claude Code to activate." ;;
  opencode-*) info "Done! Restart OpenCode to activate." ;;
  cursor)   info "Done! Restart Cursor to activate." ;;
  codex)    info "Done! codex.md is ready." ;;
esac
echo "  To uninstall: $(color dim)bash $REPO_DIR/uninstall.sh$(color reset)"
echo ""
