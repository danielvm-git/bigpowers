#!/usr/bin/env bash
# story: e73s02
# Regression tests for Windsurf install hub wiring (Wave B).
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PASS=0
FAIL=0

pass() { echo "PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "FAIL: $1" >&2; FAIL=$((FAIL + 1)); }

echo "=== test-windsurf-hub.sh ==="

INSTALL_SH="$REPO_ROOT/scripts/install.sh"
source "$REPO_ROOT/scripts/lib/install-grep.sh"
HELPERS_JS="$REPO_ROOT/scripts/lib/install-helpers.js"
SETUP_JS="$REPO_ROOT/bin/setup.js"
TARGETS_YAML="$REPO_ROOT/scripts/targets.yaml"

install_grep -q 'install_windsurf()' && pass 'install.sh: install_windsurf()' || fail 'install.sh: missing install_windsurf()'
install_grep -q 'uninstall_windsurf()' && pass 'install.sh: uninstall_windsurf()' || fail 'install.sh: missing uninstall_windsurf()'
install_grep -q 'WINDSURF_SKILLS_DIR=' && pass 'install.sh: skills dir var' || fail 'install.sh: missing skills dir var'
install_grep -q 'install_windsurf' && install_grep -q 'uninstall_windsurf' && pass 'install.sh: dispatch wired' || fail 'install.sh: dispatch missing windsurf'

DRY_OUT="$(bash "$INSTALL_SH" --dry-run 2>&1)"
grep -q 'Windsurf →' <<< "$DRY_OUT" && pass 'dry-run: Windsurf section' || fail 'dry-run: missing Windsurf section'
DRY_UNINSTALL="$(bash "$INSTALL_SH" --dry-run --uninstall 2>&1)"
grep -q 'Windsurf →' <<< "$DRY_UNINSTALL" && pass 'dry-run uninstall: Windsurf section' || fail 'dry-run uninstall: missing Windsurf section'

grep -q "case 'windsurf'" "$HELPERS_JS" && pass 'install-helpers: windsurf case' || fail 'install-helpers: missing windsurf case'
install_grep -q 'WINDSURF_HOOK_SRC=' && pass 'install.sh: hook src' || fail 'install.sh: missing hook src'
install_grep -q 'pre-tool-git-guard.sh' && pass 'install.sh: git-guard hook' || fail 'install.sh: missing git-guard hook'

SETUP_SRC="$(cat "$SETUP_JS")"
echo "$SETUP_SRC" | grep -q "SUPPORTED_IDS = new Set" && pass 'setup.js: SUPPORTED_IDS set' || fail 'setup.js: missing SUPPORTED_IDS'
grep -q "'windsurf'" <<< "$(sed -n "/SUPPORTED_IDS = new Set/,/);/p" "$SETUP_JS")" && pass 'setup.js: windsurf in SUPPORTED_IDS' || fail 'setup.js: windsurf not in SUPPORTED_IDS'

grep -q 'id: windsurf' "$TARGETS_YAML" && pass 'targets.yaml: windsurf row' || fail 'targets.yaml: missing windsurf row'
grep -q 'adapter: windsurf' "$TARGETS_YAML" && pass 'targets.yaml: windsurf adapter' || fail 'targets.yaml: missing windsurf adapter'
grep -q 'windsurf_hooks_manifest' "$TARGETS_YAML" && pass 'targets.yaml: windsurf_hooks_manifest' || fail 'targets.yaml: missing windsurf_hooks_manifest'
grep -q 'install_windsurf()' "$REPO_ROOT/scripts/verify-install.sh" && pass 'verify-install: install_windsurf assertion' || fail 'verify-install: missing install_windsurf assertion'

bash -n "$INSTALL_SH" && pass 'bash -n install.sh' || fail 'bash -n install.sh'
node --check "$HELPERS_JS" && pass 'node --check install-helpers.js' || fail 'node --check install-helpers.js'
node --check "$SETUP_JS" && pass 'node --check setup.js' || fail 'node --check setup.js'

echo "test-windsurf-hub: $PASS passed, $FAIL failed"
[[ "$FAIL" -eq 0 ]] || exit 1
