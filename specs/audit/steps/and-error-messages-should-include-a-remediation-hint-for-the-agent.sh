#!/usr/bin/env bash
# And error messages should include a "remediation hint" for the agent
# Check: CONVENTIONS.md mandates remediation hints in error messages.
if grep -qi "remediation" CONVENTIONS.md 2>/dev/null; then
  exit 0
else
  echo "CONVENTIONS.md does not mandate remediation hints in error messages"
  exit 1
fi
