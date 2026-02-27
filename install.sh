#!/usr/bin/env bash
set -euo pipefail

# ── Agentic Skills Installer ──────────────────────────────────────────────────
# Interactive multi-platform installer for 25 skills, 8 agents, and 7 hooks.
# Supports Claude Code (project/global), Cursor, and Codex CLI.
#
# Usage: bash install.sh [options]
# Run with --help for full usage information.
# ──────────────────────────────────────────────────────────────────────────────

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
VERSION="1.0.0"

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
  echo "  $(color cyan)│$(color reset)  25 skills · 8 agents · 7 hooks      $(color cyan)│$(color reset)"
  echo "  $(color cyan)╰──────────────────────────────────────╯$(color reset)"
  echo ""
}

# ── Defaults ──────────────────────────────────────────────────────────────────

TARGET=""
INSTALL_SKILLS=true
INSTALL_AGENTS=true
INSTALL_HOOKS=true
DRY_RUN=false
FORCE=false
INTERACTIVE=true

# ── CLI argument parsing ──────────────────────────────────────────────────────

usage() {
  cat <<'EOF'
Usage: install.sh [options]

Targets:
  --claude              Install to .claude/ in current directory (default)
  --claude-global       Install to ~/.claude/
  --cursor              Install to .cursor/rules/
  --codex               Append to codex.md

Components:
  --skills-only         Only install skills
  --agents-only         Only install agents
  --hooks-only          Only install hooks

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
    --cursor)        TARGET="cursor";         INTERACTIVE=false; shift ;;
    --codex)         TARGET="codex";          INTERACTIVE=false; shift ;;
    --skills-only)   INSTALL_SKILLS=true; INSTALL_AGENTS=false; INSTALL_HOOKS=false; INTERACTIVE=false; shift ;;
    --agents-only)   INSTALL_SKILLS=false; INSTALL_AGENTS=true; INSTALL_HOOKS=false; INTERACTIVE=false; shift ;;
    --hooks-only)    INSTALL_SKILLS=false; INSTALL_AGENTS=false; INSTALL_HOOKS=true; INTERACTIVE=false; shift ;;
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
  echo "    $(color bold)3.$(color reset) Cursor — this project          $(color dim).cursor/rules/$(color reset)"
  echo "    $(color bold)4.$(color reset) Codex CLI — this project       $(color dim)codex.md$(color reset)"
  echo ""
  printf "  Select [1]: "
  read -r choice
  choice="${choice:-1}"

  case "$choice" in
    1) TARGET="claude-project" ;;
    2) TARGET="claude-global" ;;
    3) TARGET="cursor" ;;
    4) TARGET="codex" ;;
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
      echo "    → $TARGET_BASE/settings.local.json"
    else
      echo "  Hooks: skipped (only supported for Claude Code)"
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
      skills_installed=$((skills_installed + 1))
    done
    info "$skills_installed skills installed"
  fi

  # Agents
  if $INSTALL_AGENTS; then
    mkdir -p "$base/agents"
    for f in "${AGENT_FILES[@]}"; do
      cp "$f" "$base/agents/"
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
        hooks_installed=$((hooks_installed + 1))
      fi
    done
    chmod +x "$base/hooks/"*.sh 2>/dev/null || true
    info "$hooks_installed hook scripts installed"

    # settings.local.json
    local settings_file="$base/settings.local.json"
    if [[ ! -f "$settings_file" ]]; then
      cp "$REPO_DIR/.claude/settings.local.json" "$settings_file"
      info "Hook configuration written to settings.local.json"
    elif grep -q "hooks/stop.sh" "$settings_file" 2>/dev/null; then
      warn "Hooks already present in settings.local.json — skipped"
    else
      warn "settings.local.json exists — merge hooks manually from:"
      echo "    $REPO_DIR/.claude/settings.local.json"
    fi
  fi

  # Manifest
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
      skills_installed=$((skills_installed + 1))
    done
    info "$skills_installed skills installed"
  fi

  # Agents — copy as-is
  if $INSTALL_AGENTS; then
    for f in "${AGENT_FILES[@]}"; do
      cp "$f" "$base/"
      agents_installed=$((agents_installed + 1))
    done
    info "$agents_installed agents installed"
  fi

  # Hooks not supported for Cursor
  if $INSTALL_HOOKS; then
    warn "Hooks are only supported for Claude Code — skipped"
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
    echo "> 18 expert-level domain skills + 8 specialized agents."
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
        skills_installed=$((skills_installed + 1))
      done
    fi

    # Agents
    if $INSTALL_AGENTS; then
      for f in "${AGENT_FILES[@]}"; do
        name="$(basename "$f" .md)"
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
    warn "Hooks are only supported for Claude Code — skipped"
  fi

  write_manifest "."
}

# ── Manifest ──────────────────────────────────────────────────────────────────

write_manifest() {
  local base="$1"
  local manifest="$base/.agentic-skills.manifest"
  local timestamp
  timestamp="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"

  # Build skill names array
  local skill_names=""
  for d in "${SKILL_DIRS[@]}"; do
    name="$(basename "$d")"
    if [[ -n "$skill_names" ]]; then
      skill_names="$skill_names, \"$name\""
    else
      skill_names="\"$name\""
    fi
  done

  # Build agent names array
  local agent_names=""
  for f in "${AGENT_FILES[@]}"; do
    name="$(basename "$f")"
    if [[ -n "$agent_names" ]]; then
      agent_names="$agent_names, \"$name\""
    else
      agent_names="\"$name\""
    fi
  done

  local hooks_val="false"
  local hook_script_names=""
  if $INSTALL_HOOKS && [[ "$TARGET" == claude-* ]]; then
    hooks_val="true"
    for hs in "$REPO_DIR/.claude/hooks/"*.sh; do
      if [[ -f "$hs" ]]; then
        hsname="$(basename "$hs")"
        if [[ -n "$hook_script_names" ]]; then
          hook_script_names="$hook_script_names, \"$hsname\""
        else
          hook_script_names="\"$hsname\""
        fi
      fi
    done
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
  "hook_scripts": [$hook_script_names]
}
EOF

  info "Manifest saved"
}

# ── Dispatch ──────────────────────────────────────────────────────────────────

case "$TARGET" in
  claude-project) install_claude "$TARGET_BASE" ;;
  claude-global)  install_claude "$TARGET_BASE" ;;
  cursor)         install_cursor "$TARGET_BASE" ;;
  codex)          install_codex ;;
esac

# ── Done ──────────────────────────────────────────────────────────────────────

echo ""
case "$TARGET" in
  claude-*) info "Done! Restart Claude Code to activate." ;;
  cursor)   info "Done! Restart Cursor to activate." ;;
  codex)    info "Done! codex.md is ready." ;;
esac
echo "  To uninstall: $(color dim)bash $REPO_DIR/uninstall.sh$(color reset)"
echo ""
