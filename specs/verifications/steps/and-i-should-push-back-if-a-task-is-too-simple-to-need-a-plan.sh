#!/usr/bin/env bash
# And I should push back if a task is "too simple" to need a plan
# Evidence: develop-tdd Red Flags table explicitly names "too simple to need tests"
if grep -qi "too simple\|simple.*cheap\|simple.*test" develop-tdd/SKILL.md; then
  exit 0
fi
echo "No evidence of pushback on 'too simple' rationalization in develop-tdd"
exit 1
