#!/usr/bin/env bash
# And I should match the existing code style and conventions
# Evidence: CONVENTIONS.md exists and audit-code checks compliance with it
if [ -f "CONVENTIONS.md" ] && grep -q "CONVENTIONS.md" audit-code/SKILL.md; then
  exit 0
fi
echo "CONVENTIONS.md missing or not referenced in audit-code"
exit 1
