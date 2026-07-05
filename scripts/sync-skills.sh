#!/usr/bin/env bash
# story: e13s03 e28s03
# sync-skills.sh — generate Cursor, Gemini CLI, and pi artifacts from SKILL.md source files
# Architecture: Parse→IR→Render. Each target is its own render_<target>() function.
# Run this after adding or updating any skill. Symlinks carry changes through automatically.
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib/skill-common.sh"

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

# ── IR: shared intermediate representation ──────────────────────────
# These globals are set by the main loop per skill and consumed by render functions.
IR_NAME=""
IR_MODEL=""
IR_DESCRIPTION=""
IR_DESC_ESCAPED=""
IR_BODY=""

# ── build_body ──────────────────────────────────────────────────────
# Builds the concatenated content: SKILL.md body + all other *.md files.
# Args: $1 = path to SKILL.md, $2 = skill directory
build_body() {
  local skill_md="$1"
  local skill_dir="$2"
  local body

  # Strip frontmatter from SKILL.md (content after second ---)
  body=$(awk '/^---/{f++; next} f>=2{print}' "$skill_md")

  # Append extra *.md files alphabetically
  local extra_md
  for extra_md in $(find "$skill_dir" -maxdepth 1 -name "*.md" ! -name "SKILL.md" | LC_ALL=C sort); do
    body="$body"$'\n\n'"---"$'\n\n'"$(cat "$extra_md")"
  done

  # Strip disable-model-invocation lines
  echo "$body" | grep -v 'disable-model-invocation'
}

# ── Render target: Cursor ───────────────────────────────────────────
# Writes .cursor/rules/<name>.mdc with YAML frontmatter + body.
render_cursor() {
  local cursor_file="$CURSOR_RULES/$IR_NAME.mdc"
  {
    echo "---"
    echo "description: \"$IR_DESC_ESCAPED\""
    echo "alwaysApply: false"
    echo "---"
    echo ""
    echo "$IR_BODY"
  } > "$cursor_file"
}

# ── Render target: Gemini Agent Skill ───────────────────────────────
# Writes .gemini/extensions/bigpowers/skills/<name>/SKILL.md
render_gemini_skill() {
  mkdir -p "$GEMINI_SKILLS/$IR_NAME"
  {
    echo "---"
    echo "name: $IR_NAME"
    echo "description: \"$IR_DESC_ESCAPED\""
    echo "---"
    echo ""
    echo "$IR_BODY"
  } > "$GEMINI_SKILLS/$IR_NAME/SKILL.md"
}

# ── Render target: Gemini Slash Command ─────────────────────────────
# Writes .gemini/extensions/bigpowers/commands/<name>.toml + prompt file
render_gemini_command() {
  mkdir -p "$GEMINI_COMMANDS/prompts"
  local prompt_file="commands/prompts/$IR_NAME.md"
  echo "$IR_BODY" > "$GEMINI_EXT_DIR/$prompt_file"
  {
    echo "description = \"$IR_DESC_ESCAPED\""
    echo "prompt = \"@{$prompt_file}\""
  } > "$GEMINI_COMMANDS/$IR_NAME.toml"
}

# ── Render target: pi Agent Skill ───────────────────────────────────
# Writes .pi/skills/<name>/SKILL.md
render_pi_skill() {
  mkdir -p "$PI_SKILLS/$IR_NAME"
  {
    echo "---"
    echo "name: $IR_NAME"
    echo "description: \"$IR_DESC_ESCAPED\""
    [[ -n "$IR_MODEL" ]] && echo "model: $IR_MODEL"
    echo "---"
    echo ""
    echo "$IR_BODY"
  } > "$PI_SKILLS/$IR_NAME/SKILL.md"
}

# ── Render target: pi Prompt Template ───────────────────────────────
# Writes .pi/prompts/<name>.md
render_pi_prompt() {
  {
    echo "---"
    echo "description: $IR_DESCRIPTION"
    echo "---"
    echo ""
    echo "$IR_BODY"
  } > "$PI_PROMPTS/$IR_NAME.md"
}

# ── Target registry ─────────────────────────────────────────────────
# Order matters: render functions are called in this order per skill.
TARGETS=(render_cursor render_gemini_skill render_gemini_command render_pi_skill render_pi_prompt)

skill_count=0

# ── Main loop: Parse → IR → Render per skill ────────────────────────
while IFS= read -r skill_dir; do
  skill_md="$skill_dir/SKILL.md"

  parse_frontmatter "$skill_md" || continue

  IR_NAME="$_PF_NAME"
  IR_MODEL="$_PF_MODEL"
  IR_DESCRIPTION="$_PF_DESCRIPTION"

  # Escape double quotes and backslashes for safe double-quoted YAML output
  IR_DESC_ESCAPED=$(echo "$IR_DESCRIPTION" | sed 's/\\/\\\\/g; s/"/\\"/g')

  [[ -z "$IR_NAME" ]] && continue

  IR_BODY=$(build_body "$skill_md" "$skill_dir")

  # Dispatch to each render target
  for target_fn in "${TARGETS[@]}"; do
    "$target_fn"
  done

  skill_count=$((skill_count + 1))
done < <(iterate_skills)

# ── Post-loop: manifest, opencode, regeneration, guards, README badge ──

