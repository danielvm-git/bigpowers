#!/usr/bin/env bash
# story: e28s01
# scripts/lib/skill-common.sh — Shared bash library for skill pipeline scripts
# Provides: resolve_repo_root, parse_frontmatter, iterate_skills
# Safe to source under set -euo pipefail; double-source is a no-op.

# Double-source guard
if [[ -n "${_SKILL_COMMON_SOURCED:-}" ]]; then
  return 0
fi
_SKILL_COMMON_SOURCED=1

# ── resolve_repo_root ───────────────────────────────────────────────
# Resolves REPO_ROOT to the repository root (two levels up from this
# library at scripts/lib/skill-common.sh). Also sets SKILLS_ROOT:
# skills/ subdirectory when it exists, repo root fallback.
resolve_repo_root() {
  REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
  SKILLS_ROOT="$REPO_ROOT"
  [[ -d "$REPO_ROOT/skills" ]] && SKILLS_ROOT="$REPO_ROOT/skills"
}

# Resolve at source time so callers don't need to
resolve_repo_root

# ── parse_frontmatter ───────────────────────────────────────────────
# Usage: parse_frontmatter <SKILL.md>
# Extracts YAML frontmatter into globals: _PF_NAME, _PF_MODEL, _PF_DESCRIPTION
# Returns 0 on success, non-zero if file missing or no name in frontmatter.
parse_frontmatter() {
  local file="$1"
  _PF_NAME=""
  _PF_MODEL=""
  _PF_DESCRIPTION=""

  if [[ ! -f "$file" ]]; then
    echo "parse_frontmatter: file not found: $file" >&2
    return 1
  fi

  # Verify YAML frontmatter exists (at least one --- delimiter)
  if ! grep -q '^---$' "$file"; then
    echo "parse_frontmatter: no YAML frontmatter in $file" >&2
    return 1
  fi

  # Extract name (single-line, first match in frontmatter)
  _PF_NAME=$(awk '/^---/{f++} f==1 && /^name:/{print; exit}' "$file" | sed 's/^name:[[:space:]]*//')

  # Extract model (single-line, first match in frontmatter)
  _PF_MODEL=$(awk '/^---/{f++} f==1 && /^model:/{print; exit}' "$file" | sed 's/^model:[[:space:]]*//')

  # Extract description (potentially multiline, from "description:" to next YAML key or closing ---)
  _PF_DESCRIPTION=$(awk '/^---/{f++; next} f==1 && /^description:/{p=1; sub(/^description:[[:space:]]*/,""); print; next} f==1 && p && /^[a-z]+:/{exit} f==1 && p{print}' "$file" \
    | tr -d '\n' \
    | sed -E 's/[[:space:]]+/ /g')

  [[ -z "$_PF_NAME" ]] && return 1
  return 0
}

# ── iterate_skills ──────────────────────────────────────────────────
# Usage: iterate_skills
# Outputs one absolute path per skill directory under SKILLS_ROOT that
# contains a SKILL.md file, in stable sorted order (no trailing slash).
iterate_skills() {
  local dir
  for dir in "$SKILLS_ROOT"/*/; do
    [[ -d "$dir" ]] || continue
    [[ -f "$dir/SKILL.md" ]] || continue
    echo "${dir%/}"
  done
}
