#!/usr/bin/env bash
# story: e71s02
# Regression tests for Copilot CLI install hub wiring (Wave B).
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PASS=0
FAIL=0

pass() { echo "PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "FAIL: $1" >&2; FAIL=$((FAIL + 1)); }

echo "=== test-copilot-hub.sh ==="

INSTALL_SH="$REPO_ROOT/scripts/install.sh"
HELPERS_JS="$REPO_ROOT/scripts/lib/install-helpers.js"
SETUP_JS="$REPO_ROOT/bin/setup.js"
TARGETS_YAML="$REPO_ROOT/scripts/targets.yaml"

grep -q 'install_copilot()' "$INSTALL_SH" && pass 'install.sh: install_copilot()' || fail 'install.sh: missing install_copilot()'
grep -q 'uninstall_copilot()' "$INSTALL_SH" && pass 'install.sh: uninstall_copilot()' || fail 'install.sh: missing uninstall_copilot()'
grep -q 'COPILOT_SKILLS_DIR=' "$INSTALL_SH" && pass 'install.sh: skills dir var' || fail 'install.sh: missing skills dir var'
grep -q 'install_copilot' "$INSTALL_SH" && grep -q 'uninstall_copilot' "$INSTALL_SH" && pass 'install.sh: dispatch wired' || fail 'install.sh: dispatch missing copilot'

DRY_OUT="$(bash "$INSTALL_SH" --dry-run 2>&1)"
grep -q 'Copilot CLI →' <<< "$DRY_OUT" && pass 'dry-run: Copilot CLI section' || fail 'dry-run: missing Copilot CLI section'
DRY_UNINSTALL="$(bash "$INSTALL_SH" --dry-run --uninstall 2>&1)"
grep -q 'Copilot CLI →' <<< "$DRY_UNINSTALL" && pass 'dry-run uninstall: Copilot CLI section' || fail 'dry-run uninstall: missing Copilot CLI section'

grep -q "case 'copilot'" "$HELPERS_JS" && pass 'install-helpers: copilot case' || fail 'install-helpers: missing copilot case'

SETUP_SRC="$(cat "$SETUP_JS")"
echo "$SETUP_SRC" | grep -q "SUPPORTED_IDS = new Set" && pass 'setup.js: SUPPORTED_IDS set' || fail 'setup.js: missing SUPPORTED_IDS'
grep -q "'copilot'" <<< "$(sed -n "/SUPPORTED_IDS = new Set/,/);/p" "$SETUP_JS")" && pass 'setup.js: copilot in SUPPORTED_IDS' || fail 'setup.js: copilot not in SUPPORTED_IDS'


bash -n "$INSTALL_SH" && pass 'bash -n install.sh' || fail 'bash -n install.sh'
node --check "$HELPERS_JS" && pass 'node --check install-helpers.js' || fail 'node --check install-helpers.js'
node --check "$SETUP_JS" && pass 'node --check setup.js' || fail 'node --check setup.js'

echo "test-copilot-hub: $PASS passed, $FAIL failed"
[[ "$FAIL" -eq 0 ]] || exit 1
