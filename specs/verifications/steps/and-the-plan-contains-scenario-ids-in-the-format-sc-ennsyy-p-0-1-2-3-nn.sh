#!/usr/bin/env bash
# And the plan contains scenario IDs in the format SC-eNNsYY-P{0|1|2|3}-NN
# Evidence: format is a hard gate in plan-tests and registered in CONVENTIONS.md
if grep -q "SC-eNNsYY-P{0|1|2|3}-NN" skills/plan-tests/SKILL.md \
   && grep -q "SC-eNNsYY" CONVENTIONS.md; then
  exit 0
fi
echo "SC-eNNsYY-P{0|1|2|3}-NN scenario ID format is not documented in both plan-tests/SKILL.md and CONVENTIONS.md"
exit 1
