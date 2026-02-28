#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_SCRIPT="$SCRIPT_DIR/install.sh"
UNINSTALL_SCRIPT="$SCRIPT_DIR/uninstall.sh"
VERSION="1.3.0"

USE_COLOR=true
[[ -n "${NO_COLOR:-}" ]] && USE_COLOR=false
[[ ! -t 1 ]] && USE_COLOR=false

color() {
  if $USE_COLOR; then
    case "$1" in
      green) printf '\033[0;32m' ;;
      yellow) printf '\033[0;33m' ;;
      red) printf '\033[0;31m' ;;
      bold) printf '\033[1m' ;;
      reset) printf '\033[0m' ;;
    esac
  fi
}

info() { echo "$(color green)✓$(color reset) $*"; }
warn() { echo "$(color yellow)⚠$(color reset) $*"; }
err() { echo "$(color red)✗$(color reset) $*" >&2; }

usage() {
  cat <<'EOF'
Agentic Skills CLI

Usage:
  bash agentic-skills.sh <command> [options]

Commands:
  install     Install skills/agents/hooks (delegates to install.sh)
  update      Reinstall based on existing manifest(s)
  self-update Fetch latest toolkit and run update
  uninstall   Remove installed files (delegates to uninstall.sh)
  status      Show detected installations
  doctor      Validate installation integrity
  version     Print CLI version
  help        Show this message

Examples:
  bash agentic-skills.sh install --claude --force
  bash agentic-skills.sh update --all
  bash agentic-skills.sh self-update --all --yes
  bash agentic-skills.sh uninstall --path .claude --force
  bash agentic-skills.sh status
  bash agentic-skills.sh doctor
  bash agentic-skills.sh version
EOF
}

json_value() {
  local file="$1"
  local key="$2"
  if command -v jq >/dev/null 2>&1; then
    jq -r --arg key "$key" 'if has($key) then .[$key] else empty end' "$file"
  else
    grep "\"$key\"" "$file" | head -1 | sed 's/.*: *"\{0,1\}\([^",}]*\)"\{0,1\}.*/\1/'
  fi
}

json_array_lines() {
  local file="$1"
  local key="$2"
  if command -v jq >/dev/null 2>&1; then
    jq -r --arg key "$key" '.[$key][]?' "$file"
  else
    grep "\"$key\"" "$file" | head -1 | sed 's/.*\[//;s/\].*//;s/"//g;s/,/\n/g' | sed '/^[[:space:]]*$/d;s/^[[:space:]]*//;s/[[:space:]]*$//'
  fi
}

discover_manifests() {
  local search_path="${1:-}"
  MANIFESTS=()

  _add_manifest_if_present() {
    local p="$1"
    if [[ -f "$p/.agentic-skills.manifest" ]]; then
      MANIFESTS+=("$p/.agentic-skills.manifest")
    fi
  }

  if [[ -n "$search_path" ]]; then
    if [[ -f "$search_path" ]]; then
      MANIFESTS+=("$search_path")
    else
      _add_manifest_if_present "$search_path"
    fi
  else
    _add_manifest_if_present ".claude"
    _add_manifest_if_present "$HOME/.claude"
    _add_manifest_if_present ".opencode"
    _add_manifest_if_present "$HOME/.config/opencode"
    _add_manifest_if_present ".codex"
    _add_manifest_if_present "${CODEX_HOME:-$HOME/.codex}"
    _add_manifest_if_present ".cursor/rules"
    _add_manifest_if_present "."
  fi

  declare -A seen=()
  local -a unique=()
  local m abs
  for m in "${MANIFESTS[@]}"; do
    abs="$(cd "$(dirname "$m")" 2>/dev/null && pwd)/$(basename "$m")"
    if [[ -z "${seen[$abs]:-}" ]]; then
      seen["$abs"]=1
      unique+=("$abs")
    fi
  done
  MANIFESTS=("${unique[@]}")
}

target_to_flag() {
  case "$1" in
    claude-project) echo "--claude" ;;
    claude-global) echo "--claude-global" ;;
    opencode-project) echo "--opencode" ;;
    opencode-global) echo "--opencode-global" ;;
    codex-project) echo "--codex" ;;
    codex-global) echo "--codex-global" ;;
    cursor) echo "--cursor" ;;
    codex) echo "--codex-md" ;;
    *) echo "" ;;
  esac
}

