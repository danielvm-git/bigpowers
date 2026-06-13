#!/usr/bin/env bash
# And names should be meaningful and unique
# Check: CONVENTIONS.md mandates specific, unique names (grep < 5 hits rule).
if grep -q "specific and unique" CONVENTIONS.md 2>/dev/null; then
  exit 0
else
  echo "CONVENTIONS.md does not mandate specific and unique naming"
  exit 1
fi
