#!/usr/bin/env bash
set -euo pipefail

# ── PostToolUse Hook (Write|Edit matcher) ────────────────────────────────────
# Run shellcheck (for .sh) or ruff (for .py) after file writes.
# Non-blocking — warnings via additionalContext only.
# Input (stdin): JSON with tool_name, tool_input.file_path
# Output (stdout): JSON with hookSpecificOutput.additionalContext (if warnings)
# Exit 0 always
# ──────────────────────────────────────────────────────────────────────────────

INPUT="$(cat)"

# Extract file_path from tool_input
file_path=""
if command -v jq &>/dev/null; then
  file_path="$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null || true)"
else
  file_path="$(echo "$INPUT" | grep -o '"file_path" *: *"[^"]*"' | head -1 | sed 's/.*: *"//;s/"$//' || true)"
fi

if [[ -z "$file_path" || ! -f "$file_path" ]]; then
  exit 0
fi

warnings=""

case "$file_path" in
  *.sh|*.bash)
    if command -v shellcheck &>/dev/null; then
      lint_output="$(shellcheck -f gcc "$file_path" 2>&1 || true)"
      if [[ -n "$lint_output" ]]; then
        warnings="ShellCheck warnings for $file_path:\n$lint_output"
      fi
    fi
    ;;
  *.py)
    if command -v uvx &>/dev/null; then
      lint_output="$(uvx ruff check "$file_path" 2>&1 || true)"
      if [[ -n "$lint_output" && ! "$lint_output" =~ "All checks passed" ]]; then
        warnings="Ruff warnings for $file_path:\n$lint_output"
      fi
    elif command -v ruff &>/dev/null; then
      lint_output="$(ruff check "$file_path" 2>&1 || true)"
      if [[ -n "$lint_output" && ! "$lint_output" =~ "All checks passed" ]]; then
        warnings="Ruff warnings for $file_path:\n$lint_output"
      fi
    fi
    ;;
esac

if [[ -n "$warnings" ]]; then
  # Escape for JSON
  warnings="${warnings//\\/\\\\}"
  warnings="${warnings//\"/\\\"}"
  warnings="${warnings//$'\n'/\\n}"
  warnings="${warnings//$'\t'/\\t}"
  printf '{"hookSpecificOutput":{"additionalContext":"%s"}}' "$warnings"
fi

exit 0
