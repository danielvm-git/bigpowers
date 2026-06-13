#!/usr/bin/env bash
# Regression: sync-skills must not strip '+' from skill descriptions (BUG-2026-06-02T164500)
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
mdc="$REPO_ROOT/.cursor/rules/trace-requirement.mdc"
if [[ ! -f "$mdc" ]]; then
  echo "missing $mdc — run bash scripts/sync-skills.sh"
  exit 1
fi
if ! grep -q 'release-plan.yaml + epic' "$mdc"; then
  echo "trace-requirement.mdc missing 'release-plan.yaml + epic' (sed regression)"
  exit 1
fi
bash "$REPO_ROOT/scripts/sync-skills.sh" >/dev/null
if ! grep -q 'release-plan.yaml + epic' "$mdc"; then
  echo "sync-skills.sh stripped '+' after regeneration"
  exit 1
fi
exit 0
