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

# ── Codex CLI (e65s02) ───────────────────────────────────────────────────────

CODEX_CONFIG_DIR="$HOME/.codex"
CODEX_SKILLS_DIR="$CODEX_CONFIG_DIR/skills"
CODEX_RENDERED="$REPO_ROOT/.codex/skills"
CODEX_CONFIG_FILE="$CODEX_CONFIG_DIR/config.toml"
CODEX_HOOKS_DIR="$CODEX_CONFIG_DIR/hooks"
CODEX_HOOK_SRC="$REPO_ROOT/scripts/hooks/codex/pre-tool-git-guard.sh"

install_codex() {
  echo ""
  echo "Codex CLI → $CODEX_SKILLS_DIR/"
  if [[ ! -d "$CODEX_RENDERED" ]]; then
    echo "  WARNING: $CODEX_RENDERED not found — run sync-skills.sh first"
    return
  fi
  local count=0
  for skill_dir in "$CODEX_RENDERED"/*/; do
    [[ -f "${skill_dir}SKILL.md" ]] || continue
    local name; name="$(basename "$skill_dir")"
    link "$skill_dir" "$CODEX_SKILLS_DIR/$name"
    count=$((count + 1))
  done
  echo "  $count skills installed"
  echo "Codex CLI → context config-bridge $CODEX_CONFIG_FILE"
  source "$REPO_ROOT/scripts/lib/context-wire.sh"
  local agents_src="$REPO_ROOT/AGENTS.md"
  [[ -f "$agents_src" ]] || agents_src="$REPO_ROOT/docs/templates/AGENTS.md"
  wire_context_mode config-bridge "$CODEX_CONFIG_FILE" "instructions" "AGENTS.md"
  if [[ -f "$CODEX_HOOK_SRC" ]]; then
    echo "Codex CLI Hooks → $CODEX_HOOKS_DIR/"
    link "$CODEX_HOOK_SRC" "$CODEX_HOOKS_DIR/pre-tool-git-guard.sh"
    chmod +x "$CODEX_HOOK_SRC" 2>/dev/null || true
    echo "  NOTE: copy $REPO_ROOT/scripts/hooks/codex/settings.example.json into tool config"
  fi
}

uninstall_codex() {
  echo ""
  echo "Codex CLI → removing management from $CODEX_CONFIG_DIR/"
  if [[ -d "$CODEX_SKILLS_DIR" ]]; then
    for dst in "$CODEX_SKILLS_DIR"/*/; do
      [[ -L "${dst%/}" ]] || continue
      unlink_if_managed "${dst%/}" "$REPO_ROOT/"
    done
  fi
  # config-bridge file $CODEX_CONFIG_FILE left for user
  unlink_if_managed "$CODEX_HOOKS_DIR/pre-tool-git-guard.sh" "$REPO_ROOT/"
}
# ── Qwen Code (e68s02) ───────────────────────────────────────────────────────

QWEN_CONFIG_DIR="$HOME/.qwen"
QWEN_SKILLS_DIR="$QWEN_CONFIG_DIR/skills"
QWEN_RENDERED="$REPO_ROOT/.qwen/skills"
QWEN_CONTEXT="$QWEN_CONFIG_DIR/QWEN.md"
QWEN_HOOKS_DIR="$QWEN_CONFIG_DIR/hooks"
QWEN_HOOK_SRC="$REPO_ROOT/scripts/hooks/qwen/pre-tool-git-guard.sh"

install_qwen() {
  echo ""
  echo "Qwen Code → $QWEN_SKILLS_DIR/"
  if [[ ! -d "$QWEN_RENDERED" ]]; then
    echo "  WARNING: $QWEN_RENDERED not found — run sync-skills.sh first"
    return
  fi
  local count=0
  for skill_dir in "$QWEN_RENDERED"/*/; do
    [[ -f "${skill_dir}SKILL.md" ]] || continue
    local name; name="$(basename "$skill_dir")"
    link "$skill_dir" "$QWEN_SKILLS_DIR/$name"
    count=$((count + 1))
  done
  echo "  $count skills installed"
  echo "Qwen Code → context symlink $QWEN_CONTEXT"
  source "$REPO_ROOT/scripts/lib/context-wire.sh"
  local agents_src="$REPO_ROOT/AGENTS.md"
  [[ -f "$agents_src" ]] || agents_src="$REPO_ROOT/docs/templates/AGENTS.md"
  wire_context_mode symlink "$QWEN_CONTEXT" "" read "$agents_src"
  if [[ -f "$QWEN_HOOK_SRC" ]]; then
    echo "Qwen Code Hooks → $QWEN_HOOKS_DIR/"
    link "$QWEN_HOOK_SRC" "$QWEN_HOOKS_DIR/pre-tool-git-guard.sh"
    chmod +x "$QWEN_HOOK_SRC" 2>/dev/null || true
    echo "  NOTE: copy $REPO_ROOT/scripts/hooks/qwen/settings.example.json into tool config"
  fi
}

uninstall_qwen() {
  echo ""
  echo "Qwen Code → removing management from $QWEN_CONFIG_DIR/"
  if [[ -d "$QWEN_SKILLS_DIR" ]]; then
    for dst in "$QWEN_SKILLS_DIR"/*/; do
      [[ -L "${dst%/}" ]] || continue
      unlink_if_managed "${dst%/}" "$REPO_ROOT/"
    done
  fi
  unlink_if_managed "$QWEN_CONTEXT" "$REPO_ROOT/"
  unlink_if_managed "$QWEN_HOOKS_DIR/pre-tool-git-guard.sh" "$REPO_ROOT/"
}
