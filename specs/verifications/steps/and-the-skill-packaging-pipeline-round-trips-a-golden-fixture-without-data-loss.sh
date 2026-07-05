#!/usr/bin/env bash
# And the skill packaging pipeline round-trips a golden fixture without data loss
# Reborn-aligned: packaging integrity (not legacy sync-preserves-plus sed regression)
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
mdc="$REPO_ROOT/.cursor/rules/trace-requirement.mdc"
needle='release-plan.yaml + epic'
if [[ ! -f "$mdc" ]]; then
  echo "missing $mdc — run bash scripts/sync-skills.sh"
  exit 1
fi
if ! grep -qF "$needle" "$mdc"; then
  echo "golden fixture missing in $mdc before sync — run bash scripts/sync-skills.sh"
  exit 1
fi
bash "$REPO_ROOT/scripts/sync-skills.sh" >/dev/null
if ! grep -qF "$needle" "$mdc"; then
  echo "packaging pipeline lost golden fixture content after round-trip"
  exit 1
fi
exit 0
