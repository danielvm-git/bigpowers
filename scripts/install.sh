#!/usr/bin/env bash
# story: e45s16
# install.sh — global symlink install for bigpowers skills
#
# Supported tools:
#   Claude Code  → ~/.claude/skills/<name>/ (one symlink per skill)
#   Gemini CLI   → ~/.gemini/extensions/bigpowers/ (one dir symlink)
#   pi           → ~/.pi/agent/skills/<name>/ (one symlink per skill)
#   Cursor       → ~/.cursor/rules/ (one dir symlink; per-project note printed)
#
# Usage:
#   ./scripts/install.sh              # install
#   ./scripts/install.sh --dry-run   # show what would be linked
#   ./scripts/install.sh --uninstall # remove all managed symlinks
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/skill-common.sh"
resolve_repo_root

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

# ── Claude Code ───────────────────────────────────────────────────────────────

CLAUDE_CONFIG_DIR="$HOME/.claude"
CLAUDE_SKILLS_DIR="$CLAUDE_CONFIG_DIR/skills"
CLAUDE_HOOKS_DIR="$CLAUDE_CONFIG_DIR/hooks"
CLAUDE_SETTINGS="$CLAUDE_CONFIG_DIR/settings.json"

install_claude() {
  echo ""
  echo "Claude Code → $CLAUDE_SKILLS_DIR/"
  local count=0
  for skill_dir in "$SKILLS_ROOT"/*/; do
    [[ -f "$skill_dir/SKILL.md" ]] || continue
    local name; name="$(basename "$skill_dir")"
    link "$skill_dir" "$CLAUDE_SKILLS_DIR/$name"
    count=$((count + 1))
  done
  echo "  $count skills installed"

  echo "Claude Code Hooks → $CLAUDE_HOOKS_DIR/"
  link "$REPO_ROOT/.gemini/extensions/bigpowers/hooks/session-start" "$CLAUDE_HOOKS_DIR/session-start"
  link "$REPO_ROOT/.gemini/extensions/bigpowers/hooks/run-hook.cmd" "$CLAUDE_HOOKS_DIR/run-hook.cmd"
  link "$REPO_ROOT/guard-git/scripts/block-dangerous-git.sh" "$CLAUDE_HOOKS_DIR/block-dangerous-git.sh"
  link "$REPO_ROOT/guard-git/scripts/lib" "$CLAUDE_HOOKS_DIR/lib"
  link "$REPO_ROOT/scripts/hooks/rtk-rewrite.sh" "$CLAUDE_HOOKS_DIR/rtk-rewrite.sh"
  # story: e45s16
  chmod +x "$REPO_ROOT/scripts/hooks/rtk-rewrite.sh" 2>/dev/null || true

  if [[ -f "$CLAUDE_SETTINGS" ]]; then
    echo "  Configuring global hooks in $CLAUDE_SETTINGS..."
    # Robustly add hooks to settings.json if not already present
    if command -v jq >/dev/null; then
      local tmp; tmp=$(mktemp)
      cat "$CLAUDE_SETTINGS" | jq '
        .hooks.SessionStart += [{"matcher":"startup|clear|compact","hooks":[{"type":"command","command":"\"'"$CLAUDE_HOOKS_DIR/run-hook.cmd"'\" session-start","async":false}]}] |
        .hooks.PreToolUse += [{"matcher":"Bash","hooks":[{"type":"command","command":"\"'"$CLAUDE_HOOKS_DIR/block-dangerous-git.sh"'\""}]}] |
        .hooks.PreToolUse += [{"matcher":"Bash","hooks":[{"type":"command","command":"\"'"$CLAUDE_HOOKS_DIR/rtk-rewrite.sh"'\""}]}] |
        # deduplicate
        .hooks.SessionStart |= unique |
        .hooks.PreToolUse |= unique
      ' > "$tmp" && run mv "$tmp" "$CLAUDE_SETTINGS"
    else
      echo "  WARNING: jq not found. Manual setup required in $CLAUDE_SETTINGS"
    fi
  fi
}

uninstall_claude() {
  echo ""
  echo "Claude Code → removing management from $CLAUDE_CONFIG_DIR/"
  if [[ -d "$CLAUDE_SKILLS_DIR" ]]; then
    for dst in "$CLAUDE_SKILLS_DIR"/*/; do
      [[ -L "${dst%/}" ]] || continue
      unlink_if_managed "${dst%/}" "$REPO_ROOT/"
    done
  fi
  if [[ -d "$CLAUDE_HOOKS_DIR" ]]; then
    unlink_if_managed "$CLAUDE_HOOKS_DIR/session-start" "$REPO_ROOT/"
    unlink_if_managed "$CLAUDE_HOOKS_DIR/run-hook.cmd" "$REPO_ROOT/"
    unlink_if_managed "$CLAUDE_HOOKS_DIR/block-dangerous-git.sh" "$REPO_ROOT/"
    unlink_if_managed "$CLAUDE_HOOKS_DIR/rtk-rewrite.sh" "$REPO_ROOT/"
    unlink_if_managed "$CLAUDE_HOOKS_DIR/lib" "$REPO_ROOT/"
  fi
}

