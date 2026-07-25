#!/usr/bin/env bash
# story: BUG-2026-07-25-land-branch-protected
# Regression: land-branch protected-branch push rejection + PR fallback.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
# shellcheck source=../scripts/lib/land-branch-push.sh
source "$REPO_ROOT/scripts/lib/land-branch-push.sh"

pass_count=0
fail_count=0

assert_true() {
  local label="$1"
  shift
  if "$@"; then
    echo "  PASS $label"
    pass_count=$((pass_count + 1))
  else
    echo "  FAIL $label"
    fail_count=$((fail_count + 1))
  fi
}

assert_false() {
  local label="$1"
  shift
  if ! "$@"; then
    echo "  PASS $label"
    pass_count=$((pass_count + 1))
  else
    echo "  FAIL $label"
    fail_count=$((fail_count + 1))
  fi
}

assert_contains() {
  local label="$1"
  local haystack="$2"
  local needle="$3"
  if [[ "$haystack" == *"$needle"* ]]; then
    echo "  PASS $label"
    pass_count=$((pass_count + 1))
  else
    echo "  FAIL $label (missing: $needle)"
    fail_count=$((fail_count + 1))
  fi
}

echo "=== is_protected_branch_rejection fixtures ==="

GH006_FIXTURE=$'remote: error: GH006: Protected branch update failed for refs/heads/main.\nremote: - Changes must be made through a pull request.\nerror: failed to push some refs'
PR_ONLY_FIXTURE=$'remote: - Changes must be made through a pull request.\nerror: failed to push some refs'
UNRELATED_FIXTURE=$'error: failed to push some refs\nremote: Permission denied'

assert_true "detects GH006 rejection" is_protected_branch_rejection "$GH006_FIXTURE"
assert_true "detects PR-required message without GH006 code" is_protected_branch_rejection "$PR_ONLY_FIXTURE"
assert_false "ignores unrelated push failure" is_protected_branch_rejection "$UNRELATED_FIXTURE"

echo "=== temp bare remote with rejecting pre-receive hook ==="

TMPDIR_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMPDIR_ROOT"' EXIT

BARE="$TMPDIR_ROOT/remote.git"
WORK="$TMPDIR_ROOT/work"
MOCK_BIN="$TMPDIR_ROOT/bin"
mkdir -p "$MOCK_BIN"

git init --bare "$BARE" >/dev/null
mkdir -p "$BARE/hooks"
cat >"$BARE/hooks/pre-receive" <<'HOOK'
#!/bin/sh
while read -r oldrev newrev refname; do
  case "$refname" in
    refs/heads/main)
      if [ "$oldrev" = "0000000000000000000000000000000000000000" ]; then
        continue
      fi
      echo "remote: error: GH006: Protected branch update failed for refs/heads/main."
      echo "remote: - Changes must be made through a pull request."
      exit 1
      ;;
  esac
done
exit 0
HOOK
chmod +x "$BARE/hooks/pre-receive"

git clone "$BARE" "$WORK" >/dev/null
git -C "$WORK" config user.email "test@example.com"
git -C "$WORK" config user.name "test"
echo "base" >"$WORK/README.md"
git -C "$WORK" add README.md
git -C "$WORK" commit -qm "chore: init"
git -C "$WORK" push origin main >/dev/null

git -C "$WORK" checkout -b feat/test >/dev/null
echo "feature" >>"$WORK/README.md"
git -C "$WORK" add README.md
git -C "$WORK" commit -qm "feat: add feature"
git -C "$WORK" checkout main >/dev/null
git -C "$WORK" merge --squash feat/test >/dev/null
git -C "$WORK" commit -qm "feat(test): squash land"
LAND_SHA="$(git -C "$WORK" rev-parse --short HEAD)"
LAND_FULL_SHA="$(git -C "$WORK" rev-parse HEAD)"
RECOVERY_BRANCH="land-recovery/feat/test"

cat >"$MOCK_BIN/gh" <<'MOCK'
#!/usr/bin/env bash
echo "https://github.com/example/repo/pull/1"
exit 0
MOCK
chmod +x "$MOCK_BIN/gh"

cd "$WORK"
export PATH="$MOCK_BIN:$PATH"
LAND_PR_FALLBACK=0
if ! land_push_default_branch main "$LAND_SHA" "feat/test" "feat(test): squash land"; then
  echo "  FAIL land_push_default_branch should succeed via PR fallback"
  fail_count=$((fail_count + 1))
