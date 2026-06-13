#!/usr/bin/env bash
# And my changes should be surgical, touching only what is required
# Evidence: CLAUDE.md and audit-code mandate scope discipline
if grep -qi "surgical\|touch only\|nothing extra\|outside the.*scope" CLAUDE.md \
   || grep -qi "surgical\|outside the stated scope\|nothing extra" audit-code/SKILL.md; then
  exit 0
fi
echo "No evidence of surgical change discipline in CLAUDE.md or audit-code"
exit 1
