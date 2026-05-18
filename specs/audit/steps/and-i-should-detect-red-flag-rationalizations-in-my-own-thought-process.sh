#!/usr/bin/env bash
# And I should detect "red flag" rationalizations in my own thought process
# Evidence: plan-work red-flag check; audit-code Red Flags section; develop-tdd Red Flags table
if grep -qi "rationalization\|red.flag" plan-work/SKILL.md \
   && grep -qi "rationalization\|Red Flag" audit-code/SKILL.md; then
  exit 0
fi
echo "Red-flag rationalization detection missing from plan-work or audit-code"
exit 1
