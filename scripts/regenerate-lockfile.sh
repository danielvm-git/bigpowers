#!/usr/bin/env bash
# story: e28s04
# regenerate-lockfile.sh — Scan all SKILL.md files and regenerate skills-lock.json
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/skill-common.sh"
LOCKFILE="$REPO_ROOT/skills-lock.json"
records=()
while IFS= read -r skill_dir; do
  skill_md="$skill_dir/SKILL.md"
  name=$(basename "$skill_dir")
  parse_frontmatter "$skill_md" || continue
  description="$_PF_DESCRIPTION"
  if command -v sha256sum &>/dev/null; then sha256=$(sha256sum "$skill_md" | cut -c1-16)
  else sha256=$(shasum -a 256 "$skill_md" | cut -c1-16); fi
  relpath="${skill_dir#$REPO_ROOT/}SKILL.md"
  records+=("$(jq -n --arg name "$name" --arg desc "$description" --arg sha "$sha256" --arg path "$relpath" \
    '{($name): {description: $desc, sha256: $sha, path: $path}}')")
done < <(iterate_skills)
jq -n --argjson skills "$(printf '%s\n' "${records[@]}" | jq -s 'add')" '{version: 1, skills: $skills}' > "$LOCKFILE"
count=$(jq '.skills | length' "$LOCKFILE")
echo "regenerate-lockfile: $count skills written to skills-lock.json"
