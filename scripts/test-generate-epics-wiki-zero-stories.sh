#!/usr/bin/env bash
# story: e53s01
# test-generate-epics-wiki-zero-stories.sh — regression test for
# BUG-2026-07-23-epics-wiki-empty-references: generate-epics-wiki.sh must
# skip epics with zero sliced stories rather than emit an invalid OKF bundle
# with an empty references[].
#
# Usage: bash scripts/test-generate-epics-wiki-zero-stories.sh

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/skill-common.sh"
resolve_repo_root
cd "$REPO_ROOT"

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

FAILURES=0
tt_pass() { echo -e "${GREEN}PASS${NC} $1"; }
tt_fail() { echo -e "${RED}FAIL${NC} $1"; FAILURES=$((FAILURES + 1)); }

FIXTURE_ID="e00"
FIXTURE_DIR="specs/epics/e00-zero-story-fixture"
FIXTURE_BUNDLE="specs/epics-wiki/${FIXTURE_ID}.okf.md"

cleanup() {
  rm -rf "$FIXTURE_DIR"
  rm -f "$FIXTURE_BUNDLE"
}
trap cleanup EXIT

mkdir -p "$FIXTURE_DIR"
cat > "${FIXTURE_DIR}/epic.yaml" <<'FIXTUREEOF'
id: e00
title: "Zero-story fixture epic"
wsjf: 0
bcps: 0
capsule_dir: epics/e00-zero-story-fixture
mode: capsule
status: todo
depends_on: []
stories: []
FIXTUREEOF

# A scoped-but-unsliced epic has a `stories:` key with nothing under it —
# grep -c '^\s*- id:' correctly returns 0 for this shape.
[[ -f "$FIXTURE_BUNDLE" ]] && rm -f "$FIXTURE_BUNDLE"

bash scripts/generate-epics-wiki.sh > /dev/null

if [[ ! -f "$FIXTURE_BUNDLE" ]]; then
  tt_pass "generate-epics-wiki.sh skips a zero-story epic (no bundle emitted)"
else
  tt_fail "generate-epics-wiki.sh emitted a bundle for a zero-story epic: $FIXTURE_BUNDLE"
fi

echo "---"
if [[ "$FAILURES" -eq 0 ]]; then
  echo -e "${GREEN}test-generate-epics-wiki-zero-stories: ALL PASS${NC}"
else
  echo -e "${RED}test-generate-epics-wiki-zero-stories: $FAILURES failure(s)${NC}"
fi
exit "$FAILURES"
