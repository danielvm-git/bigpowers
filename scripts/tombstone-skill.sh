#!/usr/bin/env bash
# story: e53s02
# tombstone-skill.sh — replace a renamed/merged skill's SKILL.md with a stub,
# preserving its story tags and registering the mapping in specs/tombstones.yaml
# for a one-release expiry window.
#
# Usage: bash scripts/tombstone-skill.sh <old-name> <new-name-or-merge-target>

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/skill-common.sh"
resolve_repo_root
cd "$REPO_ROOT"

usage() {
  cat <<'EOF'
Usage: tombstone-skill.sh <old-name> <new-name-or-merge-target>

Replaces skills/<old-name>/SKILL.md with a stub pointing at <new-name>,
preserves the old name's story tags, and registers the mapping in
specs/tombstones.yaml with a one-release expiry window.
EOF
}

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  usage
  exit 0
fi

OLD_NAME="${1:-}"
NEW_NAME="${2:-}"
NAME_PATTERN='^[a-z][a-z0-9-]*$'

if [[ -z "$OLD_NAME" || -z "$NEW_NAME" ]]; then
  usage >&2
  exit 1
fi

# Threat-model mitigation (specs/security/epics/e53/THREAT_MODEL.md): reject
# anything that isn't a bare kebab-case skill name before any path use.
for name in "$OLD_NAME" "$NEW_NAME"; do
  if [[ ! "$name" =~ $NAME_PATTERN ]]; then
    echo "ERROR: '$name' is not a valid skill name (must match $NAME_PATTERN)" >&2
    exit 1
  fi
done

OLD_SKILL_MD="skills/${OLD_NAME}/SKILL.md"
if [[ ! -f "$OLD_SKILL_MD" ]]; then
  echo "ERROR: $OLD_SKILL_MD does not exist" >&2
  exit 1
fi

STORY_TAGS=$(grep -E '^#\s*story:' "$OLD_SKILL_MD" || true)
CURRENT_VERSION=$(jq -r '.version' package.json 2>/dev/null)
CREATED_AT=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# A tombstone is still a live SKILL.md for its transition window, so it must
# carry the same required frontmatter as any other skill. Omitting `model:`
# made docs/references/model-profiles.md count one fewer skill than there are
# skill directories, which fails validate-doctrine's skill-count check.
cat > "$OLD_SKILL_MD" <<STUBEOF
---
name: ${OLD_NAME}
model: haiku
effort: light
description: "TOMBSTONE — renamed/merged to ${NEW_NAME}. This stub resolves for one release then is removed."
---

# ${OLD_NAME} (tombstoned)

This skill has been renamed or merged into \`${NEW_NAME}\`. Use \`${NEW_NAME}\` instead.

This stub exists for one release as a transition aid, then is removed once
\`scripts/validate-tombstones.sh\` flags it as expired.

${STORY_TAGS}
STUBEOF

TOMBSTONES_FILE="specs/tombstones.yaml"
[[ -f "$TOMBSTONES_FILE" ]] || echo "tombstones: []" > "$TOMBSTONES_FILE"

# Values flow through the environment, never interpolated into the python
# source string — string-interpolating shell variables into `python3 -c`
# turns any unvalidated field (e.g. CURRENT_VERSION, sourced from
# package.json) into a code-injection vector.
TOMBSTONE_FILE="$TOMBSTONES_FILE" \
TOMBSTONE_OLD_NAME="$OLD_NAME" \
TOMBSTONE_NEW_NAME="$NEW_NAME" \
TOMBSTONE_CREATED_AT="$CREATED_AT" \
TOMBSTONE_VERSION="$CURRENT_VERSION" \
python3 -c "
import os
import yaml
path = os.environ['TOMBSTONE_FILE']
d = yaml.safe_load(open(path)) or {'tombstones': []}
d.setdefault('tombstones', []).append({
    'old_name': os.environ['TOMBSTONE_OLD_NAME'],
    'new_name_or_merge_target': os.environ['TOMBSTONE_NEW_NAME'],
    'created_at': os.environ['TOMBSTONE_CREATED_AT'],
    'created_at_version': os.environ['TOMBSTONE_VERSION'],
})
yaml.dump(d, open(path, 'w'), default_flow_style=False)
"

echo "Tombstoned: ${OLD_NAME} -> ${NEW_NAME}"
echo "Registered in ${TOMBSTONES_FILE}"
