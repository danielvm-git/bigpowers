#!/usr/bin/env bash
# story: e67s02
# Regression tests for Kilo install hub wiring (Wave B).
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PASS=0
FAIL=0

pass() { echo "PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "FAIL: $1" >&2; FAIL=$((FAIL + 1)); }

echo "=== test-kilocode-hub.sh ==="

INSTALL_SH="$REPO_ROOT/scripts/install.sh"
source "$REPO_ROOT/scripts/lib/install-grep.sh"
HELPERS_JS="$REPO_ROOT/scripts/lib/install-helpers.js"
SETUP_JS="$REPO_ROOT/bin/setup.js"
TARGETS_YAML="$REPO_ROOT/scripts/targets.yaml"

install_grep -q 'install_kilocode()' && pass 'install.sh: install_kilocode()' || fail 'install.sh: missing install_kilocode()'
install_grep -q 'uninstall_kilocode()' && pass 'install.sh: uninstall_kilocode()' || fail 'install.sh: missing uninstall_kilocode()'
install_grep -q 'KILOCODE_SKILLS_DIR=' && pass 'install.sh: skills dir var' || fail 'install.sh: missing skills dir var'
install_grep -q 'install_kilocode' && install_grep -q 'uninstall_kilocode' && pass 'install.sh: dispatch wired' || fail 'install.sh: dispatch missing kilocode'

DRY_OUT="$(bash "$INSTALL_SH" --dry-run 2>&1)"
grep -q 'Kilo →' <<< "$DRY_OUT" && pass 'dry-run: Kilo section' || fail 'dry-run: missing Kilo section'
DRY_UNINSTALL="$(bash "$INSTALL_SH" --dry-run --uninstall 2>&1)"
grep -q 'Kilo →' <<< "$DRY_UNINSTALL" && pass 'dry-run uninstall: Kilo section' || fail 'dry-run uninstall: missing Kilo section'

grep -q "case 'kilo'" "$HELPERS_JS" && pass 'install-helpers: kilo case' || fail 'install-helpers: missing kilo case'
install_grep -q 'scripts/hooks/kilocode/plugin' && pass 'install.sh: plugin hook template' || fail 'install.sh: missing plugin template'

SETUP_SRC="$(cat "$SETUP_JS")"
echo "$SETUP_SRC" | grep -q "SUPPORTED_IDS = new Set" && pass 'setup.js: SUPPORTED_IDS set' || fail 'setup.js: missing SUPPORTED_IDS'
grep -q "'kilo'" <<< "$(sed -n "/SUPPORTED_IDS = new Set/,/);/p" "$SETUP_JS")" && pass 'setup.js: kilo in SUPPORTED_IDS' || fail 'setup.js: kilo not in SUPPORTED_IDS'

grep -q 'id: kilocode' "$TARGETS_YAML" && pass 'targets.yaml: kilocode row' || fail 'targets.yaml: missing kilocode row'
grep -q 'adapter: kilocode' "$TARGETS_YAML" && pass 'targets.yaml: kilocode adapter' || fail 'targets.yaml: missing kilocode adapter'
grep -q 'kilocode_hooks_manifest' "$TARGETS_YAML" && pass 'targets.yaml: kilocode_hooks_manifest' || fail 'targets.yaml: missing kilocode_hooks_manifest'
grep -q 'install_kilocode()' "$REPO_ROOT/scripts/verify-install.sh" && pass 'verify-install: install_kilocode assertion' || fail 'verify-install: missing install_kilocode assertion'

bash -n "$INSTALL_SH" && pass 'bash -n install.sh' || fail 'bash -n install.sh'
node --check "$HELPERS_JS" && pass 'node --check install-helpers.js' || fail 'node --check install-helpers.js'
node --check "$SETUP_JS" && pass 'node --check setup.js' || fail 'node --check setup.js'

echo "test-kilocode-hub: $PASS passed, $FAIL failed"
[[ "$FAIL" -eq 0 ]] || exit 1
