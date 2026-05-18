#!/usr/bin/env bash
# And I should automatically bootstrap project context at session start
# Evidence: CLAUDE.md Session Start section mandates reading CLAUDE.md, CONVENTIONS.md, STATE.md
if grep -q "Session Start" CLAUDE.md && grep -q "Before any task" CLAUDE.md; then
  exit 0
fi
echo "No mandatory Session Start bootstrap section found in CLAUDE.md"
exit 1
