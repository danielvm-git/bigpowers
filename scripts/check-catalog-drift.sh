#!/usr/bin/env bash
# story: e54s02
# story: e83s04
# check-catalog-drift.sh — advisory (Confirm-gate) diff of the live skill
# catalog against e54s01's frozen baseline. ALWAYS exits 0: this warns during
# the freeze window, it never blocks Preflight (never add to GOLDEN_GATES).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/skill-common.sh"
source "$SCRIPT_DIR/lib/python-env.sh"

resolve_repo_root
cd "$REPO_ROOT"

BASELINE="$(ls -1 "$REPO_ROOT"/specs/tech-architecture/CATALOG-BASELINE-*.yaml 2>/dev/null | sort | tail -1 || true)"

if [[ -z "$BASELINE" ]]; then
  echo "no baseline found, skipping drift check"
  exit 0
fi

"$PYTHON" "$SCRIPT_DIR/lib/check-catalog-drift.py" "$BASELINE" "$SKILLS_ROOT" </dev/null

exit 0
