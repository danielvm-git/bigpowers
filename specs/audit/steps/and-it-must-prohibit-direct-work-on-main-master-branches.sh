#!/usr/bin/env bash
# And it must prohibit direct work on main/master branches
if grep -q "No direct work" CONVENTIONS.md 2>/dev/null; then
  exit 0
else
  echo "CONVENTIONS.md does not prohibit direct work on main/master"
  exit 1
fi
