#!/usr/bin/env bash
# story: e45s16
# story: e60s01
# story: e63
# story: e64s02
# story: e74s02
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
  # story: e60s01 e63 — canonical path is skills/guard-git (not bare guard-git/)
  link "$REPO_ROOT/skills/guard-git/scripts/block-dangerous-git.sh" "$CLAUDE_HOOKS_DIR/block-dangerous-git.sh"
  link "$REPO_ROOT/skills/guard-git/scripts/lib" "$CLAUDE_HOOKS_DIR/lib"
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

# ── Gemini CLI (e64s02) ───────────────────────────────────────────────────────

GEMINI_CONFIG_DIR="$HOME/.gemini"
GEMINI_EXT_SRC="$REPO_ROOT/.gemini/extensions/bigpowers"
GEMINI_EXT_DST="$GEMINI_CONFIG_DIR/config/plugins/bigpowers"
GEMINI_HOOKS_SRC="$GEMINI_EXT_SRC/hooks"
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
  link "$GEMINI_HOOKS_SRC/session-start" "$GEMINI_HOOKS_DIR/session-start"
  link "$GEMINI_HOOKS_SRC/run-hook.cmd" "$GEMINI_HOOKS_DIR/run-hook.cmd"
  link "$GEMINI_HOOKS_SRC/before-tool-git-guard.sh" "$GEMINI_HOOKS_DIR/before-tool-git-guard.sh"
  link "$GEMINI_HOOKS_SRC/before-tool-rtk.sh" "$GEMINI_HOOKS_DIR/before-tool-rtk.sh"
  link "$GEMINI_HOOKS_SRC/before-tool-token-mgmt.sh" "$GEMINI_HOOKS_DIR/before-tool-token-mgmt.sh"
  chmod +x "$GEMINI_HOOKS_SRC/before-tool-git-guard.sh" \
    "$GEMINI_HOOKS_SRC/before-tool-rtk.sh" \
    "$GEMINI_HOOKS_SRC/before-tool-token-mgmt.sh" 2>/dev/null || true

  if [[ -f "$GEMINI_SETTINGS" ]]; then
    echo "  Configuring global hooks in $GEMINI_SETTINGS..."
    if command -v jq >/dev/null; then
      local tmp; tmp=$(mktemp)
      cat "$GEMINI_SETTINGS" | jq '
        .hooks.SessionStart += [{"matcher":"startup|clear|compact","hooks":[{"type":"command","command":"\"'"$GEMINI_HOOKS_DIR/run-hook.cmd"'\" session-start","async":false}]}] |
        .hooks.BeforeTool += [{"matcher":"run_shell_command","hooks":[{"name":"git-guardrails","type":"command","command":"GIT_GUARDRAILS_MODE=gemini \"'"$GEMINI_HOOKS_DIR/before-tool-git-guard.sh"'\"","timeout":5000}]}] |
        .hooks.BeforeTool += [{"matcher":"run_shell_command","hooks":[{"name":"rtk-rewrite","type":"command","command":"\"'"$GEMINI_HOOKS_DIR/before-tool-rtk.sh"'\"","timeout":3000}]}] |
        .hooks.SessionStart |= unique |
        .hooks.BeforeTool |= unique
      ' > "$tmp" && run mv "$tmp" "$GEMINI_SETTINGS"
    else
      echo "  WARNING: jq not found. Manual setup required in $GEMINI_SETTINGS"
      echo "  See $GEMINI_HOOKS_SRC/settings.json.example"
    fi
  else
    echo "  NOTE: $GEMINI_SETTINGS not found — copy $GEMINI_HOOKS_SRC/settings.json.example after first Gemini run"
  fi
}

