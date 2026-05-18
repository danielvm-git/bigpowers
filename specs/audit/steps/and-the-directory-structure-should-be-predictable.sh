#!/usr/bin/env bash
# And the directory structure should be predictable
# Check: project has CLAUDE.md defining structure, and all skill dirs contain SKILL.md.
if [[ ! -f "CLAUDE.md" ]]; then
  echo "No CLAUDE.md found — structure is undocumented"
  exit 1
fi

MISSING=$(find . -maxdepth 2 -name "SKILL.md" -exec dirname {} \; | while read dir; do
  [[ ! -f "$dir/SKILL.md" ]] && echo "$dir"
done)

if [[ -z "$MISSING" ]]; then
  exit 0
else
  echo "Skill dirs missing SKILL.md: $MISSING"
  exit 1
fi
