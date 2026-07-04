#!/usr/bin/env bash
# When I run plan-tests
# Evidence: plan-tests is a registered, invocable skill with a documented Core Workflow
if grep -q "^name: plan-tests" skills/plan-tests/SKILL.md \
   && grep -q "## Core Workflow" skills/plan-tests/SKILL.md; then
  exit 0
fi
echo "skills/plan-tests/SKILL.md is missing its name frontmatter or Core Workflow section"
exit 1
