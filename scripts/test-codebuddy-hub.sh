#!/usr/bin/env bash
# story: e72s02
# Regression tests for CodeBuddy install hub wiring (Wave B).
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PASS=0
FAIL=0

pass() { echo "PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "FAIL: $1" >&2; FAIL=$((FAIL + 1)); }

echo "=== test-codebuddy-hub.sh ==="

INSTALL_SH="$REPO_ROOT/scripts/install.sh"
HELPERS_JS="$REPO_ROOT/scripts/lib/install-helpers.js"
SETUP_JS="$REPO_ROOT/bin/setup.js"
TARGETS_YAML="$REPO_ROOT/scripts/targets.yaml"

grep -q 'install_codebuddy()' "$INSTALL_SH" && pass 'install.sh: install_codebuddy()' || fail 'install.sh: missing install_codebuddy()'
grep -q 'uninstall_codebuddy()' "$INSTALL_SH" && pass 'install.sh: uninstall_codebuddy()' || fail 'install.sh: missing uninstall_codebuddy()'
grep -q 'CODEBUDDY_SKILLS_DIR=' "$INSTALL_SH" && pass 'install.sh: skills dir var' || fail 'install.sh: missing skills dir var'
grep -q 'install_codebuddy' "$INSTALL_SH" && grep -q 'uninstall_codebuddy' "$INSTALL_SH" && pass 'install.sh: dispatch wired' || fail 'install.sh: dispatch missing codebuddy'

DRY_OUT="$(bash "$INSTALL_SH" --dry-run 2>&1)"
grep -q 'CodeBuddy →' <<< "$DRY_OUT" && pass 'dry-run: CodeBuddy section' || fail 'dry-run: missing CodeBuddy section'
DRY_UNINSTALL="$(bash "$INSTALL_SH" --dry-run --uninstall 2>&1)"
grep -q 'CodeBuddy →' <<< "$DRY_UNINSTALL" && pass 'dry-run uninstall: CodeBuddy section' || fail 'dry-run uninstall: missing CodeBuddy section'

grep -q "case 'codebuddy'" "$HELPERS_JS" && pass 'install-helpers: codebuddy case' || fail 'install-helpers: missing codebuddy case'
grep -q 'CODEBUDDY_HOOK_SRC=' "$INSTALL_SH" && pass 'install.sh: hook src' || fail 'install.sh: missing hook src'
grep -q 'pre-tool-git-guard.sh' "$INSTALL_SH" && pass 'install.sh: git-guard hook' || fail 'install.sh: missing git-guard hook'

SETUP_SRC="$(cat "$SETUP_JS")"
echo "$SETUP_SRC" | grep -q "SUPPORTED_IDS = new Set" && pass 'setup.js: SUPPORTED_IDS set' || fail 'setup.js: missing SUPPORTED_IDS'
grep -q "'codebuddy'" <<< "$(sed -n "/SUPPORTED_IDS = new Set/,/);/p" "$SETUP_JS")" && pass 'setup.js: codebuddy in SUPPORTED_IDS' || fail 'setup.js: codebuddy not in SUPPORTED_IDS'

grep -q 'id: codebuddy' "$TARGETS_YAML" && pass 'targets.yaml: codebuddy row' || fail 'targets.yaml: missing codebuddy row'
grep -q 'adapter: codebuddy' "$TARGETS_YAML" && pass 'targets.yaml: codebuddy adapter' || fail 'targets.yaml: missing codebuddy adapter'
grep -q 'codebuddy_hooks_manifest' "$TARGETS_YAML" && pass 'targets.yaml: codebuddy_hooks_manifest' || fail 'targets.yaml: missing codebuddy_hooks_manifest'
grep -q 'install_codebuddy()' "$REPO_ROOT/scripts/verify-install.sh" && pass 'verify-install: install_codebuddy assertion' || fail 'verify-install: missing install_codebuddy assertion'

bash -n "$INSTALL_SH" && pass 'bash -n install.sh' || fail 'bash -n install.sh'
node --check "$HELPERS_JS" && pass 'node --check install-helpers.js' || fail 'node --check install-helpers.js'
node --check "$SETUP_JS" && pass 'node --check setup.js' || fail 'node --check setup.js'

echo "test-codebuddy-hub: $PASS passed, $FAIL failed"
[[ "$FAIL" -eq 0 ]] || exit 1
