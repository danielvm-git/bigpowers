#!/usr/bin/env bash
# story: e76s02
# Regression tests for ZCode install hub wiring (Wave B).
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PASS=0
FAIL=0

pass() { echo "PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "FAIL: $1" >&2; FAIL=$((FAIL + 1)); }

echo "=== test-zcode-hub.sh ==="

INSTALL_SH="$REPO_ROOT/scripts/install.sh"
HELPERS_JS="$REPO_ROOT/scripts/lib/install-helpers.js"
SETUP_JS="$REPO_ROOT/bin/setup.js"
TARGETS_YAML="$REPO_ROOT/scripts/targets.yaml"

grep -q 'install_zcode()' "$INSTALL_SH" && pass 'install.sh: install_zcode()' || fail 'install.sh: missing install_zcode()'
grep -q 'uninstall_zcode()' "$INSTALL_SH" && pass 'install.sh: uninstall_zcode()' || fail 'install.sh: missing uninstall_zcode()'
grep -q 'ZCODE_SKILLS_DIR=' "$INSTALL_SH" && pass 'install.sh: ZCODE_SKILLS_DIR' || fail 'install.sh: missing ZCODE_SKILLS_DIR'
grep -q 'install_zcode' "$INSTALL_SH" && grep -q 'uninstall_zcode' "$INSTALL_SH" && pass 'install.sh: dispatch wired' || fail 'install.sh: dispatch missing zcode'

DRY_OUT="$(bash "$INSTALL_SH" --dry-run 2>&1)"
echo "$DRY_OUT" | grep -q 'ZCode →' && pass 'dry-run: ZCode section' || fail 'dry-run: missing ZCode section'
DRY_UNINSTALL="$(bash "$INSTALL_SH" --dry-run --uninstall 2>&1)"
echo "$DRY_UNINSTALL" | grep -q 'ZCode →' && pass 'dry-run uninstall: ZCode section' || fail 'dry-run uninstall: missing ZCode section'

grep -q "case 'zcode'" "$HELPERS_JS" && pass 'install-helpers: zcode global case' || fail 'install-helpers: missing zcode global case'
grep -q "case 'zcode'" "$HELPERS_JS" && pass 'install-helpers: zcode cases present' || fail 'install-helpers: missing zcode cases'

SETUP_SRC="$(cat "$SETUP_JS")"
echo "$SETUP_SRC" | grep -q "SUPPORTED_IDS = new Set" && pass 'setup.js: SUPPORTED_IDS set' || fail 'setup.js: missing SUPPORTED_IDS'
echo "$SETUP_SRC" | grep -q "'zcode'" "$SETUP_JS" && pass 'setup.js: zcode in TOOLS' || fail 'setup.js: zcode missing from TOOLS'
echo "$SETUP_SRC" | grep -q "'zcode'" && echo "$SETUP_SRC" | grep -q "SUPPORTED_IDS" \
  && grep -q "'zcode'" <<< "$(sed -n "/SUPPORTED_IDS = new Set/,/);/p" "$SETUP_JS")" \
  && pass 'setup.js: zcode in SUPPORTED_IDS' || fail 'setup.js: zcode not in SUPPORTED_IDS'

grep -q 'id: zcode' "$TARGETS_YAML" && pass 'targets.yaml: zcode row' || fail 'targets.yaml: missing zcode row'
grep -q 'adapter: zcode' "$TARGETS_YAML" && pass 'targets.yaml: zcode adapter' || fail 'targets.yaml: missing zcode adapter'
grep -q 'output: .zcode/skills' "$TARGETS_YAML" && pass 'targets.yaml: zcode output path' || fail 'targets.yaml: missing zcode output'

grep -q 'install_zcode()' "$REPO_ROOT/scripts/verify-install.sh" && pass 'verify-install: install_zcode assertion' || fail 'verify-install: missing install_zcode assertion'

bash -n "$INSTALL_SH" && pass 'bash -n install.sh' || fail 'bash -n install.sh'
node --check "$HELPERS_JS" && pass 'node --check install-helpers.js' || fail 'node --check install-helpers.js'
node --check "$SETUP_JS" && pass 'node --check setup.js' || fail 'node --check setup.js'

echo "test-zcode-hub: $PASS passed, $FAIL failed"
[[ "$FAIL" -eq 0 ]] || exit 1
