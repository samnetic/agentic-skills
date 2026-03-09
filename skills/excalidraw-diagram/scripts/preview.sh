#!/usr/bin/env bash
# Launch the interactive Excalidraw editor with live bidirectional file sync.
#
# Usage:
#   bash scripts/preview.sh <file.excalidraw> [--open] [--port 8091]
#
# Starts two processes:
#   1. API backend (port+1) — serves/watches the .excalidraw file, accepts saves
#   2. Vite dev server (port) — full interactive Excalidraw React editor
#
# The AI agent edits the file on disk → browser auto-updates within 1s.
# You edit in the browser → file on disk auto-saves within 2s.
#
# All dependencies are installed automatically on first run.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PREVIEW_APP="$SCRIPT_DIR/preview-app"

# Parse arguments
FILE=""
OPEN_FLAG=""
PORT=8091

for arg in "$@"; do
  case "$arg" in
    --open) OPEN_FLAG="--open" ;;
    --port) shift; PORT="${1:-8091}" ;;
    --port=*) PORT="${arg#*=}" ;;
    -*) ;; # ignore unknown flags
    *) [[ -z "$FILE" ]] && FILE="$arg" ;;
  esac
done

if [[ -z "$FILE" ]]; then
  echo "Usage: bash preview.sh <file.excalidraw> [--open] [--port 8091]"
  echo ""
  echo "  --open    Open browser automatically"
  echo "  --port N  Vite port (default 8091, API runs on N+1)"
  exit 1
fi

# Resolve to absolute path
[[ "$FILE" != /* ]] && FILE="$(pwd)/$FILE"

if [[ ! -f "$FILE" ]]; then
  echo "Error: File not found: $FILE" >&2
  exit 1
fi

API_PORT=$((PORT + 1))

# --- Auto-install dependencies ---

# 1. Preview app (React + Vite + Excalidraw)
if [[ ! -d "$PREVIEW_APP/node_modules" ]]; then
  echo "Installing Excalidraw editor dependencies (first run)..."
  (cd "$PREVIEW_APP" && npm install --silent 2>&1)
  echo "Done."
fi

# 2. Scripts npm deps (mermaid converter — shared node_modules)
if [[ ! -d "$SCRIPT_DIR/node_modules" ]]; then
  echo "Installing script dependencies..."
  (cd "$SCRIPT_DIR" && npm install --silent 2>&1)
  echo "Done."
fi

# --- Cleanup on exit ---
cleanup() {
  echo ""
  echo "Shutting down..."
  kill "$API_PID" "$VITE_PID" 2>/dev/null || true
  wait "$API_PID" "$VITE_PID" 2>/dev/null || true
}
trap cleanup EXIT INT TERM

# --- Start servers ---

# API backend
node "$SCRIPT_DIR/preview_server.mjs" "$FILE" --port "$API_PORT" --vite-port "$PORT" $OPEN_FLAG &
API_PID=$!

# Vite dev server
(cd "$PREVIEW_APP" && npx vite --port "$PORT" 2>&1) &
VITE_PID=$!

echo ""
echo "  Excalidraw Editor: http://localhost:$PORT"
echo "  Watching: $FILE"
echo ""
echo "  - You edit in browser → saves to disk (~2s)"
echo "  - AI agent edits file → browser updates (~1s)"
echo ""
echo "  Press Ctrl+C to stop."
echo ""

wait
