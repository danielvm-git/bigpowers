#!/usr/bin/env bash
# story: e45s10
# Refresh context-engineering.md sync stamp from SSOT (CLAUDE.md + PRINCIPLES.md).
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TARGET="$REPO_ROOT/docs/references/context-engineering.md"
STAMP="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

[[ -f "$TARGET" ]] || exit 0

if grep -q 'Last synced:' "$TARGET"; then
  sed -i.bak "s/\*\*Last synced:\*\*.*/\*\*Last synced:\*\* ${STAMP} (from CLAUDE.md + PRINCIPLES.md)/" "$TARGET"
  rm -f "${TARGET}.bak"
else
  printf '\n**Last synced:** %s (from CLAUDE.md + PRINCIPLES.md)\n' "$STAMP" >> "$TARGET"
fi

echo "sync-context-engineering-ref: stamped $TARGET"
