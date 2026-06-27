#!/usr/bin/env bash
# Regenerates the auto-generated catalog section in docs/references/model-profiles.md
# from live */SKILL.md frontmatter. Run after any SKILL.md addition/rename.
# Called by sync-skills.sh and npm version hooks.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TARGET="$REPO_ROOT/docs/references/model-profiles.md"
mkdir -p "$(dirname "$TARGET")"

cd "$REPO_ROOT"

# --- 1. Collect live skill→model pairs ---
declare -a ROWS=()
while IFS= read -r line; do
  skill_dir="${line%%/SKILL.md*}"
  model_raw="${line##*model: }"
  model="${model_raw// /}"
  ROWS+=("$skill_dir $model")
done < <(grep -r "^model:" */SKILL.md | sort)

TOTAL=${#ROWS[@]}

# --- 2. Build replacement block ---
BLOCK="<!-- AUTO-GENERATED-CATALOG: begin — do not edit manually; run scripts/generate-reference-tables.sh -->
| Skill | Model |
|-------|-------|"
for row in "${ROWS[@]}"; do
  skill="${row%% *}"
  model="${row##* }"
  # capitalise first letter for display
  model_cap="$(echo "${model:0:1}" | tr '[:lower:]' '[:upper:]')${model:1}"
  BLOCK+="
| \`$skill\` | **$model_cap** |"
done
BLOCK+="

Total: **$TOTAL** skills — verify with \`ls -d \*/SKILL.md | wc -l\`
<!-- AUTO-GENERATED-CATALOG: end -->"

# --- 3. Splice block into target file ---
# Replace between marker comments if they exist; otherwise append.
if grep -q "AUTO-GENERATED-CATALOG: begin" "$TARGET"; then
  python3 - "$TARGET" "$BLOCK" <<'PYEOF'
import sys, re
path = sys.argv[1]
block = sys.argv[2]
text = open(path).read()
new_text = re.sub(
    r'<!-- AUTO-GENERATED-CATALOG: begin.*?<!-- AUTO-GENERATED-CATALOG: end -->',
    block,
    text,
    flags=re.DOTALL
)
open(path, 'w').write(new_text)
PYEOF
else
  printf '\n\n## Full Skill Catalog (auto-generated)\n\n%s\n' "$BLOCK" >> "$TARGET"
fi

# --- 4. Update the "expect N" count assertion (legacy line) ---
# Replaces "expect NN" with the live count so the prose stays accurate.
sed -i.bak "s/expect [0-9]*/expect $TOTAL/" "$TARGET" && rm -f "${TARGET}.bak"

echo "generate-reference-tables: updated $TARGET ($TOTAL skills)"
