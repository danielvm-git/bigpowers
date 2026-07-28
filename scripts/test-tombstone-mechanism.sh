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

TA_PASS=0
TA_FAIL=0
TA_TMPDIR=""
source "$(dirname "${BASH_SOURCE[0]}")/lib/test-assertions.sh"
# NOT `trap ta_cleanup EXIT` — this script's cleanup restores a backed-up
# specs/tombstones.yaml and removes named fixture dirs, not a TA_TMPDIR.

FIXTURE_OLD="test-tombstone-fixture"
FIXTURE_NEW="test-tombstone-target"
FIXTURE_DIR="skills/${FIXTURE_OLD}"
TOMBSTONES_FILE="specs/tombstones.yaml"
TOMBSTONES_BACKUP=""

tombstone_test_cleanup() {
  rm -rf "$FIXTURE_DIR" "skills/${FIXTURE_NEW}"
  if [[ -n "$TOMBSTONES_BACKUP" ]]; then
    mv "$TOMBSTONES_BACKUP" "$TOMBSTONES_FILE"
  else
    rm -f "$TOMBSTONES_FILE"
  fi
}
trap tombstone_test_cleanup EXIT

if [[ -f "$TOMBSTONES_FILE" ]]; then
  TOMBSTONES_BACKUP=$(mktemp)
  cp "$TOMBSTONES_FILE" "$TOMBSTONES_BACKUP"
  rm -f "$TOMBSTONES_FILE"
fi

# --- Scenario: zero tombstones registered (6a) ---
if bash scripts/validate-tombstones.sh 2>&1 | grep -qi "no tombstones"; then
  ta_pass "validate-tombstones.sh reports clean when zero tombstones registered"
else
  ta_fail "validate-tombstones.sh did not report 'no tombstones' with an empty ledger"
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
  ta_pass "tombstone-skill.sh replaced SKILL.md with a stub"
else
  ta_fail "SKILL.md was not replaced with a tombstone stub"
fi

if grep -q "story: e00s00" "${FIXTURE_DIR}/SKILL.md"; then
  ta_pass "tombstone-skill.sh preserved the old story tag"
else
  ta_fail "story tag was not preserved in the stub"
fi

if [[ -f "$TOMBSTONES_FILE" ]] && grep -q "$FIXTURE_OLD" "$TOMBSTONES_FILE"; then
  ta_pass "tombstone-skill.sh registered the mapping in ${TOMBSTONES_FILE}"
else
  ta_fail "mapping not registered in ${TOMBSTONES_FILE}"
fi

# --- Scenario: fresh tombstone resolves cleanly ---
if bash scripts/validate-tombstones.sh 2>&1 | ta_strip_ansi | grep -q "OK: ${FIXTURE_OLD}"; then
  ta_pass "validate-tombstones.sh confirms the fresh stub resolves"
else
  ta_fail "validate-tombstones.sh did not confirm the fresh stub"
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

if bash scripts/validate-tombstones.sh 2>&1 | ta_strip_ansi | grep -qi "EXPIRED: ${FIXTURE_OLD}"; then
  ta_pass "validate-tombstones.sh flags a tombstone whose expiry window has passed"
else
  ta_fail "expired tombstone was not flagged"
fi

# --- Scenario: rejects path-traversal / invalid skill names (threat model CWE-22) ---
# tombstone-skill.sh exits non-zero on rejection, and this script runs under
# `set -o pipefail` — capture output via `|| true` first so the pipe's exit
# status doesn't mask the grep check below.
output=$(bash scripts/tombstone-skill.sh "../../etc/passwd" "target" 2>&1 || true)
if echo "$output" | grep -qi "not a valid skill name"; then
  ta_pass "tombstone-skill.sh rejects a path-traversal old-name"
else
  ta_fail "tombstone-skill.sh did not reject a path-traversal old-name"
fi

output=$(bash scripts/tombstone-skill.sh "$FIXTURE_OLD" "../../etc/passwd" 2>&1 || true)
if echo "$output" | grep -qi "not a valid skill name"; then
  ta_pass "tombstone-skill.sh rejects a path-traversal new-name"
else
  ta_fail "tombstone-skill.sh did not reject a path-traversal new-name"
fi

# --- Scenario: validate-tombstones.sh rejects an invalid name read back from the ledger ---
python3 -c "
import yaml
d = yaml.safe_load(open('$TOMBSTONES_FILE')) or {'tombstones': []}
d.setdefault('tombstones', []).append({
    'old_name': '../../etc/passwd',
    'new_name_or_merge_target': 'target',
    'created_at_version': '0.0.0',
})
yaml.dump(d, open('$TOMBSTONES_FILE', 'w'), default_flow_style=False)
"
output=$(bash scripts/validate-tombstones.sh 2>&1 | ta_strip_ansi || true)
if echo "$output" | grep -qi "FAIL.*not a valid skill name"; then
  ta_pass "validate-tombstones.sh rejects a path-traversal name read from the ledger"
else
  ta_fail "validate-tombstones.sh did not reject a path-traversal name read from the ledger"
fi
python3 -c "
import yaml
d = yaml.safe_load(open('$TOMBSTONES_FILE')) or {'tombstones': []}
d['tombstones'] = [t for t in d.get('tombstones', []) if t.get('old_name') != '../../etc/passwd']
yaml.dump(d, open('$TOMBSTONES_FILE', 'w'), default_flow_style=False)
"

echo "---"
echo "test-tombstone-mechanism: $TA_PASS passed, $TA_FAIL failed"
exit "$TA_FAIL"
