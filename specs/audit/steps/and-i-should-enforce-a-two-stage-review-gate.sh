#!/usr/bin/env bash
# And I should enforce a two-stage review gate
# Evidence: audit-code (self-review) + request-review (external agent) form a two-stage gate
if grep -qi "Distinct from\|audit-code.*first\|run.*audit-code.*first\|Run.*audit-code.*before" request-review/SKILL.md; then
  exit 0
fi
echo "No evidence of two-stage review gate (audit-code then request-review) in request-review"
exit 1
