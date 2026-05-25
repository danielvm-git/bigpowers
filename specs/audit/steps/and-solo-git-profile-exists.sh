#!/usr/bin/env bash
# And solo-git profile documents local land workflow
set -euo pipefail
if [ -f profiles/solo-git.md ] && grep -q "land-branch.sh" profiles/solo-git.md; then
  exit 0
fi
echo "profiles/solo-git.md missing or does not reference land-branch.sh"
exit 1
