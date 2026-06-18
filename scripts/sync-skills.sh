#!/usr/bin/env bash
# sync-skills.sh — generate Cursor, Gemini CLI, and pi artifacts from SKILL.md source files
# Run this after adding or updating any skill. Symlinks carry changes through automatically.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CURSOR_RULES="$REPO_ROOT/.cursor/rules"
GEMINI_EXT_DIR="$REPO_ROOT/.gemini/extensions/bigpowers"
GEMINI_SKILLS="$GEMINI_EXT_DIR/skills"
GEMINI_COMMANDS="$GEMINI_EXT_DIR/commands"
GEMINI_MANIFEST="$GEMINI_EXT_DIR/gemini-extension.json"
PI_SKILLS="$REPO_ROOT/.pi/skills"
PI_PROMPTS="$REPO_ROOT/.pi/prompts"
PI_PACKAGE_JSON="$REPO_ROOT/.pi/package.json"

mkdir -p "$CURSOR_RULES" "$GEMINI_SKILLS" "$GEMINI_COMMANDS" "$PI_SKILLS" "$PI_PROMPTS"

# Clear old artifacts to ensure a clean sync
rm -rf "${GEMINI_SKILLS:?}"/*
rm -rf "${GEMINI_COMMANDS:?}"/*
rm -rf "${PI_SKILLS:?}"/*
rm -rf "${PI_PROMPTS:?}"/*

# We'll collect metadata for the manifest if needed, 
# though skills/commands are auto-discovered.
# Manifest is still good for extension-level name/version.

skill_count=0

for skill_dir in "$REPO_ROOT"/*/; do
  skill_md="$skill_dir/SKILL.md"
  [[ -f "$skill_md" ]] || continue

  # Extract name and description from YAML frontmatter
  name=$(awk '/^---/{f++} f==1 && /^name:/{print; exit}' "$skill_md" | sed 's/^name:[[:space:]]*//')
  description=$(awk '/^---/{f++} f==1 && /^description:/{p=1} p && !/^---/{print} f==2{exit}' "$skill_md" \
    | sed 's/^description:[[:space:]]*//' \
    | tr -d '\n' \
    | sed -E 's/[[:space:]]+/ /g')

  [[ -z "$name" ]] && continue

  # Build concatenated content: SKILL.md body + all other *.md files alphabetically
  # Strip frontmatter from SKILL.md (content between second --- and EOF)
  body=$(awk '/^---/{f++; next} f>=2{print}' "$skill_md")

  for extra_md in $(find "$skill_dir" -maxdepth 1 -name "*.md" ! -name "SKILL.md" | sort); do
    body="$body"$'\n\n'"---"$'\n\n'"$(cat "$extra_md")"
  done

  # Strip disable-model-invocation lines
  body=$(echo "$body" | grep -v 'disable-model-invocation')

  # 1. Write .cursor/rules/<name>.mdc
  cursor_file="$CURSOR_RULES/$name.mdc"
  {
    echo "---"
    echo "description: \"$description\""
    echo "alwaysApply: false"
    echo "---"
    echo ""
    echo "$body"
  } > "$cursor_file"

  # 2. Write Gemini Agent Skill: .gemini/extensions/bigpowers/skills/<name>/SKILL.md
  mkdir -p "$GEMINI_SKILLS/$name"
  {
    echo "---"
    echo "name: $name"
    echo "description: \"$description\""
    echo "---"
    echo ""
    echo "$body"
  } > "$GEMINI_SKILLS/$name/SKILL.md"

  # 3. Write Gemini Slash Command: .gemini/extensions/bigpowers/commands/<name>.toml
  # We use a dedicated prompt file to keep the TOML clean
  mkdir -p "$GEMINI_COMMANDS/prompts"
  prompt_file="commands/prompts/$name.md"
  echo "$body" > "$GEMINI_EXT_DIR/$prompt_file"
  
  # Escape double quotes and backslashes for TOML
  description_toml=$(echo "$description" | sed 's/\\/\\\\/g; s/"/\\"/g')
  
  {
    echo "description = \"$description_toml\""
    echo "prompt = \"@{$prompt_file}\""
  } > "$GEMINI_COMMANDS/$name.toml"

  # 4. Write pi skill: .pi/skills/<name>/SKILL.md
  # Pi implements the Agent Skills standard — same YAML frontmatter + body format
  mkdir -p "$PI_SKILLS/$name"
  {
    echo "---"
    echo "name: $name"
    echo "description: \"$description\""
    echo "---"
    echo ""
    echo "$body"
  } > "$PI_SKILLS/$name/SKILL.md"

  # 5. Write pi prompt template: .pi/prompts/<name>.md
  # Slash-command templates expandable via /<name> in pi's editor
  {
    echo "---"
    echo "description: $description"
    echo "---"
    echo ""
    echo "$body"
  } > "$PI_PROMPTS/$name.md"

  skill_count=$((skill_count + 1))
