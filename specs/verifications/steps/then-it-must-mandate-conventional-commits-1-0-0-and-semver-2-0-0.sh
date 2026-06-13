#!/usr/bin/env bash
# Then it must mandate Conventional Commits 1.0.0 and SemVer 2.0.0
if grep -q "Conventional Commits" CONVENTIONS.md 2>/dev/null && grep -q "Semantic Versioning" CONVENTIONS.md 2>/dev/null; then
  exit 0
else
  echo "CONVENTIONS.md does not mandate Conventional Commits and Semantic Versioning"
  exit 1
fi