# ── Gemini CLI ────────────────────────────────────────────────────────────────

GEMINI_CONFIG_DIR="$HOME/.gemini"
GEMINI_EXT_SRC="$REPO_ROOT/.gemini/extensions/bigpowers"
GEMINI_EXT_DST="$GEMINI_CONFIG_DIR/extensions/bigpowers"
GEMINI_HOOKS_DIR="$GEMINI_CONFIG_DIR/hooks"
GEMINI_SETTINGS="$GEMINI_CONFIG_DIR/settings.json"

install_gemini() {
  echo ""
  echo "Gemini CLI → $GEMINI_EXT_DST"
  if [[ ! -d "$GEMINI_EXT_SRC" ]]; then
    echo "  WARNING: $GEMINI_EXT_SRC not found — run sync-skills.sh first"
    return
  fi
  link "$GEMINI_EXT_SRC" "$GEMINI_EXT_DST"

  echo "Gemini CLI Hooks → $GEMINI_HOOKS_DIR/"
  link "$REPO_ROOT/.gemini/extensions/bigpowers/hooks/session-start" "$GEMINI_HOOKS_DIR/session-start"
  link "$REPO_ROOT/.gemini/extensions/bigpowers/hooks/run-hook.cmd" "$GEMINI_HOOKS_DIR/run-hook.cmd"
  link "$REPO_ROOT/guard-git/scripts/block-dangerous-git.sh" "$GEMINI_HOOKS_DIR/block-dangerous-git.sh"
  link "$REPO_ROOT/guard-git/scripts/lib" "$GEMINI_HOOKS_DIR/lib"

  if [[ -f "$GEMINI_SETTINGS" ]]; then
    echo "  Configuring global hooks in $GEMINI_SETTINGS..."
    if command -v jq >/dev/null; then
      local tmp; tmp=$(mktemp)
      cat "$GEMINI_SETTINGS" | jq '
        .hooks.SessionStart += [{"matcher":"startup|clear|compact","hooks":[{"type":"command","command":"\"'"$GEMINI_HOOKS_DIR/run-hook.cmd"'\" session-start","async":false}]}] |
        .hooks.BeforeTool += [{"matcher":"run_shell_command","hooks":[{"name":"git-guardrails","type":"command","command":"GIT_GUARDRAILS_MODE=gemini \"'"$GEMINI_HOOKS_DIR/block-dangerous-git.sh"'\""}]}] |
        # deduplicate
        .hooks.SessionStart |= unique |
        .hooks.BeforeTool |= unique
      ' > "$tmp" && run mv "$tmp" "$GEMINI_SETTINGS"
    else
      echo "  WARNING: jq not found. Manual setup required in $GEMINI_SETTINGS"
    fi
  fi
}

