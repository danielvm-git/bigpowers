#!/usr/bin/env bash
# story: e53s01
# test-completeness-critic-scope.sh — regression test for
# BUG-2026-07-23-completeness-critic-code-tags-schema-drift: the zero-tag
# check must scope to the active story only (not siblings/other epics), and
# must WARN — not silently no-op — when active_story is unset or unresolved.
#
# Usage: bash scripts/test-completeness-critic-scope.sh

set -euo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

TA_PASS=0
TA_FAIL=0
TA_TMPDIR=""
source "$REPO_ROOT/scripts/lib/test-assertions.sh"
# NOT `trap ta_cleanup EXIT` — this script's cleanup restores backed-up
# specs/state.yaml and specs/traceability-matrix.json, not a TA_TMPDIR.

STATE_FILE="specs/state.yaml"
MATRIX_FILE="specs/traceability-matrix.json"
STATE_BACKUP=$(mktemp)
MATRIX_BACKUP=$(mktemp)
cp "$STATE_FILE" "$STATE_BACKUP"
cp "$MATRIX_FILE" "$MATRIX_BACKUP"

completeness_critic_test_cleanup() {
  cp "$STATE_BACKUP" "$STATE_FILE"
  cp "$MATRIX_BACKUP" "$MATRIX_FILE"
  rm -f "$STATE_BACKUP" "$MATRIX_BACKUP"
}
trap completeness_critic_test_cleanup EXIT

run_critic() {
  bash scripts/lib/completeness-critic.sh 2>&1 || true
}

# Fixture matrix: one untagged sibling story (e00s02) that must NOT block,
# and the active story (e00s01) which is under test.
write_matrix() {
  local active_links="$1"
  cat > "$MATRIX_FILE" <<FIXTUREEOF
{
  "stories": [
    {"id": "e00s01", "status": "in_progress", "links": ${active_links}},
    {"id": "e00s02", "status": "todo", "links": []}
  ]
}
FIXTUREEOF
}

# --- Scenario: active_story unset → WARNING, not silent pass ---
sed -i.bak '/^active_story:/d' "$STATE_FILE" && rm -f "${STATE_FILE}.bak"
write_matrix '[]'
output=$(run_critic)
if echo "$output" | grep -q "\[WARNING\].*no active_story set"; then
  ta_pass "unset active_story produces an explicit WARNING"
else
  ta_fail "unset active_story did not produce the expected WARNING"
fi

# --- Scenario: active_story set but absent from the matrix → WARNING ---
printf 'active_story: e99s99\n' >> "$STATE_FILE"
output=$(run_critic)
if echo "$output" | grep -q "\[WARNING\].*e99s99 not found"; then
  ta_pass "unresolved active_story produces an explicit WARNING"
else
  ta_fail "unresolved active_story did not produce the expected WARNING"
fi
sed -i.bak '/^active_story:/d' "$STATE_FILE" && rm -f "${STATE_FILE}.bak"

# --- Scenario: active story has zero explicit_tag links → BLOCKER, scoped to it ---
printf 'active_story: e00s01\n' >> "$STATE_FILE"
write_matrix '[]'
output=$(run_critic)
if echo "$output" | grep -q "\[BLOCKER\] active story e00s01 has zero explicit story-tag links"; then
  ta_pass "active story with zero tags is correctly flagged as BLOCKER"
else
  ta_fail "active story with zero tags was not flagged as BLOCKER"
fi

# --- Scenario: active story IS tagged → no BLOCKER, even though sibling e00s02 is untagged ---
write_matrix '[{"method": "explicit_tag", "file": "scripts/fixture.sh", "line": 1, "confidence": 1.0}]'
output=$(run_critic)
if echo "$output" | grep -q "\[BLOCKER\] active story e00s01"; then
  ta_fail "tagged active story incorrectly flagged as BLOCKER"
else
  ta_pass "tagged active story is not flagged, and untagged sibling e00s02 does not leak into the check"
fi

echo "---"
echo "test-completeness-critic-scope: $TA_PASS passed, $TA_FAIL failed"
exit "$TA_FAIL"
