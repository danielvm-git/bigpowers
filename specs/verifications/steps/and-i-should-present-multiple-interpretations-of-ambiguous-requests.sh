#!/usr/bin/env bash
# And I should present multiple interpretations of ambiguous requests
# Evidence: elaborate-spec and plan-work both mandate listing ≥2 interpretations
if grep -q "interpretation" elaborate-spec/SKILL.md \
   && grep -q "interpretation" plan-work/SKILL.md; then
  exit 0
fi
echo "Multiple interpretations gate missing from elaborate-spec or plan-work"
exit 1
