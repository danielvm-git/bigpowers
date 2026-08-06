#!/usr/bin/env bash
# story: e28s01
# Shared functions for bigpowers sync pipeline.
# Source this from any script that needs REPO_ROOT, SKILLS_ROOT, or skill iteration.
# Double-source guard: safe under set -euo pipefail.

if [ -n "${SKILL_COMMON_LOADED:-}" ]; then
  return 0
fi
SKILL_COMMON_LOADED=1

# resolve_repo_root — set REPO_ROOT and SKILLS_ROOT
resolve_repo_root() {
  local lib_dir
  lib_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" || return 1
  # Library is at REPO/scripts/lib/skill-common.sh → two levels up
  local repo_candidate
  repo_candidate="$(cd "$lib_dir/../.." 2>/dev/null && pwd)"
  if [ -n "$repo_candidate" ] && [ -d "$repo_candidate/skills" ]; then
    REPO_ROOT="$repo_candidate"
  else
    repo_candidate="$(cd "$lib_dir/.." 2>/dev/null && pwd)"
    REPO_ROOT="$repo_candidate"
  fi
  SKILLS_ROOT="$REPO_ROOT"
  [ -d "$REPO_ROOT/skills" ] && SKILLS_ROOT="$REPO_ROOT/skills"
  export REPO_ROOT SKILLS_ROOT
}

# parse_frontmatter — extract name, model, description from SKILL.md YAML frontmatter
# Usage: parse_frontmatter <path-to-SKILL.md>
# Output: exports SKILL_NAME, SKILL_MODEL, SKILL_DESC
parse_frontmatter() {
  local file="$1"
  if [ ! -f "$file" ]; then
    echo "parse_frontmatter: file not found: $file" >&2
    return 1
  fi

  local in_block=0
  local name="" model="" desc="" line

  while IFS= read -r line; do
    if [ "$line" = "---" ]; then
      in_block=$((in_block + 1))
      [ "$in_block" -eq 2 ] && break
      continue
    fi
    [ "$in_block" -ne 1 ] && continue

    # Skip comment lines (e.g. # story: tags inside the frontmatter block)
    [[ "$line" == \#* || "$line" == \<\!--* ]] && continue

    case "$line" in
      name:*)
        name="${line#name: }"
        name="${name#name:}"
        name="${name# }"
        ;;
      model:*)
        model="${line#model: }"
        model="${model#model:}"
        model="${model# }"
        ;;
      description:*)
        desc="${line#description: }"
        desc="${desc#description:}"
        desc="${desc# }"
        # Handle multiline: keep reading indented continuation lines
        ;;
    esac
  done < "$file"

  # Read continuation lines for multiline description
  local continued=0
  while IFS= read -r line; do
    if [ "$line" = "---" ]; then
      [ "$continued" -eq 0 ] && continued=1 || break
      continue
    fi
    [ "$continued" -eq 0 ] && continue
    # Skip comment lines (e.g. # story: tags inside the frontmatter block)
    [[ "$line" == \#* || "$line" == \<\!--* ]] && continue
    # If next field starts (unindented key:), stop
    [[ "$line" =~ ^[a-zA-Z_]+: ]] && break
    desc="$desc $line"
  done < "$file"

  SKILL_NAME="$name"
  SKILL_MODEL="$model"
  SKILL_DESC="$desc"
  # Compatibility: also set _PF_* for scripts that expect them
  _PF_NAME="$SKILL_NAME"
  _PF_MODEL="$SKILL_MODEL"
  _PF_DESCRIPTION="$SKILL_DESC"
  export SKILL_NAME SKILL_MODEL SKILL_DESC _PF_NAME _PF_MODEL _PF_DESCRIPTION
}

# parse_frontmatter_okf — like parse_frontmatter but also extracts effort field
parse_frontmatter_okf() {
  local file="$1"
  _PF_EFFORT=""

  if [[ ! -f "$file" ]] || ! grep -q '^---$' "$file"; then
    return 1
  fi

  _PF_NAME=$(awk '/^---/{f++} f==1 && /^name:/{print; exit}' "$file" | sed 's/^name:[[:space:]]*//')
  _PF_MODEL=$(awk '/^---/{f++} f==1 && /^model:/{print; exit}' "$file" | sed 's/^model:[[:space:]]*//')
  _PF_EFFORT=$(awk '/^---/{f++} f==1 && /^effort:/{print; exit}' "$file" | sed 's/^effort:[[:space:]]*//')
  _PF_DESCRIPTION=$(awk '/^---/{f++; next} f==1 && /^description:/{p=1; sub(/^description:[[:space:]]*/,""); print; next} f==1 && p && /^[a-z]+:/{exit} f==1 && p && !/^[[:space:]]*#/ && !/^[[:space:]]*<!--/{print}' "$file" \
    | tr -d '\n' \
    | sed -E 's/[[:space:]]+/ /g')

  [[ -z "$_PF_NAME" ]] && return 1
  export _PF_NAME _PF_MODEL _PF_EFFORT _PF_DESCRIPTION
  return 0
}

# iterate_skills — list skill directories containing SKILL.md, stable sorted order
iterate_skills() {
  resolve_repo_root 2>/dev/null || true
  if [ -d "$SKILLS_ROOT" ]; then
    for dir in "$SKILLS_ROOT"/*/; do
      [ -f "${dir}SKILL.md" ] && echo "${dir%/}"
    done | sort
  fi
}
