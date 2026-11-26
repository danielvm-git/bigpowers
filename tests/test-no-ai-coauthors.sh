#!/usr/bin/env bash
# story: e38s08
# test-no-ai-coauthors.sh — no commit introduced by this change may carry an AI
# attribution footer (CONVENTIONS.md § Git Attribution, P1).
#
# Why this exists: hooks/pre-tool-use.sh blocks the *command*, and
# scripts/land-branch.sh blocks the *solo-local land*. Neither runs when a pull
# request is merged with `gh pr merge`, so the rule was enforceable only on the
# path it was written for. This gate runs in CI on both paths.
#
# Scope is the commits this branch introduces (origin/main..HEAD). Attribution
# trailers already on main are history: removing them would rewrite main and
# invalidate every SHA cited in specs/, so they are not this gate's business.
#
# Usage: bash tests/test-no-ai-coauthors.sh [range] [--self-test]
set -euo pipefail
cd "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

PATTERN='^[[:space:]]*co[- ]authored[- ]by:'

scan_range() { # $1 = git range or empty
  local range="$1" hits
  if [ -z "$range" ]; then
    echo "ok  : no commits ahead of main to check"
    return 0
  fi
  hits=$(git log "$range" --format='%h %s%n%b' 2>/dev/null | grep -iE "$PATTERN" || true)
  if [ -n "$hits" ]; then
    echo "FAIL: AI attribution footer in commits introduced by this change:"
    git log "$range" --format='%h %s' | while read -r line; do
      if git log -1 --format='%b' "${line%% *}" | grep -qiE "$PATTERN"; then
        echo "  - $line"
      fi
    done
    echo ""
    echo "Amend the commit to drop the trailer. All commits must appear as if"
    echo "authored solely by the human user (CONVENTIONS.md § Git Attribution)."
    return 1
  fi
  echo "ok  : no AI attribution in $range"
}

self_test() {
  local ok=1
  SELFTEST_TMP=$(mktemp -d)
  trap 'rm -rf "${SELFTEST_TMP:-}"' EXIT
  (
    cd "$SELFTEST_TMP"
    git init -q . && git config user.email t@t && git config user.name t
    echo a > a.txt && git add a.txt && git commit -qm "chore: base"
    git branch -q base
    echo b > b.txt && git add b.txt && git commit -qm "feat(x): fine" 
    if scan_range "base..HEAD" >/dev/null; then echo "PASS (clean range passes)"; else echo "FAIL (clean range should pass)"; exit 1; fi
    echo c > c.txt && git add c.txt
    git commit -qm "feat(x): bad" -m "Co-Authored-By: Someone <s@example.com>"
    if scan_range "base..HEAD" >/dev/null; then echo "FAIL (co-authored commit should fail)"; exit 1; else echo "PASS (co-authored commit fails)"; fi
  ) || ok=0
  [ "$ok" -eq 1 ] && echo "OK: no-ai-coauthors self-test" || { echo "self-test FAILED"; exit 1; }
}

default_range() {
  # Always check at least one commit, so the gate cannot pass vacuously.
  if git rev-parse --verify -q origin/main >/dev/null 2>&1; then
    if [ -n "$(git rev-list origin/main..HEAD 2>/dev/null)" ]; then
      printf '%s' 'origin/main..HEAD'
      return
    fi
  fi
  if git rev-parse --verify -q HEAD~1 >/dev/null 2>&1; then
    printf '%s' 'HEAD~1..HEAD'
  else
    printf '%s' 'HEAD'
  fi
}

case "${1:-}" in
  --self-test) self_test; exit 0 ;;
  "") scan_range "$(default_range)" ;;
  *) scan_range "$1" ;;
esac
