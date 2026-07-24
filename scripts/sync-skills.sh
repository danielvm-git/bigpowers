#!/usr/bin/env bash
# story: e48s15
# story: e05s01
# story: e12s01
# story: e12s02
# story: e12s03
# story: e12s04
# story: e12s06
# story: e13s03
# story: e28s02
# story: e28s03
# story: e39s04
# story: e29s01
# story: e29s02
# sync-skills.sh — generate Cursor, Gemini CLI, pi, and OKF artifacts from SKILL.md source files
# Architecture: Parse→IR→Render. Each target is its own render_<target>() function.
# Run this after adding or updating any skill. Symlinks carry changes through automatically.
#
# Flags:
#   --okf              Generate specs/skills-wiki/ OKF concept bundle from SKILL.md frontmatter
#   --opencode <p>     Sync to bigpowers-opencode repo
#   --distribute-only  Render skills to target tool directories only — skip
#                       lockfile/index/README/reference-table/OKF-wiki regen.
#                       Used by bin/setup.js: end-user installs never carry
#                       specs/ or docs/ (see .npmignore), so that dev-only
#                       maintenance step has nothing to operate on.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/python-env.sh"

OKF_MODE=0
OPN_TARGET=""
DISTRIBUTE_ONLY=0

for arg in "$@"; do
  case "$arg" in
    --okf) OKF_MODE=1 ;;
    --opencode=*) OPN_TARGET="${arg#*=}" ;;
    --opencode) shift; OPN_TARGET="$1" ;;
    --distribute-only) DISTRIBUTE_ONLY=1 ;;
    --help|-h)
      echo "Usage: sync-skills.sh [--okf] [--opencode <path>] [--distribute-only]"
      echo ""
      echo "  --okf              Generate specs/skills-wiki/ OKF concept bundle"
      echo "  --opencode         Sync skills to bigpowers-opencode repo"
      echo "  --distribute-only  Render skills only — skip dev-maintenance regen"
      echo "  --help             Show this message"
      exit 0
      ;;
    *) echo "sync-skills: unknown flag: $arg" >&2; exit 2 ;;
  esac
done

_LIB_DIR="$(dirname "${BASH_SOURCE[0]}")/lib"
source "$(dirname "${BASH_SOURCE[0]}")/lib/skill-common.sh"
source "$(dirname "${BASH_SOURCE[0]}")/lib/sync-render.sh"
source "$(dirname "${BASH_SOURCE[0]}")/lib/sync-post.sh"
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

export CURSOR_RULES GEMINI_EXT_DIR GEMINI_SKILLS GEMINI_COMMANDS GEMINI_MANIFEST PI_SKILLS PI_PROMPTS PI_PACKAGE_JSON OKF_WIKI_SKILLS OKF_WIKI_DIR

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
  echo "sync-skills: WARN — yq unavailable or targets.yaml missing; using legacy render list (cursor gemini pi)" >&2
  SKILL_ADAPTERS=(cursor gemini pi)
fi

OKF_FLAG=""
[[ "$OKF_MODE" -eq 1 ]] && OKF_FLAG="--okf"

# Run srp-engine.py --all to process all skills in Python
"$PYTHON" "$REPO_ROOT/scripts/lib/srp-engine.py" --all $OKF_FLAG

# Count generated skills
skill_count=$(find "$CURSOR_RULES" -maxdepth 1 -name "*.mdc" | wc -l | tr -d ' ')

opencode_count=0
[[ -n "$OPN_TARGET" ]] && sync_opencode_copy && opencode_count="${SYNC_OPENCODE_COUNT:-0}"

if [[ "$OKF_MODE" -eq 1 ]]; then
  echo ""
  echo "--- OKF skills-wiki post-sync ---"
  bash "$REPO_ROOT/scripts/okf-post-sync.sh"
fi

if [[ "$DISTRIBUTE_ONLY" -eq 1 ]]; then
  echo "sync-skills: $skill_count skills synced (--distribute-only: dev-maintenance regen skipped)"
  exit 0
fi

sync_post_run "$skill_count" "$opencode_count"
exit 0
