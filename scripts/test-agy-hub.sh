#!/usr/bin/env bash
# story: e74s02
# Regression tests for Antigravity CLI install hub wiring (Wave B).
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PASS=0
FAIL=0

pass() { echo "PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "FAIL: $1" >&2; FAIL=$((FAIL + 1)); }

echo "=== test-agy-hub.sh ==="

INSTALL_SH="$REPO_ROOT/scripts/install.sh"
source "$REPO_ROOT/scripts/lib/install-grep.sh"
HELPERS_JS="$REPO_ROOT/scripts/lib/install-helpers.js"
SETUP_JS="$REPO_ROOT/bin/setup.js"
TARGETS_YAML="$REPO_ROOT/scripts/targets.yaml"

install_grep -q 'install_agy()' && pass 'install.sh: install_agy()' || fail 'install.sh: missing install_agy()'
install_grep -q 'install_antigravity()' && pass 'install.sh: install_antigravity alias' || fail 'install.sh: missing install_antigravity()'
install_grep -q 'uninstall_agy()' && pass 'install.sh: uninstall_agy()' || fail 'install.sh: missing uninstall_agy()'
install_grep -q 'uninstall_antigravity()' && pass 'install.sh: uninstall_antigravity alias' || fail 'install.sh: missing uninstall_antigravity()'
install_grep -q 'AGY_SKILLS_DIR=' && pass 'install.sh: AGY_SKILLS_DIR' || fail 'install.sh: missing AGY_SKILLS_DIR'
install_grep -q 'antigravity-cli/skills' && pass 'install.sh: antigravity-cli path' || fail 'install.sh: missing antigravity-cli path'
install_grep -q 'install_agy' && install_grep -q 'uninstall_agy' && pass 'install.sh: dispatch wired' || fail 'install.sh: dispatch missing agy'
! grep -q '\.gemini/extensions/bigpowers' <<< "$(sed -n '/install_agy/,/^}/p' "$INSTALL_SH")" \
  && pass 'install.sh: no gemini extension path' || fail 'install.sh: touches gemini extension path'

DRY_OUT="$(bash "$INSTALL_SH" --dry-run 2>&1)"
grep -q 'Antigravity CLI →' <<< "$DRY_OUT" && pass 'dry-run: Antigravity CLI section' || fail 'dry-run: missing Antigravity CLI section'
DRY_UNINSTALL="$(bash "$INSTALL_SH" --dry-run --uninstall 2>&1)"
grep -q 'Antigravity CLI →' <<< "$DRY_UNINSTALL" && pass 'dry-run uninstall: Antigravity CLI section' || fail 'dry-run uninstall: missing Antigravity CLI section'

grep -q "case 'antigravity'" "$HELPERS_JS" && pass 'install-helpers: antigravity case' || fail 'install-helpers: missing antigravity case'
grep -q "case 'agy'" "$HELPERS_JS" && pass 'install-helpers: agy case' || fail 'install-helpers: missing agy case'
grep -q "'antigravity-cli', 'skills'" "$HELPERS_JS" && pass 'install-helpers: antigravity-cli global path' || fail 'install-helpers: missing antigravity-cli path'
grep -q "'\\.agents', 'skills'" "$HELPERS_JS" && pass 'install-helpers: .agents/skills local path' || fail 'install-helpers: missing .agents/skills path'

SETUP_SRC="$(cat "$SETUP_JS")"
echo "$SETUP_SRC" | grep -q "SUPPORTED_IDS = new Set" && pass 'setup.js: SUPPORTED_IDS set' || fail 'setup.js: missing SUPPORTED_IDS'
echo "$SETUP_SRC" | grep -q "'antigravity'" && pass 'setup.js: antigravity in TOOLS/SUPPORTED_IDS' || fail 'setup.js: antigravity missing'
echo "$SETUP_SRC" | grep -q "'agy'" && pass 'setup.js: agy in SUPPORTED_IDS' || fail 'setup.js: agy missing from SUPPORTED_IDS'
echo "$SETUP_SRC" | grep -q 'antigravity-cli/skills' <<< "$DRY_OUT" && pass 'setup.js: antigravity-cli global path' || fail 'setup.js: wrong antigravity global path'
echo "$SETUP_SRC" | grep -q "'\\.agents/skills'" && pass 'setup.js: .agents/skills local path' || fail 'setup.js: wrong antigravity local path'

grep -q 'id: agy' "$TARGETS_YAML" && pass 'targets.yaml: agy row' || fail 'targets.yaml: missing agy row'
grep -q 'adapter: agy' "$TARGETS_YAML" && pass 'targets.yaml: agy adapter' || fail 'targets.yaml: missing agy adapter'
grep -q 'output: .agents/skills' "$TARGETS_YAML" && pass 'targets.yaml: agy output path' || fail 'targets.yaml: missing agy output'
grep -q 'agy_skills_nonempty' "$TARGETS_YAML" && pass 'targets.yaml: agy contract' || fail 'targets.yaml: missing agy contract'

grep -q 'install_agy()' "$REPO_ROOT/scripts/verify-install.sh" && pass 'verify-install: install_agy assertion' || fail 'verify-install: missing install_agy assertion'

bash -n "$INSTALL_SH" && pass 'bash -n install.sh' || fail 'bash -n install.sh'
node --check "$HELPERS_JS" && pass 'node --check install-helpers.js' || fail 'node --check install-helpers.js'
node --check "$SETUP_JS" && pass 'node --check setup.js' || fail 'node --check setup.js'

echo "test-agy-hub: $PASS passed, $FAIL failed"
[[ "$FAIL" -eq 0 ]] || exit 1
