#!/usr/bin/env bash
# story: BUG-2026-10-25-ci-critical-path
# test-golden-gate-runner.sh — regression guard for golden_run_deterministic_gates.
#
# Runs the real runner against a fixture gate list and asserts:
#   (a) a failing gate prints the tail of its output (CI used to show only FAIL)
#   (b) GOLDEN_SKIP_GATES reports a named gate as SKIP with its reason
#   (c) an unknown name in GOLDEN_SKIP_GATES is a FAIL, so a typo cannot
#       silently disable nothing while claiming to skip something
#   (d) without GOLDEN_SKIP_GATES every gate runs — the default stays full
#
# Usage: bash scripts/test-golden-gate-runner.sh

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/skill-common.sh"
resolve_repo_root
cd "$REPO_ROOT"

FAILURES=0
pass() { echo "PASS $1"; }
fail() { echo "FAIL $1"; FAILURES=$((FAILURES + 1)); }

# Run the runner in a subshell with a fixture gate list; prints its stdout and
# the final counters as "COUNTS pass fail skip".
run_fixture() {
  (
    source scripts/lib/golden-suite-gates.sh
    GOLDEN_GATES=(
      "ok-gate:true:false"
      "bad-gate:sh -c 'echo marker-line-from-failing-gate; exit 3':false"
      "covered-gate:true:false"
    )
    golden_run_deterministic_gates
    echo "COUNTS $PASS_COUNT $FAIL_COUNT $SKIP_COUNT"
  )
}

out=$(GOLDEN_SKIP_GATES="" run_fixture)
echo "$out" | grep -q 'marker-line-from-failing-gate' \
  && pass "(a) failing gate output is printed" \
  || fail "(a) failing gate output is missing"
echo "$out" | grep -q '^COUNTS 2 1 0$' \
  && pass "(d) no skip list runs every gate" \
  || fail "(d) default run counts wrong: $(echo "$out" | grep COUNTS)"

out=$(GOLDEN_SKIP_GATES="covered-gate" GOLDEN_SKIP_REASON="runs in its own CI job" run_fixture)
echo "$out" | grep -q '^\[covered-gate\] .*SKIP.*runs in its own CI job' \
  && pass "(b) skipped gate reported with reason" \
  || fail "(b) skipped gate not reported with reason"
echo "$out" | grep -q '^COUNTS 1 1 1$' \
  && pass "(b) skipped gate counted as skip, not pass" \
  || fail "(b) skip counts wrong: $(echo "$out" | grep COUNTS)"

out=$(GOLDEN_SKIP_GATES="no-such-gate" run_fixture)
echo "$out" | grep -q 'no-such-gate' && echo "$out" | grep -q '^COUNTS 2 2 0$' \
  && pass "(c) unknown skip name fails the run" \
  || fail "(c) unknown skip name accepted: $(echo "$out" | grep COUNTS)"

[ "$FAILURES" -eq 0 ] && echo "OK: golden gate runner" || { echo "$FAILURES check(s) failed"; exit 1; }
