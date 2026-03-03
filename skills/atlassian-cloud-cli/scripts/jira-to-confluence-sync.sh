#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  jira-to-confluence-sync.sh --jql "<JQL>" [options]

Generate a markdown report from Jira work items via `acli` and optionally
publish it to Confluence via `confluence-cli`.

Options:
  --jql <query>            Required. Bounded JQL query.
  --limit <n>              Max work items to fetch (default: 20).
  --output-file <path>     Output markdown file path.
  --page-id <id>           Existing Confluence page ID to update.
  --space-key <key>        Space key for page creation (with --title).
  --title <text>           New page title for create mode.
  --apply                  Publish to Confluence. Default is dry-run only.
  -h, --help               Show this help text.

Behavior:
  - Dry-run by default: only generates markdown file.
  - With --apply:
    - If --page-id is set: updates that page.
    - Else creates a page using --space-key and --title.

Examples:
  jira-to-confluence-sync.sh \
    --jql "project = APPSMBO ORDER BY updated DESC" \
    --limit 25

  jira-to-confluence-sync.sh \
    --jql "project = APPSMBO AND statusCategory != Done ORDER BY updated DESC" \
    --page-id 123456789 \
    --apply
EOF
}

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 2
  fi
}

JQL=""
LIMIT=20
OUTPUT_FILE=""
PAGE_ID=""
SPACE_KEY=""
TITLE=""
APPLY=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --jql)
      JQL="${2:-}"
      shift 2
      ;;
    --limit)
      LIMIT="${2:-}"
      shift 2
      ;;
    --output-file)
      OUTPUT_FILE="${2:-}"
      shift 2
      ;;
    --page-id)
      PAGE_ID="${2:-}"
      shift 2
      ;;
    --space-key)
      SPACE_KEY="${2:-}"
      shift 2
      ;;
    --title)
      TITLE="${2:-}"
      shift 2
      ;;
    --apply)
      APPLY=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [[ -z "$JQL" ]]; then
  echo "--jql is required." >&2
  usage >&2
  exit 2
fi

if ! [[ "$LIMIT" =~ ^[0-9]+$ ]] || [[ "$LIMIT" -le 0 ]]; then
  echo "--limit must be a positive integer." >&2
  exit 2
fi

if [[ "$APPLY" -eq 1 ]]; then
  if [[ -z "$PAGE_ID" ]] && { [[ -z "$SPACE_KEY" ]] || [[ -z "$TITLE" ]]; }; then
    echo "With --apply, provide --page-id OR both --space-key and --title." >&2
    exit 2
  fi
fi

require_cmd acli
require_cmd confluence-cli
require_cmd jq

if [[ -z "$OUTPUT_FILE" ]]; then
  OUTPUT_FILE="./jira-sync-$(date -u +%Y%m%dT%H%M%SZ).md"
fi

echo "Fetching Jira work items..."
RAW_JSON="$(acli jira workitem search \
  --jql "$JQL" \
  --limit "$LIMIT" \
  --fields "key,summary,status,assignee,priority" \
  --json)"

COUNT="$(echo "$RAW_JSON" | jq 'length')"
GENERATED_AT="$(date -u +"%Y-%m-%d %H:%M:%SZ")"

{
  echo "# Jira Sync Report"
  echo
  echo "- Generated at (UTC): $GENERATED_AT"
  echo "- JQL: \`$JQL\`"
  echo "- Limit: $LIMIT"
  echo "- Result count: $COUNT"
  echo
  echo "| Key | Summary | Status | Assignee | Priority |"
  echo "| --- | --- | --- | --- | --- |"
  echo "$RAW_JSON" | jq -r '
    def clean:
      if . == null then "-" else tostring end
      | gsub("\n"; " ")
      | gsub("\\|"; "\\\\|");
    .[] |
    [
      .key,
      (.fields.summary | clean),
      (.fields.status.name | clean),
      (.fields.assignee.displayName | clean),
      (.fields.priority.name | clean)
    ] |
    "| " + (.[0] // "-") + " | " + .[1] + " | " + .[2] + " | " + .[3] + " | " + .[4] + " |"
  '
} > "$OUTPUT_FILE"

echo "Report written: $OUTPUT_FILE"

if [[ "$APPLY" -ne 1 ]]; then
  echo "Dry-run mode: no Confluence changes made."
  exit 0
fi

echo "Publishing to Confluence..."
PUBLISH_OUTPUT=""
TARGET_PAGE_ID="$PAGE_ID"

if [[ -n "$PAGE_ID" ]]; then
  PUBLISH_OUTPUT="$(confluence-cli update "$PAGE_ID" --file "$OUTPUT_FILE" --format markdown)"
else
  PUBLISH_OUTPUT="$(confluence-cli create "$TITLE" "$SPACE_KEY" --file "$OUTPUT_FILE" --format markdown)"
fi

echo "$PUBLISH_OUTPUT"

if [[ -z "$TARGET_PAGE_ID" ]]; then
  TARGET_PAGE_ID="$(echo "$PUBLISH_OUTPUT" | sed -n 's/.*(ID: \([0-9]\+\)).*/\1/p' | head -n1)"
fi

if [[ -n "$TARGET_PAGE_ID" ]]; then
  echo
  echo "Verification:"
  confluence-cli info "$TARGET_PAGE_ID"
else
  echo
  echo "Warning: could not resolve target page ID from publish output." >&2
fi
