#!/usr/bin/env bash
# And I should identify and deepen "shallow" modules
# Check: deepen-architecture skill exists — dedicated shallow-module deepening capability.
if [[ -f "deepen-architecture/SKILL.md" ]]; then
  exit 0
else
  echo "deepen-architecture/SKILL.md not found — no deepening skill"
  exit 1
fi
