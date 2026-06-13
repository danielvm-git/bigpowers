#!/usr/bin/env bash
# Then I should surface assumptions before writing code
# Evidence: elaborate-spec asks clarifying questions before any output;
#           plan-work has pre-flight checks before drafting steps
if grep -q "clarif\|assumption\|Success criteria\|How will you know" elaborate-spec/SKILL.md \
   && grep -q "Pre-flight\|define-success\|success criteria" plan-work/SKILL.md; then
  exit 0
fi
echo "No evidence of surfacing assumptions before writing code"
exit 1
