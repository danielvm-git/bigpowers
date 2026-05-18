#!/usr/bin/env bash
# Then the "Boy Scout Rule" should be applied to every change (Leave it cleaner)
# Check: CONVENTIONS.md mandates the Boy Scout Rule in writing.
if grep -qi "boy scout" CONVENTIONS.md 2>/dev/null; then
  exit 0
else
  echo "CONVENTIONS.md does not mandate the Boy Scout Rule"
  exit 1
fi
