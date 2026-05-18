#!/usr/bin/env bash
# And nesting should be shallow (max 2 levels)
# Check: step scripts have no control flow beyond 2 levels (8+ leading spaces).
VIOLATIONS=$(grep -rEn '^\s{8,}(if |for |while )' specs/audit/steps/ 2>/dev/null | grep -v ':[0-9]*:#')

if [[ -z "$VIOLATIONS" ]]; then
  exit 0
else
  echo "Deep nesting found in step scripts:"
  echo "$VIOLATIONS"
  exit 1
fi
