#!/usr/bin/env bash
# And it must mandate function size limits (4-20 lines)
if grep -q "20 lines" CONVENTIONS.md 2>/dev/null; then
  exit 0
else
  echo "CONVENTIONS.md does not mandate function size limits (4-20 lines)"
  exit 1
fi
