#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

python3 "$ROOT_DIR/scripts/sync-github-skill.py" \
  --repo vercel-labs/agent-browser \
  --path skills/agent-browser \
  --ref main \
  --dest "$ROOT_DIR/skills/agent-browser/references/upstream"

python3 "$ROOT_DIR/scripts/check-skill-quality.py" \
  "$ROOT_DIR/skills/agent-browser" \
  --profile internal \
  --strict-frontmatter \
  --fail-on-warn \
  --verbose

