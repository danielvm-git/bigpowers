#!/usr/bin/env bash
# And I should define verifiable success criteria for every step
# Evidence: plan-work mandates verify: command on every step; define-success skill exists
if grep -q "verify:" skills/plan-work/SKILL.md && [ -d "skills/define-success" ]; then
  exit 0
fi
echo "No evidence of verifiable success criteria mandate in plan-work or define-success"
exit 1
