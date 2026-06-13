#!/usr/bin/env bash
# And I should compact session state for cold-starts
# Check: session-state skill exists — dedicated session compaction capability.
if [[ -f "session-state/SKILL.md" ]]; then
  exit 0
else
  echo "session-state/SKILL.md not found — no session compaction skill"
  exit 1
fi
