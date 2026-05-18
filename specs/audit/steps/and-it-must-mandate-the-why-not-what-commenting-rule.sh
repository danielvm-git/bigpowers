#!/usr/bin/env bash
# And it must mandate the "Why not What" commenting rule
if grep -q "WHY" CONVENTIONS.md 2>/dev/null && grep -q "WHAT" CONVENTIONS.md 2>/dev/null; then
  exit 0
else
  echo "CONVENTIONS.md does not mandate the Why not What commenting rule"
  exit 1
fi
