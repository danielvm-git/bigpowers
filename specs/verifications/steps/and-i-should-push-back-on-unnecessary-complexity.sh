#!/usr/bin/env bash
# And I should push back on unnecessary complexity
# Evidence: plan-work complexity pushback gate with forcing function requirement
if grep -q "Complexity pushback\|forcing function\|complexity" plan-work/SKILL.md; then
  exit 0
fi
echo "No evidence of complexity pushback gate in plan-work"
exit 1
