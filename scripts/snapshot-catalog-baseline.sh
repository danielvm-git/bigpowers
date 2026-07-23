#!/usr/bin/env bash
# story: e54s01
# snapshot-catalog-baseline.sh — freeze the live skill catalog into a dated,
# immutable YAML baseline for e56's reclassification diff.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/skill-common.sh"
source "$SCRIPT_DIR/lib/python-env.sh"

resolve_repo_root
cd "$REPO_ROOT"

DRY_RUN=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=true; shift ;;
    -h|--help) echo "Usage: bash scripts/snapshot-catalog-baseline.sh [--dry-run]"; exit 0 ;;
    *) echo "Unknown flag: $1" >&2; exit 2 ;;
  esac
done

DATE_STR="$(date +%Y-%m-%d)"
COMMIT_HASH="$(git rev-parse HEAD 2>/dev/null || echo unknown)"
OUT_FILE="$REPO_ROOT/specs/tech-architecture/CATALOG-BASELINE-${DATE_STR}.yaml"

# unquote_source_desc — strip a source frontmatter's own surrounding quotes
# and unescape its inner \" , or re-quoting double-escapes the description.
unquote_source_desc() {
  local desc="$1"
  if [[ "$desc" == \"*\" ]]; then
    desc="${desc#\"}"
    desc="${desc%\"}"
    desc="${desc//\\\"/\"}"
  fi
  echo "$desc"
}

# emit_skill_row — print one skill's YAML row to stdout; appends any missing-
# field warning line for that skill to $WARN_FILE (a plain file, since this
# function runs inside a command-substitution subshell and can't mutate the
# caller's shell variables).
emit_skill_row() {
  local skill_md="$1" name phase model effort desc desc_escaped
  name="$(basename "$(dirname "$skill_md")")"
  parse_frontmatter_okf "$skill_md" || true

  phase="$(awk '/^---/{f++} f==1 && /^phase:/{print; exit}' "$skill_md" | sed 's/^phase:[[:space:]]*//')"
  model="${_PF_MODEL:-}"
  effort="${_PF_EFFORT:-}"
  desc="${_PF_DESCRIPTION:-}"

  [[ -z "$phase" ]] && phase="null"
  [[ -z "$model" ]] && { model="null"; echo "  - \"${name}: missing model field\"" >> "$WARN_FILE"; }
  [[ -z "$effort" ]] && { effort="null"; echo "  - \"${name}: missing effort field\"" >> "$WARN_FILE"; }
  [[ -z "$desc" ]] && desc="null"

  desc="$(unquote_source_desc "$desc")"
  desc_escaped="${desc//\"/\\\"}"

  echo "  - name: \"${name}\"\n    path: \"skills/${name}/SKILL.md\"\n    phase: ${phase}\n    effort: ${effort}\n    model: ${model}\n    description: \"${desc_escaped}\"\n"
}

WARN_FILE="$(mktemp)"
trap 'rm -f "$WARN_FILE"' EXIT

ROWS=""
COUNT=0

for skill_md in "$SKILLS_ROOT"/*/SKILL.md; do
  [[ -f "$skill_md" ]] || continue
  ROWS="${ROWS}$(emit_skill_row "$skill_md")"
  COUNT=$((COUNT + 1))
done

WARNINGS="$(cat "$WARN_FILE")"
WARN_COUNT="$(grep -c '^  -' "$WARN_FILE" || true)"

if $DRY_RUN; then
  echo "${COUNT} skills scanned"
  echo "${WARN_COUNT} warnings"
  [[ -n "$WARNINGS" ]] && echo -e "warnings:\n${WARNINGS}"
  exit 0
fi

mkdir -p "$REPO_ROOT/specs/tech-architecture"

{
  echo "# CATALOG-BASELINE-${DATE_STR}.yaml"
  echo "# frozen for e54-e59 migration; do not hand-edit"
  echo "snapshot_date: \"${DATE_STR}\""
  echo "commit_hash: \"${COMMIT_HASH}\""
  echo "total_skill_count: ${COUNT}"
  echo "warnings:"
  if [[ -n "$WARNINGS" ]]; then
    echo -e "$WARNINGS"
  else
    echo "  []"
  fi
  echo "skills:"
  echo -e "$ROWS"
} > "$OUT_FILE"

echo "Wrote ${OUT_FILE} (${COUNT} skills, ${WARN_COUNT} warnings)"