project_workdir_from_manifest() {
  local target="$1"
  local target_path="$2"

  case "$target" in
    claude-project)
      if [[ "$target_path" == */.claude ]]; then
        echo "${target_path%/.claude}"
      else
        echo "$(dirname "$target_path")"
      fi
      ;;
    opencode-project)
      if [[ "$target_path" == */.opencode ]]; then
        echo "${target_path%/.opencode}"
      else
        echo "$(dirname "$target_path")"
      fi
      ;;
    codex-project)
      if [[ "$target_path" == */.codex ]]; then
        echo "${target_path%/.codex}"
      else
        echo "$(dirname "$target_path")"
      fi
      ;;
    codex-global)
      echo "$SCRIPT_DIR"
      ;;
    cursor)
      if [[ "$target_path" == */.cursor/rules ]]; then
        echo "${target_path%/.cursor/rules}"
      else
        echo "$(dirname "$(dirname "$target_path")")"
      fi
      ;;
    codex)
      echo "$target_path"
      ;;
    *)
      echo "$SCRIPT_DIR"
      ;;
  esac
}

select_manifest_if_needed() {
  if [[ ${#MANIFESTS[@]} -eq 0 ]]; then
    return 1
  fi
  if [[ ${#MANIFESTS[@]} -eq 1 ]]; then
    echo "${MANIFESTS[0]}"
    return 0
  fi
  if [[ -t 0 ]]; then
    echo "Multiple installations found:"
    local i
    for i in "${!MANIFESTS[@]}"; do
      printf "  %s. %s\n" "$((i + 1))" "${MANIFESTS[$i]}"
    done
    printf "Select [1]: "
    read -r choice
    choice="${choice:-1}"
    local idx=$((choice - 1))
    if [[ $idx -lt 0 || $idx -ge ${#MANIFESTS[@]} ]]; then
      err "Invalid selection"
      return 1
    fi
    echo "${MANIFESTS[$idx]}"
    return 0
  fi
  echo "${MANIFESTS[0]}"
}

cmd_install() {
  exec bash "$INSTALL_SCRIPT" "$@"
}

cmd_uninstall() {
  exec bash "$UNINSTALL_SCRIPT" "$@"
}

cmd_status() {
  local search_path=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --path)
        search_path="$2"
        shift 2
        ;;
      --no-color)
        USE_COLOR=false
        shift
        ;;
      --help)
        cat <<'EOF'
Usage: bash agentic-skills.sh status [--path <dir-or-manifest>] [--no-color]
EOF
        return 0
        ;;
      *)
        err "Unknown option: $1"
        return 1
        ;;
    esac
  done

  discover_manifests "$search_path"
  if [[ ${#MANIFESTS[@]} -eq 0 ]]; then
    echo "No Agentic Skills installations found."
    return 0
  fi

  echo "Found ${#MANIFESTS[@]} installation(s):"
  local m target target_path version installed_at hooks
  local skill_count agent_count
  for m in "${MANIFESTS[@]}"; do
    target="$(json_value "$m" "target")"
    target_path="$(json_value "$m" "target_path")"
    version="$(json_value "$m" "version")"
    installed_at="$(json_value "$m" "installed_at")"
    hooks="$(json_value "$m" "hooks")"
    skill_count="$(json_array_lines "$m" "skills" | wc -l | tr -d ' ')"
    agent_count="$(json_array_lines "$m" "agents" | wc -l | tr -d ' ')"
    echo ""
    echo "- Manifest: $m"
    echo "  Target: $target"
    echo "  Path: $target_path"
    echo "  Version: $version"
    echo "  Installed at: $installed_at"
    echo "  Components: skills=$skill_count agents=$agent_count hooks=$hooks"
  done
}

cmd_update() {
  local search_path=""
  local update_all=false
  local dry_run=false
  local force=true

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --path)
        search_path="$2"
        shift 2
        ;;
      --all)
        update_all=true
        shift
        ;;
      --dry-run)
        dry_run=true
        shift
        ;;
      --force)
        force=true
        shift
        ;;
      --no-force)
        force=false
        shift
        ;;
      --no-color)
        USE_COLOR=false
        shift
        ;;
      --help)
        cat <<'EOF'
Usage: bash agentic-skills.sh update [options]

Options:
  --path <dir-or-manifest>  Update a specific installation
  --all                     Update all detected installations
  --dry-run                 Preview without writing
  --force                   Overwrite existing files (default)
  --no-force                Do not force overwrite
EOF
        return 0
        ;;
      *)
        err "Unknown option: $1"
        return 1
        ;;
    esac
  done

  discover_manifests "$search_path"
  if [[ ${#MANIFESTS[@]} -eq 0 ]]; then
    err "No Agentic Skills installation found."
    return 1
  fi

  local -a targets=()
  if $update_all; then
    targets=("${MANIFESTS[@]}")
  else
    local selected
    selected="$(select_manifest_if_needed)" || return 1
    targets=("$selected")
  fi

  local m target target_path target_flag hooks
  local workdir
  local skill_count agent_count
  local -a install_args
  for m in "${targets[@]}"; do
    target="$(json_value "$m" "target")"
    target_path="$(json_value "$m" "target_path")"
    hooks="$(json_value "$m" "hooks")"
    skill_count="$(json_array_lines "$m" "skills" | wc -l | tr -d ' ')"
    agent_count="$(json_array_lines "$m" "agents" | wc -l | tr -d ' ')"
    target_flag="$(target_to_flag "$target")"

    if [[ -z "$target_flag" ]]; then
      err "Unknown target in manifest: $target ($m)"
      return 1
    fi

    install_args=("$target_flag")
    if [[ "$skill_count" -eq 0 ]]; then
      install_args+=("--no-skills")
    fi
    if [[ "$agent_count" -eq 0 ]]; then
      install_args+=("--no-agents")
    fi
    if [[ "$hooks" != "true" ]]; then
      install_args+=("--no-hooks")
    fi
    if $dry_run; then
      install_args+=("--dry-run")
    fi
    if $force; then
      install_args+=("--force")
    fi

    workdir="$(project_workdir_from_manifest "$target" "$target_path")"
    if [[ ! -d "$workdir" ]]; then
      err "Working directory not found for $target: $workdir"
      return 1
    fi

    info "Updating $target at $target_path"
    (
      cd "$workdir"
      bash "$INSTALL_SCRIPT" "${install_args[@]}"
    )
  done
}

cmd_self_update() {
  local source=""
  local repo="samnetic/agentic-skills"
  local ref="main"
  local yes=false
  local use_ssh=false
  local -a update_args=()
  local tmp_clone=""

  cleanup_self_update() {
    if [[ -n "$tmp_clone" && -d "$tmp_clone" ]]; then
      rm -rf "$tmp_clone"
    fi
  }

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --source)
        source="$2"
        shift 2
        ;;
      --repo)
        repo="$2"
        shift 2
        ;;
      --ref)
        ref="$2"
        shift 2
        ;;
      --path)
        update_args+=("$1" "$2")
        shift 2
        ;;
      --all|--dry-run|--force|--no-force|--no-color)
        update_args+=("$1")
        shift
        ;;
      --yes)
        yes=true
        shift
        ;;
      --ssh)
        use_ssh=true
        shift
        ;;
      --help)
        cat <<'EOF'