done

# Assemble final gemini-extension.json (top-level fields only — not scripts.version)
pkg_version=$(jq -r '.version' "$REPO_ROOT/package.json")
pkg_desc=$(jq -r '.description' "$REPO_ROOT/package.json")

jq -n --arg name "bigpowers" \
      --arg version "$pkg_version" \
      --arg desc "${skill_count} skills — ${pkg_desc}" \
      '{name: $name, version: $version, description: $desc}' > "$GEMINI_MANIFEST"

# 6. Write pi package config: .pi/package.json
# Enables pi install (local path, npm, or git) with auto-discovered skills and prompts
jq -n --arg version "$pkg_version" \
      --arg desc "${skill_count} skills — ${pkg_desc}" \
      '{
        "name": "bigpowers",
        "version": $version,
        "description": $desc,
        "keywords": ["pi-package"],
        "pi": {
          "skills": ["./skills"],
          "prompts": ["./prompts"]
        }
      }' > "$PI_PACKAGE_JSON"

# 7. Write OpenCode configuration: opencode.json (minimal project-level config)
# Skills are loaded on-demand via opencode's native skill tool, not instructions.
# Full opencode integration lives in the bigpowers-opencode repo.
{
  echo "{"
  echo "  \"\$schema\": \"https://opencode.ai/config.json\","
  echo "  \"instructions\": [\"CLAUDE.md\", \"CONVENTIONS.md\"]"
  echo "}"
} > "$REPO_ROOT/opencode.json"

# 5. Sync to bigpowers-opencode repo (if --opencode path is provided)
OPN_TARGET=""
for arg in "$@"; do
  case "$arg" in
    --opencode=*) OPN_TARGET="${arg#*=}" ;;
    --opencode)   shift; OPN_TARGET="$1" ;;
  esac
done

if [[ -n "$OPN_TARGET" ]] && [[ -d "$OPN_TARGET" ]]; then
  echo ""
  echo "Syncing skills to opencode repo: $OPN_TARGET"
  OPN_SKILLS="$OPN_TARGET/skills"
  mkdir -p "$OPN_SKILLS"
  opencode_count=0
  for skill_dir in "$REPO_ROOT"/*/; do
    skill_md="$skill_dir/SKILL.md"
    [[ -f "$skill_md" ]] || continue
    skill_name=$(basename "$skill_dir")
    mkdir -p "$OPN_SKILLS/$skill_name"
    cp "$skill_md" "$OPN_SKILLS/$skill_name/SKILL.md"
    opencode_count=$((opencode_count + 1))
  done
  echo "  → $opencode_count skills copied to $OPN_SKILLS/"
fi

# Regenerate lexical skill index for search-skills
if [[ -x "$REPO_ROOT/scripts/build-skill-index.sh" ]]; then
  bash "$REPO_ROOT/scripts/build-skill-index.sh" || true
fi

echo "sync-skills: $skill_count skills synced"
echo "  → .cursor/rules/ ($skill_count .mdc files)"
echo "  → .gemini/extensions/bigpowers/skills/ (Agent Skills)"
echo "  → .gemini/extensions/bigpowers/commands/ (Slash Commands)"
echo "  → .gemini/extensions/bigpowers/gemini-extension.json"
echo "  → .pi/skills/ ($skill_count skill dirs — pi Agent Skills)"
echo "  → .pi/prompts/ ($skill_count prompt templates — pi slash commands)"
echo "  → .pi/package.json (pi package manifest)"
echo "  → opencode.json (CLAUDE.md + CONVENTIONS.md instructions)"
[[ -n "$OPN_TARGET" ]] && echo "  → bigpowers-opencode: $opencode_count skills"

# Regression guard (BUG-2026-06-02T164500): BSD sed without -E strips '+' from descriptions
trace_mdc="$REPO_ROOT/.cursor/rules/trace-requirement.mdc"
if [[ -f "$trace_mdc" ]] && ! grep -q 'release-plan.yaml + epic' "$trace_mdc"; then
  echo "sync-skills: FAIL — '+' missing from trace-requirement; use sed -E for whitespace collapse" >&2
  exit 1
fi
manifest="$REPO_ROOT/.gemini/extensions/bigpowers/gemini-extension.json"
if [[ -f "$manifest" ]]; then
  ext_ver=$(jq -r '.version // empty' "$manifest")
  pkg_ver=$(jq -r '.version // empty' "$REPO_ROOT/package.json")
  if [[ -z "$ext_ver" || -z "$pkg_ver" ]]; then
    : # skip version compare when either field is missing
  elif [[ "$ext_ver" != "$pkg_ver" ]]; then
    echo "sync-skills: FAIL — gemini-extension.json version ($ext_ver) != package.json ($pkg_ver)" >&2
    exit 1
  fi
fi

# Regenerate derived reference tables from live SKILL.md frontmatter
bash "$REPO_ROOT/scripts/generate-reference-tables.sh"

exit 0
