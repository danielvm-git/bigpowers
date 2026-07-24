"""Generate install.sh blocks for Wave B hub wiring."""
from __future__ import annotations

from wave_b_hub_config import prefix

def install_sh_block(cfg: dict) -> str:
    p = prefix(cfg)
    fn = cfg["fn"]
    label = cfg["label"]
    story = cfg["story"]
    home = cfg["home"]
    sub = cfg["skills_sub"]
    rendered = cfg["rendered"]
    kind = cfg["kind"]
    ctx = cfg.get("context", {})
    hooks = cfg.get("hooks")

    lines = [
        f"# ── {label} ({story}) ───────────────────────────────────────────────────────",
        "",
        f'{p}_CONFIG_DIR="$HOME/{home}"',
        f'{p}_SKILLS_DIR="${p}_CONFIG_DIR/{sub}"',
        f'{p}_RENDERED="$REPO_ROOT/{rendered}"',
    ]

    if ctx.get("mode") == "config-bridge":
        lines.append(f'{p}_CONFIG_FILE="${p}_CONFIG_DIR/{ctx["bridge"]}"')
    elif ctx.get("mode") in ("symlink", "copy"):
        lines.append(f'{p}_CONTEXT="${p}_CONFIG_DIR/{ctx["file"]}"')

    if hooks is True:
        lines.append(f'{p}_HOOKS_DIR="${p}_CONFIG_DIR/hooks"')
        lines.append(f'{p}_HOOK_SRC="$REPO_ROOT/scripts/hooks/{fn}/pre-tool-git-guard.sh"')

    lines.extend(["", f"install_{fn}() {{", "  echo \"\"", f'  echo "{label} → ${p}_SKILLS_DIR/"'])

    if kind == "skill_dir":
        lines.extend([
            f'  if [[ ! -d "${p}_RENDERED" ]]; then',
            f'    echo "  WARNING: ${p}_RENDERED not found — run sync-skills.sh first"',
            "    return",
            "  fi",
            "  local count=0",
            f'  for skill_dir in "${p}_RENDERED"/*/; do',
            '    [[ -f "${skill_dir}SKILL.md" ]] || continue',
            '    local name; name="$(basename "$skill_dir")"',
            f'    link "$skill_dir" "${p}_SKILLS_DIR/$name"',
            "    count=$((count + 1))",
            "  done",
            '  echo "  $count skills installed"',
        ])
    else:
        lines.extend([
            f'  if [[ ! -d "${p}_RENDERED" ]]; then',
            f'    echo "  WARNING: ${p}_RENDERED not found — run sync-skills.sh first"',
            "    return",
            "  fi",
            "  local count=0",
            f'  for rule in "${p}_RENDERED"/*.md; do',
            '    [[ -f "$rule" ]] || continue',
            f'    link "$rule" "${p}_SKILLS_DIR/$(basename "$rule")"',
            "    count=$((count + 1))",
            "  done",
            f'  echo "  $count rules installed"',
        ])

    mode = ctx.get("mode")
    if mode and mode != "native":
        ctx_target = f"${p}_CONFIG_FILE" if mode == "config-bridge" else f"${p}_CONTEXT"
        lines.extend([
            f'  echo "{label} → context {mode} {ctx_target}"',
            '  source "$REPO_ROOT/scripts/lib/context-wire.sh"',
            '  local agents_src="$REPO_ROOT/AGENTS.md"',
            '  [[ -f "$agents_src" ]] || agents_src="$REPO_ROOT/docs/templates/AGENTS.md"',
        ])
        if mode == "config-bridge":
            lines.append(
                f'  wire_context_mode config-bridge "${p}_CONFIG_FILE" "{ctx["key"]}" "{ctx["wire"]}"'
            )
        elif mode == "symlink":
            lines.append(f'  wire_context_mode symlink "${p}_CONTEXT" "" read "$agents_src"')
        elif mode == "copy":
            lines.append(f'  run mkdir -p "$(dirname "${p}_CONTEXT")"')
            lines.append(f'  run cp "$agents_src" "${p}_CONTEXT"')

    if hooks is True:
        lines.extend([
            f'  if [[ -f "${p}_HOOK_SRC" ]]; then',
            f'    echo "{label} Hooks → ${p}_HOOKS_DIR/"',
            f'    link "${p}_HOOK_SRC" "${p}_HOOKS_DIR/pre-tool-git-guard.sh"',
            f'    chmod +x "${p}_HOOK_SRC" 2>/dev/null || true',
            f'    echo "  NOTE: copy $REPO_ROOT/scripts/hooks/{fn}/settings.example.json into tool config"',
            "  fi",
        ])
    elif hooks == "plugin":
        lines.extend([
            f'  if [[ -d "$REPO_ROOT/scripts/hooks/{fn}/plugin" ]]; then',
            f'    echo "{label} → hook plugin template at scripts/hooks/{fn}/plugin/ (manual install)"',
            "  fi",
        ])

    lines.extend(["}", ""])

    lines.append(f"uninstall_{fn}() {{")
    lines.append('  echo ""')
    lines.append(f'  echo "{label} → removing management from ${p}_CONFIG_DIR/"')
    if kind == "skill_dir":
        lines.extend([
            f'  if [[ -d "${p}_SKILLS_DIR" ]]; then',
            f'    for dst in "${p}_SKILLS_DIR"/*/; do',
            '      [[ -L "${dst%/}" ]] || continue',
            '      unlink_if_managed "${dst%/}" "$REPO_ROOT/"',
            "    done",
            "  fi",
        ])
    else:
        lines.extend([
            f'  if [[ -d "${p}_SKILLS_DIR" ]]; then',
            f'    for dst in "${p}_SKILLS_DIR"/*.md; do',
            '      [[ -L "$dst" ]] || continue',
            '      unlink_if_managed "$dst" "$REPO_ROOT/"',
            "    done",
            "  fi",
        ])
    if ctx.get("mode") in ("symlink", "copy"):
        lines.append(f'  unlink_if_managed "${p}_CONTEXT" "$REPO_ROOT/"')
    if ctx.get("mode") == "config-bridge":
        lines.append(f'  # config-bridge file ${p}_CONFIG_FILE left for user')
    if hooks is True:
        lines.append(f'  unlink_if_managed "${p}_HOOKS_DIR/pre-tool-git-guard.sh" "$REPO_ROOT/"')
    lines.extend(["}", ""])
    return "\n".join(lines)


