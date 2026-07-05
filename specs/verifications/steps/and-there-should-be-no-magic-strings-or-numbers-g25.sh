#!/usr/bin/env bash
# And there should be no "magic strings" or numbers (G25)
# Check: hardcoded absolute user paths in scripts.
# Exclusions: ad-hoc verification scripts with absolute paths
VIOLATIONS=$(grep -rn '/Users/' scripts/ 2>/dev/null \
  | grep -v ':[0-9]*:#' \
  | grep -v 'hermes-verify-e39')

if [[ -z "$VIOLATIONS" ]]; then
  exit 0
else
  echo "Magic paths found:"
  echo "$VIOLATIONS"
  exit 1
fi
