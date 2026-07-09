#!/usr/bin/env bash
# story: BUG-2026-07-09T033939-golden-g01-submodule-checkout
# Regression: orphan gitlinks (160000) without .gitmodules URLs break actions/checkout.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
# shellcheck source=../scripts/lib/check-orphan-gitlinks.sh
source "$REPO_ROOT/scripts/lib/check-orphan-gitlinks.sh"

# Clean tree must pass.
if ! output="$(check_orphan_gitlinks "$REPO_ROOT")"; then
  echo "FAIL: check_orphan_gitlinks failed on clean tree"
  exit 1
fi
if [[ "$output" != "no orphan gitlinks" ]]; then
  echo "FAIL: unexpected output: $output"
  exit 1
fi

# Synthetic orphan: gitlink path with no .gitmodules entry must fail.
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT
git -C "$tmpdir" init -q
git -C "$tmpdir" config user.email "test@example.com"
git -C "$tmpdir" config user.name "test"
mkdir -p "$tmpdir/sub"
echo "nested" >"$tmpdir/sub/file.txt"
git -C "$tmpdir/sub" init -q
git -C "$tmpdir/sub" add file.txt
git -C "$tmpdir/sub" commit -qm "nested"
git -C "$tmpdir" add sub
if ! check_orphan_gitlinks "$tmpdir" >/dev/null 2>&1; then
  echo "PASS: synthetic orphan gitlink correctly rejected"
  exit 0
fi

echo "FAIL: check_orphan_gitlinks should reject orphan gitlink in synthetic repo"
exit 1
