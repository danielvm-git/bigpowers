#!/usr/bin/env bash
# install.sh — global symlink install for bigpowers skills
#
# Supported tools:
#   Claude Code  → ~/.claude/skills/<name>/ (one symlink per skill)
#   Gemini CLI   → ~/.gemini/extensions/bigpowers/ (one dir symlink)
#   Cursor       → ~/.cursor/rules/ (one dir symlink; per-project note printed)
#   OpenCode     → instructions printed (no standard global path)
#
# Usage:
#   ./scripts/install.sh              # install
#   ./scripts/install.sh --dry-run   # show what would be linked
#   ./scripts/install.sh --uninstall # remove all managed symlinks
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

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
  for skill_dir in "$REPO_ROOT"/*/; do
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

  if [[ -f "$CLAUDE_SETTINGS" ]]; then
    echo "  Configuring global hooks in $CLAUDE_SETTINGS..."
    # Robustly add hooks to settings.json if not already present
    if command -v jq >/dev/null; then
      local tmp; tmp=$(mktemp)
      cat "$CLAUDE_SETTINGS" | jq '
        .hooks.SessionStart += [{"matcher":"startup|clear|compact","hooks":[{"type":"command","command":"\"'"$CLAUDE_HOOKS_DIR/run-hook.cmd"'\" session-start","async":false}]}] |
        .hooks.PreToolUse += [{"matcher":"Bash","hooks":[{"type":"command","command":"\"'"$CLAUDE_HOOKS_DIR/block-dangerous-git.sh"'\""}]}] |
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

# ── OpenCode ──────────────────────────────────────────────────────────────────

print_opencode_instructions() {
  echo ""
  echo "OpenCode — manual setup (no standard global path):"
  echo "  Add to your project's opencode.json:"
  echo "    {\"rules\": [\"$(ls "$REPO_ROOT"/.cursor/rules/*.mdc 2>/dev/null | head -1 | xargs dirname 2>/dev/null || echo "$REPO_ROOT/.cursor/rules")/**/*.mdc\"]}"
  echo "  Or symlink the rules directory into your project:"
  echo "    ln -sfn $CURSOR_RULES_SRC .cursor/rules"
}

# ── main ──────────────────────────────────────────────────────────────────────

echo "bigpowers install.sh — REPO: $REPO_ROOT"
$DRY_RUN && echo "(dry-run mode — no changes written)"
$UNINSTALL && echo "(uninstall mode)"

if $UNINSTALL; then
  uninstall_claude
  uninstall_gemini
  uninstall_cursor
  echo ""
  echo "bigpowers uninstalled."
else
  install_claude
  install_gemini
  install_cursor
  print_opencode_instructions
  echo ""
  echo "bigpowers installed. Future updates:"
  echo "  git pull && ./scripts/sync-skills.sh"
fi
