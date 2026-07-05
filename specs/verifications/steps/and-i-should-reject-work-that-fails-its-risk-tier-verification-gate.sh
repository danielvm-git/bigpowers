#!/usr/bin/env bash
# And I should reject work that fails its risk-tier verification gate
# Evidence: verify-work scales by P0-P3; release-branch HARD GATE blocks red branches
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
vw="$REPO_ROOT/skills/verify-work/SKILL.md"
rb="$REPO_ROOT/skills/release-branch/SKILL.md"
missing=0
for tier in P0 P1 P2 P3; do
  grep -q "$tier" "$vw" || missing=$((missing + 1))
done
if [[ $missing -gt 0 ]]; then
  echo "verify-work missing P0-P3 risk-tier verification depth"
  exit 1
fi
if ! grep -qi 'HARD GATE\|HARD-GATE' "$rb"; then
  echo "release-branch missing HARD GATE for failed verification"
  exit 1
fi
if ! grep -qi 'gate\|block' "$rb"; then
  echo "release-branch missing merge block on failed gates"
  exit 1
fi
exit 0
