#!/usr/bin/env bash
# test-trace-matrix-size.sh — recurrence guard for BUG-2026-07-06-gate-trace-matrix-oversized
#
# Asserts trace-matrix.py and its extracted modules stay under the 300-line cap.
#
# Usage: bash scripts/test-trace-matrix-size.sh

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/skill-common.sh"
resolve_repo_root

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

CAP=300
FAILURES=0

pass() { echo -e "${GREEN}PASS${NC} $1"; }
fail() { echo -e "${RED}FAIL${NC} $1"; FAILURES=$((FAILURES + 1)); }

check_lines() {
  local file="$1"
  local lines
  lines=$(wc -l < "$REPO_ROOT/$file" | tr -d ' ')
  if [[ "$lines" -le "$CAP" ]]; then
    pass "$file: $lines lines (≤ $CAP)"
  else
    fail "$file: $lines lines (exceeds $CAP)"
  fi
}

for f in \
  scripts/lib/trace-matrix.py \
  scripts/lib/simple_yaml.py \
  scripts/lib/trace_renderer.py
do
  check_lines "$f"
done

if [[ "$FAILURES" -gt 0 ]]; then
  echo "test-trace-matrix-size.sh: $FAILURES failure(s)" >&2
  exit 1
fi

exit 0
