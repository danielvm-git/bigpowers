#!/usr/bin/env bash
# Then it produces specs/tech-architecture/eNN-TEST_PLAN_LATEST.md
# Evidence: verify block and Publish step both target the canonical output path
if grep -q "specs/tech-architecture/\$(echo \$EPIC" skills/plan-tests/SKILL.md \
   && grep -qi "Generate \`specs/tech-architecture/eNN-TEST_PLAN_LATEST.md\`" skills/plan-tests/SKILL.md; then
  exit 0
fi
echo "skills/plan-tests/SKILL.md does not wire its Publish step or verify: to the eNN-TEST_PLAN_LATEST.md path"
exit 1
