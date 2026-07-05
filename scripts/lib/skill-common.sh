#!/usr/bin/env bash
# story: e28s01
# scripts/lib/skill-common.sh — Shared bash library for skill pipeline scripts
# Provides: resolve_repo_root, parse_frontmatter, iterate_skills
if [[ -n "${_SKILL_COMMON_SOURCED:-}" ]]; then return 0; fi
_SKILL_COMMON_SOURCED=1

resolve_repo_root() {
  REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
  SKILLS_ROOT="$REPO_ROOT"
  [[ -d "$REPO_ROOT/skills" ]] && SKILLS_ROOT="$REPO_ROOT/skills"
}
resolve_repo_root

parse_frontmatter() {
  local file="$1"
  _PF_NAME=""; _PF_MODEL=""; _PF_DESCRIPTION=""
  [[ -f "$file" ]] || { echo "parse_frontmatter: file not found: $file" >&2; return 1; }
  grep -q '^---$' "$file" || { echo "parse_frontmatter: no YAML frontmatter in $file" >&2; return 1; }
  _PF_NAME=$(awk '/^---/{f++} f==1 && /^name:/{print; exit}' "$file" | sed 's/^name:[[:space:]]*//')
  _PF_MODEL=$(awk '/^---/{f++} f==1 && /^model:/{print; exit}' "$file" | sed 's/^model:[[:space:]]*//')
  _PF_DESCRIPTION=$(awk '/^---/{f++; next} f==1 && /^description:/{p=1; sub(/^description:[[:space:]]*/,""); print; next} f==1 && p && /^[a-z]+:/{exit} f==1 && p{print}' "$file" \
    | tr -d '\n' | sed -E 's/[[:space:]]+/ /g')
  [[ -z "$_PF_NAME" ]] && return 1
  return 0
}

iterate_skills() {
  local dir
  for dir in "$SKILLS_ROOT"/*/; do
    [[ -d "$dir" ]] || continue
    [[ -f "$dir/SKILL.md" ]] || continue
    echo "${dir%/}"
  done
}
