#!/usr/bin/env bash
# And there should be no commented-out code (C5)
# Check: lines that match commented-out shell syntax (if [, for , while [, function).
VIOLATIONS=$(grep -rn '^[[:space:]]*#[[:space:]]*\(if \[\|for [a-z]\|while \[\|function [a-z]\)' \
  scripts/ specs/verifications/steps/ 2>/dev/null)

if [[ -z "$VIOLATIONS" ]]; then
  exit 0
else
  echo "Commented-out code found:"
  echo "$VIOLATIONS"
  exit 1
fi
