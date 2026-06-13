#!/usr/bin/env bash
# And it must mandate explicit typing
if grep -q "explicit" CONVENTIONS.md 2>/dev/null; then
  exit 0
else
  echo "CONVENTIONS.md does not mandate explicit typing"
  exit 1
fi
