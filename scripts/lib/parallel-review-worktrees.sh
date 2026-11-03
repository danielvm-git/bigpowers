#!/usr/bin/env bash
# story: e45s18
# parallel-review-worktrees.sh — isolated git worktrees for parallel audit-code / security-review
# Usage: bash scripts/lib/parallel-review-worktrees.sh <audit-code|security-review>
set -euo pipefail

CHECK="${1:?usage: parallel-review-worktrees.sh <audit-code|security-review>}"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

BASE=".bigpowers/worktrees/review-${CHECK}"
mkdir -p "$(dirname "$BASE")"

# Capture first: `git worktree list | grep -q` is a pipefail race (BUG-2026-11-02-pipefail-pipe-race).
WORKTREES="$(git worktree list)"
if grep -q "$BASE" <<<"$WORKTREES"; then
  git worktree remove --force "$BASE" 2>/dev/null || true
fi

git worktree add --detach "$BASE" HEAD >/dev/null
echo "WORKTREE: $BASE (detached @ $(git -C "$BASE" rev-parse --short HEAD))"

case "$CHECK" in
  audit-code)
    echo "Run audit-code checklist inside worktree; reports → specs/verifications/"
    ;;
  security-review)
    echo "Run security-review 5-phase scan inside worktree; reports → specs/security/"
    ;;
  *)
    echo "Unknown check: $CHECK" >&2
    exit 2
    ;;
esac

echo "OK: isolated worktree ready — parallel checks cannot corrupt parent working tree"
