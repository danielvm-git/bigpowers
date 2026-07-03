#!/usr/bin/env bash
# And I should use "caveman" mode to reduce token usage
# Check: terse-mode skill exists — dedicated caveman/token-reduction capability.
if [[ -f "skills/terse-mode/SKILL.md" ]]; then
  exit 0
else
  echo "skills/terse-mode/SKILL.md not found — no caveman mode skill"
  exit 1
fi
