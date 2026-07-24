# ── Trae (e70s02) ───────────────────────────────────────────────────────

TRAE_CONFIG_DIR="$HOME/.trae"
TRAE_SKILLS_DIR="$TRAE_CONFIG_DIR/skills"
TRAE_RENDERED="$REPO_ROOT/.trae/skills"
TRAE_CONTEXT="$TRAE_CONFIG_DIR/AGENTS.md"
TRAE_HOOKS_DIR="$TRAE_CONFIG_DIR/hooks"
TRAE_HOOK_SRC="$REPO_ROOT/scripts/hooks/trae/pre-tool-git-guard.sh"

install_trae() {
  echo ""
  echo "Trae → $TRAE_SKILLS_DIR/"
  if [[ ! -d "$TRAE_RENDERED" ]]; then
    echo "  WARNING: $TRAE_RENDERED not found — run sync-skills.sh first"
    return
  fi
  local count=0
  for skill_dir in "$TRAE_RENDERED"/*/; do
    [[ -f "${skill_dir}SKILL.md" ]] || continue
    local name; name="$(basename "$skill_dir")"
    link "$skill_dir" "$TRAE_SKILLS_DIR/$name"
    count=$((count + 1))
  done
  echo "  $count skills installed"
  echo "Trae → context symlink $TRAE_CONTEXT"
  source "$REPO_ROOT/scripts/lib/context-wire.sh"
  local agents_src="$REPO_ROOT/AGENTS.md"
  [[ -f "$agents_src" ]] || agents_src="$REPO_ROOT/docs/templates/AGENTS.md"
  wire_context_mode symlink "$TRAE_CONTEXT" "" read "$agents_src"
  if [[ -f "$TRAE_HOOK_SRC" ]]; then
    echo "Trae Hooks → $TRAE_HOOKS_DIR/"
    link "$TRAE_HOOK_SRC" "$TRAE_HOOKS_DIR/pre-tool-git-guard.sh"
    chmod +x "$TRAE_HOOK_SRC" 2>/dev/null || true
    echo "  NOTE: copy $REPO_ROOT/scripts/hooks/trae/settings.example.json into tool config"
  fi
}

uninstall_trae() {
  echo ""
  echo "Trae → removing management from $TRAE_CONFIG_DIR/"
  if [[ -d "$TRAE_SKILLS_DIR" ]]; then
    for dst in "$TRAE_SKILLS_DIR"/*/; do
      [[ -L "${dst%/}" ]] || continue
      unlink_if_managed "${dst%/}" "$REPO_ROOT/"
    done
  fi
  unlink_if_managed "$TRAE_CONTEXT" "$REPO_ROOT/"
  unlink_if_managed "$TRAE_HOOKS_DIR/pre-tool-git-guard.sh" "$REPO_ROOT/"
}
# ── Windsurf (e73s02) ───────────────────────────────────────────────────────

WINDSURF_CONFIG_DIR="$HOME/.codeium/windsurf"
WINDSURF_SKILLS_DIR="$WINDSURF_CONFIG_DIR/rules"
WINDSURF_RENDERED="$REPO_ROOT/.windsurf/rules"
WINDSURF_CONTEXT="$WINDSURF_CONFIG_DIR/AGENTS.md"
WINDSURF_HOOKS_DIR="$WINDSURF_CONFIG_DIR/hooks"
WINDSURF_HOOK_SRC="$REPO_ROOT/scripts/hooks/windsurf/pre-tool-git-guard.sh"

