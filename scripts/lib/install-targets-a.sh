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

