#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "Running installer smoke tests..."
bash "$ROOT_DIR/tests/smoke-installer.sh"

echo ""
echo "Running manager smoke tests..."
bash "$ROOT_DIR/tests/smoke-manager.sh"

echo ""
echo "Running CLI smoke tests..."
bash "$ROOT_DIR/tests/smoke-clis.sh"

echo ""
echo "All tests passed."
