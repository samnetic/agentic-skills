#!/usr/bin/env bash
set -euo pipefail

# ── PreCompact Hook ──────────────────────────────────────────────────────────
# Backup transcript before context compaction. Side-effect only.
# Input (stdin): JSON with session_id, transcript_path, trigger ("manual"|"auto")
# Exit 0 always (PreCompact has no decision control)
# ──────────────────────────────────────────────────────────────────────────────

INPUT="$(cat)"

# Parse transcript_path
transcript_path=""
if command -v jq &>/dev/null; then
  transcript_path="$(echo "$INPUT" | jq -r '.transcript_path // empty' 2>/dev/null || true)"
else
  transcript_path="$(echo "$INPUT" | grep -o '"transcript_path" *: *"[^"]*"' | sed 's/.*: *"//;s/"$//' || true)"
fi

# Parse trigger
trigger=""
if command -v jq &>/dev/null; then
  trigger="$(echo "$INPUT" | jq -r '.trigger // "unknown"' 2>/dev/null || echo "unknown")"
else
  trigger="$(echo "$INPUT" | grep -o '"trigger" *: *"[^"]*"' | sed 's/.*: *"//;s/"$//' || echo "unknown")"
fi

# Backup transcript if it exists
if [[ -n "$transcript_path" && -f "$transcript_path" ]]; then
  backup_dir="${CLAUDE_PROJECT_DIR:-.}/.claude/hooks/backups"
  mkdir -p "$backup_dir"
  timestamp="$(date -u '+%Y%m%d_%H%M%S')"
  cp "$transcript_path" "$backup_dir/pre_compact_${trigger}_${timestamp}.jsonl"
fi

exit 0
