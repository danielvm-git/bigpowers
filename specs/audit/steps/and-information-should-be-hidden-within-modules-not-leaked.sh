#!/usr/bin/env bash
# And information should be hidden within modules, not leaked
# Check: no script in scripts/ cross-sources another (no global state leakage).
VIOLATIONS=$(grep -rn "^source \|^\. " scripts/ 2>/dev/null | grep -v ':[0-9]*:#')

if [[ -z "$VIOLATIONS" ]]; then
  exit 0
else
  echo "Cross-module sourcing found (information leakage):"
  echo "$VIOLATIONS"
  exit 1
fi
