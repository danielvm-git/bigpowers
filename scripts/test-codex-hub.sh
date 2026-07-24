#!/usr/bin/env bash
# story: e65s02
# Regression tests for Codex CLI install hub wiring (Wave B).
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PASS=0
FAIL=0

pass() { echo "PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "FAIL: $1" >&2; FAIL=$((FAIL + 1)); }

echo "=== test-codex-hub.sh ==="

INSTALL_SH="$REPO_ROOT/scripts/install.sh"
HELPERS_JS="$REPO_ROOT/scripts/lib/install-helpers.js"
SETUP_JS="$REPO_ROOT/bin/setup.js"
TARGETS_YAML="$REPO_ROOT/scripts/targets.yaml"

grep -q 'install_codex()' "$INSTALL_SH" && pass 'install.sh: install_codex()' || fail 'install.sh: missing install_codex()'
grep -q 'uninstall_codex()' "$INSTALL_SH" && pass 'install.sh: uninstall_codex()' || fail 'install.sh: missing uninstall_codex()'
grep -q 'CODEX_SKILLS_DIR=' "$INSTALL_SH" && pass 'install.sh: skills dir var' || fail 'install.sh: missing skills dir var'
grep -q 'install_codex' "$INSTALL_SH" && grep -q 'uninstall_codex' "$INSTALL_SH" && pass 'install.sh: dispatch wired' || fail 'install.sh: dispatch missing codex'

DRY_OUT="$(bash "$INSTALL_SH" --dry-run 2>&1)"
grep -q 'Codex CLI →' <<< "$DRY_OUT" && pass 'dry-run: Codex CLI section' || fail 'dry-run: missing Codex CLI section'
DRY_UNINSTALL="$(bash "$INSTALL_SH" --dry-run --uninstall 2>&1)"
grep -q 'Codex CLI →' <<< "$DRY_UNINSTALL" && pass 'dry-run uninstall: Codex CLI section' || fail 'dry-run uninstall: missing Codex CLI section'

grep -q "case 'codex'" "$HELPERS_JS" && pass 'install-helpers: codex case' || fail 'install-helpers: missing codex case'
grep -q 'CODEX_HOOK_SRC=' "$INSTALL_SH" && pass 'install.sh: hook src' || fail 'install.sh: missing hook src'
grep -q 'pre-tool-git-guard.sh' "$INSTALL_SH" && pass 'install.sh: git-guard hook' || fail 'install.sh: missing git-guard hook'

SETUP_SRC="$(cat "$SETUP_JS")"
echo "$SETUP_SRC" | grep -q "SUPPORTED_IDS = new Set" && pass 'setup.js: SUPPORTED_IDS set' || fail 'setup.js: missing SUPPORTED_IDS'
grep -q "'codex'" <<< "$(sed -n "/SUPPORTED_IDS = new Set/,/);/p" "$SETUP_JS")" && pass 'setup.js: codex in SUPPORTED_IDS' || fail 'setup.js: codex not in SUPPORTED_IDS'

grep -q 'id: codex' "$TARGETS_YAML" && pass 'targets.yaml: codex row' || fail 'targets.yaml: missing codex row'
grep -q 'adapter: codex' "$TARGETS_YAML" && pass 'targets.yaml: codex adapter' || fail 'targets.yaml: missing codex adapter'
grep -q 'codex_hooks_manifest' "$TARGETS_YAML" && pass 'targets.yaml: codex_hooks_manifest' || fail 'targets.yaml: missing codex_hooks_manifest'
grep -q 'install_codex()' "$REPO_ROOT/scripts/verify-install.sh" && pass 'verify-install: install_codex assertion' || fail 'verify-install: missing install_codex assertion'

bash -n "$INSTALL_SH" && pass 'bash -n install.sh' || fail 'bash -n install.sh'
node --check "$HELPERS_JS" && pass 'node --check install-helpers.js' || fail 'node --check install-helpers.js'
node --check "$SETUP_JS" && pass 'node --check setup.js' || fail 'node --check setup.js'

echo "test-codex-hub: $PASS passed, $FAIL failed"
[[ "$FAIL" -eq 0 ]] || exit 1
