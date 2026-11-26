#!/usr/bin/env bash
# story: BUG-2026-11-07-assert-epic-gate-fail-open
# Regression test: assert-epic-gate.sh release must fail when specs/AUDIT_LATEST.md
# has no audited_range or records a range that does not match the current branch diff.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GATE="$REPO_ROOT/scripts/lib/assert-epic-gate.sh"

pass=0
fail=0
ok()  { printf 'ok   %s\n' "$1"; pass=$((pass + 1)); }
bad() { printf 'FAIL %s\n' "$1"; fail=$((fail + 1)); }

TMP_REPO="$(mktemp -d)"
trap 'rm -rf "$TMP_REPO"' EXIT

cd "$TMP_REPO"
git init -q -b main
git config user.name "Test User"
git config user.email "test@example.com"
echo "base" > file.txt
git add file.txt
git commit -q -m "chore: initial"
BASE_SHA="$(git rev-parse HEAD)"
BASE_SHORT="$(git rev-parse --short HEAD)"

# Create another branch with 2 commits (simulates stale PR #194 audit)
git checkout -q -b feat/other
echo "other1" >> file.txt && git commit -qam "feat: other 1"
echo "other2" >> file.txt && git commit -qam "feat: other 2"
OTHER_HEAD="$(git rev-parse HEAD)"

# Create target feature branch with 2 commits
git checkout -q -b feat/target "$BASE_SHA"
echo "target1" >> file.txt && git commit -qam "feat: target 1"
TARGET_C1="$(git rev-parse HEAD)"
echo "target2" >> file.txt && git commit -qam "feat: target 2"
TARGET_HEAD="$(git rev-parse HEAD)"
TARGET_SHORT="$(git rev-parse --short HEAD)"

mkdir -p specs

# T1 — Missing audited_range on release MUST fail
cat > specs/AUDIT_LATEST.md <<'MD'
# Audit Code — PR #194
**VERDICT: PASS**
MD
out="$(bash "$GATE" release 2>&1 || true)"
if ! bash "$GATE" release >/dev/null 2>&1 && grep -qi "audited_range" <<<"$out"; then
  ok "T1 release fails when audited_range is missing"
else
  bad "T1 release passed or lacked audited_range diagnostic: $out"
fi

# T2 — Stale audit from another branch MUST fail with explicit range mismatch
cat > specs/AUDIT_LATEST.md <<MD
# Audit Code — feat/other
audited_range: { base: $BASE_SHA, head: $OTHER_HEAD, commits: 2 }
**VERDICT: PASS**
MD
out="$(bash "$GATE" release 2>&1 || true)"
if ! bash "$GATE" release >/dev/null 2>&1 && grep -q "audit covers" <<<"$out"; then
  ok "T2 release fails on stale audit from another branch"
else
  bad "T2 release passed or lacked mismatch message: $out"
fi

# T3 — Stale commit count (new commit added after audit) MUST fail
cat > specs/AUDIT_LATEST.md <<MD
# Audit Code — feat/target (1 commit)
audited_range: { base: $BASE_SHA, head: $TARGET_C1, commits: 1 }
**VERDICT: PASS**
MD
out="$(bash "$GATE" release 2>&1 || true)"
if ! bash "$GATE" release >/dev/null 2>&1 && grep -q "1 commits" <<<"$out" && grep -q "2 commits" <<<"$out"; then
  ok "T3 release fails when branch has extra unaudited commits"
else
  bad "T3 release passed or lacked commit counts: $out"
fi

# T4 — Exact matching audited_range MUST pass
cat > specs/AUDIT_LATEST.md <<MD
# Audit Code — feat/target
audited_range: { base: $BASE_SHA, head: $TARGET_HEAD, commits: 2 }
**VERDICT: PASS**
MD
if bash "$GATE" release >/dev/null 2>&1; then
  ok "T4 release passes when audited_range matches current branch diff"
else
  bad "T4 release failed on valid matching audited_range"
fi

# T5 — Short SHAs in audited_range MUST pass
cat > specs/AUDIT_LATEST.md <<MD
# Audit Code — feat/target
audited_range: { base: $BASE_SHORT, head: $TARGET_SHORT, commits: 2 }
**VERDICT: PASS**
MD
if bash "$GATE" release >/dev/null 2>&1; then
  ok "T5 release passes with short SHAs in audited_range"
else
  bad "T5 release failed with short SHAs"
fi

# T6 — Non-release stage (commit) remains backward compatible without audited_range
cat > specs/AUDIT_LATEST.md <<'MD'
# Audit Code
VERDICT: PASS
MD
if bash "$GATE" commit >/dev/null 2>&1; then
  ok "T6 commit stage remains backward compatible without audited_range"
else
  bad "T6 commit stage broke without audited_range"
fi

# T7 — VERDICT: FAIL still fails even with matching audited_range
cat > specs/AUDIT_LATEST.md <<MD
# Audit Code — feat/target
audited_range: { base: $BASE_SHA, head: $TARGET_HEAD, commits: 2 }
**VERDICT: FAIL**
MD
if ! bash "$GATE" release >/dev/null 2>&1; then
  ok "T7 release fails when VERDICT is FAIL despite valid audited_range"
else
  bad "T7 release passed on VERDICT: FAIL"
fi

printf '\n%s\n' "$( [ "$fail" -eq 0 ] && echo "PASS: $pass/$((pass + fail)) assert-epic-gate checks" || echo "FAIL: $fail of $((pass + fail)) checks" )"
[ "$fail" -eq 0 ] || exit 1