Usage: bash agentic-skills.sh self-update [options]

Fetches a source repo and runs `update` using that source.

Options:
  --source <path-or-git-url>  Use local dir or explicit git URL instead of GitHub default
  --repo <owner/repo>         GitHub repository to clone (default: samnetic/agentic-skills)
  --ref <git-ref>             Git ref/tag/branch (default: main)
  --yes                       Skip confirmation prompt
  --ssh                       Clone GitHub repo over SSH when using --repo

Update passthrough options:
  --path <dir-or-manifest>    Update specific installation
  --all                       Update all detected installations
  --dry-run                   Preview only
  --force                     Force overwrite (default behavior in update)
  --no-force                  Disable force overwrite
  --no-color                  Disable colors
EOF
        return 0
        ;;
      *)
        err "Unknown option: $1"
        return 1
        ;;
    esac
  done

  local source_dir=""
  local source_label=""
  if [[ -n "$source" ]]; then
    if [[ -d "$source" ]]; then
      source_dir="$(cd "$source" && pwd)"
      source_label="$source_dir"
    else
      tmp_clone="$(mktemp -d)"
      if ! git clone --depth 1 --branch "$ref" "$source" "$tmp_clone" >/dev/null 2>&1; then
        err "Failed to clone source: $source (ref: $ref)"
        cleanup_self_update
        return 1
      fi
      source_dir="$tmp_clone"
      source_label="$source@$ref"
    fi
  else
    local repo_url="https://github.com/$repo.git"
    if $use_ssh; then
      repo_url="git@github.com:$repo.git"
    fi
    tmp_clone="$(mktemp -d)"
    if ! git clone --depth 1 --branch "$ref" "$repo_url" "$tmp_clone" >/dev/null 2>&1; then
      err "Failed to clone repository: $repo_url (ref: $ref)"
      err "Hint: use --source <local-path> for offline/local updates."
      cleanup_self_update
      return 1
    fi
    source_dir="$tmp_clone"
    source_label="$repo@$ref"
  fi

  if [[ ! -f "$source_dir/agentic-skills.sh" || ! -f "$source_dir/install.sh" ]]; then
    err "Invalid source: missing agentic-skills.sh/install.sh in $source_dir"
    cleanup_self_update
    return 1
  fi

  if ! $yes && [[ -t 0 ]]; then
    echo "Source: $source_label"
    printf "Proceed with self-update? [Y/n]: "
    read -r confirm
    confirm="${confirm:-Y}"
    if [[ "$confirm" =~ ^[Nn]$ ]]; then
      echo "Aborted."
      cleanup_self_update
      return 0
    fi
  fi

  info "Running update from source: $source_label"
  bash "$source_dir/agentic-skills.sh" update "${update_args[@]}"
  cleanup_self_update
}

