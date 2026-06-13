#!/usr/bin/env bash
# And I should avoid speculative abstractions
# Evidence: plan-work complexity pushback gate; develop-tdd red flags table
if grep -q "abstraction\|forcing\|speculative" plan-work/SKILL.md \
   && grep -qi "speculative\|No speculative" develop-tdd/SKILL.md; then
  exit 0
fi
echo "No evidence of speculative abstraction prohibition in plan-work or develop-tdd"
exit 1
