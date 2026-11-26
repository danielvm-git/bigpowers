#!/usr/bin/env bash
# test-trace-ignored-paths.sh — trace-stories must index only files git would track
#
# Covers BUG-2026-11-03-trace-indexes-other-worktrees and
# BUG-2026-11-03-wiki-indexes-ignored-reports (same root cause):
#   - a gitignored .claude/worktrees/<other>/ copy contributes no links
#   - a gitignored specs/verifications/reports/ file contributes no links
#   - the tracked original still links (anti-vacuity)
#   - the committed matrix and wiki link no gitignored, untracked path
#
# Usage: bash scripts/test-trace-ignored-paths.sh

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/python-env.sh"
source "$(dirname "${BASH_SOURCE[0]}")/lib/skill-common.sh"
resolve_repo_root

TRACE_ENGINE="$REPO_ROOT/scripts/lib/trace-stories.py"
FAILURES=0

ignored_pass() { echo "PASS $1"; }
ignored_fail() { echo "FAIL $1"; FAILURES=$((FAILURES + 1)); }

write_ignored_fixture() {
  local root="$1"
  mkdir -p "$root/specs/epics/e99-test" "$root/scripts"
  cat >"$root/specs/release-plan.yaml" <<'EOF'
release:
  version: "1.0.0"
epics:
  - id: e99
    title: "Ignored Paths Epic"
    wsjf: 5.0
    mode: capsule
    status: proposed
    capsule_dir: epics/e99-test
EOF
  {
    echo "stories:"
    for i in $(seq 1 51); do
      printf '  - id: e99s%02d\n    title: "Widget Gizmo %d"\n    bcp: 1\n' "$i" "$i"
    done
  } >"$root/specs/epics/e99-test/epic.yaml"
  {
    echo "development_status:"
    for i in $(seq 1 51); do printf '  e99s%02d: todo\n' "$i"; done
  } >"$root/specs/execution-status.yaml"
  printf '# story: e99s01\n' >"$root/scripts/widget-gizmo.sh"
  printf '.claude/\nspecs/verifications/reports/\n' >"$root/.gitignore"
  git -C "$root" init -q
  git -C "$root" add -A
  git -C "$root" -c user.name=t -c user.email=t@t commit -qm fixture
  # Another session's worktree: gitignored, but full of tagged, matching files.
  local other="$root/.claude/worktrees/other-session"
  mkdir -p "$other/scripts"
  cp "$root/scripts/widget-gizmo.sh" "$other/scripts/widget-gizmo.sh"
  mkdir -p "$root/specs/verifications/reports"
  cp "$root/scripts/widget-gizmo.sh" "$root/specs/verifications/reports/widget-gizmo-report.sh"
}

echo "=== trace-ignored-paths: fixture — gitignored worktree copy ==="
FIXTURE_ROOT=$(mktemp -d)
OUT_DIR=$(mktemp -d)
trap 'rm -rf "$FIXTURE_ROOT" "$OUT_DIR"' EXIT
write_ignored_fixture "$FIXTURE_ROOT"
$PYTHON "$TRACE_ENGINE" "$FIXTURE_ROOT" "$OUT_DIR/matrix.json" "$OUT_DIR/trace.md" \
  "$OUT_DIR/wiki" 0 json >/dev/null 2>&1

links=$($PYTHON -c 'import json,sys
m = json.load(open(sys.argv[1]))
print("\n".join(l["file"] for s in m["stories"] for l in s["links"]))' "$OUT_DIR/matrix.json")

IGNORED_RE='^(\.claude/|specs/verifications/reports/)'
if grep -Eq "$IGNORED_RE" <<<"$links"; then
  ignored_fail "matrix links gitignored paths:"
  grep -E "$IGNORED_RE" <<<"$links" | sort -u | sed 's/^/  /'
else
  ignored_pass "matrix has no gitignored links"
fi
if grep -qx 'scripts/widget-gizmo.sh' <<<"$links"; then
  ignored_pass "tracked file still links (scan is not vacuous)"
else
  ignored_fail "tracked scripts/widget-gizmo.sh lost its link"
fi
if grep -rEq '\.claude/|specs/verifications/reports/' "$OUT_DIR/wiki" "$OUT_DIR/trace.md"; then
  ignored_fail "wiki or TRACEABILITY markdown links gitignored paths"
else
  ignored_pass "wiki and TRACEABILITY markdown have no gitignored links"
fi

echo ""
echo "=== trace-ignored-paths: committed outputs ==="
committed_links=$($PYTHON -c 'import json,sys
m = json.load(open(sys.argv[1]))
print("\n".join(sorted({l["file"] for s in m["stories"] for l in s["links"]})))' \
  "$REPO_ROOT/specs/traceability-matrix.json")
# check-ignore skips tracked files, so this lists only ignored-and-untracked links.
ignored_links=$(git -C "$REPO_ROOT" check-ignore --stdin <<<"$committed_links" || true)

committed_outputs_clean() {
  [[ -z "$ignored_links" ]] || return 1
  grep -q '^\.claude/' <<<"$committed_links" && return 1
  ! grep -rEq '^ *- file: "?\.claude/' "$REPO_ROOT/specs/codebase-wiki"
}

if committed_outputs_clean; then
  ignored_pass "committed traceability outputs link no gitignored or .claude/ paths"
else
  ignored_fail "committed traceability outputs link gitignored or .claude/ paths:"
  sed -n '1,10s/^/  /p' <<<"$ignored_links"
fi

echo ""
if [[ $FAILURES -eq 0 ]]; then
  echo "test-trace-ignored-paths: PASS"
  exit 0
fi
echo "test-trace-ignored-paths: FAIL ($FAILURES failure(s))"
exit 1
