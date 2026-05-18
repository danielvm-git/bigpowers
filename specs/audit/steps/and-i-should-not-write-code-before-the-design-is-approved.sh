#!/usr/bin/env bash
# And I should not write code before the design is approved
# Evidence: develop-tdd and plan-work both gate on plan/design existing first
if grep -q "HARD GATE\|HARD-GATE" develop-tdd/SKILL.md \
   && grep -qi "before.*plan\|design.*approv\|plan.*approv\|no plan.*no code\|Do NOT write code" develop-tdd/SKILL.md; then
  exit 0
fi
echo "No evidence of design-before-code gate in develop-tdd"
exit 1
