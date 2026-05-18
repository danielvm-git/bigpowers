#!/usr/bin/env bash
# Then public symbols should be unique enough to be searched with 'grep' (< 5 results)
# Check: no function name is defined in more than one script file.
VIOLATIONS=$(grep -rEoh '^[a-z_][a-z_0-9]*\s*\(\)' scripts/ specs/audit/steps/ 2>/dev/null \
  | sed 's/[[:space:]]*()//' \
  | sort | uniq -d)

if [[ -z "$VIOLATIONS" ]]; then
  exit 0
else
  echo "Duplicate function names across files:"
  echo "$VIOLATIONS"
  exit 1
fi
