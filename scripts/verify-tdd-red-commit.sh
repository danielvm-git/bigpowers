#!/usr/bin/env bash
# story: e80s01 e80s03
# Mechanical gate: test-only (RED) commit must fail when checked out in isolation.
# Usage:
#   bash scripts/verify-tdd-red-commit.sh [--self-test]
#   TDD_VERIFY_CMD='npm test' bash scripts/verify-tdd-red-commit.sh
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

self_test() {
  local tmp
  tmp=$(mktemp -d)
  trap 'rm -rf "$tmp"' RETURN
  cd "$tmp"
  git init -q
  git config user.email "tdd-verify@bigpowers.local"
  git config user.name "tdd-verify"

  mkdir -p test
  cat > package.json <<'JSON'
{"name":"tdd-fixture","scripts":{"test":"node test/run.js"}}
JSON
  cat > test/run.js <<'JS'
const fs = require('fs');
const impl = fs.existsSync('src/impl.js');
process.exit(impl ? 0 : 1);
JS
  git add .
  git commit -q -m "test(scope): red — expect failure without impl"

  git checkout -q HEAD
  if node test/run.js; then
    echo "FAIL: RED commit passed in isolation (expected failure)"
    return 1
  fi
  echo "PASS: RED commit fails in isolation"

  mkdir -p src
  echo 'module.exports = {};' > src/impl.js
  git add src/impl.js
  git commit -q -m "fix(scope): green — implementation"
  if ! node test/run.js; then
    echo "FAIL: GREEN commit should pass"
    return 1
  fi
  echo "PASS: GREEN commit passes"
  echo "verify-tdd-red-commit: self-test OK"
}

if [[ "${1:-}" == "--self-test" ]]; then
  self_test
  exit $?
fi

if ! git rev-parse --git-dir >/dev/null 2>&1; then
  echo "ERROR: not a git repository"
  exit 1
fi

if [[ "$(git rev-list --count HEAD 2>/dev/null || echo 0)" -lt 2 ]]; then
  echo "SKIP: need at least 2 commits (test-only RED then fix GREEN)"
  exit 0
fi

VERIFY_CMD="${TDD_VERIFY_CMD:-}"
if [[ -z "$VERIFY_CMD" ]]; then
  if [[ -f package.json ]] && grep -q '"test"' package.json 2>/dev/null; then
    VERIFY_CMD="npm test --if-present"
  elif [[ -f Cargo.toml ]]; then
    VERIFY_CMD="cargo test"
  else
    echo "SKIP: set TDD_VERIFY_CMD for this repo"
    exit 0
  fi
fi

RED_SHA=$(git rev-parse HEAD~1)
WORKTREE=$(mktemp -d)
trap 'git worktree remove -f "$WORKTREE" 2>/dev/null || rm -rf "$WORKTREE"' EXIT

git worktree add -q --detach "$WORKTREE" "$RED_SHA"
(
  cd "$WORKTREE"
  if bash -c "$VERIFY_CMD"; then
    echo "FAIL: test-only commit $RED_SHA passed in isolation — RED gate violated"
    exit 1
  fi
  echo "PASS: test-only commit $RED_SHA fails in isolation"
)
