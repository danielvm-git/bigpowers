#!/usr/bin/env bash
# story: e80s01
# Pre-flight runner for gate-trace skill verify — ensures critic inputs exist.
# Usage: bash scripts/run-gate-trace-verify.sh [--self-test]
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

self_test() {
  local tmp="$REPO_ROOT/specs/verifications/fixtures/gate-trace-selftest"
  mkdir -p "$tmp"
  echo '{"stories":{},"coverage_pct":85,"oracle_stats":{"heuristic_ratio":0.2}}' > "$tmp/traceability-matrix.json"
  echo '{"gaps":[]}' > "$tmp/blind-spots.json"
  test -f scripts/lib/completeness-critic.sh
  grep -q 'R1' skills/gate-trace/SKILL.md
  grep -q 'completeness-critic' skills/gate-trace/SKILL.md
  echo "run-gate-trace-verify: self-test OK"
}

if [[ "${1:-}" == "--self-test" ]]; then
  self_test
  exit 0
fi

[[ -f specs/traceability-matrix.json ]] || bash scripts/trace-stories.sh --json
[[ -f specs/blind-spots.json ]] || bash scripts/check-blind-spots.sh 2>/dev/null || true

if [[ ! -f specs/traceability-matrix.json ]]; then
  echo "FAIL: missing specs/traceability-matrix.json"
  exit 1
fi

bash scripts/lib/completeness-critic.sh
echo "run-gate-trace-verify: OK"
