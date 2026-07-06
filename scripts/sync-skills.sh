#!/usr/bin/env bash
# story: e13s03 e28s03 e39s04
# sync-skills.sh — generate Cursor, Gemini CLI, pi, and OKF artifacts from SKILL.md source files
# Architecture: Parse→IR→Render. Each target is its own render_<target>() function.
# Run this after adding or updating any skill. Symlinks carry changes through automatically.
#
# Flags:
#   --okf          Generate specs/skills-wiki/ OKF concept bundle from SKILL.md frontmatter
#   --opencode <p> Sync to bigpowers-opencode repo
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/python-env.sh"

OKF_MODE=0
OPN_TARGET=""

for arg in "$@"; do
  case "$arg" in
    --okf) OKF_MODE=1 ;;
    --opencode=*) OPN_TARGET="${arg#*=}" ;;
    --opencode) shift; OPN_TARGET="$1" ;;
    --help|-h)
      echo "Usage: sync-skills.sh [--okf] [--opencode <path>]"
      echo ""
      echo "  --okf        Generate specs/skills-wiki/ OKF concept bundle"
      echo "  --opencode   Sync skills to bigpowers-opencode repo"
      echo "  --help       Show this message"
      exit 0
      ;;
    *) echo "sync-skills: unknown flag: $arg" >&2; exit 2 ;;
  esac
done

_LIB_DIR="$(dirname "${BASH_SOURCE[0]}")/lib"
source "$_LIB_DIR/skill-common.sh"
source "$_LIB_DIR/sync-render.sh"
source "$_LIB_DIR/sync-post.sh"
resolve_repo_root

CURSOR_RULES="$REPO_ROOT/.cursor/rules"
GEMINI_EXT_DIR="$REPO_ROOT/.gemini/extensions/bigpowers"
GEMINI_SKILLS="$GEMINI_EXT_DIR/skills"
GEMINI_COMMANDS="$GEMINI_EXT_DIR/commands"
GEMINI_MANIFEST="$GEMINI_EXT_DIR/gemini-extension.json"
PI_SKILLS="$REPO_ROOT/.pi/skills"
PI_PROMPTS="$REPO_ROOT/.pi/prompts"
PI_PACKAGE_JSON="$REPO_ROOT/.pi/package.json"
OKF_WIKI_SKILLS="$REPO_ROOT/specs/skills-wiki/skills"
OKF_WIKI_DIR="$REPO_ROOT/specs/skills-wiki"

mkdir -p "$CURSOR_RULES" "$GEMINI_SKILLS" "$GEMINI_COMMANDS" "$PI_SKILLS" "$PI_PROMPTS"
rm -rf "${GEMINI_SKILLS:?}"/* "${GEMINI_COMMANDS:?}"/* "${PI_SKILLS:?}"/* "${PI_PROMPTS:?}"/*

IR_NAME="" IR_MODEL="" IR_DESCRIPTION="" IR_DESC_ESCAPED="" IR_BODY=""

TARGETS_FILE="$REPO_ROOT/scripts/targets.yaml"
SKILL_ADAPTERS=()
if [[ -f "$TARGETS_FILE" ]] && command -v yq >/dev/null 2>&1; then
  bash "$REPO_ROOT/scripts/validate-targets-yaml.sh" >/dev/null
  while IFS= read -r adapter; do
    [[ -n "$adapter" && "$adapter" != "null" ]] && SKILL_ADAPTERS+=("$adapter")
  done < <(yq -r '.targets[] | select(.skill != null) | .skill.adapter' "$TARGETS_FILE" | sort -u)
else
  echo "sync-skills: WARN — targets.yaml missing; using legacy render list" >&2
  SKILL_ADAPTERS=(cursor gemini pi)
fi

skill_count=0
while IFS= read -r skill_dir; do
  skill_md="$skill_dir/SKILL.md"

  if [[ "$OKF_MODE" -eq 1 ]]; then
    parse_frontmatter_okf "$skill_md" || continue
  else
    parse_frontmatter "$skill_md" || continue
  fi

  IR_NAME="$_PF_NAME"
  IR_MODEL="$_PF_MODEL"
  IR_DESCRIPTION="$_PF_DESCRIPTION"
  IR_DESC_ESCAPED=$(echo "$IR_DESCRIPTION" | sed 's/\\/\\\\/g; s/\"/\\"/g')
  [[ -z "$IR_NAME" ]] && continue

  IR_BODY=$(build_body "$skill_md" "$skill_dir")
  SKILL_MD_PATH="$skill_md"

  for adapter_name in "${SKILL_ADAPTERS[@]}"; do
    adapter_script="$REPO_ROOT/scripts/adapters/${adapter_name}.sh"
    # shellcheck source=/dev/null
    source "$adapter_script"
    render_skill
  done

  [[ "$OKF_MODE" -eq 1 ]] && render_okf_concept
  skill_count=$((skill_count + 1))
done < <(iterate_skills)

opencode_count=0
[[ -n "$OPN_TARGET" ]] && sync_opencode_copy && opencode_count="${SYNC_OPENCODE_COUNT:-0}"

if [[ "$OKF_MODE" -eq 1 ]]; then
  echo ""
  echo "--- OKF skills-wiki post-sync ---"
  bash "$REPO_ROOT/scripts/okf-post-sync.sh"
fi

sync_post_run "$skill_count" "$opencode_count"
exit 0