cmd_doctor() {
  local search_path=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --path)
        search_path="$2"
        shift 2
        ;;
      --no-color)
        USE_COLOR=false
        shift
        ;;
      --help)
        cat <<'EOF'
Usage: bash agentic-skills.sh doctor [--path <dir-or-manifest>] [--no-color]
EOF
        return 0
        ;;
      *)
        err "Unknown option: $1"
        return 1
        ;;
    esac
  done

  discover_manifests "$search_path"
  if [[ ${#MANIFESTS[@]} -eq 0 ]]; then
    warn "No Agentic Skills installations found."
    return 0
  fi

  local fail_count=0
  local pass_count=0
  local m target hooks manifest_dir codex_root
  local skill agent hs pf
  local -a skills agents hook_scripts plugin_files

  for m in "${MANIFESTS[@]}"; do
    target="$(json_value "$m" "target")"
    hooks="$(json_value "$m" "hooks")"
    manifest_dir="$(dirname "$m")"
    codex_root="$(json_value "$m" "target_path")"

    mapfile -t skills < <(json_array_lines "$m" "skills")
    mapfile -t agents < <(json_array_lines "$m" "agents")
    mapfile -t hook_scripts < <(json_array_lines "$m" "hook_scripts")
    mapfile -t plugin_files < <(json_array_lines "$m" "plugin_files")

    echo ""
    echo "Doctor: $m ($target)"

    case "$target" in
      claude-project|claude-global|opencode-project|opencode-global|codex-project|codex-global)
        for skill in "${skills[@]}"; do
          if [[ -f "$manifest_dir/skills/$skill/SKILL.md" ]]; then
            pass_count=$((pass_count + 1))
          else
            err "Missing skill file: $manifest_dir/skills/$skill/SKILL.md"
            fail_count=$((fail_count + 1))
          fi
        done
        for agent in "${agents[@]}"; do
          if [[ -f "$manifest_dir/agents/$agent" ]]; then
            pass_count=$((pass_count + 1))
          else
            err "Missing agent file: $manifest_dir/agents/$agent"
            fail_count=$((fail_count + 1))
          fi
        done
        ;;
      cursor)
        for skill in "${skills[@]}"; do
          if [[ -f "$manifest_dir/$skill.md" ]]; then
            pass_count=$((pass_count + 1))
          else
            err "Missing skill file: $manifest_dir/$skill.md"
            fail_count=$((fail_count + 1))
          fi
        done
        for agent in "${agents[@]}"; do
          if [[ -f "$manifest_dir/$agent" ]]; then
            pass_count=$((pass_count + 1))
          else
            err "Missing agent file: $manifest_dir/$agent"
            fail_count=$((fail_count + 1))
          fi
        done
        ;;
      codex)
        if [[ -f "$codex_root/codex.md" ]]; then
          pass_count=$((pass_count + 1))
        else
          err "Missing codex.md in: $codex_root"
          fail_count=$((fail_count + 1))
        fi
        ;;
      *)
        err "Unknown target in manifest: $target"
        fail_count=$((fail_count + 1))
        ;;
    esac

    if [[ "$hooks" == "true" ]]; then
      if [[ "$target" == claude-* ]]; then
        for hs in "${hook_scripts[@]}"; do
          if [[ -f "$manifest_dir/hooks/$hs" ]]; then
            pass_count=$((pass_count + 1))
          else
            err "Missing hook script: $manifest_dir/hooks/$hs"
            fail_count=$((fail_count + 1))
          fi
        done
      elif [[ "$target" == opencode-* ]]; then
        for pf in "${plugin_files[@]}"; do
          if [[ -f "$manifest_dir/plugins/$pf" ]]; then
            pass_count=$((pass_count + 1))
          else
            err "Missing plugin file: $manifest_dir/plugins/$pf"
            fail_count=$((fail_count + 1))
          fi
        done
      fi
    fi
  done

  echo ""
  echo "Doctor summary: pass=$pass_count fail=$fail_count"
  [[ $fail_count -eq 0 ]]
}

main() {
  local cmd="${1:-help}"
  if [[ "$cmd" == "--version" || "$cmd" == "-v" ]]; then
    cmd="version"
  fi
  shift || true

  case "$cmd" in
    install) cmd_install "$@" ;;
    update) cmd_update "$@" ;;
    self-update) cmd_self_update "$@" ;;
    uninstall) cmd_uninstall "$@" ;;
    status) cmd_status "$@" ;;
    doctor) cmd_doctor "$@" ;;
    version) echo "$VERSION" ;;
    help|-h|--help) usage ;;
    *)
      err "Unknown command: $cmd"
      echo ""
      usage
      return 1
      ;;
  esac
}

main "$@"
