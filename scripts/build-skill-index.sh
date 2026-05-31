#!/usr/bin/env bash
# build-skill-index.sh — lexical index for search-skills (zero embedding deps)
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="$REPO_ROOT/specs/SKILL-SEARCH-INDEX.md"
mkdir -p "$(dirname "$OUT")"

{
  echo "# Skill Search Index (auto-generated)"
  echo ""
  echo "Regenerate: \`bash scripts/build-skill-index.sh\`"
  echo ""
  echo "| name | model | description |"
  echo "|------|-------|-------------|"
  for skill_dir in $(find "$REPO_ROOT" -maxdepth 1 -mindepth 1 -type d | sort); do
    skill_md="$skill_dir/SKILL.md"
    [[ -f "$skill_md" ]] || continue
    name=$(awk '/^---/{f++} f==1 && /^name:/{print; exit}' "$skill_md" | sed 's/^name:[[:space:]]*//')
    model=$(awk '/^---/{f++} f==1 && /^model:/{print; exit}' "$skill_md" | sed 's/^model:[[:space:]]*//')
    desc=$(awk '/^---/{f++} f==1 && /^description:/{p=1} p && !/^---/{print}' "$skill_md" \
      | sed 's/^description:[[:space:]]*//' | tr -d '\n' | sed 's/|/\\|/g' | cut -c1-200)
    [[ -z "$name" ]] && continue
    echo "| $name | ${model:-sonnet} | $desc |"
  done
} > "$OUT"

echo "build-skill-index: wrote $OUT"
