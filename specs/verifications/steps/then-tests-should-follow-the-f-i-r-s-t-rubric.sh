#!/usr/bin/env bash
# Then tests should follow the F.I.R.S.T rubric
# Verification: Check for "F.I.R.S.T" in skill docs and test files
if grep -rq "F.I.R.S.T" . --include="*.md" --include="*.mdc"; then
  exit 0
else
  echo "F.I.R.S.T rubric not referenced in documentation or rules."
  exit 1
fi
