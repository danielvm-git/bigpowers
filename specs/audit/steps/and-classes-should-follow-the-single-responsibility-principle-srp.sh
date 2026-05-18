#!/usr/bin/env bash
# And classes should follow the Single Responsibility Principle (SRP)
# For bigpowers: each skill directory must contain exactly one SKILL.md (single purpose).
VIOLATIONS=$(find . -maxdepth 2 -name "SKILL.md" | sed 's|/SKILL.md||' | sort | uniq -d)

if [[ -z "$VIOLATIONS" ]]; then
  exit 0
else
  echo "Skill dirs with duplicate SKILL.md entries: $VIOLATIONS"
  exit 1
fi
