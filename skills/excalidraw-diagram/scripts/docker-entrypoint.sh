#!/usr/bin/env bash
set -euo pipefail

FILE="${1:-/data/diagram.excalidraw}"
PORT="${PORT:-8091}"
API_PORT="${API_PORT:-8092}"

if [[ ! -f "$FILE" ]]; then
  echo "No .excalidraw file found at $FILE"
  echo "Mount one with: docker run -v /path/to/diagram.excalidraw:/data/diagram.excalidraw ..."
  echo ""
  echo "Creating empty diagram..."
  cat > "$FILE" <<'EMPTY'
{
  "type": "excalidraw",
  "version": 2,
  "source": "https://excalidraw.com",
  "elements": [],
  "appState": { "viewBackgroundColor": "#ffffff" },
  "files": {}
}
EMPTY
fi

cleanup() {
  kill "$API_PID" "$VITE_PID" 2>/dev/null || true
  wait "$API_PID" "$VITE_PID" 2>/dev/null || true
}
trap cleanup EXIT INT TERM

# Start API backend
node /app/preview_server.mjs "$FILE" --port "$API_PORT" --vite-port "$PORT" &
API_PID=$!

# Start Vite dev server (--host exposes outside container)
cd /app/preview-app && npx vite --port "$PORT" --host 0.0.0.0 &
VITE_PID=$!

echo ""
echo "  Excalidraw Editor: http://localhost:$PORT"
echo "  Watching: $FILE"
echo ""

wait
