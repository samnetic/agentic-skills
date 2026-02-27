#!/usr/bin/env bash
set -euo pipefail

# ── SessionStart Hook ────────────────────────────────────────────────────────
# Inject git status and context files at session start.
# Input (stdin): JSON with session_id, source ("startup"|"resume"|"clear")
# Output (stdout): JSON with hookSpecificOutput.additionalContext
# ──────────────────────────────────────────────────────────────────────────────

INPUT="$(cat)"

context_parts=()

# Current date
context_parts+=("Date: $(date '+%Y-%m-%d')")

# Git info (if in a git repo)
if git rev-parse --is-inside-work-tree &>/dev/null; then
  branch="$(git branch --show-current 2>/dev/null || echo "detached")"
  uncommitted="$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')"
  context_parts+=("Git: branch=$branch, uncommitted_files=$uncommitted")
fi

# Include CONTEXT.md if present
project_dir="${CLAUDE_PROJECT_DIR:-.}"
if [[ -f "$project_dir/.claude/CONTEXT.md" ]]; then
  content="$(head -c 500 "$project_dir/.claude/CONTEXT.md")"
  context_parts+=("CONTEXT.md: $content")
fi

# Include TODO.md if present
if [[ -f "$project_dir/.claude/TODO.md" ]]; then
  content="$(head -c 500 "$project_dir/.claude/TODO.md")"
  context_parts+=("TODO.md: $content")
fi

# Join context parts
IFS=$'\n'
context="${context_parts[*]}"

# Escape for JSON: backslashes, quotes, newlines, tabs
context="${context//\\/\\\\}"
context="${context//\"/\\\"}"
context="${context//$'\n'/\\n}"
context="${context//$'\t'/\\t}"

printf '{"hookSpecificOutput":{"additionalContext":"%s"}}' "$context"
exit 0
