#!/usr/bin/env bash
# And it must mandate the F.I.R.S.T rubric for tests
if grep -q "F.I.R.S.T" CONVENTIONS.md 2>/dev/null; then
  exit 0
else
  echo "CONVENTIONS.md does not mandate the F.I.R.S.T rubric for tests"
  exit 1
fi
