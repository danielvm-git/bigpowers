#!/usr/bin/env bash
# story: e53s02
# test-tombstone-mechanism.sh — exercises tombstone-skill.sh and
# validate-tombstones.sh end-to-end against throwaway fixtures.
#
# Usage: bash scripts/test-tombstone-mechanism.sh

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
strip_ansi() { sed -E 's/\x1b\[[0-9;]*m//g'; }

FIXTURE_OLD="test-tombstone-fixture"
FIXTURE_NEW="test-tombstone-target"
FIXTURE_DIR="skills/${FIXTURE_OLD}"
TOMBSTONES_FILE="specs/tombstones.yaml"
TOMBSTONES_BACKUP=""

cleanup() {
  rm -rf "$FIXTURE_DIR" "skills/${FIXTURE_NEW}"
  if [[ -n "$TOMBSTONES_BACKUP" ]]; then
    mv "$TOMBSTONES_BACKUP" "$TOMBSTONES_FILE"
  else
    rm -f "$TOMBSTONES_FILE"
  fi
}
trap cleanup EXIT

if [[ -f "$TOMBSTONES_FILE" ]]; then
  TOMBSTONES_BACKUP=$(mktemp)
  cp "$TOMBSTONES_FILE" "$TOMBSTONES_BACKUP"
  rm -f "$TOMBSTONES_FILE"
fi

# --- Scenario: zero tombstones registered (6a) ---
if bash scripts/validate-tombstones.sh 2>&1 | grep -qi "no tombstones"; then
  tt_pass "validate-tombstones.sh reports clean when zero tombstones registered"
else
  tt_fail "validate-tombstones.sh did not report 'no tombstones' with an empty ledger"
fi

# --- Scenario: tombstone-skill.sh generates a stub ---
mkdir -p "$FIXTURE_DIR"
cat > "${FIXTURE_DIR}/SKILL.md" <<'FIXTUREEOF'
# story: e00s00
---
name: test-tombstone-fixture
description: throwaway fixture for test-tombstone-mechanism.sh
---
Fixture body.
FIXTUREEOF

bash scripts/tombstone-skill.sh "$FIXTURE_OLD" "$FIXTURE_NEW"

if grep -q "TOMBSTONE" "${FIXTURE_DIR}/SKILL.md"; then
  tt_pass "tombstone-skill.sh replaced SKILL.md with a stub"
else
  tt_fail "SKILL.md was not replaced with a tombstone stub"
fi

if grep -q "story: e00s00" "${FIXTURE_DIR}/SKILL.md"; then
  tt_pass "tombstone-skill.sh preserved the old story tag"
else
  tt_fail "story tag was not preserved in the stub"
fi

if [[ -f "$TOMBSTONES_FILE" ]] && grep -q "$FIXTURE_OLD" "$TOMBSTONES_FILE"; then
  tt_pass "tombstone-skill.sh registered the mapping in ${TOMBSTONES_FILE}"
else
  tt_fail "mapping not registered in ${TOMBSTONES_FILE}"
fi

# --- Scenario: fresh tombstone resolves cleanly ---
if bash scripts/validate-tombstones.sh 2>&1 | strip_ansi | grep -q "OK: ${FIXTURE_OLD}"; then
  tt_pass "validate-tombstones.sh confirms the fresh stub resolves"
else
  tt_fail "validate-tombstones.sh did not confirm the fresh stub"
fi

# --- Scenario: expired tombstone flagged (6b) ---
python3 -c "
import yaml
d = yaml.safe_load(open('$TOMBSTONES_FILE')) or {'tombstones': []}
for t in d['tombstones']:
    if t['old_name'] == '$FIXTURE_OLD':
        t['created_at_version'] = '0.0.0'
yaml.dump(d, open('$TOMBSTONES_FILE', 'w'), default_flow_style=False)
"

if bash scripts/validate-tombstones.sh 2>&1 | strip_ansi | grep -qi "EXPIRED: ${FIXTURE_OLD}"; then
  tt_pass "validate-tombstones.sh flags a tombstone whose expiry window has passed"
else
  tt_fail "expired tombstone was not flagged"
fi

echo "---"
if [[ "$FAILURES" -eq 0 ]]; then
  echo -e "${GREEN}test-tombstone-mechanism: ALL PASS${NC}"
else
  echo -e "${RED}test-tombstone-mechanism: $FAILURES failure(s)${NC}"
fi
exit "$FAILURES"
