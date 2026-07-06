#!/usr/bin/env bash
# story: e38s04
# check-blind-spots.sh — TEA-inspired heuristic blind-spot detector.
# Thin bash wrapper — the detection engine lives in scripts/lib/blind-spots.py.
# Reads execution-status.yaml + traceability-matrix.json, runs 7 structural
# quality checks, and emits specs/blind-spots.json.
# Also detects SC- scenario gaps (sc-gap).
#
# Checks: verify-gap, test-gap, epic-orphan, stale-tag, double-tag, bootstrap-testless, sc-gap.
# Severities: HIGH / MEDIUM / LOW. Exit 1 on HIGH findings.

set -euo pipefail

BLIND_SPOTS_JSON="$REPO_ROOT/specs/blind-spots.json"
EXEC_STATUS="$REPO_ROOT/specs/execution-status.yaml"
MATRIX_JSON="$REPO_ROOT/specs/traceability-matrix.json"
VERIFICATIONS_DIR="$REPO_ROOT/specs/verifications"
EPICS_DIR="$REPO_ROOT/specs/epics"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --help|-h)
      cat <<'USAGE'
Usage: check-blind-spots.sh [flags]

Run 7 heuristic blind-spot checks on the codebase.

Flags:
  --help   Print this message and exit.

Checks: verify-gap, test-gap, epic-orphan, stale-tag, double-tag, bootstrap-testless, sc-gap.
Output: specs/blind-spots.json
Exit: 0 = no HIGH findings, 1 = HIGH findings or input files missing.
USAGE
      exit 0
      ;;
    *)
      echo "check-blind-spots.sh: unknown flag: $1" >&2
      echo "Try --help for usage." >&2
      exit 1
      ;;
  esac
done

if [[ ! -f "$EXEC_STATUS" ]]; then
  echo "check-blind-spots.sh: execution-status.yaml: not found at $EXEC_STATUS" >&2
  exit 1
fi

exec python3 "$(dirname "${BASH_SOURCE[0]}")/lib/blind-spots.py" \
  "$REPO_ROOT" "$BLIND_SPOTS_JSON" "$EXEC_STATUS" "$MATRIX_JSON" "$VERIFICATIONS_DIR" "$EPICS_DIR"
