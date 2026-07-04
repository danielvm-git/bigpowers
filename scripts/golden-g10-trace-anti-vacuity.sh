#!/usr/bin/env bash
# golden-g10-trace-anti-vacuity.sh — Trace Engine Anti-Vacuity Self-Test (G-10)
#
# Proves that trace-stories.py CAN detect a degenerate matrix (floor assertion).
# It is fed a fixture where specs/release-plan.yaml has valid YAML but produces
# 0 stories — the --strict floor assertion MUST catch this and exit 2.
#
# If --strict exits 0 or 1 on this fixture, the trace engine is failing-open
# (same bug class as BUG-2026-07-03-trace-engine-vacuous-gate).
#
# Usage: bash scripts/golden-g10-trace-anti-vacuity.sh
# Exit 0: trace-stories.py correctly detected the degenerate fixture (exit 2)
# Exit 1: trace-stories.py passed vacuously on the degenerate fixture (fail-open risk)

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FIXTURE_DIR="$REPO_ROOT/specs/verifications/fixtures/trace-vacuous"
TRACE_ENGINE="$REPO_ROOT/scripts/lib/trace-stories.py"

echo "=== G-10: Trace Engine Anti-Vacuity Self-Test ==="
echo "Fixture: $FIXTURE_DIR"
echo ""

if [[ ! -f "$FIXTURE_DIR/specs/release-plan.yaml" ]]; then
  echo "ERROR: fixture not found: $FIXTURE_DIR/specs/release-plan.yaml"
  exit 1
fi

MATRIX_JSON=$(mktemp)
TRACE_MD=$(mktemp)
OKF_DIR=$(mktemp -d)
trap 'rm -f "$MATRIX_JSON" "$TRACE_MD"; rm -rf "$OKF_DIR"' EXIT

set +e
actual_output=$(python3 "$TRACE_ENGINE" "$FIXTURE_DIR" "$MATRIX_JSON" "$TRACE_MD" "$OKF_DIR" 1 "" 2>&1)
actual_exit=$?
set -e

echo "$actual_output"
echo ""

if [[ $actual_exit -eq 2 ]]; then
  echo -e "${GREEN}PASS${NC} trace-stories.py --strict correctly detected the degenerate fixture (exit 2)"
  echo "G-10: PASS"
  exit 0
elif [[ $actual_exit -eq 0 ]]; then
  echo -e "${RED}FAIL${NC} trace-stories.py --strict passed vacuously on a 0-story fixture (exit 0)"
  echo "G-10: FAIL — fail-open risk (BUG-2026-07-03-trace-engine-vacuous-gate class)"
  exit 1
else
  echo -e "${RED}FAIL${NC} trace-stories.py --strict exited $actual_exit (expected 2)"
  echo "G-10: FAIL — unexpected exit code"
  exit 1
fi
