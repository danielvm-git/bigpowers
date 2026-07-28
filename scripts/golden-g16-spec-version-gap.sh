#!/usr/bin/env bash
# story: e44s02
# golden-g16-spec-version-gap.sh — bigpowers' own repo must never show a spec
# version gap against itself.
#
# check-spec-version-gap.sh is a fully-formed SoT-drift detector for consuming
# projects (installed package.json version vs the spec-format version stamped
# or fingerprinted in their specs/), the same class of check as G-12, but it
# had no gate of its own and was reachable from nothing (G-13). Running it
# against this repo's own specs/ is the natural self-test the tool already
# supports via --project: bigpowers' own package.json version and its own
# specs/state.yaml bigpowers_version stamp must always agree.
#
# Usage: bash scripts/golden-g16-spec-version-gap.sh [--self-test]
# Exit 0: no gap (or, under --self-test, a deliberately injected gap was
#         correctly detected)
# Exit 1: a real gap exists, or --self-test failed to detect an injected one

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/skill-common.sh"
resolve_repo_root
cd "$REPO_ROOT"

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

if [[ "${1:-}" == "--self-test" ]]; then
  echo "=== G-16 self-test: prove the gap detector can fail ==="
  TMP=$(mktemp -d)
  trap 'rm -rf "$TMP"' EXIT
  mkdir -p "$TMP/specs"
  cp package.json "$TMP/package.json"
  # A stamped version far behind package.json's must be reported as a gap.
  # set +e around the call: under set -e, `out=$(cmd)` itself aborts the
  # script when cmd exits non-zero — exactly the outcome under test here — so
  # rc=$? would never be reached.
  printf 'bigpowers_version: 0.0.1\nactive_flow: null\n' > "$TMP/specs/state.yaml"
  set +e
  out=$(bash scripts/check-spec-version-gap.sh --project "$TMP" --skip-block --json 2>&1)
  rc=$?
  set -e
  # check-spec-version-gap.sh's stamp path emits json.dumps-formatted JSON
  # ("gap": true, with a space); its fingerprint path emits hand-concatenated
  # JSON ("gap":true, no space) — tolerate both rather than assuming one.
  if [[ $rc -eq 1 ]] && grep -qE '"gap":[[:space:]]*true' <<<"$out"; then
    echo -e "${GREEN}PASS${NC} injected version gap detected (exit $rc): $out"
    echo "G-16 self-test: PASS"
    exit 0
  fi
  echo -e "${RED}FAIL${NC} injected gap was not detected (exit $rc): $out"
  echo "G-16 self-test: FAIL"
  exit 1
fi

echo "=== G-16: spec version gap (self-check) ==="
# Same set -e hazard as the self-test above: a real gap exits non-zero, and
# without set +e this assignment would abort before the FAIL branch prints.
set +e
OUT=$(bash scripts/check-spec-version-gap.sh --project . --skip-block --json 2>&1)
RC=$?
set -e
echo "  $OUT"

if [[ $RC -eq 0 ]]; then
  echo -e "${GREEN}PASS${NC} no spec version gap"
  echo "G-16: PASS"
  exit 0
fi
echo -e "${RED}FAIL${NC} bigpowers' own specs/ disagree with its own package.json version (exit $RC)"
echo "G-16: FAIL"
exit 1