install_windsurf() {
  echo ""
  echo "Windsurf → $WINDSURF_SKILLS_DIR/"
  if [[ ! -d "$WINDSURF_RENDERED" ]]; then
    echo "  WARNING: $WINDSURF_RENDERED not found — run sync-skills.sh first"
    return
  fi
  local count=0
  for rule in "$WINDSURF_RENDERED"/*.md; do
    [[ -f "$rule" ]] || continue
    link "$rule" "$WINDSURF_SKILLS_DIR/$(basename "$rule")"
    count=$((count + 1))
  done
  echo "  $count rules installed"
  echo "Windsurf → context copy $WINDSURF_CONTEXT"
  source "$REPO_ROOT/scripts/lib/context-wire.sh"
  local agents_src="$REPO_ROOT/AGENTS.md"
  [[ -f "$agents_src" ]] || agents_src="$REPO_ROOT/docs/templates/AGENTS.md"
  run mkdir -p "$(dirname "$WINDSURF_CONTEXT")"
  run cp "$agents_src" "$WINDSURF_CONTEXT"
  if [[ -f "$WINDSURF_HOOK_SRC" ]]; then
    echo "Windsurf Hooks → $WINDSURF_HOOKS_DIR/"
    link "$WINDSURF_HOOK_SRC" "$WINDSURF_HOOKS_DIR/pre-tool-git-guard.sh"
    chmod +x "$WINDSURF_HOOK_SRC" 2>/dev/null || true
    echo "  NOTE: copy $REPO_ROOT/scripts/hooks/windsurf/settings.example.json into tool config"
  fi
}

uninstall_windsurf() {
  echo ""
  echo "Windsurf → removing management from $WINDSURF_CONFIG_DIR/"
  if [[ -d "$WINDSURF_SKILLS_DIR" ]]; then
    for dst in "$WINDSURF_SKILLS_DIR"/*.md; do
      [[ -L "$dst" ]] || continue
      unlink_if_managed "$dst" "$REPO_ROOT/"
    done
  fi
  unlink_if_managed "$WINDSURF_CONTEXT" "$REPO_ROOT/"
  unlink_if_managed "$WINDSURF_HOOKS_DIR/pre-tool-git-guard.sh" "$REPO_ROOT/"
}
# ── OpenCode (e62s02) ───────────────────────────────────────────────────────

OPENCODE_CONFIG_DIR="$HOME/.config/opencode"
OPENCODE_SKILLS_DIR="$OPENCODE_CONFIG_DIR/skills"
OPENCODE_RENDERED="$REPO_ROOT/.opencode/skills"
OPENCODE_CONTEXT="$OPENCODE_CONFIG_DIR/AGENTS.md"

install_opencode() {
  echo ""
  echo "OpenCode → $OPENCODE_SKILLS_DIR/"
  if [[ ! -d "$OPENCODE_RENDERED" ]]; then
    echo "  WARNING: $OPENCODE_RENDERED not found — run sync-skills.sh first"
    return
  fi
  local count=0
  for skill_dir in "$OPENCODE_RENDERED"/*/; do
    [[ -f "${skill_dir}SKILL.md" ]] || continue
    local name; name="$(basename "$skill_dir")"
    link "$skill_dir" "$OPENCODE_SKILLS_DIR/$name"
    count=$((count + 1))
  done
  echo "  $count skills installed"
  echo "OpenCode → context symlink $OPENCODE_CONTEXT"
  source "$REPO_ROOT/scripts/lib/context-wire.sh"
  local agents_src="$REPO_ROOT/AGENTS.md"
  [[ -f "$agents_src" ]] || agents_src="$REPO_ROOT/docs/templates/AGENTS.md"
  wire_context_mode symlink "$OPENCODE_CONTEXT" "" read "$agents_src"
}

uninstall_opencode() {
  echo ""
  echo "OpenCode → removing management from $OPENCODE_CONFIG_DIR/"
  if [[ -d "$OPENCODE_SKILLS_DIR" ]]; then
    for dst in "$OPENCODE_SKILLS_DIR"/*/; do
      [[ -L "${dst%/}" ]] || continue
      unlink_if_managed "${dst%/}" "$REPO_ROOT/"
    done
  fi
  unlink_if_managed "$OPENCODE_CONTEXT" "$REPO_ROOT/"
}
# ── Copilot CLI (e71s02) ───────────────────────────────────────────────────────

COPILOT_CONFIG_DIR="$HOME/.copilot"
COPILOT_SKILLS_DIR="$COPILOT_CONFIG_DIR/skills"
COPILOT_RENDERED="$REPO_ROOT/.copilot/skills"
COPILOT_CONTEXT="$COPILOT_CONFIG_DIR/AGENTS.md"

install_copilot() {
  echo ""
  echo "Copilot CLI → $COPILOT_SKILLS_DIR/"
  if [[ ! -d "$COPILOT_RENDERED" ]]; then
    echo "  WARNING: $COPILOT_RENDERED not found — run sync-skills.sh first"
    return
  fi
  local count=0
  for skill_dir in "$COPILOT_RENDERED"/*/; do
    [[ -f "${skill_dir}SKILL.md" ]] || continue
    local name; name="$(basename "$skill_dir")"
    link "$skill_dir" "$COPILOT_SKILLS_DIR/$name"
    count=$((count + 1))
  done
  echo "  $count skills installed"
  echo "Copilot CLI → context copy $COPILOT_CONTEXT"
  source "$REPO_ROOT/scripts/lib/context-wire.sh"
  local agents_src="$REPO_ROOT/AGENTS.md"
  [[ -f "$agents_src" ]] || agents_src="$REPO_ROOT/docs/templates/AGENTS.md"
  run mkdir -p "$(dirname "$COPILOT_CONTEXT")"
  run cp "$agents_src" "$COPILOT_CONTEXT"
}

uninstall_copilot() {
  echo ""
  echo "Copilot CLI → removing management from $COPILOT_CONFIG_DIR/"
  if [[ -d "$COPILOT_SKILLS_DIR" ]]; then
    for dst in "$COPILOT_SKILLS_DIR"/*/; do
      [[ -L "${dst%/}" ]] || continue
      unlink_if_managed "${dst%/}" "$REPO_ROOT/"
    done
  fi
  unlink_if_managed "$COPILOT_CONTEXT" "$REPO_ROOT/"
}
