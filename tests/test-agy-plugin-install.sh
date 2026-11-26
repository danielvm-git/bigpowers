#!/usr/bin/env bash
# story: BUG-2026-11-26-agy-plugin-install
# Regression test: Antigravity global install must link the rendered native
# plugin bundle (.bigpowers/rendered/antigravity with plugin.json + skills/)
# into ~/.gemini/config/plugins/bigpowers and clean up legacy symlinks from
# ~/.gemini/antigravity-cli/skills/.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
pass=0
fail=0
ok()  { printf 'ok   %s\n' "$1"; pass=$((pass + 1)); }
bad() { printf 'FAIL %s\n' "$1"; fail=$((fail + 1)); }

TMP_HOME="$(mktemp -d)"
trap 'rm -rf "$TMP_HOME"' EXIT

PLUGIN_MANIFEST="$REPO_ROOT/.bigpowers/rendered/antigravity/plugin.json"
PKG_VER="$(jq -r '.version' "$REPO_ROOT/package.json")"

# T1 — rendered Antigravity plugin manifest exists and matches package.json
if [[ -f "$PLUGIN_MANIFEST" ]] \
  && [[ "$(jq -r '.name // empty' "$PLUGIN_MANIFEST")" == "bigpowers" ]] \
  && [[ "$(jq -r '.version // empty' "$PLUGIN_MANIFEST")" == "$PKG_VER" ]]; then
  ok "T1 .bigpowers/rendered/antigravity/plugin.json valid (bigpowers v$PKG_VER)"
else
  bad "T1 missing or invalid $PLUGIN_MANIFEST"
fi

# T2 — setup.js advertises ~/.gemini/config/plugins/bigpowers
if grep -q "id: 'antigravity'.*globalPath: '~/.gemini/config/plugins/bigpowers'" "$REPO_ROOT/bin/setup.js"; then
  ok "T2 bin/setup.js antigravity globalPath is ~/.gemini/config/plugins/bigpowers"
else
  bad "T2 bin/setup.js antigravity globalPath does not point to ~/.gemini/config/plugins/bigpowers"
fi

# T3 & T4 — installGlobal('antigravity') links plugin and cleans legacy symlinks
mkdir -p "$TMP_HOME/.gemini/antigravity-cli/skills"
ln -s "$REPO_ROOT/.bigpowers/rendered/antigravity/skills/fix-bug" \
  "$TMP_HOME/.gemini/antigravity-cli/skills/fix-bug"
mkdir -p "$TMP_HOME/.gemini/antigravity-cli/skills/user-custom-skill"

HOME="$TMP_HOME" node -e "
  const { installGlobal } = require('$REPO_ROOT/scripts/lib/install-helpers');
  installGlobal({ id: 'antigravity' }, '$REPO_ROOT');
" 2>/dev/null || true

DST="$TMP_HOME/.gemini/config/plugins/bigpowers"
if [[ -L "$DST" ]] && [[ "$(readlink "$DST")" == "$REPO_ROOT/.bigpowers/rendered/antigravity" ]] \
  && [[ -f "$DST/skills/fix-bug/SKILL.md" ]]; then
  ok "T3 installGlobal links ~/.gemini/config/plugins/bigpowers -> .bigpowers/rendered/antigravity"
else
  bad "T3 installGlobal did not link $DST to .bigpowers/rendered/antigravity"
fi

if [[ ! -L "$TMP_HOME/.gemini/antigravity-cli/skills/fix-bug" ]] \
  && [[ -d "$TMP_HOME/.gemini/antigravity-cli/skills/user-custom-skill" ]]; then
  ok "T4 installGlobal removes legacy bigpowers symlink and preserves user-owned entries"
else
  bad "T4 legacy symlink cleanup failed or removed user-owned directory"
fi

# T5 — uninstallTool('antigravity') removes plugin symlink and legacy symlinks
ln -s "$REPO_ROOT/.bigpowers/rendered/antigravity/skills/fix-bug" \
  "$TMP_HOME/.gemini/antigravity-cli/skills/fix-bug"
HOME="$TMP_HOME" node -e "
  const { uninstallTool } = require('$REPO_ROOT/scripts/lib/install-helpers');
  uninstallTool('antigravity', '$REPO_ROOT');
" 2>/dev/null || true

if [[ ! -L "$DST" ]] && [[ ! -L "$TMP_HOME/.gemini/antigravity-cli/skills/fix-bug" ]] \
  && [[ -d "$TMP_HOME/.gemini/antigravity-cli/skills/user-custom-skill" ]]; then
  ok "T5 uninstallTool removes plugin symlink and legacy symlinks safely"
else
  bad "T5 uninstallTool left managed symlinks behind or touched user entry"
fi

# T6 — install.sh --dry-run targets ~/.gemini/config/plugins/bigpowers for Antigravity
DRY_OUT="$(HOME="$TMP_HOME" bash "$REPO_ROOT/scripts/install.sh" --dry-run 2>&1 || true)"
if grep -Fq "Antigravity CLI → $TMP_HOME/.gemini/config/plugins/bigpowers" <<<"$DRY_OUT"; then
  ok "T6 install.sh --dry-run shows Antigravity -> ~/.gemini/config/plugins/bigpowers"
else
  bad "T6 install.sh --dry-run does not target ~/.gemini/config/plugins/bigpowers for Antigravity"
fi

printf '\n%s\n' "$( [ "$fail" -eq 0 ] && echo "PASS: $pass/$((pass + fail)) agy plugin install checks" || echo "FAIL: $fail of $((pass + fail)) checks" )"
[ "$fail" -eq 0 ] || exit 1
