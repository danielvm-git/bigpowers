#!/usr/bin/env bash
# story: e64s02
# Regression tests for Gemini install hub wiring (Wave B).
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PASS=0
FAIL=0

pass() { echo "PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "FAIL: $1" >&2; FAIL=$((FAIL + 1)); }

echo "=== test-gemini-hub.sh ==="

INSTALL_SH="$REPO_ROOT/scripts/install.sh"
source "$REPO_ROOT/scripts/lib/install-grep.sh"
HELPERS_JS="$REPO_ROOT/scripts/lib/install-helpers.js"
SETUP_JS="$REPO_ROOT/bin/setup.js"
TARGETS_YAML="$REPO_ROOT/scripts/targets.yaml"

install_grep -q 'install_gemini()' && pass 'install.sh: install_gemini()' || fail 'install.sh: missing install_gemini()'
install_grep -q 'uninstall_gemini()' && pass 'install.sh: uninstall_gemini()' || fail 'install.sh: missing uninstall_gemini()'
install_grep -q 'GEMINI_HOOKS_SRC=' && pass 'install.sh: GEMINI_HOOKS_SRC' || fail 'install.sh: missing GEMINI_HOOKS_SRC'
install_grep -q 'before-tool-git-guard.sh' && pass 'install.sh: Wave A git-guard hook' || fail 'install.sh: missing before-tool-git-guard.sh'
install_grep -q 'before-tool-rtk.sh' && pass 'install.sh: Wave A rtk hook' || fail 'install.sh: missing before-tool-rtk.sh'
install_grep -q 'install_gemini' && install_grep -q 'uninstall_gemini' && pass 'install.sh: dispatch wired' || fail 'install.sh: dispatch missing gemini'

DRY_OUT="$(bash "$INSTALL_SH" --dry-run 2>&1)"
grep -q 'Gemini CLI →' <<< "$DRY_OUT" && pass 'dry-run: Gemini CLI section' || fail 'dry-run: missing Gemini CLI section'
grep -q 'before-tool-git-guard.sh' <<< "$DRY_OUT" && pass 'dry-run: git-guard hook symlink' || fail 'dry-run: missing git-guard hook'
DRY_UNINSTALL="$(bash "$INSTALL_SH" --dry-run --uninstall 2>&1)"
grep -q 'Gemini CLI →' <<< "$DRY_UNINSTALL" && pass 'dry-run uninstall: Gemini CLI section' || fail 'dry-run uninstall: missing Gemini CLI section'

grep -q "case 'gemini'" "$HELPERS_JS" && pass 'install-helpers: gemini global case' || fail 'install-helpers: missing gemini global case'
grep -q 'before-tool-git-guard.sh' "$HELPERS_JS" && pass 'install-helpers: gemini hook wiring' || fail 'install-helpers: missing gemini hook wiring'

SETUP_SRC="$(cat "$SETUP_JS")"
echo "$SETUP_SRC" | grep -q "SUPPORTED_IDS = new Set" && pass 'setup.js: SUPPORTED_IDS set' || fail 'setup.js: missing SUPPORTED_IDS'
echo "$SETUP_SRC" | grep -q "'gemini'" "$SETUP_JS" && pass 'setup.js: gemini in TOOLS' || fail 'setup.js: gemini missing from TOOLS'
echo "$SETUP_SRC" | grep -q "'gemini'" && echo "$SETUP_SRC" | grep -q "SUPPORTED_IDS" \
  && grep -q "'gemini'" <<< "$(sed -n "/SUPPORTED_IDS = new Set/,/);/p" "$SETUP_JS")" \
  && pass 'setup.js: gemini in SUPPORTED_IDS' || fail 'setup.js: gemini not in SUPPORTED_IDS'

grep -q 'id: gemini' "$TARGETS_YAML" && pass 'targets.yaml: gemini row' || fail 'targets.yaml: missing gemini row'
grep -q 'adapter: gemini' "$TARGETS_YAML" && pass 'targets.yaml: gemini adapter' || fail 'targets.yaml: missing gemini adapter'
grep -q 'gemini_hooks_manifest' "$TARGETS_YAML" && pass 'targets.yaml: gemini_hooks_manifest contract' || fail 'targets.yaml: missing gemini_hooks_manifest'

grep -q 'install_gemini()' "$REPO_ROOT/scripts/verify-install.sh" && pass 'verify-install: install_gemini assertion' || fail 'verify-install: missing install_gemini assertion'
grep -q 'gemini_hooks_manifest' "$REPO_ROOT/scripts/verify-install.sh" && pass 'verify-install: gemini hook contract' || fail 'verify-install: missing gemini hook contract'

bash -n "$INSTALL_SH" && pass 'bash -n install.sh' || fail 'bash -n install.sh'
node --check "$HELPERS_JS" && pass 'node --check install-helpers.js' || fail 'node --check install-helpers.js'
node --check "$SETUP_JS" && pass 'node --check setup.js' || fail 'node --check setup.js'

echo "test-gemini-hub: $PASS passed, $FAIL failed"
[[ "$FAIL" -eq 0 ]] || exit 1
