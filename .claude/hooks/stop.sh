#!/usr/bin/env bash
set -euo pipefail

# ── Stop Hook ────────────────────────────────────────────────────────────────
# Backup transcript on session stop. Guard against infinite loops.
# Input (stdin): JSON with session_id, transcript_path, stop_hook_active
# Exit 0 always (no decision control on Stop)
# ──────────────────────────────────────────────────────────────────────────────

INPUT="$(cat)"

# Parse stop_hook_active — if true, exit immediately to prevent infinite loop
stop_active="$(echo "$INPUT" | grep -o '"stop_hook_active" *: *true' || true)"
if [[ -n "$stop_active" ]]; then
  exit 0
fi

# Parse transcript_path
transcript_path=""
if command -v jq &>/dev/null; then
  transcript_path="$(echo "$INPUT" | jq -r '.transcript_path // empty' 2>/dev/null || true)"
else
  transcript_path="$(echo "$INPUT" | grep -o '"transcript_path" *: *"[^"]*"' | sed 's/.*: *"//;s/"$//' || true)"
fi

# Parse session_id for backup filename
session_id=""
if command -v jq &>/dev/null; then
  session_id="$(echo "$INPUT" | jq -r '.session_id // "unknown"' 2>/dev/null || echo "unknown")"
else
  session_id="$(echo "$INPUT" | grep -o '"session_id" *: *"[^"]*"' | sed 's/.*: *"//;s/"$//' || echo "unknown")"
fi

# Backup transcript if it exists
if [[ -n "$transcript_path" && -f "$transcript_path" ]]; then
  backup_dir="${CLAUDE_PROJECT_DIR:-.}/.claude/hooks/backups"
  mkdir -p "$backup_dir"
  timestamp="$(date -u '+%Y%m%d_%H%M%S')"
  # Use last 8 chars of session_id for brevity
  short_id="${session_id: -8}"
  cp "$transcript_path" "$backup_dir/${short_id}_${timestamp}.jsonl"
fi

exit 0
