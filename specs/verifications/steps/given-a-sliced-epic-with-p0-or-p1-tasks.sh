#!/usr/bin/env bash
# Given a sliced epic with P0 or P1 tasks
# Evidence: plan-tests reads the sliced story list and gates on risk: P0|P1
if grep -q "risk: P0|P1" skills/plan-tests/SKILL.md \
   && grep -qi "Read sliced stories in the active epic capsule" skills/plan-tests/SKILL.md; then
  exit 0
fi
echo "plan-tests SKILL.md does not document reading a sliced P0/P1 epic as its precondition"
exit 1
