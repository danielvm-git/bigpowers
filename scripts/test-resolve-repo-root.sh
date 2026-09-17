#!/usr/bin/env bash
# Regression test for resolve_repo_root() in consumer layouts without skills/.
# See: https://github.com/danielvm-git/bigpowers/issues/130
set -euo pipefail

TA_PASS=0
TA_FAIL=0
TA_TMPDIR=""

source "$(dirname "${BASH_SOURCE[0]}")/lib/test-assertions.sh"
trap ta_cleanup EXIT

echo "=== test-resolve-repo-root.sh ==="

# Consumer project: scripts/lib present, no local skills/ directory.
TA_TMPDIR="$(mktemp -d)"
mkdir -p "$TA_TMPDIR/scripts/lib"
cp "$(dirname "${BASH_SOURCE[0]}")/lib/skill-common.sh" "$TA_TMPDIR/scripts/lib/"

set +e
out=$(bash -c "source '$TA_TMPDIR/scripts/lib/skill-common.sh' && resolve_repo_root && printf '%s|%s' \"\$REPO_ROOT\" \"\$SKILLS_ROOT\"")
rc=$?
set -e

if [[ $rc -ne 0 ]]; then
  ta_fail "consumer layout: resolve_repo_root exited $rc"
elif [[ "$out" == "$TA_TMPDIR|$TA_TMPDIR" ]]; then
  ta_pass "consumer layout without skills/ resolves repo root (not scripts/)"
else
  ta_fail "consumer layout: expected REPO_ROOT=$TA_TMPDIR, got: $out"
fi

# bigpowers repo: skills/ and scripts/lib both present.
source "$(dirname "${BASH_SOURCE[0]}")/lib/skill-common.sh"
resolve_repo_root
expected_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [[ "$REPO_ROOT" == "$expected_root" && -d "$REPO_ROOT/skills" ]]; then
  ta_pass "bigpowers repo resolves REPO_ROOT with skills/"
else
  ta_fail "bigpowers repo: REPO_ROOT=$REPO_ROOT expected=$expected_root"
fi

echo "=== $TA_PASS passed, $TA_FAIL failed ==="
[[ "$TA_FAIL" -eq 0 ]]
