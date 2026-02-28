#!/usr/bin/env bash
set -euo pipefail

# ── Agentic Skills Uninstaller ────────────────────────────────────────────────
# Manifest-based surgical removal. Only removes files that were installed.
#
# Usage: bash uninstall.sh [options]
# Run with --help for full usage information.
# ──────────────────────────────────────────────────────────────────────────────

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
  echo "  $(color cyan)│$(color reset)  $(color bold)Agentic Skills — Uninstall$(color reset)          $(color cyan)│$(color reset)"
  echo "  $(color cyan)╰──────────────────────────────────────╯$(color reset)"
  echo ""
}

# ── Defaults ──────────────────────────────────────────────────────────────────

SEARCH_PATH=""
FORCE=false

# ── CLI argument parsing ──────────────────────────────────────────────────────

usage() {
  cat <<'EOF'
Usage: uninstall.sh [options]

  --path <dir>    Path to search for manifest (default: . and ~)
  --force         Skip confirmation prompt
  --no-color      Disable colored output
  --help          Show this message
EOF
  exit 0
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --path)     SEARCH_PATH="$2"; shift 2 ;;
    --force)    FORCE=true; shift ;;
    --no-color) USE_COLOR=false; shift ;;
    --help)     usage ;;
    *)          err "Unknown option: $1"; echo ""; usage ;;
  esac
done

# ── Find manifests ────────────────────────────────────────────────────────────

MANIFESTS=()

find_manifest() {
  local dir="$1"
  if [[ -f "$dir/.agentic-skills.manifest" ]]; then
    MANIFESTS+=("$dir/.agentic-skills.manifest")
  fi
}

if [[ -n "$SEARCH_PATH" ]]; then
  find_manifest "$SEARCH_PATH"
else
  # Search common locations
  find_manifest ".claude"
  find_manifest "$HOME/.claude"
  find_manifest ".opencode"
  find_manifest "$HOME/.config/opencode"
  find_manifest ".cursor/rules"
  find_manifest "."
fi

# Deduplicate by resolving to absolute paths
declare -A SEEN
UNIQUE_MANIFESTS=()
for m in "${MANIFESTS[@]}"; do
  abs="$(cd "$(dirname "$m")" 2>/dev/null && pwd)/$(basename "$m")"
  if [[ -z "${SEEN[$abs]:-}" ]]; then
    SEEN[$abs]=1
    UNIQUE_MANIFESTS+=("$m")
  fi
done
MANIFESTS=("${UNIQUE_MANIFESTS[@]}")

