#!/usr/bin/env bash
# And I should use fresh subagent context for independent reviews
# Evidence: request-review dispatches a fresh agent with clean context
if grep -qi "fresh\|clean context\|no shared state" request-review/SKILL.md; then
  exit 0
fi
echo "No evidence of fresh subagent context mandate in request-review"
exit 1
