#!/usr/bin/env bash
# And complex logic should include "Provenance" links (ADRs, Jira, or Commits)
# Check: CONVENTIONS.md mandates Provenance links for complex or non-obvious logic.
if grep -qi "provenance" CONVENTIONS.md 2>/dev/null; then
  exit 0
else
  echo "CONVENTIONS.md does not mandate Provenance links"
  exit 1
fi
