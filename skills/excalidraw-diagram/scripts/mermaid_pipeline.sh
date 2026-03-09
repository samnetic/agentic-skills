#!/usr/bin/env bash
set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_NAME="$(basename "$0")"

usage() {
  cat <<EOF
Usage: $SCRIPT_NAME [options] <input.mmd|input.md>

Run Mermaid -> Excalidraw conversion, lint, and optional PNG render.

Options:
  -o, --output <file>        Output .excalidraw file path
  -p, --png <file>           Output PNG file path (default: output basename + .png)
      --strict-lint          Fail if linter emits warnings
      --force-convert        Forward --force-convert to mermaid_to_excalidraw.mjs
      --no-convert           Forward --no-convert to mermaid_to_excalidraw.mjs
      --no-render            Skip PNG rendering step
  -h, --help                 Show this help
EOF
}

die() {
  echo "ERROR: $*" >&2
  exit 1
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "missing required command: $1"
}

abspath() {
  local input_path="$1"
  if [[ "$input_path" = /* ]]; then
    printf '%s\n' "$input_path"
    return
  fi
  printf '%s/%s\n' "$(pwd)" "$input_path"
}

default_excal_output() {
  local input_path="$1"
  local input_abs
  input_abs="$(abspath "$input_path")"
  local dir base stem
  dir="$(dirname "$input_abs")"
  base="$(basename "$input_abs")"
  stem="${base%.*}"
  printf '%s/%s.excalidraw\n' "$dir" "$stem"
}

STRICT_LINT=false
NO_RENDER=false
CONVERT_FLAG=""
OUTPUT_EXCAL=""
OUTPUT_PNG=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -o|--output)
      [[ $# -ge 2 ]] || die "--output requires a value"
      OUTPUT_EXCAL="$2"
      shift 2
      ;;
    -p|--png)
      [[ $# -ge 2 ]] || die "--png requires a value"
      OUTPUT_PNG="$2"
      shift 2
      ;;
    --strict-lint)
      STRICT_LINT=true
      shift
      ;;
    --force-convert)
      CONVERT_FLAG="--force-convert"
      shift
      ;;
    --no-convert)
      CONVERT_FLAG="--no-convert"
      shift
      ;;
    --no-render)
      NO_RENDER=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --)
      shift
      break
      ;;
    -*)
      die "unknown option: $1"
      ;;
    *)
      break
      ;;
  esac
done

[[ $# -ge 1 ]] || {
  usage
  die "input file is required"
}

INPUT_FILE="$1"
[[ -f "$INPUT_FILE" ]] || die "input file not found: $INPUT_FILE"

require_cmd node
require_cmd python3

if [[ -z "$OUTPUT_EXCAL" ]]; then
  OUTPUT_EXCAL="$(default_excal_output "$INPUT_FILE")"
else
  OUTPUT_EXCAL="$(abspath "$OUTPUT_EXCAL")"
fi

if [[ -z "$OUTPUT_PNG" ]]; then
  OUTPUT_PNG="${OUTPUT_EXCAL%.excalidraw}.png"
else
  OUTPUT_PNG="$(abspath "$OUTPUT_PNG")"
fi

mkdir -p "$(dirname "$OUTPUT_EXCAL")"

echo "==> Converting Mermaid to Excalidraw"
if [[ -n "$CONVERT_FLAG" ]]; then
  node "$SCRIPT_DIR/mermaid_to_excalidraw.mjs" "$INPUT_FILE" --output "$OUTPUT_EXCAL" "$CONVERT_FLAG"
else
  node "$SCRIPT_DIR/mermaid_to_excalidraw.mjs" "$INPUT_FILE" --output "$OUTPUT_EXCAL"
fi

echo "==> Linting Excalidraw JSON"
if [[ "$STRICT_LINT" == "true" ]]; then
  python3 "$SCRIPT_DIR/lint_excalidraw.py" "$OUTPUT_EXCAL" --strict
else
  python3 "$SCRIPT_DIR/lint_excalidraw.py" "$OUTPUT_EXCAL"
fi

if [[ "$NO_RENDER" == "true" ]]; then
  echo "==> Skipping render (--no-render)"
  echo "EXCALIDRAW: $OUTPUT_EXCAL"
  exit 0
fi

echo "==> Rendering PNG"
if command -v uv >/dev/null 2>&1; then
  uv run python "$SCRIPT_DIR/render_excalidraw.py" "$OUTPUT_EXCAL" --output "$OUTPUT_PNG"
else
  python3 "$SCRIPT_DIR/render_excalidraw.py" "$OUTPUT_EXCAL" --output "$OUTPUT_PNG"
fi

echo "EXCALIDRAW: $OUTPUT_EXCAL"
echo "PNG: $OUTPUT_PNG"

