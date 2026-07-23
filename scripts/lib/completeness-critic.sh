#!/usr/bin/env bash
# story: e45s05
# Adversarial gap-finding completeness critic — post gate-trace.
# Classifications: BLOCKER | WARNING | FILLED
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

BLOCKERS=0
WARNINGS=0
FILLED=0

classify() {
  local kind="$1" msg="$2"
  echo "[$kind] $msg"
  case "$kind" in
    BLOCKER) BLOCKERS=$((BLOCKERS + 1)) ;;
    WARNING) WARNINGS=$((WARNINGS + 1)) ;;
    FILLED) FILLED=$((FILLED + 1)) ;;
  esac
}

# Ensure upstream artifacts exist
[[ -f specs/traceability-matrix.json ]] \
  || classify BLOCKER "Missing specs/traceability-matrix.json — run trace-stories.sh --json"
[[ -f specs/blind-spots.json ]] \
  || classify BLOCKER "Missing specs/blind-spots.json — run check-blind-spots.sh"

if [[ -f specs/traceability-matrix.json ]]; then
  # verify-work runs per-story (build-epic builds one story at a time), so this
  # check must scope to the story currently being verified — not its
  # not-yet-built siblings (which have no code tags by definition until their
  # own turn) and not unrelated epics (which may be plan-worked-to-build-ready
  # but not yet kicked off).
  ACTIVE_STORY="$(grep '^active_story:' specs/state.yaml 2>/dev/null | awk '{print $2}')"
  if [[ -n "$ACTIVE_STORY" ]]; then
    UNDONE="$(jq --arg s "$ACTIVE_STORY" \
      '[.stories[]? | select(.id == $s and .status != "done" and ((.links // []) | map(select(.method == "explicit_tag")) | length) == 0)] | length' \
      specs/traceability-matrix.json 2>/dev/null || echo 0)"
    (( UNDONE > 0 )) && classify BLOCKER "active story $ACTIVE_STORY has zero explicit story-tag links"
  fi
  COVERAGE="$(jq -r '.summary.coverage_percent // .coverage_percent // empty' specs/traceability-matrix.json 2>/dev/null)"
  if [[ -n "$COVERAGE" && "$COVERAGE" != "null" ]]; then
    awk -v c="$COVERAGE" 'BEGIN{if(c+0 < 60) exit 1}' || classify WARNING "Trace coverage ${COVERAGE}% below 60% target"
    awk -v c="$COVERAGE" 'BEGIN{if(c+0 >= 80) exit 0; exit 1}' && classify FILLED "Trace coverage ${COVERAGE}% meets 80% PASS bar"
  fi
fi

if [[ -f specs/blind-spots.json ]]; then
  HIGH="$(jq '[.findings[]? | select(.severity == "HIGH")] | length' specs/blind-spots.json 2>/dev/null || echo 0)"
  (( HIGH > 0 )) && classify BLOCKER "$HIGH HIGH-severity blind-spot finding(s) remain open"
fi

# Verify evidence for done stories
if [[ -d specs/verifications ]]; then
  VC="$(find specs/verifications -maxdepth 1 -name '*-verify.yaml' 2>/dev/null | wc -l | tr -d ' ')"
  (( VC == 0 )) && classify WARNING "No specs/verifications/*-verify.yaml evidence bundles"
  (( VC > 0 )) && classify FILLED "$VC verification evidence bundle(s) on disk"
else
  classify WARNING "specs/verifications/ directory missing"
fi

echo "---"
echo "completeness-critic: BLOCKER=$BLOCKERS WARNING=$WARNINGS FILLED=$FILLED"

if (( BLOCKERS > 0 )); then
  echo "MERGE GATE ABORT: BLOCKER findings must be resolved" >&2
  exit 1
fi

exit 0
