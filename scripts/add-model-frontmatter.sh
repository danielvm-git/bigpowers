#!/usr/bin/env bash
# add-model-frontmatter.sh — one-time helper; idempotent model: injection
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# SKILLS_ROOT: use skills/ when it exists, fall back to repo root
SKILLS_ROOT="$REPO_ROOT"
[[ -d "$REPO_ROOT/skills" ]] && SKILLS_ROOT="$REPO_ROOT/skills"

# Bash 3.2-compatible model mapping (no declare -A)
get_model() {
  case "$1" in
    survey-context|verify-work|validate-fix|audit-code|enforce-first|trace-requirement|commit-message|release-branch|kickoff-branch|guard-git|hook-commits|execute-plan|organize-workspace|terse-mode|session-state|search-skills|setup-environment|reset-baseline) echo "haiku" ;;
    elaborate-spec|grill-with-docs|design-interface|plan-work|request-review|evolve-skill) echo "opus" ;;
    *) echo "sonnet" ;;
  esac
}

for skill_dir in "$SKILLS_ROOT"/*/; do
  skill_md="$skill_dir/SKILL.md"
  [[ -f "$skill_md" ]] || continue
  name=$(basename "$skill_dir")
  model=$(get_model "$name")
  if grep -q '^model:' "$skill_md" 2>/dev/null; then
    continue
  fi
  # Insert model: after name: line in frontmatter
  awk -v m="$model" '
    /^---$/ { fm++; print; next }
    fm==1 && /^name:/ { print; print "model: " m; next }
    { print }
  ' "$skill_md" > "$skill_md.tmp" && mv "$skill_md.tmp" "$skill_md"
  echo "model: $model → $name"
done
