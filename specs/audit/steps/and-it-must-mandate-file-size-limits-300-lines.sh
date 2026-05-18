#!/usr/bin/env bash
# And it must mandate file size limits (< 300 lines)
if grep -q "300 lines" CONVENTIONS.md 2>/dev/null; then
  exit 0
else
  echo "CONVENTIONS.md does not mandate file size limits (< 300 lines)"
  exit 1
fi
