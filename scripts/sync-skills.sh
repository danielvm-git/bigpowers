#!/usr/bin/env bash
# sync-skills.sh — generate Cursor and Gemini CLI artifacts from SKILL.md source files
# Run this after adding or updating any skill. Symlinks carry changes through automatically.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CURSOR_RULES="$REPO_ROOT/.cursor/rules"
GEMINI_COMMANDS="$REPO_ROOT/.gemini/extensions/bigpowers/commands"
GEMINI_EXT="$REPO_ROOT/.gemini/extensions/bigpowers/gemini_extension.yaml"

mkdir -p "$CURSOR_RULES" "$GEMINI_COMMANDS"

# Start fresh gemini_extension.yaml
cat > "$GEMINI_EXT" <<'YAML_HEADER'
name: bigpowers
version: 1.0.0
description: "37 agent skills for production-ready, TDD-driven software by solo developers"
commands:
YAML_HEADER

skill_count=0

for skill_dir in "$REPO_ROOT"/*/; do
  skill_md="$skill_dir/SKILL.md"
  [[ -f "$skill_md" ]] || continue

  # Extract name and description from YAML frontmatter
  name=$(awk '/^---/{f++} f==1 && /^name:/{print; exit}' "$skill_md" | sed 's/^name:[[:space:]]*//')
  description=$(awk '/^---/{f++} f==1 && /^description:/{p=1} p && !/^---/{print} f==2{exit}' "$skill_md" \
    | sed 's/^description:[[:space:]]*//' \
    | tr -d '\n' \
    | sed 's/[[:space:]]\+/ /g')

  [[ -z "$name" ]] && continue

  # Build concatenated content: SKILL.md body + all other *.md files alphabetically
  body=""
  # Strip frontmatter from SKILL.md (content between second --- and EOF)
  skill_body=$(awk '/^---/{f++; next} f>=2{print}' "$skill_md")
  body="$skill_body"

  for extra_md in $(find "$skill_dir" -maxdepth 1 -name "*.md" ! -name "SKILL.md" | sort); do
    body="$body"$'\n\n'"---"$'\n\n'"$(cat "$extra_md")"
  done

  # Strip disable-model-invocation lines
  body=$(echo "$body" | grep -v 'disable-model-invocation')

  # Write .cursor/rules/<name>.mdc
  cursor_file="$CURSOR_RULES/$name.mdc"
  {
    echo "---"
    echo "description: \"$description\""
    echo "alwaysApply: false"
    echo "---"
    echo ""
    echo "$body"
  } > "$cursor_file"

  # Write .gemini/extensions/bigpowers/commands/<name>.md
  echo "$body" > "$GEMINI_COMMANDS/$name.md"

  # Append to gemini_extension.yaml
  {
    echo "  - name: $name"
    echo "    description: \"$description\""
    echo "    prompt_file: commands/$name.md"
  } >> "$GEMINI_EXT"

  skill_count=$((skill_count + 1))
done

echo "sync-skills: $skill_count skills synced"
echo "  → .cursor/rules/ ($skill_count .mdc files)"
echo "  → .gemini/extensions/bigpowers/commands/ ($skill_count .md files)"
echo "  → .gemini/extensions/bigpowers/gemini_extension.yaml"
