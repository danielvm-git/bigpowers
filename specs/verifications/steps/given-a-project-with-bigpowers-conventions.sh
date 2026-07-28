#!/usr/bin/env bash
# Given a project with bigpowers conventions
# Check: CONVENTIONS.md and specs/ exist — this project has adopted bigpowers governance.
if [[ -f "CONVENTIONS.md" && -d "specs" ]]; then
  exit 0
else
  echo "Not a bigpowers-conventions project: missing CONVENTIONS.md or specs/"
  exit 1
fi
