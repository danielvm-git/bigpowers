#!/usr/bin/env bash
# story: e45s16
# story: e60s01
# story: e63
# story: e64s02
# story: e74s02
# story: e71s02
# story: e62s02
# story: e73s02
# story: e70s02
# story: e67s02
# story: e66s02
# story: e72s02
# story: e68s02
# story: e65s02
# install.sh — global symlink install for bigpowers skills
#
# Supported tools:
#   Claude Code  → ~/.claude/skills/<name>/ (one symlink per skill)
#   Gemini CLI   → ~/.gemini/config/plugins/bigpowers/ (one dir symlink)
#   pi           → ~/.pi/agent/skills/<name>/ (one symlink per skill)
#   Hermes Agent → ~/.hermes/skills/<name>/ (symlink rendered .hermes/skills/)
#   ZCode        → ~/.zcode/skills/<name>/ (symlink rendered .zcode/skills/)
#   MiMo Code    → ~/.mimocode/skills/<name>/ (symlink rendered .mimocode/skills/)
#   Antigravity  → ~/.gemini/antigravity-cli/skills/ (NOT .gemini/extensions/ — e64 Gemini)
#   Cursor       → ~/.cursor/rules/ (one dir symlink; per-project note printed)
#
# Usage:
#   ./scripts/install.sh              # install
#   ./scripts/install.sh --dry-run   # show what would be linked
#   ./scripts/install.sh --uninstall # remove all managed symlinks
set -euo pipefail

# SKILLS_ROOT: use skills/ subdirectory when it exists, fall back to repo root
source "$(dirname "${BASH_SOURCE[0]}")/lib/skill-common.sh"
resolve_repo_root

DRY_RUN=false
UNINSTALL=false

for arg in "$@"; do
  case "$arg" in
    --dry-run)   DRY_RUN=true ;;
    --uninstall) UNINSTALL=true ;;
    *) echo "Unknown flag: $arg" >&2; exit 1 ;;
  esac
done

export DRY_RUN

# ── helpers ──────────────────────────────────────────────────────────────────

run() {
  if $DRY_RUN; then
    echo "  [dry-run] $*"
  else
    "$@"
  fi
}

link() {
  local src="$1" dst="$2"
  local dst_dir; dst_dir="$(dirname "$dst")"
  run mkdir -p "$dst_dir"
  run ln -sfn "$src" "$dst"
  echo "  linked: $dst → $src"
}

unlink_if_managed() {
  local dst="$1" src_prefix="$2"
  if [[ -L "$dst" ]]; then
    local target; target="$(readlink "$dst")"
    if [[ "$target" == "$src_prefix"* ]]; then
      run rm "$dst"
      echo "  removed: $dst"
    fi
  fi
}

# Per-target install/uninstall functions (extracted for file-size cap)
_INSTALL_LIB="$(dirname "${BASH_SOURCE[0]}")/lib"
source "$_INSTALL_LIB/install-targets-a.sh"
source "$_INSTALL_LIB/install-targets-b.sh"
source "$_INSTALL_LIB/install-targets-c.sh"
source "$_INSTALL_LIB/install-targets-d.sh"

# ── main ──────────────────────────────────────────────────────────────────────

echo "bigpowers install.sh — REPO: $REPO_ROOT"
$DRY_RUN && echo "(dry-run mode — no changes written)"
$UNINSTALL && echo "(uninstall mode)"

if $UNINSTALL; then
  uninstall_claude
  uninstall_gemini
  uninstall_pi
  uninstall_hermes
  uninstall_zcode
  uninstall_mimo
  uninstall_agy
  uninstall_cursor
  uninstall_codex
  uninstall_qwen
  uninstall_codebuddy
  uninstall_cline
  uninstall_kilocode
  uninstall_trae
  uninstall_windsurf
  uninstall_opencode
  uninstall_copilot
  echo ""
  echo "bigpowers uninstalled."
else
  install_claude
  install_gemini
  install_pi
  install_hermes
  install_zcode
  install_mimo
  install_agy
  install_cursor
  install_codex
  install_qwen
  install_codebuddy
  install_cline
  install_kilocode
  install_trae
  install_windsurf
  install_opencode
  install_copilot
  echo ""
  echo "bigpowers installed. Future updates:"
  if [[ -d "$REPO_ROOT/.git" ]]; then
    echo "  git pull && ./scripts/sync-skills.sh"
  else
    echo "  npm update -g bigpowers && bigpowers update"
  fi
fi
