#!/usr/bin/env bash
# And every change should include runnable tests as verification
# Check: CONVENTIONS.md mandates verification steps for every change.
if grep -qi "verif" CONVENTIONS.md 2>/dev/null; then
  exit 0
else
  echo "CONVENTIONS.md does not mandate runnable verification"
  exit 1
fi
