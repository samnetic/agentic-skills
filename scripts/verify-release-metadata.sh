#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TAG="${1:-}"

if [[ -z "$TAG" ]]; then
  echo "Usage: $0 <tag>" >&2
  exit 1
fi

VERSION="${TAG#v}"

pkg_version="$(node -p "require('$ROOT_DIR/package.json').version")"
install_version="$(awk -F'"' '/^VERSION=/{print $2; exit}' "$ROOT_DIR/install.sh")"
cli_version="$(awk -F'"' '/^VERSION=/{print $2; exit}' "$ROOT_DIR/agentic-skills.sh")"

if [[ "$VERSION" != "$pkg_version" ]]; then
  echo "Tag/package mismatch: tag=$VERSION package.json=$pkg_version" >&2
  exit 1
fi

if [[ "$VERSION" != "$install_version" ]]; then
  echo "Tag/install mismatch: tag=$VERSION install.sh=$install_version" >&2
  exit 1
fi

if [[ "$VERSION" != "$cli_version" ]]; then
  echo "Tag/cli mismatch: tag=$VERSION agentic-skills.sh=$cli_version" >&2
  exit 1
fi

if ! rg -n "^## \\[$VERSION\\]" "$ROOT_DIR/CHANGELOG.md" >/dev/null 2>&1; then
  echo "Changelog missing entry for version $VERSION" >&2
  exit 1
fi

echo "Release metadata verified for $TAG"
