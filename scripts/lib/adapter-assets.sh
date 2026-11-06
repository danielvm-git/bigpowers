#!/usr/bin/env bash
# story: BUG-2026-11-06-dist-render-missing-assets
# adapter-assets.sh — mirror a skill's bundled files into a rendered payload.
#
# A rendered target that ships only SKILL.md is a broken skill: 38 of 80 skills
# reference sibling files (LANGUAGE.md, HEURISTICS.md, scripts/*.js, templates,
# fixtures). The symlink install channels ship the whole directory, so without
# this the same skill behaves differently per channel (issue #218).
#
# The helper copies every sibling entry of the source skill directory except
# SKILL.md itself. Markdown siblings are already inlined into the rendered body
# by build_body(), but they are copied too so relative links resolve instead of
# dangling.

if [ -n "${ADAPTER_ASSETS_LOADED:-}" ]; then
  return 0
fi
ADAPTER_ASSETS_LOADED=1

# mirror_skill_assets <dest-skill-dir> <skill-name>
# Returns 0 on success, 1 when the source directory cannot be found.
mirror_skill_assets() {
  local dest="$1"
  local name="$2"
  local root="${BP_REPO_ROOT:-}"
  local source=""

  if [[ -z "$root" && -n "${SKILL_MD_PATH:-}" ]]; then
    root="$(cd "$(dirname "$SKILL_MD_PATH")/../.." && pwd)"
  fi
  [[ -n "$root" ]] || return 1

  source="$root/skills/$name"
  [[ -d "$source" ]] || return 1
  mkdir -p "$dest"

  local entry base
  for entry in "$source"/* "$source"/.[!.]*; do
    [[ -e "$entry" ]] || continue
    base="$(basename "$entry")"
    [[ "$base" == "SKILL.md" ]] && continue
    rm -rf "${dest:?}/$base"
    cp -R "$entry" "$dest/$base"
  done
  return 0
}

# assert_skill_assets <rendered-skills-dir>
# Verifies every source sibling exists in the rendered tree. Prints one line per
# missing entry and returns 1 when anything is absent.
assert_skill_assets() {
  local rendered="$1"
  local root="${BP_REPO_ROOT:-$(pwd)}"
  local missing=0

  [[ -d "$rendered" ]] || return 1

  local skill_dir name entry base
  for skill_dir in "$root"/skills/*/; do
    [[ -f "$skill_dir/SKILL.md" ]] || continue
    name="$(basename "$skill_dir")"
    for entry in "$skill_dir"/* "$skill_dir"/.[!.]*; do
      [[ -e "$entry" ]] || continue
      base="$(basename "$entry")"
      [[ "$base" == "SKILL.md" ]] && continue
      if [[ ! -e "$rendered/$name/$base" ]]; then
        echo "missing asset: $rendered/$name/$base"
        missing=$((missing + 1))
      fi
    done
  done

  [[ "$missing" -eq 0 ]]
}
