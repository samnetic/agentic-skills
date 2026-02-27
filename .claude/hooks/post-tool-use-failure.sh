#!/usr/bin/env bash
set -euo pipefail

# ── PostToolUseFailure Hook ──────────────────────────────────────────────────
# Log tool failures with timestamps for debugging.
# Input (stdin): JSON with tool_name, tool_use_id, error, session_id
# Exit 0 always
# ──────────────────────────────────────────────────────────────────────────────

INPUT="$(cat)"

log_dir="${CLAUDE_PROJECT_DIR:-.}/.claude/hooks/logs"
mkdir -p "$log_dir"
log_file="$log_dir/tool_failures.jsonl"

timestamp="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"

# Use jq for safe JSON parsing when available, otherwise log raw input
if command -v jq &>/dev/null; then
  # Safe extraction via jq — no shell injection possible
  tool_name="$(echo "$INPUT" | jq -r '.tool_name // "unknown"')"
  tool_use_id="$(echo "$INPUT" | jq -r '.tool_use_id // "unknown"')"
  error_msg="$(echo "$INPUT" | jq -r '.error // "unknown"')"
  session_id="$(echo "$INPUT" | jq -r '.session_id // "unknown"')"

  # Build JSON safely with jq
  jq -n -c \
    --arg ts "$timestamp" \
    --arg tn "$tool_name" \
    --arg ti "$tool_use_id" \
    --arg err "$error_msg" \
    --arg sid "$session_id" \
    '{timestamp: $ts, tool_name: $tn, tool_use_id: $ti, error: $err, session_id: $sid}' >> "$log_file"
else
  # Fallback: log the raw input with a timestamp prefix
  printf '{"timestamp":"%s","raw_input":%s}\n' "$timestamp" "$INPUT" >> "$log_file"
fi

exit 0
