#!/usr/bin/env bash
# story: e48s01
# story: e48s03
# Regression tests for OKF bundle generators (e48 audit gap closure)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "=== OKF generator regression tests ==="

require_min_count() {
  local dir="$1" min="$2" label="$3"
  local count
  count="$(find "$dir" -maxdepth 1 -name '*.okf.md' -type f 2>/dev/null | wc -l | tr -d ' ')"
  if [[ "$count" -lt "$min" ]]; then
    echo "FAIL: expected at least $min $label bundles in $dir, got $count"
    exit 1
  fi
  echo "  $label: $count bundles"
}

echo "→ generate-epics-wiki.sh"
bash "$REPO_ROOT/scripts/generate-epics-wiki.sh" >/dev/null
require_min_count "$REPO_ROOT/specs/epics-wiki" 1 "epic"
bash "$REPO_ROOT/scripts/validate-okf.sh" --dir "$REPO_ROOT/specs/epics-wiki"

if ! grep -q '^tier:' "$REPO_ROOT/specs/epics-wiki/e48.okf.md"; then
  echo "FAIL: e48.okf.md missing tier: field (e48s06)"
  exit 1
fi

echo "→ generate-adr-wiki.sh"
bash "$REPO_ROOT/scripts/generate-adr-wiki.sh" >/dev/null
require_min_count "$REPO_ROOT/specs/adr-wiki" 1 "adr"
bash "$REPO_ROOT/scripts/validate-okf.sh" --dir "$REPO_ROOT/specs/adr-wiki"

echo "→ sync-bugs-registry.sh"
bash "$REPO_ROOT/scripts/sync-bugs-registry.sh" >/dev/null
require_min_count "$REPO_ROOT/specs/bugs" 1 "bug"
bash "$REPO_ROOT/scripts/validate-okf.sh" --dir "$REPO_ROOT/specs/bugs"

echo "→ publish-to-wiki.sh --dry-run"
OUTPUT="$(bash "$REPO_ROOT/kernel/src/publish-to-wiki.sh" --dry-run)"
if [[ "$OUTPUT" != *"pages:"* ]]; then
  echo "FAIL: publish-to-wiki dry-run missing page manifest"
  echo "$OUTPUT"
  exit 1
fi

echo "PASS: OKF generators and publish-to-wiki dry-run"
exit 0
