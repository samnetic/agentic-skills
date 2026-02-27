#!/usr/bin/env bash
set -euo pipefail

# ── PreToolUse Hook (Bash matcher) ───────────────────────────────────────────
# Block dangerous rm -rf commands and .env file access.
# Input (stdin): JSON with tool_name, tool_input.command
# Exit 0 = allow, Exit 2 = block
# ──────────────────────────────────────────────────────────────────────────────

INPUT="$(cat)"

# Extract command from tool_input
command_str=""
if command -v jq &>/dev/null; then
  command_str="$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null || true)"
else
  # Fallback: extract command value (handles multiline poorly but covers simple cases)
  command_str="$(echo "$INPUT" | grep -o '"command" *: *"[^"]*"' | head -1 | sed 's/.*: *"//;s/"$//' || true)"
fi

if [[ -z "$command_str" ]]; then
  exit 0
fi

# ── Check for dangerous rm -rf patterns ──────────────────────────────────────

# Normalize: collapse whitespace, strip leading whitespace
normalized="$(echo "$command_str" | tr -s ' ')"

# Block: rm -rf /, rm -rf /*, rm -rf ~, rm -rf ~/, rm -rf ., rm -rf ./, rm -rf *
# Also catches: rm -rf --no-preserve-root /
if echo "$normalized" | grep -qE 'rm\s+(-[a-zA-Z]*r[a-zA-Z]*f|--recursive\s+--force|-[a-zA-Z]*f[a-zA-Z]*r)[a-zA-Z]*\s+(\/\s*$|\/\*|~\/?(\s|$)|\.\/?(\s|$)|\*(\s|$))'; then
  echo "BLOCKED: Dangerous rm -rf pattern detected: $command_str" >&2
  exit 2
fi

# Also catch standalone rm -rf / even with flags in between
if echo "$normalized" | grep -qE 'rm\s+.*--no-preserve-root'; then
  echo "BLOCKED: --no-preserve-root is not allowed" >&2
  exit 2
fi

# ── Check for .env file access ───────────────────────────────────────────────

# Allow .env.example, .env.sample, .env.template, .env.test
# Block: cat .env, source .env, less .env, etc.
if echo "$normalized" | grep -qE '(cat|less|more|head|tail|source|\.)\s+[^\s]*\.env(\s|$)'; then
  # Check it's not an allowed variant
  if ! echo "$normalized" | grep -qE '\.(env\.example|env\.sample|env\.template|env\.test|env\.development\.local|env\.local\.example)'; then
    echo "BLOCKED: Direct .env file access detected. Use environment variables instead." >&2
    exit 2
  fi
fi

exit 0