else
  echo "  PASS land_push_default_branch succeeds on protected rejection"
  pass_count=$((pass_count + 1))
fi

if [ "$LAND_PR_FALLBACK" = "1" ]; then
  echo "  PASS LAND_PR_FALLBACK flag set"
  pass_count=$((pass_count + 1))
else
  echo "  FAIL LAND_PR_FALLBACK flag not set"
  fail_count=$((fail_count + 1))
fi

if git show-ref --verify --quiet "refs/heads/$RECOVERY_BRANCH"; then
  echo "  PASS recovery branch exists locally"
  pass_count=$((pass_count + 1))
else
  echo "  FAIL recovery branch missing locally"
  fail_count=$((fail_count + 1))
fi

if git rev-parse main >/dev/null 2>&1 && [ "$(git rev-parse main)" != "$LAND_FULL_SHA" ]; then
  echo "  PASS local main reset away from stranded squash commit"
  pass_count=$((pass_count + 1))
else
  echo "  FAIL local main still points at squash commit"
  fail_count=$((fail_count + 1))
fi

if git ls-remote --heads origin "$RECOVERY_BRANCH" | grep -q "$RECOVERY_BRANCH"; then
  echo "  PASS recovery branch pushed to origin"
  pass_count=$((pass_count + 1))
else
  echo "  FAIL recovery branch not on origin"
  fail_count=$((fail_count + 1))
fi
cd "$REPO_ROOT"

echo "=== gh failure prints recovery commands ==="

BARE2="$TMPDIR_ROOT/remote2.git"
WORK2="$TMPDIR_ROOT/work2"
git init --bare "$BARE2" >/dev/null
mkdir -p "$BARE2/hooks"
cp "$BARE/hooks/pre-receive" "$BARE2/hooks/pre-receive"
chmod +x "$BARE2/hooks/pre-receive"

cat >"$MOCK_BIN/gh" <<'MOCK'
#!/usr/bin/env bash
echo "gh: authentication required" >&2
exit 1
MOCK
chmod +x "$MOCK_BIN/gh"

git clone "$BARE2" "$WORK2" >/dev/null
git -C "$WORK2" config user.email "test@example.com"
git -C "$WORK2" config user.name "test"
echo "base" >"$WORK2/README.md"
git -C "$WORK2" add README.md
git -C "$WORK2" commit -qm "chore: init"
git -C "$WORK2" push origin main >/dev/null
git -C "$WORK2" checkout -b feat/broken >/dev/null
echo "feature" >>"$WORK2/README.md"
git -C "$WORK2" add README.md
git -C "$WORK2" commit -qm "feat: broken land"
git -C "$WORK2" checkout main >/dev/null
git -C "$WORK2" merge --squash feat/broken >/dev/null
git -C "$WORK2" commit -qm "feat(broken): squash land"
BROKEN_SHA="$(git -C "$WORK2" rev-parse --short HEAD)"
BROKEN_FULL_SHA="$(git -C "$WORK2" rev-parse HEAD)"
BROKEN_RECOVERY="land-recovery/feat/broken"

cd "$WORK2"
export PATH="$MOCK_BIN:$PATH"
set +e
stderr_file="$(mktemp)"
land_push_default_branch main "$BROKEN_SHA" "feat/broken" "feat(broken): squash land" 2>"$stderr_file"
status=$?
set -e
stderr="$(cat "$stderr_file")"
rm -f "$stderr_file"

if [ "$status" -ne 0 ]; then
  echo "  PASS land_push_default_branch exits non-zero when gh fails"
  pass_count=$((pass_count + 1))
else
  echo "  FAIL expected non-zero exit when gh fails"
  fail_count=$((fail_count + 1))
fi

assert_contains "recovery commands mention git branch" "$stderr" "git branch $BROKEN_RECOVERY $BROKEN_FULL_SHA"
assert_contains "recovery commands mention gh pr create" "$stderr" "gh pr create --base main --head $BROKEN_RECOVERY"
cd "$REPO_ROOT"

echo ""
echo "Results: $pass_count passed, $fail_count failed"
if [ "$fail_count" -gt 0 ]; then
  exit 1
fi
echo "All land-branch protected-branch tests passed."
