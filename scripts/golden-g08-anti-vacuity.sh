#!/usr/bin/env bash
# golden-g08-anti-vacuity.sh — validate-specs-yaml.sh Anti-Vacuity Self-Test (G-08)
#
# Proves that validate-specs-yaml.sh CAN detect structurally corrupt YAML
# (BUG-2026-07-03-validate-specs-no-real-parser bug class). It is fed a
# fixture where specs/verifications/fixtures/corrupt-yaml/release-plan.yaml
# is deliberately flattened/corrupt (matching the real yaml-roundtrip
# corruption pattern) while still containing every string the grep-only
# checks look for (^epics:, version:, ^release:). A validator that only
# greps for those strings passes vacuously; a validator that really parses
# the YAML must FAIL.
#
# Mirrors scripts/golden-g07-negative-path.sh's fixture + non-zero-exit
# pattern.
#
# Usage: bash scripts/golden-g08-anti-vacuity.sh
# Exit 0: validate-specs-yaml.sh correctly detected the corrupt fixture
# Exit 1: validate-specs-yaml.sh passed vacuously on the corrupt fixture

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/skill-common.sh"
resolve_repo_root

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

FIXTURE_DIR="$REPO_ROOT/specs/verifications/fixtures/corrupt-yaml"
VALIDATOR="$REPO_ROOT/scripts/validate-specs-yaml.sh"

echo "=== G-08: Anti-Vacuity Self-Test (validate-specs-yaml.sh) ==="
echo "Fixture: $FIXTURE_DIR"
echo ""

if [[ ! -f "$FIXTURE_DIR/release-plan.yaml" ]]; then
  echo "ERROR: fixture not found: $FIXTURE_DIR/release-plan.yaml"
  exit 1
fi

set +e
actual_output=$(bash "$VALIDATOR" "$FIXTURE_DIR" 2>&1)
actual_exit=$?
set -e
source "$(dirname "${BASH_SOURCE[0]}")/lib/skill-common.sh"
resolve_repo_root

echo "$actual_output"
echo ""

if [[ $actual_exit -ne 0 ]]; then
  echo -e "${GREEN}PASS${NC} validate-specs-yaml.sh correctly detected the corrupt fixture (exit $actual_exit)"
  echo "G-08: PASS"
  exit 0
else
  echo -e "${RED}FAIL${NC} validate-specs-yaml.sh passed vacuously on a structurally corrupt fixture (exit 0)"
  echo "G-08: FAIL — fail-open risk (same bug class as GAP-1 / BUG-2026-07-03-validate-specs-no-real-parser)"
  exit 1
fi
