#!/usr/bin/env bash
# And I should loop until behavioral correctness is verified
# Evidence: validate-fix loop-until-all-green rule; execute-plan behavioral correctness note
if grep -qi "loop\|all checks pass\|return to step 1" validate-fix/SKILL.md \
   && grep -qi "behavioral" execute-plan/SKILL.md; then
  exit 0
fi
echo "No evidence of loop-until-correct discipline in validate-fix or execute-plan"
exit 1
