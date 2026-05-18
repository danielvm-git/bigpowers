#!/usr/bin/env bash
# Given the system architecture
# Check: specs/ dir and CLAUDE.md exist — architecture is documented.
if [[ -d "specs" && -f "CLAUDE.md" ]]; then
  exit 0
else
  echo "Architecture not documented: missing specs/ or CLAUDE.md"
  exit 1
fi
