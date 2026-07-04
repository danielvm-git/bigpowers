#!/usr/bin/env bash
# And the plan specifies test levels and fixture architectures
# Evidence: Level Strategy + Fixture Design are workflow steps; REFERENCE.md has a Fixture Architecture template section
if grep -qi "Level Strategy" skills/plan-tests/SKILL.md \
   && grep -qi "Fixture Design" skills/plan-tests/SKILL.md \
   && grep -qi "Fixture Architecture" skills/plan-tests/REFERENCE.md; then
  exit 0
fi
echo "plan-tests does not wire Level Strategy / Fixture Design steps to a Fixture Architecture template"
exit 1
