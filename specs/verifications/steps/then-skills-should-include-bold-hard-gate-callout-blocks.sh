#!/usr/bin/env bash
# Then skills should include bold HARD-GATE callout blocks
count=$(grep -rl "HARD GATE\|HARD-GATE" . --include="SKILL.md" | wc -l)
if [ "$count" -ge 5 ]; then
  echo "HARD-GATE blocks found in $count skill files"
  exit 0
fi
echo "Expected ≥5 skills with HARD-GATE blocks, found $count"
exit 1
