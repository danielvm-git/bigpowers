#!/usr/bin/env bash
# Regression: the protected-branch check must read the branch of the session's cwd
# (hook payload `.cwd`), not the branch of whatever directory the hook process
# started in. A worktree session on a feature branch was blocked because the hook ran
# from the main checkout, which sits on `main`.
set -euo pipefail
unset GIT_BIGPOWERS_LAND

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOK="$(cd "$SCRIPT_DIR/.." && pwd)/hooks/pre-tool-use.sh"

pass_count=0
fail_count=0

# run_hook <hook-process-cwd> <payload-json> -> sets EXIT_CODE and OUTPUT
run_hook() {
  EXIT_CODE=0
  OUTPUT=$(cd "$1" && echo "$2" | bash "$HOOK" 2>&1) || EXIT_CODE=$?
}

expect_allowed() {
  local label="$1"
  if [ "$EXIT_CODE" -eq 0 ]; then
    echo "  PASS $label"
    pass_count=$((pass_count + 1))
  else
    echo "  FAIL $label (expected allow, got exit $EXIT_CODE: $OUTPUT)"
    fail_count=$((fail_count + 1))
  fi
}

expect_blocked() {
  local label="$1"
  if [ "$EXIT_CODE" -ne 0 ] && echo "$OUTPUT" | grep -qi "protected branch"; then
    echo "  PASS $label"
    pass_count=$((pass_count + 1))
  else
    echo "  FAIL $label (expected protected-branch block, got exit $EXIT_CODE: $OUTPUT)"
    fail_count=$((fail_count + 1))
  fi
}

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

MAIN="$TMP_DIR/main-checkout"
WORKTREE="$TMP_DIR/feature-worktree"
git init -q -b main "$MAIN"
git -C "$MAIN" config user.email "test@bigpowers.local"
git -C "$MAIN" config user.name "test"
git -C "$MAIN" commit -q --allow-empty -m "chore: init"
git -C "$MAIN" worktree add -q -b feat/example "$WORKTREE"

commit_payload() {
  jq -nc --arg cwd "$1" '{tool_name:"Bash", cwd:$cwd, tool_input:{command:"git commit -m \"feat: add thing\""}}'
}
push_payload() {
  jq -nc --arg cwd "$1" '{tool_name:"Bash", cwd:$cwd, tool_input:{command:"git push"}}'
}

echo "=== Guard uses the session cwd, not the hook process cwd ==="

# The bug: hook process starts in the main checkout (on main), session is the worktree.
run_hook "$MAIN" "$(commit_payload "$WORKTREE")"
expect_allowed "commit from a feature-branch worktree is allowed when the hook runs on main"

run_hook "$MAIN" "$(push_payload "$WORKTREE")"
expect_allowed "bare push from a feature-branch worktree is allowed when the hook runs on main"

# The guard must still protect main when the session itself is on main.
run_hook "$WORKTREE" "$(commit_payload "$MAIN")"
expect_blocked "commit in a session on main is blocked even if the hook runs in a feature worktree"

run_hook "$MAIN" "$(push_payload "$MAIN")"
expect_blocked "bare push in a session on main is blocked"

# No cwd in the payload: fall back to the hook process cwd (previous behavior).
run_hook "$MAIN" '{"tool_name":"Bash","tool_input":{"command":"git commit -m \"feat: add thing\""}}'
expect_blocked "payload without cwd falls back to the hook process cwd (main)"

run_hook "$WORKTREE" '{"tool_name":"Bash","tool_input":{"command":"git commit -m \"feat: add thing\""}}'
expect_allowed "payload without cwd falls back to the hook process cwd (feature)"

# A stale or missing cwd must not turn into an allow-everything path.
run_hook "$MAIN" "$(commit_payload "$TMP_DIR/does-not-exist")"
expect_blocked "nonexistent payload cwd falls back to the hook process cwd (main)"

echo ""
echo "Results: $pass_count passed, $fail_count failed"
[ "$fail_count" -eq 0 ]
