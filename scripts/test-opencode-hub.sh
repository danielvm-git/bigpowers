#!/usr/bin/env bash
# story: e62s02
# Regression tests for OpenCode install hub wiring (Wave B).
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PASS=0
FAIL=0

pass() { echo "PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "FAIL: $1" >&2; FAIL=$((FAIL + 1)); }

echo "=== test-opencode-hub.sh ==="

INSTALL_SH="$REPO_ROOT/scripts/install.sh"
source "$REPO_ROOT/scripts/lib/install-grep.sh"
HELPERS_JS="$REPO_ROOT/scripts/lib/install-helpers.js"
SETUP_JS="$REPO_ROOT/bin/setup.js"
TARGETS_YAML="$REPO_ROOT/scripts/targets.yaml"

install_grep -q 'install_opencode()' && pass 'install.sh: install_opencode()' || fail 'install.sh: missing install_opencode()'
install_grep -q 'uninstall_opencode()' && pass 'install.sh: uninstall_opencode()' || fail 'install.sh: missing uninstall_opencode()'
install_grep -q 'OPENCODE_SKILLS_DIR=' && pass 'install.sh: skills dir var' || fail 'install.sh: missing skills dir var'
install_grep -q 'install_opencode' && install_grep -q 'uninstall_opencode' && pass 'install.sh: dispatch wired' || fail 'install.sh: dispatch missing opencode'

DRY_OUT="$(bash "$INSTALL_SH" --dry-run 2>&1)"
grep -q 'OpenCode →' <<< "$DRY_OUT" && pass 'dry-run: OpenCode section' || fail 'dry-run: missing OpenCode section'
DRY_UNINSTALL="$(bash "$INSTALL_SH" --dry-run --uninstall 2>&1)"
grep -q 'OpenCode →' <<< "$DRY_UNINSTALL" && pass 'dry-run uninstall: OpenCode section' || fail 'dry-run uninstall: missing OpenCode section'

grep -q "case 'opencode'" "$HELPERS_JS" && pass 'install-helpers: opencode case' || fail 'install-helpers: missing opencode case'

SETUP_SRC="$(cat "$SETUP_JS")"
echo "$SETUP_SRC" | grep -q "SUPPORTED_IDS = new Set" && pass 'setup.js: SUPPORTED_IDS set' || fail 'setup.js: missing SUPPORTED_IDS'
grep -q "'opencode'" <<< "$(sed -n "/SUPPORTED_IDS = new Set/,/);/p" "$SETUP_JS")" && pass 'setup.js: opencode in SUPPORTED_IDS' || fail 'setup.js: opencode not in SUPPORTED_IDS'


bash -n "$INSTALL_SH" && pass 'bash -n install.sh' || fail 'bash -n install.sh'
node --check "$HELPERS_JS" && pass 'node --check install-helpers.js' || fail 'node --check install-helpers.js'
node --check "$SETUP_JS" && pass 'node --check setup.js' || fail 'node --check setup.js'

echo "test-opencode-hub: $PASS passed, $FAIL failed"
[[ "$FAIL" -eq 0 ]] || exit 1