if [[ ${#MANIFESTS[@]} -eq 0 ]]; then
  banner
  echo "  No Agentic Skills installation found. Nothing to remove."
  echo ""
  exit 0
fi

# ── Select manifest if multiple found ─────────────────────────────────────────

MANIFEST=""

if [[ ${#MANIFESTS[@]} -eq 1 ]]; then
  MANIFEST="${MANIFESTS[0]}"
elif [[ -t 0 ]] && ! $FORCE; then
  banner
  header "Multiple installations found:"
  echo ""
  for i in "${!MANIFESTS[@]}"; do
    idx=$((i + 1))
    echo "    $(color bold)$idx.$(color reset) ${MANIFESTS[$i]}"
  done
  echo ""
  printf "  Select [1]: "
  read -r choice
  choice="${choice:-1}"
  idx=$((choice - 1))
  if [[ $idx -lt 0 || $idx -ge ${#MANIFESTS[@]} ]]; then
    err "Invalid choice"
    exit 1
  fi
  MANIFEST="${MANIFESTS[$idx]}"
else
  # Non-interactive with multiple: use the first one
  MANIFEST="${MANIFESTS[0]}"
fi

# ── Parse manifest ────────────────────────────────────────────────────────────

MANIFEST_DIR="$(dirname "$MANIFEST")"

# Simple JSON parsing with grep/sed (no jq dependency)
json_value() {
  local key="$1"
  grep "\"$key\"" "$MANIFEST" | head -1 | sed 's/.*: *"\{0,1\}\([^",}]*\)"\{0,1\}.*/\1/'
}

json_array() {
  local key="$1"
  grep "\"$key\"" "$MANIFEST" | head -1 | sed 's/.*\[//;s/\].*//;s/"//g;s/,/ /g' | tr -s ' '
}

TARGET="$(json_value "target")"
TARGET_PATH="$(json_value "target_path")"
HOOKS="$(json_value "hooks")"
SKILLS=($(json_array "skills"))
AGENTS=($(json_array "agents"))
PLUGIN_FILES=($(json_array "plugin_files"))

SKILL_COUNT=${#SKILLS[@]}
AGENT_COUNT=${#AGENTS[@]}

# ── Show summary and confirm ──────────────────────────────────────────────────

banner

header "Found installation:"
echo ""
echo "    Path:    $(color bold)$TARGET_PATH$(color reset)"
echo "    Target:  $TARGET"
echo "    Skills:  $SKILL_COUNT"
echo "    Agents:  $AGENT_COUNT"
echo "    Hooks:   $HOOKS"
echo ""

if ! $FORCE && [[ -t 0 ]]; then
  printf "  Remove everything? [y/N]: "
  read -r confirm
  if [[ ! "$confirm" =~ ^[Yy] ]]; then
    echo ""
    echo "  Aborted."
    exit 0
  fi
fi

echo ""

# ── Remove skills ─────────────────────────────────────────────────────────────

skills_removed=0

case "$TARGET" in
  claude-project|claude-global|opencode-project|opencode-global)
    for skill in "${SKILLS[@]}"; do
      skill_dir="$MANIFEST_DIR/skills/$skill"
      if [[ -d "$skill_dir" ]]; then
        rm -rf "$skill_dir"
        skills_removed=$((skills_removed + 1))
      fi
    done
    # Clean up empty skills/ directory
    if [[ -d "$MANIFEST_DIR/skills" ]] && [ -z "$(ls -A "$MANIFEST_DIR/skills" 2>/dev/null)" ]; then
      rmdir "$MANIFEST_DIR/skills"
    fi
    ;;
  cursor)
    for skill in "${SKILLS[@]}"; do
      skill_file="$MANIFEST_DIR/$skill.md"
      if [[ -f "$skill_file" ]]; then
        rm -f "$skill_file"
        skills_removed=$((skills_removed + 1))
      fi
    done
    ;;
  codex)
    if [[ -f "codex.md" ]]; then
      rm -f "codex.md"
      skills_removed=$SKILL_COUNT
    fi
    ;;
esac

if [[ $skills_removed -gt 0 ]]; then
  info "$skills_removed skills removed"
fi

# ── Remove agents ─────────────────────────────────────────────────────────────

agents_removed=0

case "$TARGET" in
  claude-project|claude-global|opencode-project|opencode-global)
    for agent in "${AGENTS[@]}"; do
      agent_file="$MANIFEST_DIR/agents/$agent"
      if [[ -f "$agent_file" ]]; then
        rm -f "$agent_file"
        agents_removed=$((agents_removed + 1))
      fi
    done
    # Clean up empty agents/ directory
    if [[ -d "$MANIFEST_DIR/agents" ]] && [ -z "$(ls -A "$MANIFEST_DIR/agents" 2>/dev/null)" ]; then
      rmdir "$MANIFEST_DIR/agents"
    fi
    ;;
  cursor)
    for agent in "${AGENTS[@]}"; do
      agent_file="$MANIFEST_DIR/$agent"
      if [[ -f "$agent_file" ]]; then
        rm -f "$agent_file"
        agents_removed=$((agents_removed + 1))
      fi
    done
    ;;
esac

if [[ $agents_removed -gt 0 ]]; then
  info "$agents_removed agents removed"
fi

# ── Remove hooks ──────────────────────────────────────────────────────────────

if [[ "$HOOKS" == "true" ]]; then
  hooks_removed=0
  hook_scripts=($(json_array "hook_scripts"))

  if [[ "$TARGET" == claude-* ]]; then
    for hs in "${hook_scripts[@]}"; do
      hs_file="$MANIFEST_DIR/hooks/$hs"
      if [[ -f "$hs_file" ]]; then
        rm -f "$hs_file"
        hooks_removed=$((hooks_removed + 1))
      fi
    done
    rm -rf "$MANIFEST_DIR/hooks/logs" "$MANIFEST_DIR/hooks/backups"
    if [[ -d "$MANIFEST_DIR/hooks" ]] && [ -z "$(ls -A "$MANIFEST_DIR/hooks" 2>/dev/null)" ]; then
      rmdir "$MANIFEST_DIR/hooks"
    fi
  elif [[ "$TARGET" == opencode-* ]]; then
    for pf in "${PLUGIN_FILES[@]}"; do
      plugin_file="$MANIFEST_DIR/plugins/$pf"
      if [[ -f "$plugin_file" ]]; then
        rm -f "$plugin_file"
        hooks_removed=$((hooks_removed + 1))
      fi
    done
    if [[ -d "$MANIFEST_DIR/plugins" ]] && [ -z "$(ls -A "$MANIFEST_DIR/plugins" 2>/dev/null)" ]; then
      rmdir "$MANIFEST_DIR/plugins"
    fi
    rm -rf "$MANIFEST_DIR/hooks/logs"
  fi

  if [[ $hooks_removed -gt 0 ]]; then
    info "$hooks_removed hook/plugin files removed"
  fi
  if [[ "$TARGET" == claude-* ]]; then
    warn "Hooks config may exist in settings.json/settings.local.json — review and remove manually:"
    echo "    $MANIFEST_DIR/settings.json"
    echo "    $MANIFEST_DIR/settings.local.json"
  fi
fi

# ── Remove manifest ──────────────────────────────────────────────────────────

rm -f "$MANIFEST"
info "Manifest removed"

echo ""
echo "  Agentic Skills uninstalled."
echo ""
