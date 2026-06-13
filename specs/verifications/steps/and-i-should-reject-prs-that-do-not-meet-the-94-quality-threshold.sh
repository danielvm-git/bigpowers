#!/usr/bin/env bash
# And I should reject PRs that do not meet the 94% quality threshold
# Evidence: request-review HARD-GATE blocks merge if score < 94%
if grep -q "94%" request-review/SKILL.md && grep -q "HARD GATE\|HARD-GATE" request-review/SKILL.md; then
  exit 0
fi
echo "94% quality threshold HARD-GATE missing from request-review"
exit 1
