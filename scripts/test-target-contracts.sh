#!/usr/bin/env bash
# story: e37s08
# test-target-contracts.sh — anti-vacuity guard for run_contract.
#
# Every contract named in scripts/targets.yaml must have a real assertion behind
# it. run_contract used to end in `*) echo "SKIP ..."; return 0`, so seven
# declared contracts (cline/codebuddy/codex/kilocode/qwen/trae/windsurf
# _hooks_manifest) silently passed forever. This test fails if that default ever
# returns to being permissive, or if targets.yaml declares a contract nothing
# implements.
#
# Usage: bash scripts/test-target-contracts.sh
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/skill-common.sh"
resolve_repo_root
cd "$REPO_ROOT"

PASS=0
FAIL=0
pass() { echo "PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "FAIL: $1" >&2; FAIL=$((FAIL + 1)); }

echo "=== test-target-contracts.sh ==="

# shellcheck source=lib/target-contracts.sh
source "$REPO_ROOT/scripts/lib/target-contracts.sh"

# 1. An unknown contract MUST fail. This is the anti-vacuity assertion.
set +e
out=$(run_contract "faketarget" "definitely_not_a_real_contract" 2>&1)
rc=$?
set -e
if [[ $rc -ne 0 ]]; then
  pass "unknown contract fails (exit $rc)"
else
  fail "unknown contract returned 0 — run_contract is fail-open again: $out"
fi

# 2. Every contract declared in targets.yaml must resolve to an assertion.
#    Probing with a nonexistent target id means a real assertion returns 1 with
#    a FAIL line, while a missing implementation hits the default branch and
#    reports "unknown contract".
declared=$(grep -E "^      - [a-z0-9_]+$" scripts/targets.yaml | sed 's/^      - //' | sort -u)
[[ -n "$declared" ]] || fail "no contracts parsed from targets.yaml"

for c in $declared; do
  set +e
  out=$(run_contract "__probe__" "$c" 2>&1)
  set -e
  if grep -q "unknown contract" <<<"$out"; then
    fail "$c declared in targets.yaml but no assertion implements it"
  else
    pass "$c has an implementation"
  fi
done

# 3. Every *_hooks_manifest target must actually ship a parseable manifest.
for c in $declared; do
  case "$c" in
    gemini_hooks_manifest) continue ;;  # adapter-level validator, not a file check
    *_hooks_manifest)
      t="${c%_hooks_manifest}"
      if [[ -f "scripts/hooks/${t}/hooks-manifest.json" ]]; then
        pass "$t ships hooks-manifest.json"
      else
        fail "$t declares $c but scripts/hooks/${t}/hooks-manifest.json is missing"
      fi
      ;;
  esac
done

echo "test-target-contracts: $PASS passed, $FAIL failed"
[[ "$FAIL" -eq 0 ]] || exit 1
