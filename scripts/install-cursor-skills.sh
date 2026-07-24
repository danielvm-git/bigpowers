#!/usr/bin/env bash
# story: e78
# DEPRECATED wrapper — Cursor integration is Rules (.mdc), not ~/.cursor/skills copies.
# Canonical install: bash scripts/install.sh  OR  node bin/setup.js (bigpowers setup)
# This script now symlinks repo .cursor/rules → TARGET_DIR (default: ~/.cursor/rules).
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SOURCE_DIR="${SOURCE_DIR:-$REPO_ROOT/.cursor/rules}"
TARGET_DIR="${TARGET_DIR:-$HOME/.cursor/rules}"

echo "NOTE: install-cursor-skills.sh is deprecated; use scripts/install.sh or bigpowers setup." >&2
echo "      Redirecting to rules symlink: $TARGET_DIR → $SOURCE_DIR" >&2

if [[ ! -d "$SOURCE_DIR" ]]; then
  echo "SOURCE_DIR missing: $SOURCE_DIR — run bash scripts/sync-skills.sh first" >&2
  exit 1
fi

mkdir -p "$(dirname "$TARGET_DIR")"
ln -sfn "$SOURCE_DIR" "$TARGET_DIR"
echo "Done. Linked $TARGET_DIR → $SOURCE_DIR"
echo "NOTE: Cursor does not scan ~/.cursor/rules/ globally; also symlink into each project:"
echo "  ln -sfn $SOURCE_DIR .cursor/rules"
