#!/usr/bin/env bash
# story: e37s05
# golden-g13-test-orphans.sh — every scripts/test-*.sh must be wired into a gate.
#
# Before this gate, 33 of 35 test scripts were reachable from nothing: not CI,
# not Preflight, not package.json, not another script. Writing a test was not
# enough to make it run, so tests accumulated as dead weight and regressions
# they would have caught shipped anyway (test-adapters.sh silently exercised 1
# of 21 adapters for months).
#
# Usage: bash scripts/golden-g13-test-orphans.sh [--self-test]
# Exit 0: every test script is referenced by the gate list
# Exit 1: at least one orphan (or, under --self-test, the gate failed to notice
#         a deliberately unlisted script)

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/skill-common.sh"
resolve_repo_root
cd "$REPO_ROOT"

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

GATES_FILE="scripts/lib/golden-suite-gates.sh"

find_orphans() { # $1 = extra script basename to consider (may be empty)
  local extra="${1:-}"
  local orphans=""
  local f b
  for f in scripts/test-*.sh; do
    [[ -e "$f" ]] || continue
    b="$(basename "$f")"
    grep -q "$b" "$GATES_FILE" || orphans+="  $b"$'\n'
  done
  if [[ -n "$extra" ]]; then
    grep -q "$extra" "$GATES_FILE" || orphans+="  $extra"$'\n'
  fi
  printf '%s' "$orphans"
}

if [[ "${1:-}" == "--self-test" ]]; then
  echo "=== G-13 self-test: prove the gate can fail ==="
  # A name that is definitely not in the gate list must be reported.
  if [[ -n "$(find_orphans "test-definitely-not-wired.sh")" ]]; then
    echo -e "${GREEN}PASS${NC} G-13 reports an unlisted test script"
    echo "G-13 self-test: PASS"
    exit 0
  fi
  echo -e "${RED}FAIL${NC} G-13 did not report an unlisted script — vacuous gate"
  echo "G-13 self-test: FAIL"
  exit 1
fi

echo "=== G-13: test-script orphan check ==="
ORPHANS="$(find_orphans "")"
TOTAL=$(ls scripts/test-*.sh 2>/dev/null | wc -l | tr -d ' ')

if [[ -z "$ORPHANS" ]]; then
  echo "  ok  : all $TOTAL test script(s) are wired into $GATES_FILE"
  echo -e "${GREEN}PASS${NC}"
  echo "G-13: PASS"
  exit 0
fi

echo "  orphaned test scripts (present but reachable from no gate):"
printf '%s' "$ORPHANS"
echo -e "${RED}FAIL${NC} add them to GOLDEN_GATES in $GATES_FILE, or delete them"
echo "G-13: FAIL"
exit 1
