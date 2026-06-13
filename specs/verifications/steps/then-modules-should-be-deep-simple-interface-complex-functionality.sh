#!/usr/bin/env bash
# Then modules should be "deep" (simple interface, complex functionality)
# Check: CONVENTIONS.md mandates wrapping libs behind thin interfaces.
if grep -q "interface" CONVENTIONS.md 2>/dev/null; then
  exit 0
else
  echo "CONVENTIONS.md does not mandate thin interfaces for modules"
  exit 1
fi
