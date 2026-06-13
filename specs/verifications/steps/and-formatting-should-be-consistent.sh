#!/usr/bin/env bash
# And formatting should be consistent
# Check: no shell script in scripts/ mixes tab and space indentation.
VIOLATIONS=$(for f in scripts/*.sh; do
  has_tabs=$(grep -c $'^\t' "$f" 2>/dev/null || echo 0)
  has_spaces=$(grep -c '^  ' "$f" 2>/dev/null || echo 0)
  if [[ "$has_tabs" -gt 0 && "$has_spaces" -gt 0 ]]; then
    echo "$f"
  fi
done)

if [[ -z "$VIOLATIONS" ]]; then
  exit 0
else
  echo "Mixed tab/space indentation found in:"
  echo "$VIOLATIONS"
  exit 1
fi
