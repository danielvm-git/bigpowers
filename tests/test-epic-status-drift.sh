#!/usr/bin/env bash
# story: BUG-001
# Regression test: epic.yaml status matches execution-status.yaml for completed epics
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
EXEC_STATUS="$REPO_ROOT/specs/execution-status.yaml"
EPICS_ROOT="$REPO_ROOT/specs/epics"

if [[ ! -f "$EXEC_STATUS" ]]; then
  echo "FAIL: missing $EXEC_STATUS"
  exit 1
fi

FAILURES=0

while IFS= read -r line; do
  [[ "$line" =~ ^[[:space:]]*(e[0-9]+):[[:space:]]*done[[:space:]]*$ ]] || continue
  epic_id="${BASH_REMATCH[1]}"

  # e37 is redesigned as Reach — execution-status may say done while capsule stays planned
  [[ "$epic_id" == "e37" ]] && continue

  epic_yaml=""
  for candidate in \
    "$EPICS_ROOT/$epic_id"*/epic.yaml \
    "$EPICS_ROOT/archive/$epic_id"*/epic.yaml; do
    if [[ -f "$candidate" ]]; then
      epic_yaml="$candidate"
      break
    fi
  done

  if [[ -z "$epic_yaml" ]]; then
    echo "WARN: no epic.yaml found for $epic_id (execution-status: done)"
    continue
  fi

  yaml_status="$(grep -m1 '^status:' "$epic_yaml" | sed 's/^status:[[:space:]]*//' | tr -d '"')"
  if [[ "$yaml_status" != "done" ]]; then
    echo "FAIL: $epic_id epic.yaml status='$yaml_status' but execution-status.yaml says done ($epic_yaml)"
    FAILURES=$((FAILURES + 1))
  fi
done < "$EXEC_STATUS"

if [[ "$FAILURES" -gt 0 ]]; then
  echo "FAIL: $FAILURES epic status drift(s)"
  exit 1
fi

echo "PASS: epic.yaml status aligned with execution-status for completed epics"
exit 0
