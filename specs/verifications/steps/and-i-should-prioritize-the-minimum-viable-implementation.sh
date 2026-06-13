#!/usr/bin/env bash
# And I should prioritize the minimum viable implementation
# Evidence: plan-work and develop-tdd mandate minimal code per step
if grep -qi "minimum\|minimal\|smallest possible\|minimum viable" plan-work/SKILL.md \
   && grep -qi "minimal code\|minimum\|only enough" develop-tdd/SKILL.md; then
  exit 0
fi
echo "No evidence of minimum viable implementation priority in plan-work or develop-tdd"
exit 1
