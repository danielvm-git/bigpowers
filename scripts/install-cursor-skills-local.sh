#!/usr/bin/env bash
# story: e78
# DEPRECATED wrapper — project-local Cursor rules symlink (not .cursor/skills copies).
# Usage: ./scripts/install-cursor-skills-local.sh [INSTALL_ROOT]
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
INSTALL_ROOT="$(cd "${1:-$PWD}" && pwd)"
export TARGET_DIR="${TARGET_DIR:-$INSTALL_ROOT/.cursor/rules}"
export SOURCE_DIR="${SOURCE_DIR:-$REPO_ROOT/.cursor/rules}"

echo "NOTE: install-cursor-skills-local.sh is deprecated; prefer bigpowers setup (local) or:" >&2
echo "  ln -sfn $SOURCE_DIR $TARGET_DIR" >&2

exec "$REPO_ROOT/scripts/install-cursor-skills.sh"