uninstall_gemini() {
  echo ""
  echo "Gemini CLI → removing management from $GEMINI_CONFIG_DIR/"
  unlink_if_managed "$GEMINI_EXT_DST" "$REPO_ROOT/"
  if [[ -d "$GEMINI_HOOKS_DIR" ]]; then
    unlink_if_managed "$GEMINI_HOOKS_DIR/session-start" "$REPO_ROOT/"
    unlink_if_managed "$GEMINI_HOOKS_DIR/run-hook.cmd" "$REPO_ROOT/"
    unlink_if_managed "$GEMINI_HOOKS_DIR/before-tool-git-guard.sh" "$REPO_ROOT/"
    unlink_if_managed "$GEMINI_HOOKS_DIR/before-tool-rtk.sh" "$REPO_ROOT/"
    unlink_if_managed "$GEMINI_HOOKS_DIR/before-tool-token-mgmt.sh" "$REPO_ROOT/"
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

# ── Hermes Agent (e61s02) ─────────────────────────────────────────────────────

HERMES_CONFIG_DIR="$HOME/.hermes"
HERMES_SKILLS_DIR="$HERMES_CONFIG_DIR/skills"
HERMES_RENDERED="$REPO_ROOT/.hermes/skills"
HERMES_CONFIG="$HERMES_CONFIG_DIR/config.yaml"
HERMES_HOOKS_DIR="$HERMES_CONFIG_DIR/hooks"

install_hermes() {
  echo ""
  echo "Hermes Agent → $HERMES_SKILLS_DIR/"
  if [[ ! -d "$HERMES_RENDERED" ]]; then
    echo "  WARNING: $HERMES_RENDERED not found — run sync-skills.sh first"
    return
  fi
  local count=0
  for skill_dir in "$HERMES_RENDERED"/*/; do
    [[ -f "${skill_dir}SKILL.md" ]] || continue
    local name; name="$(basename "$skill_dir")"
    link "$skill_dir" "$HERMES_SKILLS_DIR/$name"
    count=$((count + 1))
  done
  echo "  $count skills installed"

  echo "Hermes Agent → context bridge $HERMES_CONFIG"
  source "$REPO_ROOT/scripts/lib/context-wire.sh"
  wire_context_mode config-bridge "$HERMES_CONFIG" "instructions" "AGENTS.md"

  if [[ -d "$REPO_ROOT/scripts/hooks/hermes/gateway/session-log" ]]; then
    echo "Hermes Agent hook templates → $HERMES_HOOKS_DIR/ (copy paths into config to enable)"
    link "$REPO_ROOT/scripts/hooks/hermes/gateway/session-log" "$HERMES_HOOKS_DIR/session-log"
  fi
}

uninstall_hermes() {
  echo ""
  echo "Hermes Agent → removing management from $HERMES_CONFIG_DIR/"
  if [[ -d "$HERMES_SKILLS_DIR" ]]; then
    for dst in "$HERMES_SKILLS_DIR"/*/; do
      [[ -L "${dst%/}" ]] || continue
      unlink_if_managed "${dst%/}" "$REPO_ROOT/"
    done
  fi
  unlink_if_managed "$HERMES_HOOKS_DIR/session-log" "$REPO_ROOT/"
}

# ── ZCode (e76s02) ────────────────────────────────────────────────────────────

ZCODE_CONFIG_DIR="$HOME/.zcode"
ZCODE_SKILLS_DIR="$ZCODE_CONFIG_DIR/skills"
ZCODE_RENDERED="$REPO_ROOT/.zcode/skills"
ZCODE_AGENTS="$ZCODE_CONFIG_DIR/AGENTS.md"

install_zcode() {
  echo ""
  echo "ZCode → $ZCODE_SKILLS_DIR/"
  if [[ ! -d "$ZCODE_RENDERED" ]]; then
    echo "  WARNING: $ZCODE_RENDERED not found — run sync-skills.sh first"
    return
  fi
  local count=0
  for skill_dir in "$ZCODE_RENDERED"/*/; do
    [[ -f "${skill_dir}SKILL.md" ]] || continue
    local name; name="$(basename "$skill_dir")"
    link "$skill_dir" "$ZCODE_SKILLS_DIR/$name"
    count=$((count + 1))
  done
  echo "  $count skills installed"

  echo "ZCode → context symlink $ZCODE_AGENTS"
  source "$REPO_ROOT/scripts/lib/context-wire.sh"
  local zcode_agents_src="$REPO_ROOT/AGENTS.md"
  [[ -f "$zcode_agents_src" ]] || zcode_agents_src="$REPO_ROOT/docs/templates/AGENTS.md"
  wire_context_mode symlink "$ZCODE_AGENTS" "" read "$zcode_agents_src"
}

uninstall_zcode() {
  echo ""
  echo "ZCode → removing management from $ZCODE_CONFIG_DIR/"
  if [[ -d "$ZCODE_SKILLS_DIR" ]]; then
    for dst in "$ZCODE_SKILLS_DIR"/*/; do
      [[ -L "${dst%/}" ]] || continue
      unlink_if_managed "${dst%/}" "$REPO_ROOT/"
    done
  fi
  unlink_if_managed "$ZCODE_AGENTS" "$REPO_ROOT/"
}

# ── MiMo Code (e69s02) ────────────────────────────────────────────────────────

MIMO_CONFIG_DIR="$HOME/.mimocode"
MIMO_SKILLS_DIR="$MIMO_CONFIG_DIR/skills"
MIMO_RENDERED="$REPO_ROOT/.mimocode/skills"
MIMO_AGENTS="$MIMO_CONFIG_DIR/AGENTS.md"

install_mimo() {
  echo ""
  echo "MiMo Code → $MIMO_SKILLS_DIR/"
  if [[ ! -d "$MIMO_RENDERED" ]]; then
    echo "  WARNING: $MIMO_RENDERED not found — run sync-skills.sh first"
    return
  fi
  local count=0
  for skill_dir in "$MIMO_RENDERED"/*/; do
    [[ -f "${skill_dir}SKILL.md" ]] || continue
    local name; name="$(basename "$skill_dir")"
    link "$skill_dir" "$MIMO_SKILLS_DIR/$name"
    count=$((count + 1))
  done
  echo "  $count skills installed"

  echo "MiMo Code → context symlink $MIMO_AGENTS"
  source "$REPO_ROOT/scripts/lib/context-wire.sh"
  local mimo_agents_src="$REPO_ROOT/AGENTS.md"
  [[ -f "$mimo_agents_src" ]] || mimo_agents_src="$REPO_ROOT/docs/templates/AGENTS.md"
  wire_context_mode symlink "$MIMO_AGENTS" "" read "$mimo_agents_src"
}

uninstall_mimo() {
  echo ""
  echo "MiMo Code → removing management from $MIMO_CONFIG_DIR/"
  if [[ -d "$MIMO_SKILLS_DIR" ]]; then
    for dst in "$MIMO_SKILLS_DIR"/*/; do
      [[ -L "${dst%/}" ]] || continue
      unlink_if_managed "${dst%/}" "$REPO_ROOT/"
    done
  fi
  unlink_if_managed "$MIMO_AGENTS" "$REPO_ROOT/"
}

# ── Antigravity CLI / agy (e74s02) ────────────────────────────────────────────
# Global skills: ~/.gemini/antigravity-cli/skills/ (separate from e64 Gemini extension)

AGY_CONFIG_DIR="$HOME/.gemini/antigravity-cli"
AGY_SKILLS_DIR="$AGY_CONFIG_DIR/skills"
AGY_RENDERED="$REPO_ROOT/.agents/skills"

install_agy() {
  echo ""
  echo "Antigravity CLI → $AGY_SKILLS_DIR/"
  if [[ ! -d "$AGY_RENDERED" ]]; then
    echo "  WARNING: $AGY_RENDERED not found — run sync-skills.sh first"
    return
  fi
  local count=0
  for skill_dir in "$AGY_RENDERED"/*/; do
    [[ -f "${skill_dir}SKILL.md" ]] || continue
    local name; name="$(basename "$skill_dir")"
    link "$skill_dir" "$AGY_SKILLS_DIR/$name"
    count=$((count + 1))
  done
  echo "  $count skills installed"
  echo "  NOTE: Antigravity uses ~/.gemini/antigravity-cli/skills/ — not .gemini/extensions/ (Gemini CLI)"
}

install_antigravity() {
  install_agy
}

uninstall_agy() {
  echo ""
  echo "Antigravity CLI → removing management from $AGY_CONFIG_DIR/"
  if [[ -d "$AGY_SKILLS_DIR" ]]; then
    for dst in "$AGY_SKILLS_DIR"/*/; do
      [[ -L "${dst%/}" ]] || continue
      unlink_if_managed "${dst%/}" "$REPO_ROOT/"
    done
  fi
}

uninstall_antigravity() {
  uninstall_agy
}

# ── Codex CLI (e37s15) ───────────────────────────────────────────────────────

CODEX_DIR="$HOME/.codex"
CODEX_AGENTS="$CODEX_DIR/AGENTS.md"
CODEX_TEMPLATE="$REPO_ROOT/templates/codex/AGENTS.md"

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
  uninstall_hermes
  uninstall_zcode
  uninstall_mimo
  uninstall_agy
  uninstall_cursor
  uninstall_codex
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
  echo ""
  echo "bigpowers installed. Future updates:"
  if [[ -d "$REPO_ROOT/.git" ]]; then
    echo "  git pull && ./scripts/sync-skills.sh"
  else
    echo "  npm update -g bigpowers && bigpowers update"
  fi
fi
