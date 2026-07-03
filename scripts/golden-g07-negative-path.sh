#!/usr/bin/env bash
# golden-g07-negative-path.sh — Step Script Negative-Path Self-Test (G-07)
#
# Proves that compliance step scripts CAN detect violations (GAP-1 bug class).
# Each step script is run against a deliberately broken fixture and MUST
# return a non-zero exit code (i.e., detect the violation).
#
# If any step script exits 0 on the broken fixture, it may be failing-open
# (passing vacuously) — the same class of bug that caused GAP-1.
#
# Usage: bash scripts/golden-g07-negative-path.sh
# Exit 0: all step scripts detected their violations (negative path verified)
# Exit 1: at least one step script failed to detect a violation (fail-open risk)

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

PASS=0
FAIL=0

g07_pass() { echo -e "  ${GREEN}PASS${NC} $*"; PASS=$((PASS + 1)); }
g07_fail() { echo -e "  ${RED}FAIL${NC} $*"; FAIL=$((FAIL + 1)); }

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FIXTURE_DIR="$REPO_ROOT/specs/verifications/fixtures/negative-path"
STEPS_DIR="$REPO_ROOT/specs/verifications/steps"

if [[ ! -d "$FIXTURE_DIR" ]]; then
  echo "ERROR: Fixture directory not found: $FIXTURE_DIR"
  exit 1
fi

echo "=== G-07: Negative-Path Self-Test ==="
echo "Fixture: $FIXTURE_DIR"
echo ""

# Each entry: "step_script|violation_description"
TESTS=(
  "and-files-should-be-small-enough-to-avoid-context-window-truncation-300-lines.sh|300-line cap: fixture has a 350-line script"
  "and-files-should-remain-under-500-lines-newspaper-metaphor.sh|500-line cap: fixture has a 550-line step script"
  "and-it-must-mandate-file-size-limits-300-lines.sh|CONVENTIONS.md: missing '300 lines' mandate"
  "then-it-must-mandate-conventional-commits-1-0-0-and-semver-2-0-0.sh|CONVENTIONS.md: missing Conventional Commits mandate"
  "then-skills-should-include-bold-hard-gate-callout-blocks.sh|SKILL.md: missing HARD GATE blocks"
)

for entry in "${TESTS[@]}"; do
  step_script="${entry%%|*}"
  description="${entry##*|}"

  script_path="$STEPS_DIR/$step_script"
  if [[ ! -f "$script_path" ]]; then
    g07_fail "$step_script: step script not found"
    continue
  fi

  # Run the step script from the fixture directory so it finds fixture files
  # (scripts/, CONVENTIONS.md, SKILL.md) instead of the real repo files.
  # Use set +e temporarily because the step script IS expected to exit non-zero.
  set +e
  actual_output=$(cd "$FIXTURE_DIR" && bash "$script_path" 2>&1)
  actual_exit=$?
  set -e

  if [[ $actual_exit -ne 0 ]]; then
    g07_pass "$step_script ($description) — correctly detected violation"
  else
    g07_fail "$step_script ($description) — FAILED TO DETECT violation (exit 0 on broken fixture, possible fail-open)"
    echo "         output: $actual_output"
  fi
done

echo ""
echo "──────────────────────────────────────────"
echo -e "Results: ${GREEN}${PASS} passed${NC}, ${RED}${FAIL} failed${NC}"
echo "──────────────────────────────────────────"

if [[ "$FAIL" -gt 0 ]]; then
  echo "G-07: FAIL — $FAIL step script(s) may be failing-open (GAP-1 bug class)"
  exit 1
fi

echo "G-07: PASS — all step scripts correctly detect violations on negative-path fixture"
exit 0
