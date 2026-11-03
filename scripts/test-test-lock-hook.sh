#!/usr/bin/env bash
# story: e86s02
# Test suite for test-lock hook and RED-commit verification in pre-tool-use.sh.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
HOOK="$REPO_ROOT/hooks/pre-tool-use.sh"

pass_count=0
fail_count=0

lock_assert_denied() {
  local label="$1"
  local input="$2"
  local expected_substr="${3:-}"
  local output exit_code=0
  output=$(echo "$input" | bash "$HOOK" 2>&1) || exit_code=$?
  if [ "$exit_code" -ne 0 ] || echo "$output" | grep -q '"decision"[[:space:]]*:[[:space:]]*"deny"'; then
    if [ -n "$expected_substr" ] && ! echo "$output" | grep -qi "$expected_substr"; then
      echo "  FAIL $label (expected to contain '$expected_substr', got: $output)"
      fail_count=$((fail_count + 1))
    else
      echo "  PASS $label"
      pass_count=$((pass_count + 1))
    fi
  else
    echo "  FAIL $label (expected deny, but was allowed: $output)"
    fail_count=$((fail_count + 1))
  fi
}

lock_assert_allowed() {
  local label="$1"
  local input="$2"
  local output exit_code=0
  output=$(echo "$input" | bash "$HOOK" 2>&1) || exit_code=$?
  if [ "$exit_code" -eq 0 ] && ! echo "$output" | grep -q '"decision"[[:space:]]*:[[:space:]]*"deny"'; then
    echo "  PASS $label"
    pass_count=$((pass_count + 1))
  else
    echo "  FAIL $label (expected allow, but was denied: $output)"
    fail_count=$((fail_count + 1))
  fi
}

echo "=== Test Locking Hook Tests (e86s02) ==="

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

cd "$TMP_DIR"
git init -q
git config user.email "test@bigpowers.local"
git config user.name "test"
mkdir -p specs test src

cat > specs/state.yaml <<'YAML'
active_flow: fix_bug
YAML

echo "initial" > src/app.js
git add .
git commit -q -m "feat(app): initial commit"

# 1. Without a RED commit yet during fix_bug, test edits should be allowed (to author the RED test)
lock_assert_allowed "Test file edit allowed when authoring RED test" \
  '{"tool": "Edit", "file_path": "test/app.test.js"}'

# 2. Commit a RED test
echo "test red" > test/app.test.js
git add test/app.test.js
git commit -q -m "test(app): red test reproducing defect"

# 3. Now that a RED commit exists and active_flow is fix_bug, test edits must be LOCKED
lock_assert_denied "Test file edit denied after RED commit in fix_bug" \
  '{"tool": "Edit", "file_path": "test/app.test.js"}' \
  "locked"

lock_assert_denied "Test file write denied after RED commit in fix_bug" \
  '{"tool": "Write", "file_path": "tests/test_other.py"}' \
  "locked"

# 4. Source file edits must remain allowed
lock_assert_allowed "Source file edit allowed after RED commit in fix_bug" \
  '{"tool": "Edit", "file_path": "src/app.js"}'

# 5. When active_flow is not fix_bug, test edits are allowed
cat > specs/state.yaml <<'YAML'
active_flow: build_epic
YAML
lock_assert_allowed "Test file edit allowed when active_flow is not fix_bug" \
  '{"tool": "Edit", "file_path": "test/app.test.js"}'

echo ""
echo "=== Summary: $pass_count passed, $fail_count failed ==="
if [ "$fail_count" -gt 0 ]; then
  exit 1
fi
exit 0