uninstall_gemini() {
  echo ""
  echo "Gemini CLI → removing management from $GEMINI_CONFIG_DIR/"
  unlink_if_managed "$GEMINI_EXT_DST" "$REPO_ROOT/"
  if [[ -d "$GEMINI_HOOKS_DIR" ]]; then
    unlink_if_managed "$GEMINI_HOOKS_DIR/session-start" "$REPO_ROOT/"
    unlink_if_managed "$GEMINI_HOOKS_DIR/run-hook.cmd" "$REPO_ROOT/"
    unlink_if_managed "$GEMINI_HOOKS_DIR/block-dangerous-git.sh" "$REPO_ROOT/"
    unlink_if_managed "$GEMINI_HOOKS_DIR/lib" "$REPO_ROOT/"
  fi
}

# ── Cursor ────────────────────────────────────────────────────────────────────

CURSOR_RULES_SRC="$REPO_ROOT/.cursor/rules"
CURSOR_RULES_DST="$HOME/.cursor/rules"

install_cursor() {
  echo ""
  echo "Cursor → $CURSOR_RULES_DST"
  if [[ ! -d "$CURSOR_RULES_SRC" ]]; then
    echo "  WARNING: $CURSOR_RULES_SRC not found — run sync-skills.sh first"
    return
  fi
  link "$CURSOR_RULES_SRC" "$CURSOR_RULES_DST"
  echo ""
  echo "  NOTE: Cursor does not scan ~/.cursor/rules/ globally."
  echo "  For per-project access, run in your project root:"
  echo "    ln -sfn $CURSOR_RULES_SRC .cursor/rules"
}

uninstall_cursor() {
  echo ""
  echo "Cursor → removing $CURSOR_RULES_DST"
  unlink_if_managed "$CURSOR_RULES_DST" "$REPO_ROOT/"
}

# ── pi ────────────────────────────────────────────────────────────────────────

PI_CONFIG_DIR="$HOME/.pi"
PI_SKILLS_DIR="$PI_CONFIG_DIR/agent/skills"

install_pi() {
  echo ""
  echo "pi → $PI_SKILLS_DIR/"
  local count=0
  for skill_dir in "$SKILLS_ROOT"/*/; do
    [[ -f "$skill_dir/SKILL.md" ]] || continue
    local name; name="$(basename "$skill_dir")"
    link "$skill_dir" "$PI_SKILLS_DIR/$name"
    count=$((count + 1))
  done
  echo "  $count skills installed"
}

uninstall_pi() {
  echo ""
  echo "pi → removing management from $PI_CONFIG_DIR/"
  if [[ -d "$PI_SKILLS_DIR" ]]; then
    for dst in "$PI_SKILLS_DIR"/*/; do
      [[ -L "${dst%/}" ]] || continue
      unlink_if_managed "${dst%/}" "$REPO_ROOT/"
    done
  fi
}

# ── Codex CLI (e37s15) ───────────────────────────────────────────────────────

CODEX_DIR="$HOME/.codex"
CODEX_AGENTS="$CODEX_DIR/AGENTS.md"
CODEX_TEMPLATE="$REPO_ROOT/docs/templates/codex/AGENTS.md"

install_codex() {
  echo ""
  echo "Codex CLI → $CODEX_AGENTS"
  [[ -f "$CODEX_TEMPLATE" ]] || { echo "  skip: template missing $CODEX_TEMPLATE" >&2; return 0; }
  link "$CODEX_TEMPLATE" "$CODEX_AGENTS"
}

uninstall_codex() {
  echo ""
  echo "Codex CLI → removing $CODEX_AGENTS"
  unlink_if_managed "$CODEX_AGENTS" "$REPO_ROOT/"
}

# ── main ──────────────────────────────────────────────────────────────────────

echo "bigpowers install.sh — REPO: $REPO_ROOT"
$DRY_RUN && echo "(dry-run mode — no changes written)"
$UNINSTALL && echo "(uninstall mode)"

if $UNINSTALL; then
  uninstall_claude
  uninstall_gemini
  uninstall_pi
  uninstall_cursor
  uninstall_codex
  echo ""
  echo "bigpowers uninstalled."
else
  install_claude
  install_gemini
  install_pi
  install_cursor
  install_codex
  echo ""
  echo "bigpowers installed. Future updates:"
  if [[ -d "$REPO_ROOT/.git" ]]; then
    echo "  git pull && ./scripts/sync-skills.sh"
  else
    echo "  npm update -g bigpowers && bigpowers update"
  fi
fi
