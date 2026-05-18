#!/usr/bin/env bash
# And conditionals should be expressed as positives (G29)
# Check: double-negation patterns (! [[ ! ...) in shell scripts.
VIOLATIONS=$(grep -rn '! \[\[.*!' scripts/ 2>/dev/null | grep -v ':[0-9]*:#')

if [[ -z "$VIOLATIONS" ]]; then
  exit 0
else
  echo "Double-negation conditionals found:"
  echo "$VIOLATIONS"
  exit 1
fi
