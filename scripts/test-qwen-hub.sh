#!/usr/bin/env bash
# story: e68s02
# Regression tests for Qwen Code install hub wiring (Wave B).
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PASS=0
FAIL=0

pass() { echo "PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "FAIL: $1" >&2; FAIL=$((FAIL + 1)); }

echo "=== test-qwen-hub.sh ==="

INSTALL_SH="$REPO_ROOT/scripts/install.sh"
HELPERS_JS="$REPO_ROOT/scripts/lib/install-helpers.js"
SETUP_JS="$REPO_ROOT/bin/setup.js"
TARGETS_YAML="$REPO_ROOT/scripts/targets.yaml"

grep -q 'install_qwen()' "$INSTALL_SH" && pass 'install.sh: install_qwen()' || fail 'install.sh: missing install_qwen()'
grep -q 'uninstall_qwen()' "$INSTALL_SH" && pass 'install.sh: uninstall_qwen()' || fail 'install.sh: missing uninstall_qwen()'
grep -q 'QWEN_SKILLS_DIR=' "$INSTALL_SH" && pass 'install.sh: skills dir var' || fail 'install.sh: missing skills dir var'
grep -q 'install_qwen' "$INSTALL_SH" && grep -q 'uninstall_qwen' "$INSTALL_SH" && pass 'install.sh: dispatch wired' || fail 'install.sh: dispatch missing qwen'

DRY_OUT="$(bash "$INSTALL_SH" --dry-run 2>&1)"
grep -q 'Qwen Code →' <<< "$DRY_OUT" && pass 'dry-run: Qwen Code section' || fail 'dry-run: missing Qwen Code section'
DRY_UNINSTALL="$(bash "$INSTALL_SH" --dry-run --uninstall 2>&1)"
grep -q 'Qwen Code →' <<< "$DRY_UNINSTALL" && pass 'dry-run uninstall: Qwen Code section' || fail 'dry-run uninstall: missing Qwen Code section'

grep -q "case 'qwen'" "$HELPERS_JS" && pass 'install-helpers: qwen case' || fail 'install-helpers: missing qwen case'
grep -q 'QWEN_HOOK_SRC=' "$INSTALL_SH" && pass 'install.sh: hook src' || fail 'install.sh: missing hook src'
grep -q 'pre-tool-git-guard.sh' "$INSTALL_SH" && pass 'install.sh: git-guard hook' || fail 'install.sh: missing git-guard hook'

SETUP_SRC="$(cat "$SETUP_JS")"
echo "$SETUP_SRC" | grep -q "SUPPORTED_IDS = new Set" && pass 'setup.js: SUPPORTED_IDS set' || fail 'setup.js: missing SUPPORTED_IDS'
grep -q "'qwen'" <<< "$(sed -n "/SUPPORTED_IDS = new Set/,/);/p" "$SETUP_JS")" && pass 'setup.js: qwen in SUPPORTED_IDS' || fail 'setup.js: qwen not in SUPPORTED_IDS'

grep -q 'id: qwen' "$TARGETS_YAML" && pass 'targets.yaml: qwen row' || fail 'targets.yaml: missing qwen row'
grep -q 'adapter: qwen' "$TARGETS_YAML" && pass 'targets.yaml: qwen adapter' || fail 'targets.yaml: missing qwen adapter'
grep -q 'qwen_hooks_manifest' "$TARGETS_YAML" && pass 'targets.yaml: qwen_hooks_manifest' || fail 'targets.yaml: missing qwen_hooks_manifest'
grep -q 'install_qwen()' "$REPO_ROOT/scripts/verify-install.sh" && pass 'verify-install: install_qwen assertion' || fail 'verify-install: missing install_qwen assertion'

bash -n "$INSTALL_SH" && pass 'bash -n install.sh' || fail 'bash -n install.sh'
node --check "$HELPERS_JS" && pass 'node --check install-helpers.js' || fail 'node --check install-helpers.js'
node --check "$SETUP_JS" && pass 'node --check setup.js' || fail 'node --check setup.js'

echo "test-qwen-hub: $PASS passed, $FAIL failed"
[[ "$FAIL" -eq 0 ]] || exit 1
