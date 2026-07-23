#!/usr/bin/env bash
# story: e53s01
# golden-g11-gitignore-venv.sh — Python venv gitignore gate (G-11)
#
# Prevents recurrence of BUG-2026-07-03-venv-not-gitignored: a root .venv/
# must be ignored before `git add .` can accidentally commit vendored packages.
#
# Asserts:
#   1. .gitignore contains .venv/, venv/, __pycache__/, *.pyc
#   2. git check-ignore .venv succeeds (when .venv exists or as path rule)
#
# Exit 0 on all assertions passing; exit 1 on first failure.
#
# Usage: bash scripts/golden-g11-gitignore-venv.sh

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/skill-common.sh"
resolve_repo_root

cd "$REPO_ROOT"

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

PASS=0
FAIL=0

g11_pass() { echo -e "${GREEN}PASS${NC} $*"; PASS=$((PASS + 1)); }
g11_fail() { echo -e "${RED}FAIL${NC} $*"; FAIL=$((FAIL + 1)); }

required_patterns=( '.venv/' 'venv/' '__pycache__/' '*.pyc' )

for pattern in "${required_patterns[@]}"; do
  if grep -qxF "$pattern" .gitignore; then
    g11_pass ".gitignore contains $pattern"
  else
    g11_fail ".gitignore missing $pattern"
  fi
done

# git check-ignore on a directory-only pattern (.venv/) only matches when the
# path is confirmed to be a directory — a nonexistent .venv (e.g. a fresh
# kickoff-branch worktree, before setup-environment runs) reports as "not
# ignored" even when the pattern is correct. Create it if absent so the check
# is independent of prior local setup; remove it again only if we created it.
CREATED_VENV=0
if [ ! -e .venv ]; then
  mkdir .venv
  CREATED_VENV=1
fi

if git check-ignore -q .venv 2>/dev/null; then
  g11_pass "git check-ignore .venv"
else
  g11_fail "git check-ignore .venv (path not ignored)"
fi

[ "$CREATED_VENV" -eq 1 ] && rmdir .venv 2>/dev/null || true

echo ""
echo "G-11 summary: $PASS passed, $FAIL failed"
if [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
