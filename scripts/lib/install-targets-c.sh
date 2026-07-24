# ── CodeBuddy (e72s02) ───────────────────────────────────────────────────────

CODEBUDDY_CONFIG_DIR="$HOME/.codebuddy"
CODEBUDDY_SKILLS_DIR="$CODEBUDDY_CONFIG_DIR/skills"
CODEBUDDY_RENDERED="$REPO_ROOT/.codebuddy/skills"
CODEBUDDY_CONTEXT="$CODEBUDDY_CONFIG_DIR/AGENTS.md"
CODEBUDDY_HOOKS_DIR="$CODEBUDDY_CONFIG_DIR/hooks"
CODEBUDDY_HOOK_SRC="$REPO_ROOT/scripts/hooks/codebuddy/pre-tool-git-guard.sh"

install_codebuddy() {
  echo ""
  echo "CodeBuddy → $CODEBUDDY_SKILLS_DIR/"
  if [[ ! -d "$CODEBUDDY_RENDERED" ]]; then
    echo "  WARNING: $CODEBUDDY_RENDERED not found — run sync-skills.sh first"
    return
  fi
  local count=0
  for skill_dir in "$CODEBUDDY_RENDERED"/*/; do
    [[ -f "${skill_dir}SKILL.md" ]] || continue
    local name; name="$(basename "$skill_dir")"
    link "$skill_dir" "$CODEBUDDY_SKILLS_DIR/$name"
    count=$((count + 1))
  done
  echo "  $count skills installed"
  echo "CodeBuddy → context symlink $CODEBUDDY_CONTEXT"
  source "$REPO_ROOT/scripts/lib/context-wire.sh"
  local agents_src="$REPO_ROOT/AGENTS.md"
  [[ -f "$agents_src" ]] || agents_src="$REPO_ROOT/docs/templates/AGENTS.md"
  wire_context_mode symlink "$CODEBUDDY_CONTEXT" "" read "$agents_src"
  if [[ -f "$CODEBUDDY_HOOK_SRC" ]]; then
    echo "CodeBuddy Hooks → $CODEBUDDY_HOOKS_DIR/"
    link "$CODEBUDDY_HOOK_SRC" "$CODEBUDDY_HOOKS_DIR/pre-tool-git-guard.sh"
    chmod +x "$CODEBUDDY_HOOK_SRC" 2>/dev/null || true
    echo "  NOTE: copy $REPO_ROOT/scripts/hooks/codebuddy/settings.example.json into tool config"
  fi
}

uninstall_codebuddy() {
  echo ""
  echo "CodeBuddy → removing management from $CODEBUDDY_CONFIG_DIR/"
  if [[ -d "$CODEBUDDY_SKILLS_DIR" ]]; then
    for dst in "$CODEBUDDY_SKILLS_DIR"/*/; do
      [[ -L "${dst%/}" ]] || continue
      unlink_if_managed "${dst%/}" "$REPO_ROOT/"
    done
  fi
  unlink_if_managed "$CODEBUDDY_CONTEXT" "$REPO_ROOT/"
  unlink_if_managed "$CODEBUDDY_HOOKS_DIR/pre-tool-git-guard.sh" "$REPO_ROOT/"
}
# ── Cline (e66s02) ───────────────────────────────────────────────────────

CLINE_CONFIG_DIR="$HOME/.cline"
CLINE_SKILLS_DIR="$CLINE_CONFIG_DIR/skills"
CLINE_RENDERED="$REPO_ROOT/.cline/skills"

install_cline() {
  echo ""
  echo "Cline → $CLINE_SKILLS_DIR/"
  if [[ ! -d "$CLINE_RENDERED" ]]; then
    echo "  WARNING: $CLINE_RENDERED not found — run sync-skills.sh first"
    return
  fi
  local count=0
  for skill_dir in "$CLINE_RENDERED"/*/; do
    [[ -f "${skill_dir}SKILL.md" ]] || continue
    local name; name="$(basename "$skill_dir")"
    link "$skill_dir" "$CLINE_SKILLS_DIR/$name"
    count=$((count + 1))
  done
  echo "  $count skills installed"
  if [[ -d "$REPO_ROOT/scripts/hooks/cline/plugin" ]]; then
    echo "Cline → hook plugin template at scripts/hooks/cline/plugin/ (manual install)"
  fi
}

uninstall_cline() {
  echo ""
  echo "Cline → removing management from $CLINE_CONFIG_DIR/"
  if [[ -d "$CLINE_SKILLS_DIR" ]]; then
    for dst in "$CLINE_SKILLS_DIR"/*/; do
      [[ -L "${dst%/}" ]] || continue
      unlink_if_managed "${dst%/}" "$REPO_ROOT/"
    done
  fi
}
# ── Kilo (e67s02) ───────────────────────────────────────────────────────

KILOCODE_CONFIG_DIR="$HOME/.kilocode"
KILOCODE_SKILLS_DIR="$KILOCODE_CONFIG_DIR/rules"
KILOCODE_RENDERED="$REPO_ROOT/.kilocode/rules"
KILOCODE_CONTEXT="$KILOCODE_CONFIG_DIR/AGENTS.md"

install_kilocode() {
  echo ""
  echo "Kilo → $KILOCODE_SKILLS_DIR/"
  if [[ ! -d "$KILOCODE_RENDERED" ]]; then
    echo "  WARNING: $KILOCODE_RENDERED not found — run sync-skills.sh first"
    return
  fi
  local count=0
  for rule in "$KILOCODE_RENDERED"/*.md; do
    [[ -f "$rule" ]] || continue
    link "$rule" "$KILOCODE_SKILLS_DIR/$(basename "$rule")"
    count=$((count + 1))
  done
  echo "  $count rules installed"
  echo "Kilo → context copy $KILOCODE_CONTEXT"
  source "$REPO_ROOT/scripts/lib/context-wire.sh"
  local agents_src="$REPO_ROOT/AGENTS.md"
  [[ -f "$agents_src" ]] || agents_src="$REPO_ROOT/docs/templates/AGENTS.md"
  run mkdir -p "$(dirname "$KILOCODE_CONTEXT")"
  run cp "$agents_src" "$KILOCODE_CONTEXT"
  if [[ -d "$REPO_ROOT/scripts/hooks/kilocode/plugin" ]]; then
    echo "Kilo → hook plugin template at scripts/hooks/kilocode/plugin/ (manual install)"
  fi
}

uninstall_kilocode() {
  echo ""
  echo "Kilo → removing management from $KILOCODE_CONFIG_DIR/"
  if [[ -d "$KILOCODE_SKILLS_DIR" ]]; then
    for dst in "$KILOCODE_SKILLS_DIR"/*.md; do
      [[ -L "$dst" ]] || continue
      unlink_if_managed "$dst" "$REPO_ROOT/"
    done
  fi
  unlink_if_managed "$KILOCODE_CONTEXT" "$REPO_ROOT/"
}
