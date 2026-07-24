#!/usr/bin/env bash
# story: e61s02
# Regression tests for Hermes install hub wiring (Wave B).
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PASS=0
FAIL=0

pass() { echo "PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "FAIL: $1" >&2; FAIL=$((FAIL + 1)); }

echo "=== test-hermes-hub.sh ==="

INSTALL_SH="$REPO_ROOT/scripts/install.sh"
source "$REPO_ROOT/scripts/lib/install-grep.sh"
HELPERS_JS="$REPO_ROOT/scripts/lib/install-helpers.js"
SETUP_JS="$REPO_ROOT/bin/setup.js"
TARGETS_YAML="$REPO_ROOT/scripts/targets.yaml"

install_grep -q 'install_hermes()' && pass 'install.sh: install_hermes()' || fail 'install.sh: missing install_hermes()'
install_grep -q 'uninstall_hermes()' && pass 'install.sh: uninstall_hermes()' || fail 'install.sh: missing uninstall_hermes()'
install_grep -q 'HERMES_SKILLS_DIR=' && pass 'install.sh: HERMES_SKILLS_DIR' || fail 'install.sh: missing HERMES_SKILLS_DIR'
install_grep -q 'install_hermes' && install_grep -q 'uninstall_hermes' && pass 'install.sh: dispatch wired' || fail 'install.sh: dispatch missing hermes'

DRY_OUT="$(bash "$INSTALL_SH" --dry-run 2>&1)"
grep -q 'Hermes Agent →' <<< "$DRY_OUT" && pass 'dry-run: Hermes Agent section' || fail 'dry-run: missing Hermes Agent section'
DRY_UNINSTALL="$(bash "$INSTALL_SH" --dry-run --uninstall 2>&1)"
grep -q 'Hermes Agent →' <<< "$DRY_UNINSTALL" && pass 'dry-run uninstall: Hermes Agent section' || fail 'dry-run uninstall: missing Hermes Agent section'

grep -q "case 'hermes'" "$HELPERS_JS" && pass 'install-helpers: hermes global case' || fail 'install-helpers: missing hermes global case'
grep -q "case 'hermes'" "$HELPERS_JS" && pass 'install-helpers: hermes cases present' || fail 'install-helpers: missing hermes cases'

SETUP_SRC="$(cat "$SETUP_JS")"
echo "$SETUP_SRC" | grep -q "SUPPORTED_IDS = new Set" && pass 'setup.js: SUPPORTED_IDS set' || fail 'setup.js: missing SUPPORTED_IDS'
echo "$SETUP_SRC" | grep -q "'hermes'" "$SETUP_JS" && pass 'setup.js: hermes in TOOLS' || fail 'setup.js: hermes missing from TOOLS'
echo "$SETUP_SRC" | grep -q "'hermes'" && echo "$SETUP_SRC" | grep -q "SUPPORTED_IDS" \
  && grep -q "'hermes'" <<< "$(sed -n "/SUPPORTED_IDS = new Set/,/);/p" "$SETUP_JS")" \
  && pass 'setup.js: hermes in SUPPORTED_IDS' || fail 'setup.js: hermes not in SUPPORTED_IDS'

grep -q 'id: hermes' "$TARGETS_YAML" && pass 'targets.yaml: hermes row' || fail 'targets.yaml: missing hermes row'
grep -q 'adapter: hermes' "$TARGETS_YAML" && pass 'targets.yaml: hermes adapter' || fail 'targets.yaml: missing hermes adapter'
grep -q 'bridge_key: instructions' "$TARGETS_YAML" && pass 'targets.yaml: instructions bridge_key' || fail 'targets.yaml: missing bridge_key'

grep -q 'install_hermes()' "$REPO_ROOT/scripts/verify-install.sh" && pass 'verify-install: install_hermes assertion' || fail 'verify-install: missing install_hermes assertion'

bash -n "$INSTALL_SH" && pass 'bash -n install.sh' || fail 'bash -n install.sh'
node --check "$HELPERS_JS" && pass 'node --check install-helpers.js' || fail 'node --check install-helpers.js'
node --check "$SETUP_JS" && pass 'node --check setup.js' || fail 'node --check setup.js'

echo "test-hermes-hub: $PASS passed, $FAIL failed"
[[ "$FAIL" -eq 0 ]] || exit 1
