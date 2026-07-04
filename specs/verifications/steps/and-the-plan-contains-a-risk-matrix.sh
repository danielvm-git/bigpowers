#!/usr/bin/env bash
# And the plan contains a risk matrix
# Evidence: the test-plan template in REFERENCE.md has a Risk Matrix & Scenarios section
if grep -qi "Risk Matrix" skills/plan-tests/REFERENCE.md; then
  exit 0
fi
echo "skills/plan-tests/REFERENCE.md template is missing a Risk Matrix section"
exit 1
