#!/usr/bin/env bash
# story: e53s01
# test-golden-g11-worktree-venv.sh — regression test for
# BUG-2026-07-23-golden-g11-worktree-venv: golden-g11-gitignore-venv.sh must
# PASS in a fresh worktree where .venv does not exist yet on disk (before
# setup-environment has run), not just when a real .venv is already present.
#
# Usage: bash scripts/test-golden-g11-worktree-venv.sh

set -euo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

FAILURES=0
tt_pass() { echo -e "${GREEN}PASS${NC} $1"; }
tt_fail() { echo -e "${RED}FAIL${NC} $1"; FAILURES=$((FAILURES + 1)); }
strip_ansi() { sed -E 's/\x1b\[[0-9;]*m//g'; }

VENV_MOVED=0
if [[ -e .venv ]]; then
  mv .venv .venv.test-golden-g11-backup
  VENV_MOVED=1
fi

cleanup() {
  rm -rf .venv
  if [[ "$VENV_MOVED" -eq 1 ]]; then
    mv .venv.test-golden-g11-backup .venv
  fi
}
trap cleanup EXIT

# --- Scenario: .venv absent (fresh worktree) → gate still PASSes ---
if [[ -e .venv ]]; then
  tt_fail "test setup failed to remove .venv before running the gate"
else
  output=$(bash scripts/golden-g11-gitignore-venv.sh 2>&1 | strip_ansi) && exit_code=0 || exit_code=$?
  if [[ "$exit_code" -eq 0 ]] && echo "$output" | grep -q "PASS git check-ignore .venv"; then
    tt_pass "gate PASSes when .venv does not exist on disk"
  else
    tt_fail "gate did not PASS with .venv absent (exit=$exit_code)"
  fi

  # The gate must clean up the .venv it created for the check — a fresh
  # worktree shouldn't be left with a stray directory after a gate run.
  if [[ ! -e .venv ]]; then
    tt_pass "gate removes the .venv it created for the check"
  else
    tt_fail "gate left a stray .venv behind after the check"
  fi
fi

echo "---"
if [[ "$FAILURES" -eq 0 ]]; then
  echo -e "${GREEN}test-golden-g11-worktree-venv: ALL PASS${NC}"
else
  echo -e "${RED}test-golden-g11-worktree-venv: $FAILURES failure(s)${NC}"
fi
exit "$FAILURES"