# Assemble final gemini-extension.json
pkg_version=$(jq -r '.version' "$REPO_ROOT/package.json")
pkg_desc=$(jq -r '.description' "$REPO_ROOT/package.json")

jq -n --arg name "bigpowers" \
      --arg version "$pkg_version" \
      --arg desc "${skill_count} skills — ${pkg_desc}" \
      '{name: $name, version: $version, description: $desc}' > "$GEMINI_MANIFEST"

# Write pi package config: .pi/package.json
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

# Write OpenCode configuration: opencode.json
{
  echo "{"
  echo "  \"\$schema\": \"https://opencode.ai/config.json\","
  echo "  \"instructions\": [\"CLAUDE.md\", \"CONVENTIONS.md\"]"
  echo "}"
} > "$REPO_ROOT/opencode.json"

# Sync to bigpowers-opencode repo (if --opencode path is provided)
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
  for skill_dir in "$SKILLS_ROOT"/*/; do
    skill_md="$skill_dir/SKILL.md"
    [[ -f "$skill_md" ]] || continue
    skill_name=$(basename "$skill_dir")
    mkdir -p "$OPN_SKILLS/$skill_name"
    cp "$skill_md" "$OPN_SKILLS/$skill_name/SKILL.md"
    opencode_count=$((opencode_count + 1))
  done
  echo "  → $opencode_count skills copied to $OPN_SKILLS/"
fi

# Regenerate skills-lock.json catalog
if [[ -x "$REPO_ROOT/scripts/regenerate-lockfile.sh" ]]; then
  bash "$REPO_ROOT/scripts/regenerate-lockfile.sh" || { echo "sync-skills: FAIL — lockfile regeneration failed" >&2; exit 1; }
fi

# Regenerate SKILL-INDEX.md from lockfile + frontmatter
if [[ -x "$REPO_ROOT/scripts/generate-skill-index.sh" ]]; then
  bash "$REPO_ROOT/scripts/generate-skill-index.sh" || { echo "sync-skills: FAIL — SKILL-INDEX.md generation failed" >&2; exit 1; }
fi

# Regenerate lexical skill index for search-skills
if [[ -x "$REPO_ROOT/scripts/build-skill-index.sh" ]]; then
  bash "$REPO_ROOT/scripts/build-skill-index.sh" || true
fi

# Prune orphan cursor rules
CURSOR_KEEP="context7.mdc"
for mdc in "$CURSOR_RULES"/*.mdc; do
  [[ -e "$mdc" ]] || continue
  mdc_base=$(basename "$mdc")
  case " $CURSOR_KEEP " in *" $mdc_base "*) continue ;; esac
  if [[ ! -f "$SKILLS_ROOT/${mdc_base%.mdc}/SKILL.md" ]]; then
    rm "$mdc"
    echo "  → pruned orphan cursor rule: $mdc_base"
  fi
done

# Stamp the README skill-count badge
readme="$REPO_ROOT/README.md"
if [[ -f "$readme" ]] && grep -q 'badge/skills-' "$readme"; then
  readme_tmp=$(mktemp)
  sed -E "s|(badge/skills-)[0-9]+(-brightgreen)|\1${skill_count}\2|" "$readme" > "$readme_tmp"
  mv "$readme_tmp" "$readme"
fi

echo "sync-skills: $skill_count skills synced"
echo "  → .cursor/rules/ ($skill_count .mdc files)"
echo "  → .gemini/extensions/bigpowers/skills/ (Agent Skills)"
echo "  → .gemini/extensions/bigpowers/commands/ (Slash Commands)"
echo "  → .gemini/extensions/bigpowers/gemini-extension.json"
echo "  → .pi/skills/ ($skill_count skill dirs — pi Agent Skills)"
echo "  → .pi/prompts/ ($skill_count prompt templates — pi slash commands)"
echo "  → .pi/package.json (pi package manifest)"
echo "  → skills-lock.json (catalog with SHA-256 hashes)"
echo "  → SKILL-INDEX.md (auto-generated skill reference)"
echo "  → opencode.json (CLAUDE.md + CONVENTIONS.md instructions)"
[[ -n "$OPN_TARGET" ]] && echo "  → bigpowers-opencode: $opencode_count skills"

# Regression guard (BUG-2026-06-02T164500)
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

# Regression guard (BUG-2026-06-18T100000): validate generated YAML frontmatter
validate_script="$REPO_ROOT/scripts/validate-skill-yaml.py"
if [[ -f "$validate_script" ]] && command -v python3 &>/dev/null; then
  if ! python3 "$validate_script" > /dev/null 2>&1; then
    echo "sync-skills: FAIL — YAML frontmatter validation failed" >&2
    python3 "$validate_script" >&2
    exit 1
  fi
fi

# Regression guard (BUG-2026-07-02T103911): no bash 4+ features
if grep -rn '^declare -A\|^[[:space:]]*declare -A' scripts/sync-skills.sh scripts/generate-skill-index.sh scripts/regenerate-lockfile.sh scripts/build-skill-index.sh 2>/dev/null; then
  echo "sync-skills: FAIL — bash 4+ features detected in install-chain scripts (not macOS-compatible)" >&2
  exit 1
fi

# Regenerate derived reference tables
if [[ -d "$REPO_ROOT/.git" ]]; then
  bash "$REPO_ROOT/scripts/generate-reference-tables.sh"
fi

exit 0
