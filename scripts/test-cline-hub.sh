#!/usr/bin/env bash
# story: e66s02
# Regression tests for Cline install hub wiring (Wave B).
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PASS=0
FAIL=0

pass() { echo "PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "FAIL: $1" >&2; FAIL=$((FAIL + 1)); }

echo "=== test-cline-hub.sh ==="

INSTALL_SH="$REPO_ROOT/scripts/install.sh"
source "$REPO_ROOT/scripts/lib/install-grep.sh"
HELPERS_JS="$REPO_ROOT/scripts/lib/install-helpers.js"
SETUP_JS="$REPO_ROOT/bin/setup.js"
TARGETS_YAML="$REPO_ROOT/scripts/targets.yaml"

install_grep -q 'install_cline()' && pass 'install.sh: install_cline()' || fail 'install.sh: missing install_cline()'
install_grep -q 'uninstall_cline()' && pass 'install.sh: uninstall_cline()' || fail 'install.sh: missing uninstall_cline()'
install_grep -q 'CLINE_SKILLS_DIR=' && pass 'install.sh: skills dir var' || fail 'install.sh: missing skills dir var'
install_grep -q 'install_cline' && install_grep -q 'uninstall_cline' && pass 'install.sh: dispatch wired' || fail 'install.sh: dispatch missing cline'

DRY_OUT="$(bash "$INSTALL_SH" --dry-run 2>&1)"
grep -q 'Cline →' <<< "$DRY_OUT" && pass 'dry-run: Cline section' || fail 'dry-run: missing Cline section'
DRY_UNINSTALL="$(bash "$INSTALL_SH" --dry-run --uninstall 2>&1)"
grep -q 'Cline →' <<< "$DRY_UNINSTALL" && pass 'dry-run uninstall: Cline section' || fail 'dry-run uninstall: missing Cline section'

grep -q "case 'cline'" "$HELPERS_JS" && pass 'install-helpers: cline case' || fail 'install-helpers: missing cline case'
install_grep -q 'scripts/hooks/cline/plugin' && pass 'install.sh: plugin hook template' || fail 'install.sh: missing plugin template'

SETUP_SRC="$(cat "$SETUP_JS")"
echo "$SETUP_SRC" | grep -q "SUPPORTED_IDS = new Set" && pass 'setup.js: SUPPORTED_IDS set' || fail 'setup.js: missing SUPPORTED_IDS'
grep -q "'cline'" <<< "$(sed -n "/SUPPORTED_IDS = new Set/,/);/p" "$SETUP_JS")" && pass 'setup.js: cline in SUPPORTED_IDS' || fail 'setup.js: cline not in SUPPORTED_IDS'

grep -q 'id: cline' "$TARGETS_YAML" && pass 'targets.yaml: cline row' || fail 'targets.yaml: missing cline row'
grep -q 'adapter: cline' "$TARGETS_YAML" && pass 'targets.yaml: cline adapter' || fail 'targets.yaml: missing cline adapter'
grep -q 'cline_hooks_manifest' "$TARGETS_YAML" && pass 'targets.yaml: cline_hooks_manifest' || fail 'targets.yaml: missing cline_hooks_manifest'
grep -q 'install_cline()' "$REPO_ROOT/scripts/verify-install.sh" && pass 'verify-install: install_cline assertion' || fail 'verify-install: missing install_cline assertion'

bash -n "$INSTALL_SH" && pass 'bash -n install.sh' || fail 'bash -n install.sh'
node --check "$HELPERS_JS" && pass 'node --check install-helpers.js' || fail 'node --check install-helpers.js'
node --check "$SETUP_JS" && pass 'node --check setup.js' || fail 'node --check setup.js'

echo "test-cline-hub: $PASS passed, $FAIL failed"
[[ "$FAIL" -eq 0 ]] || exit 1
