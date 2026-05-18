#!/usr/bin/env bash
# And tests should be fast and run with a single command (T9)
# Check: CLAUDE.md defines a Test or Run command in its commands table.
if grep -q '| Test\|| Run' CLAUDE.md 2>/dev/null; then
  exit 0
else
  echo "CLAUDE.md does not define a Test or Run command"
  exit 1
fi
