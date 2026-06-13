#!/usr/bin/env bash
# And context window constraints should be proactively managed
# Check: CONVENTIONS.md mandates file sizes to fit within a single agent context window.
if grep -q "context window" CONVENTIONS.md 2>/dev/null; then
  exit 0
else
  echo "CONVENTIONS.md does not mandate context window management"
  exit 1
fi
