#!/usr/bin/env bash
# story: e83s03
# test-okf-bundles.sh — validate every OKF bundle directory that CI validates.
#
# Parity gate. CI's `sync` job runs validate-okf.sh over six specs/ directories;
# the local gate set did not, so `npm run compliance` and
# `scripts/run-verification-gates.sh` both went green while CI's `sync` job was
# red on e83s03 (receipts.json carried source "mixed", which the validator did
# not allow). Keep the two lists identical: if CI validates a directory, this
# gate validates it too.
set -euo pipefail
cd "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

DIRS=(
  specs/metrics
  specs/migrations
  specs/epics-wiki
  specs/adr-wiki
  specs/bugs
  specs/verifications/reports
)

fail=0
for dir in "${DIRS[@]}"; do
  [ -d "$dir" ] || continue
  out=$(bash scripts/validate-okf.sh --dir "$dir" 2>&1) || {
    echo "FAIL: OKF validation failed in $dir"
    grep -E 'FAIL|violation' <<<"$out" || echo "$out"
    fail=1
    continue
  }
  echo "ok  : OKF bundles valid in $dir"
done

if [ "$fail" -ne 0 ]; then
  echo ""
  echo "Local gate set has drifted from CI's Validate OKF bundles step"
  echo "(.github/workflows/test-build-release.yml). Fix the artifacts or the validator."
  exit 1
fi
echo "ok  : all CI-validated OKF directories pass locally"
