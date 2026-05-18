#!/usr/bin/env bash
# Then names should be intention-revealing and unambiguous (N1, N4)
# Verification: Check for "data", "manager", "handler" in filenames (smells)
BAD_NAMES=$(find . -name "*data*" -o -name "*manager*" -o -name "*handler*" | grep -v ".git" | grep -v "node_modules" | grep -v '^\./\.')

if [[ -z "$BAD_NAMES" ]]; then
  exit 0
else
  echo "Ambiguous names found: $BAD_NAMES"
  exit 1
fi
