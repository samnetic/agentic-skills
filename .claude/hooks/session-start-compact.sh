#!/usr/bin/env bash
set -euo pipefail

# ── SessionStart (compact) Hook ──────────────────────────────────────────────
# Re-inject skill/agent awareness after context compaction.
# Input (stdin): JSON with session_id, source
# Output (stdout): JSON with hookSpecificOutput.hookEventName + additionalContext
# ──────────────────────────────────────────────────────────────────────────────

INPUT="$(cat)"

project_dir="${CLAUDE_PROJECT_DIR:-.}"
context_parts=("CRITICAL CONTEXT TO PRESERVE AFTER COMPACTION:")

# Count and list skills
skills_dir="$project_dir/.claude/skills"
if [[ -d "$skills_dir" ]]; then
  skill_names=()
  while IFS= read -r d; do
    [[ -d "$d" ]] && skill_names+=("$(basename "$d")")
  done < <(find "$skills_dir" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort)
  skill_count=${#skill_names[@]}
  if [[ $skill_count -gt 0 ]]; then
    skill_list="$(IFS=', '; echo "${skill_names[*]}")"
    context_parts+=("Skills ($skill_count): $skill_list")
  fi
else
  context_parts+=("Skills: none found in $skills_dir")
fi

# Count and list agents
agents_dir="$project_dir/.claude/agents"
if [[ -d "$agents_dir" ]]; then
  agent_names=()
  while IFS= read -r f; do
    name="$(basename "$f" .md)"
    agent_names+=("$name")
  done < <(find "$agents_dir" -maxdepth 1 -name '*.md' -type f 2>/dev/null | sort)
  agent_count=${#agent_names[@]}
  if [[ $agent_count -gt 0 ]]; then
    agent_list="$(IFS=', '; echo "${agent_names[*]}")"
    context_parts+=("Agents ($agent_count): $agent_list")
  fi
else
  context_parts+=("Agents: none found in $agents_dir")
fi

context_parts+=("Always use relevant skills for the task at hand.")

# Join context parts
IFS=$'\n'
context="${context_parts[*]}"

# Escape for JSON
context="${context//\\/\\\\}"
context="${context//\"/\\\"}"
context="${context//$'\n'/\\n}"
context="${context//$'\t'/\\t}"

printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"%s"}}' "$context"
exit 0
