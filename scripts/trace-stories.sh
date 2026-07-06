#!/usr/bin/env bash
# story: e38s01
# trace-stories.sh — deterministic spec-to-code coverage matrix builder.
# Thin bash wrapper — the builder engine lives in scripts/lib/trace-stories.py.
# Oracle tiers (TEA-inspired): explicit tag (high), file heuristic (medium), task ref (low).
#
# Usage:
#   bash scripts/trace-stories.sh            # full matrix, stdout
#   bash scripts/trace-stories.sh --strict   # exit non-zero on P0 uncovered
#   bash scripts/trace-stories.sh --json     # emit JSON to specs/traceability-matrix.json
#   bash scripts/trace-stories.sh --help     # this message
#
# Exit codes:
#   0 — matrix built successfully
#   1 — input file missing or unparseable
#   2 — --strict mode: P0 story has 0% coverage

set -euo pipefail

MATRIX_JSON="$REPO_ROOT/specs/traceability-matrix.json"
TRACE_MD="$REPO_ROOT/specs/TRACEABILITY_LATEST.md"
RELEASE_PLAN="$REPO_ROOT/specs/release-plan.yaml"
EXEC_STATUS="$REPO_ROOT/specs/execution-status.yaml"
OKF_DIR="$REPO_ROOT/specs/codebase-wiki"
MODE=""
STRICT=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --help|-h)
      cat <<'USAGE'
Usage: trace-stories.sh [flags]

Build a deterministic spec-to-code coverage matrix from story tags.

Flags:
  --strict   Exit non-zero if any P0 story has 0% code coverage.
  --json     Emit JSON matrix to specs/traceability-matrix.json.
  --help     Print this message and exit.

Exit codes:
  0  Matrix built successfully.
  1  Required input file missing or unparseable.
  2  --strict mode: one or more P0 stories have 0% code coverage.
USAGE
      exit 0
      ;;
    --strict) STRICT=1; shift ;;
    --json)   MODE="json"; shift ;;
    *)
      echo "trace-stories.sh: unknown flag: $1" >&2
      echo "Try --help for usage." >&2
      exit 1
      ;;
  esac
done

if [[ ! -f "$RELEASE_PLAN" ]]; then
  echo "trace-stories.sh: release-plan.yaml: not found at $RELEASE_PLAN" >&2
  exit 1
fi
if [[ ! -f "$EXEC_STATUS" ]]; then
  echo "trace-stories.sh: execution-status.yaml: not found at $EXEC_STATUS" >&2
  exit 1
fi

exec python3 "$(dirname "${BASH_SOURCE[0]}")/lib/trace-stories.py" \
  "$REPO_ROOT" "$MATRIX_JSON" "$TRACE_MD" "$OKF_DIR" "$STRICT" "$MODE"
