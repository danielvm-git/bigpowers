#!/usr/bin/env bash
# story: e69s02
# Regression tests for MiMo Code install hub wiring (Wave B).
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PASS=0
FAIL=0

pass() { echo "PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "FAIL: $1" >&2; FAIL=$((FAIL + 1)); }

echo "=== test-mimo-hub.sh ==="

INSTALL_SH="$REPO_ROOT/scripts/install.sh"
HELPERS_JS="$REPO_ROOT/scripts/lib/install-helpers.js"
SETUP_JS="$REPO_ROOT/bin/setup.js"
TARGETS_YAML="$REPO_ROOT/scripts/targets.yaml"

grep -q 'install_mimo()' "$INSTALL_SH" && pass 'install.sh: install_mimo()' || fail 'install.sh: missing install_mimo()'
grep -q 'uninstall_mimo()' "$INSTALL_SH" && pass 'install.sh: uninstall_mimo()' || fail 'install.sh: missing uninstall_mimo()'
grep -q 'MIMO_SKILLS_DIR=' "$INSTALL_SH" && pass 'install.sh: MIMO_SKILLS_DIR' || fail 'install.sh: missing MIMO_SKILLS_DIR'
grep -q 'install_mimo' "$INSTALL_SH" && grep -q 'uninstall_mimo' "$INSTALL_SH" && pass 'install.sh: dispatch wired' || fail 'install.sh: dispatch missing mimo'

DRY_OUT="$(bash "$INSTALL_SH" --dry-run 2>&1)"
echo "$DRY_OUT" | grep -q 'MiMo Code →' && pass 'dry-run: MiMo Code section' || fail 'dry-run: missing MiMo Code section'
DRY_UNINSTALL="$(bash "$INSTALL_SH" --dry-run --uninstall 2>&1)"
echo "$DRY_UNINSTALL" | grep -q 'MiMo Code →' && pass 'dry-run uninstall: MiMo Code section' || fail 'dry-run uninstall: missing MiMo Code section'

grep -q "case 'mimo'" "$HELPERS_JS" && pass 'install-helpers: mimo global case' || fail 'install-helpers: missing mimo global case'
grep -q "case 'mimo'" "$HELPERS_JS" && pass 'install-helpers: mimo cases present' || fail 'install-helpers: missing mimo cases'

SETUP_SRC="$(cat "$SETUP_JS")"
echo "$SETUP_SRC" | grep -q "SUPPORTED_IDS = new Set" && pass 'setup.js: SUPPORTED_IDS set' || fail 'setup.js: missing SUPPORTED_IDS'
echo "$SETUP_SRC" | grep -q "'mimo'" "$SETUP_JS" && pass 'setup.js: mimo in TOOLS' || fail 'setup.js: mimo missing from TOOLS'
echo "$SETUP_SRC" | grep -q "'mimo'" && echo "$SETUP_SRC" | grep -q "SUPPORTED_IDS" \
  && grep -q "'mimo'" <<< "$(sed -n "/SUPPORTED_IDS = new Set/,/);/p" "$SETUP_JS")" \
  && pass 'setup.js: mimo in SUPPORTED_IDS' || fail 'setup.js: mimo not in SUPPORTED_IDS'

grep -q 'id: mimo' "$TARGETS_YAML" && pass 'targets.yaml: mimo row' || fail 'targets.yaml: missing mimo row'
grep -q 'adapter: mimo' "$TARGETS_YAML" && pass 'targets.yaml: mimo adapter' || fail 'targets.yaml: missing mimo adapter'
grep -q 'output: .mimocode/skills' "$TARGETS_YAML" && pass 'targets.yaml: mimo output path' || fail 'targets.yaml: missing mimo output'

grep -q 'install_mimo()' "$REPO_ROOT/scripts/verify-install.sh" && pass 'verify-install: install_mimo assertion' || fail 'verify-install: missing install_mimo assertion'

bash -n "$INSTALL_SH" && pass 'bash -n install.sh' || fail 'bash -n install.sh'
node --check "$HELPERS_JS" && pass 'node --check install-helpers.js' || fail 'node --check install-helpers.js'
node --check "$SETUP_JS" && pass 'node --check setup.js' || fail 'node --check setup.js'

echo "test-mimo-hub: $PASS passed, $FAIL failed"
[[ "$FAIL" -eq 0 ]] || exit 1
