#!/usr/bin/env bash
# story: BUG-2026-11-02-pipefail-pipe-race
# test-pipefail-pipe-race.sh — regression guard for SIGPIPE races under pipefail.
#
# `producer | grep -q` (or `| head`) fails at random under `set -o pipefail`:
# the reader exits early, the producer dies with SIGPIPE (141), and pipefail
# reports the pipeline as failed — a found match reads as "not found".
#
#   (a) anti-vacuity: the racy shape really fails on this host
#   (b) each fix shape used in the repo passes RUNS times with a long producer
#   (c) static guard: no pipefail script pipes git output into an early-exit reader
#
# Usage: bash scripts/test-pipefail-pipe-race.sh

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/skill-common.sh"
resolve_repo_root
cd "$REPO_ROOT"

source scripts/lib/test-assertions.sh
TA_PASS=0
TA_FAIL=0
RUNS=20

# ~2 MB of output: far past any pipe buffer, so an early reader always wins.
long_producer() { seq 1 300000; }

# Runs "$@" RUNS times; prints how many runs returned non-zero.
count_failures() {
  local i fails=0
  for ((i = 0; i < RUNS; i++)); do
    "$@" || fails=$((fails + 1))
  done
  echo "$fails"
}

racy_grep_q()      { long_producer | grep -q '^1$'; }
fixed_capture()    { local out; out="$(long_producer)"; grep -q '^1$' <<<"$out"; }
fixed_nonempty()   { [[ -n "$(long_producer)" ]]; }
fixed_awk_limit()  { long_producer | awk -v limit=3 'NR <= limit' >/dev/null; }
fixed_sed_range()  { long_producer | sed -n '1,5p' >/dev/null; }

echo "=== test-pipefail-pipe-race.sh ==="

fails=$(count_failures racy_grep_q)
[[ "$fails" -gt 0 ]] \
  && ta_pass "(a) racy 'producer | grep -q' fails under pipefail ($fails/$RUNS)" \
  || ta_fail "(a) racy shape never failed — test cannot detect the race on this host"

for fix in fixed_capture fixed_nonempty fixed_awk_limit fixed_sed_range; do
  fails=$(count_failures "$fix")
  [[ "$fails" -eq 0 ]] \
    && ta_pass "(b) $fix: 0/$RUNS failures" \
    || ta_fail "(b) $fix: $fails/$RUNS failures"
done

# run-skill-verify.sh holds `git diff ... | head -20` as a fixture string of
# fail-open verify directives, not as a command it runs.
hits=$(grep -rlE 'pipefail' scripts hooks --include='*.sh' \
  | grep -v '^scripts/run-skill-verify\.sh$' \
  | xargs grep -nE 'git [a-z-]+[^|]*\|[[:space:]]*(grep -[a-zA-Z]*[qm]|head)' \
  | grep -vE '^[^:]+:[0-9]+:[[:space:]]*#' || true)
[[ -z "$hits" ]] \
  && ta_pass "(c) no pipefail script pipes git output into grep -q/-m or head" \
  || ta_fail "(c) git output piped into an early-exit reader:"$'\n'"$hits"

echo "$TA_PASS passed, $TA_FAIL failed"
[[ "$TA_FAIL" -eq 0 ]]
