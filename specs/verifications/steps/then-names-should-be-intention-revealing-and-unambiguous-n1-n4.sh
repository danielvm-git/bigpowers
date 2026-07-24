#!/usr/bin/env bash
# Then names should be intention-revealing and unambiguous (N1, N4)
# Verification: Check for "data", "manager", "handler" in filenames (smells)
# Exclusions: compound words where data/manager/handler is part of a meaningful phrase,
# plus filenames dictated by an external framework's own loader convention (not our naming choice)
BAD_NAMES=$(find . -type f \
  | grep -v '.git' | grep -v 'node_modules' | grep -v 'specs/epics' \
  | grep -vE '\.(git|venv|worktrees)/' \
  | grep -vE '(without-data-loss|test-data|example-data)' \
  | grep -vE 'scripts/hooks/hermes/gateway/session-log/handler\.py' \
  | grep -E '(^|[-_./])data([-_./]|$)|(^|[-_./])manager([-_./]|$)|(^|[-_./])handler([-_./]|$)' \
  || true)

if [[ -z "$BAD_NAMES" ]]; then
  exit 0
else
  echo "Ambiguous names found: $BAD_NAMES"
  exit 1
fi
