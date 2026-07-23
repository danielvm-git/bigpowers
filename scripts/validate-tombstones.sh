#!/usr/bin/env bash
# story: e53s02
# validate-tombstones.sh — confirm each registered tombstone's stub still
# resolves, and flag any whose one-release expiry window has passed.
#
# Usage: bash scripts/validate-tombstones.sh

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/skill-common.sh"
resolve_repo_root
cd "$REPO_ROOT"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

TOMBSTONES_FILE="specs/tombstones.yaml"
FAIL=0

if [[ ! -f "$TOMBSTONES_FILE" ]]; then
  echo -e "${GREEN}OK${NC}: no tombstones registered"
  exit 0
fi

CURRENT_VERSION=$(grep '"version"' package.json 2>/dev/null | head -1 | sed 's/.*: *"\(.*\)".*/\1/')

ROWS=$(python3 -c "
import yaml
d = yaml.safe_load(open('$TOMBSTONES_FILE')) or {'tombstones': []}
for t in d.get('tombstones', []) or []:
    print(f\"{t['old_name']}\t{t['new_name_or_merge_target']}\t{t.get('created_at_version', '')}\")
")

if [[ -z "$ROWS" ]]; then
  echo -e "${GREEN}OK${NC}: no tombstones registered"
  exit 0
fi

while IFS=$'\t' read -r old_name new_name created_version; do
  [[ -z "$old_name" ]] && continue
  stub="skills/${old_name}/SKILL.md"

  if [[ ! -f "$stub" ]]; then
    echo -e "${RED}FAIL${NC}: ${old_name} -> ${new_name} — stub missing at ${stub}"
    FAIL=1
    continue
  fi
  if ! grep -q "TOMBSTONE" "$stub"; then
    echo -e "${RED}FAIL${NC}: ${old_name} — stub exists but is not a tombstone"
    FAIL=1
    continue
  fi

  if [[ -n "$created_version" && "$created_version" != "$CURRENT_VERSION" ]]; then
    echo -e "${YELLOW}EXPIRED${NC}: ${old_name} -> ${new_name} — created at ${created_version}, now ${CURRENT_VERSION}; remove the stub"
    continue
  fi

  echo -e "${GREEN}OK${NC}: ${old_name} -> ${new_name} resolves"
done <<< "$ROWS"

exit "$FAIL"
