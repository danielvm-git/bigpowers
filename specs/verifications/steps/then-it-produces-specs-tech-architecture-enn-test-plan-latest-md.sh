#!/usr/bin/env bash
# Then it produces specs/tech-architecture/eNN-TEST_PLAN_LATEST.md
# Evidence: verify block references the canonical TEST_PLAN_LATEST.md path pattern
if grep -q 'TEST_PLAN_LATEST' skills/plan-tests/SKILL.md; then
  exit 0
fi
echo "skills/plan-tests/SKILL.md does not reference the eNN-TEST_PLAN_LATEST.md path"
exit 1
