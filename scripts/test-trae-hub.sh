#!/usr/bin/env bash
# story: e70s02
# Regression tests for Trae install hub wiring (Wave B).
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PASS=0
FAIL=0

pass() { echo "PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "FAIL: $1" >&2; FAIL=$((FAIL + 1)); }

echo "=== test-trae-hub.sh ==="

INSTALL_SH="$REPO_ROOT/scripts/install.sh"
HELPERS_JS="$REPO_ROOT/scripts/lib/install-helpers.js"
SETUP_JS="$REPO_ROOT/bin/setup.js"
TARGETS_YAML="$REPO_ROOT/scripts/targets.yaml"

grep -q 'install_trae()' "$INSTALL_SH" && pass 'install.sh: install_trae()' || fail 'install.sh: missing install_trae()'
grep -q 'uninstall_trae()' "$INSTALL_SH" && pass 'install.sh: uninstall_trae()' || fail 'install.sh: missing uninstall_trae()'
grep -q 'TRAE_SKILLS_DIR=' "$INSTALL_SH" && pass 'install.sh: skills dir var' || fail 'install.sh: missing skills dir var'
grep -q 'install_trae' "$INSTALL_SH" && grep -q 'uninstall_trae' "$INSTALL_SH" && pass 'install.sh: dispatch wired' || fail 'install.sh: dispatch missing trae'

DRY_OUT="$(bash "$INSTALL_SH" --dry-run 2>&1)"
grep -q 'Trae →' <<< "$DRY_OUT" && pass 'dry-run: Trae section' || fail 'dry-run: missing Trae section'
DRY_UNINSTALL="$(bash "$INSTALL_SH" --dry-run --uninstall 2>&1)"
grep -q 'Trae →' <<< "$DRY_UNINSTALL" && pass 'dry-run uninstall: Trae section' || fail 'dry-run uninstall: missing Trae section'

grep -q "case 'trae'" "$HELPERS_JS" && pass 'install-helpers: trae case' || fail 'install-helpers: missing trae case'
grep -q 'TRAE_HOOK_SRC=' "$INSTALL_SH" && pass 'install.sh: hook src' || fail 'install.sh: missing hook src'
grep -q 'pre-tool-git-guard.sh' "$INSTALL_SH" && pass 'install.sh: git-guard hook' || fail 'install.sh: missing git-guard hook'

SETUP_SRC="$(cat "$SETUP_JS")"
echo "$SETUP_SRC" | grep -q "SUPPORTED_IDS = new Set" && pass 'setup.js: SUPPORTED_IDS set' || fail 'setup.js: missing SUPPORTED_IDS'
grep -q "'trae'" <<< "$(sed -n "/SUPPORTED_IDS = new Set/,/);/p" "$SETUP_JS")" && pass 'setup.js: trae in SUPPORTED_IDS' || fail 'setup.js: trae not in SUPPORTED_IDS'

grep -q 'id: trae' "$TARGETS_YAML" && pass 'targets.yaml: trae row' || fail 'targets.yaml: missing trae row'
grep -q 'adapter: trae' "$TARGETS_YAML" && pass 'targets.yaml: trae adapter' || fail 'targets.yaml: missing trae adapter'
grep -q 'trae_hooks_manifest' "$TARGETS_YAML" && pass 'targets.yaml: trae_hooks_manifest' || fail 'targets.yaml: missing trae_hooks_manifest'
grep -q 'install_trae()' "$REPO_ROOT/scripts/verify-install.sh" && pass 'verify-install: install_trae assertion' || fail 'verify-install: missing install_trae assertion'

bash -n "$INSTALL_SH" && pass 'bash -n install.sh' || fail 'bash -n install.sh'
node --check "$HELPERS_JS" && pass 'node --check install-helpers.js' || fail 'node --check install-helpers.js'
node --check "$SETUP_JS" && pass 'node --check setup.js' || fail 'node --check setup.js'

echo "test-trae-hub: $PASS passed, $FAIL failed"
[[ "$FAIL" -eq 0 ]] || exit 1
