#!/usr/bin/env bash
# And complex boolean logic should be encapsulated in named functions (G28)
# Check: if-conditions with 3+ boolean operators on a single line.
VIOLATIONS=$(grep -rn 'if .*&&.*&&\|if .*||.*||' scripts/ 2>/dev/null | grep -v ':[0-9]*:#')

if [[ -z "$VIOLATIONS" ]]; then
  exit 0
else
  echo "Complex boolean chains found:"
  echo "$VIOLATIONS"
  exit 1
fi
