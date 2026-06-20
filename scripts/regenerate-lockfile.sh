#!/usr/bin/env bash
# regenerate-lockfile.sh — Scan all SKILL.md files and regenerate skills-lock.json
# Output: Canonical catalog with name, description, sha256, path for every skill.
# Run this after adding, removing, or updating any skill.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOCKFILE="$REPO_ROOT/skills-lock.json"

# Build JSON using jq from individual skill records
# We pipe each skill as a JSON object, then jq -s merges them into an object keyed by name
records=()
for skill_dir in "$REPO_ROOT"/*/; do
  skill_md="$skill_dir/SKILL.md"
  [[ -f "$skill_md" ]] || continue

  name=$(basename "$skill_dir")
  # Extract description from YAML frontmatter (between first --- and second ---)
  description=$(awk '/^---/{f++; next} f==1 && /^description:/{p=1; sub(/^description:[[:space:]]*/,""); print; next} f==1 && p && /^[a-z]+:/{exit} f==1 && p{print}' "$skill_md" \
    | tr -d '\n' | sed -E 's/[[:space:]]+/ /g')

  # Compute SHA-256 of full SKILL.md content (first 16 hex chars for compact uniqueness)
  sha256=$(sha256sum "$skill_md" | cut -c1-16)

  # Relative path from repo root
  relpath="${skill_dir#$REPO_ROOT/}SKILL.md"

  # Emit JSON record for this skill
  records+=("$(jq -n --arg name "$name" \
                       --arg desc "$description" \
                       --arg sha "$sha256" \
                       --arg path "$relpath" \
    '{($name): {description: $desc, sha256: $sha, path: $path}}')")
done

# Merge all records into a single "skills" object with version
jq -n --argjson skills "$(printf '%s\n' "${records[@]}" | jq -s 'add')" \
  '{version: 1, skills: $skills}' > "$LOCKFILE"

count=$(jq '.skills | length' "$LOCKFILE")
echo "regenerate-lockfile: $count skills written to skills-lock.json"
