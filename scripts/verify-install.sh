#!/usr/bin/env bash
# story: e47s04
# verify-install.sh — manual assertion harness for install + seed wiring
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PASS=0
FAIL=0
TMPDIR=""

cleanup() { [[ -n "$TMPDIR" && -d "$TMPDIR" ]] && rm -rf "$TMPDIR"; }
trap cleanup EXIT

pass() { echo "  PASS $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL $1"; FAIL=$((FAIL + 1)); }

echo "=== install.sh --dry-run ==="
DRY_OUT="$("$REPO_ROOT/scripts/install.sh" --dry-run 2>&1)"

echo "$DRY_OUT" | grep -q 'pi →' && pass "install --dry-run includes pi" || fail "install --dry-run missing pi"
DRY_UNINSTALL="$("$REPO_ROOT/scripts/install.sh" --dry-run --uninstall 2>&1)"
echo "$DRY_UNINSTALL" | grep -q 'pi →' && pass "uninstall --dry-run includes pi" || fail "uninstall --dry-run missing pi"
echo "$DRY_OUT" | grep -qi 'opencode' && fail "install references opencode" || pass "install has no opencode reference"
echo "$DRY_OUT" | grep -q 'Claude Code →' && pass "install includes Claude Code" || fail "install missing Claude Code"
echo "$DRY_OUT" | grep -q 'Gemini CLI →' && pass "install includes Gemini CLI" || fail "install missing Gemini CLI"
echo "$DRY_OUT" | grep -q 'Cursor →' && pass "install includes Cursor" || fail "install missing Cursor"

for tool in "Claude Code" "pi"; do
  # Find the skills count in the tool's section (between this tool header and next section)
  section=$(echo "$DRY_OUT" | sed -n "/${tool} →/,/^$/p")
  count=$(echo "$section" | grep -o '[0-9]\+ skills installed' | grep -o '[0-9]\+' || echo "0")
  [[ "$count" -gt 0 ]] && pass "${tool}: $count skills" || fail "${tool}: 0 skills"
done

echo ""
echo "=== seed-conventions local wiring ==="
grep -qi 'local tool wiring' "$REPO_ROOT/skills/seed-conventions/SKILL.md" && pass "SKILL.md: local tool wiring" || fail "SKILL.md: missing local tool wiring"
grep -qi 'opencode.json' "$REPO_ROOT/skills/seed-conventions/REFERENCE.md" && pass "REFERENCE.md: opencode.json" || fail "REFERENCE.md: missing opencode.json"
grep -qi 'cursor/rules' "$REPO_ROOT/skills/seed-conventions/REFERENCE.md" && pass "REFERENCE.md: Cursor symlink" || fail "REFERENCE.md: missing Cursor symlink"

OPENCODE_JSON=$(sed -n '/```json/,/```/p' "$REPO_ROOT/skills/seed-conventions/REFERENCE.md" | grep -v '```' || true)
if [[ -n "$OPENCODE_JSON" ]]; then
  TMPDIR=$(mktemp -d)
  echo "$OPENCODE_JSON" > "$TMPDIR/test-opencode.json"
  jq empty "$TMPDIR/test-opencode.json" 2>/dev/null && pass "opencode.json valid JSON" || fail "opencode.json NOT valid JSON"
else
  fail "opencode.json template not found"
fi

echo ""
echo "=== install.sh source ==="
grep -q 'install_pi()' "$REPO_ROOT/scripts/install.sh" && pass "source: install_pi()" || fail "source: missing install_pi()"
grep -q 'uninstall_pi()' "$REPO_ROOT/scripts/install.sh" && pass "source: uninstall_pi()" || fail "source: missing uninstall_pi()"
grep -q 'PI_SKILLS_DIR="$PI_CONFIG_DIR/agent/skills"' "$REPO_ROOT/scripts/install.sh" && pass "source: targets ~/.pi/agent/skills/" || fail "source: wrong pi target"
! grep -q 'install_opencode\|print_opencode_instructions' "$REPO_ROOT/scripts/install.sh" && pass "source: no opencode functions" || fail "source: opencode functions remain"

echo ""
echo "──────────────────────────────────────────"
echo "verify-install: $PASS passed, $FAIL failed"
[[ "$FAIL" -gt 0 ]] && { echo "Overall: fail"; exit 1; } || echo "Overall: pass"
