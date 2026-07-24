#!/usr/bin/env python3
# story: e45s22
"""Apply Wave B install hub wiring for fleet integration epics."""
from __future__ import annotations

import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]

# WSJF order — previous fn is dispatch anchor for next epic
HUB_ORDER = ["e65", "e68", "e72", "e66", "e67", "e70", "e73", "e62", "e71"]

HUB_EPICS: dict[str, dict] = {
    "e65": {
        "story": "e65s02",
        "fn": "codex",
        "setup_id": "codex",
        "label": "Codex CLI",
        "home": ".codex",
        "skills_sub": "skills",
        "rendered": ".codex/skills",
        "kind": "skill_dir",
        "context": {"mode": "config-bridge", "bridge": "config.toml", "key": "instructions", "wire": "AGENTS.md"},
        "hooks": True,
        "manifest": "codex_hooks_manifest",
    },
    "e68": {
        "story": "e68s02",
        "fn": "qwen",
        "setup_id": "qwen",
        "label": "Qwen Code",
        "home": ".qwen",
        "skills_sub": "skills",
        "rendered": ".qwen/skills",
        "kind": "skill_dir",
        "context": {"mode": "symlink", "file": "QWEN.md"},
        "hooks": True,
        "manifest": "qwen_hooks_manifest",
    },
    "e72": {
        "story": "e72s02",
        "fn": "codebuddy",
        "setup_id": "codebuddy",
        "label": "CodeBuddy",
        "home": ".codebuddy",
        "skills_sub": "skills",
        "rendered": ".codebuddy/skills",
        "kind": "skill_dir",
        "context": {"mode": "symlink", "file": "AGENTS.md"},
        "hooks": True,
        "manifest": "codebuddy_hooks_manifest",
    },
    "e66": {
        "story": "e66s02",
        "fn": "cline",
        "setup_id": "cline",
        "label": "Cline",
        "home": ".cline",
        "skills_sub": "skills",
        "rendered": ".cline/skills",
        "kind": "skill_dir",
        "context": {"mode": "native"},
        "hooks": "plugin",
        "manifest": "cline_hooks_manifest",
    },
    "e67": {
        "story": "e67s02",
        "fn": "kilocode",
        "setup_id": "kilo",
        "label": "Kilo",
        "home": ".kilocode",
        "skills_sub": "rules",
        "rendered": ".kilocode/rules",
        "kind": "rules_file",
        "context": {"mode": "copy", "file": "AGENTS.md"},
        "hooks": "plugin",
        "manifest": "kilocode_hooks_manifest",
    },
    "e70": {
        "story": "e70s02",
        "fn": "trae",
        "setup_id": "trae",
        "label": "Trae",
        "home": ".trae",
        "skills_sub": "skills",
        "rendered": ".trae/skills",
        "kind": "skill_dir",
        "context": {"mode": "symlink", "file": "AGENTS.md"},
        "hooks": True,
        "manifest": "trae_hooks_manifest",
    },
    "e73": {
        "story": "e73s02",
        "fn": "windsurf",
        "setup_id": "windsurf",
        "label": "Windsurf",
        "home": ".codeium/windsurf",
        "skills_sub": "rules",
        "rendered": ".windsurf/rules",
        "kind": "rules_file",
        "context": {"mode": "copy", "file": "AGENTS.md"},
        "hooks": True,
        "manifest": "windsurf_hooks_manifest",
    },
    "e62": {
        "story": "e62s02",
        "fn": "opencode",
        "setup_id": "opencode",
        "label": "OpenCode",
        "home": ".config/opencode",
        "skills_sub": "skills",
        "rendered": ".opencode/skills",
        "kind": "skill_dir",
        "context": {"mode": "symlink", "file": "AGENTS.md"},
        "hooks": False,
        "manifest": None,
    },
    "e71": {
        "story": "e71s02",
        "fn": "copilot",
        "setup_id": "copilot",
        "label": "Copilot CLI",
        "home": ".copilot",
        "skills_sub": "skills",
        "rendered": ".copilot/skills",
        "kind": "skill_dir",
        "context": {"mode": "copy", "file": "AGENTS.md"},
        "hooks": False,
        "manifest": None,
    },
}


def prefix(cfg: dict) -> str:
    return cfg["fn"].upper().replace("-", "_")


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
            lines.append(f'  cp "$agents_src" "${p}_CONTEXT"')

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


def helpers_global_case(cfg: dict) -> str:
    fn = cfg["fn"]
    setup_id = cfg["setup_id"]
    home = cfg["home"]
    sub = cfg["skills_sub"]
    rendered = cfg["rendered"]
    kind = cfg["kind"]
    ctx = cfg.get("context", {})
    hooks = cfg.get("hooks")
    story = cfg["story"]

    p = []
    p.append(f"    case '{setup_id}':")
    if setup_id != fn:
        p.append(f"    case '{fn}':")

    if kind == "skill_dir":
        p.append(f"      linkRenderedSkills(path.join(repoRoot, '{rendered}'), path.join(homeDir, '{home}', '{sub}'));")
    else:
        p.append(f"      {{")
        p.append(f"        const renderedDir = path.join(repoRoot, '{rendered}');")
        p.append(f"        const targetDir = path.join(homeDir, '{home}', '{sub}');")
        p.append(f"        fs.mkdirSync(targetDir, {{ recursive: true }});")
        p.append(f"        if (fs.existsSync(renderedDir)) {{")
        p.append(f"          for (const f of fs.readdirSync(renderedDir)) {{")
        p.append(f"            if (!f.endsWith('.md')) continue;")
        p.append(f"            linkFile(path.join(renderedDir, f), path.join(targetDir, f));")
        p.append(f"          }}")
        p.append(f"        }}")
        p.append(f"      }}")

    mode = ctx.get("mode")
    if mode == "config-bridge":
        p.append(f"      bridgeHermesConfig(path.join(homeDir, '{home}', '{ctx['bridge']}'));")
    elif mode == "symlink":
        p.append(f"      {{")
        p.append(f"        const agentsSrc = path.join(repoRoot, 'AGENTS.md');")
        p.append(f"        const agentsDst = path.join(homeDir, '{home}', '{ctx['file']}');")
        p.append(f"        fs.mkdirSync(path.dirname(agentsDst), {{ recursive: true }});")
        p.append(f"        linkFile(agentsSrc, agentsDst);")
        p.append(f"      }}")
    elif mode == "copy":
        p.append(f"      {{")
        p.append(f"        const agentsSrc = path.join(repoRoot, 'AGENTS.md');")
        p.append(f"        const agentsDst = path.join(homeDir, '{home}', '{ctx['file']}');")
        p.append(f"        fs.mkdirSync(path.dirname(agentsDst), {{ recursive: true }});")
        p.append(f"        if (fs.existsSync(agentsSrc)) fs.copyFileSync(agentsSrc, agentsDst);")
        p.append(f"      }}")

    if hooks is True:
        p.append(f"      {{")
        p.append(f"        const hookSrc = path.join(repoRoot, 'scripts', 'hooks', '{fn}', 'pre-tool-git-guard.sh');")
        p.append(f"        const hookDst = path.join(homeDir, '{home}', 'hooks', 'pre-tool-git-guard.sh');")
        p.append(f"        if (fs.existsSync(hookSrc)) {{")
        p.append(f"          fs.mkdirSync(path.dirname(hookDst), {{ recursive: true }});")
        p.append(f"          linkHook(hookSrc, hookDst);")
        p.append(f"        }}")
        p.append(f"      }}")

    p.append(f"      break; // story: {story}")
    return "\n".join(p)


def helpers_local_case(cfg: dict) -> str:
    fn = cfg["fn"]
    setup_id = cfg["setup_id"]
    home = cfg["home"]
    sub = cfg["skills_sub"]
    rendered = cfg["rendered"]
    kind = cfg["kind"]
    ctx = cfg.get("context", {})
    story = cfg["story"]

    # local paths use cwd-relative versions
    local_home = home if not home.startswith(".config") else home.replace(".config/", ".config/")
    p = []
    p.append(f"    case '{setup_id}':")
    if setup_id != fn:
        p.append(f"    case '{fn}':")

    if kind == "skill_dir":
        p.append(f"      linkRenderedSkills(path.join(repoRoot, '{rendered}'), path.join(cwd, '{local_home}', '{sub}'));")
    else:
        p.append(f"      {{")
        p.append(f"        const renderedDir = path.join(repoRoot, '{rendered}');")
        p.append(f"        const targetDir = path.join(cwd, '{local_home}', '{sub}');")
        p.append(f"        fs.mkdirSync(targetDir, {{ recursive: true }});")
        p.append(f"        if (fs.existsSync(renderedDir)) {{")
        p.append(f"          for (const f of fs.readdirSync(renderedDir)) {{")
        p.append(f"            if (!f.endsWith('.md')) continue;")
        p.append(f"            linkFile(path.join(renderedDir, f), path.join(targetDir, f));")
        p.append(f"          }}")
        p.append(f"        }}")
        p.append(f"      }}")

    mode = ctx.get("mode")
    if mode == "config-bridge":
        p.append(f"      bridgeHermesConfig(path.join(cwd, '{local_home}', '{ctx['bridge']}'));")
    elif mode == "symlink":
        p.append(f"      {{")
        p.append(f"        const agentsSrc = path.join(repoRoot, 'AGENTS.md');")
        p.append(f"        const agentsDst = path.join(cwd, '{local_home}', '{ctx['file']}');")
        p.append(f"        fs.mkdirSync(path.dirname(agentsDst), {{ recursive: true }});")
        p.append(f"        linkFile(agentsSrc, agentsDst);")
        p.append(f"      }}")
    elif mode == "copy":
        p.append(f"      {{")
        p.append(f"        const agentsSrc = path.join(repoRoot, 'AGENTS.md');")
        p.append(f"        const agentsDst = path.join(cwd, '{local_home}', '{ctx['file']}');")
        p.append(f"        fs.mkdirSync(path.dirname(agentsDst), {{ recursive: true }});")
        p.append(f"        if (fs.existsSync(agentsSrc)) fs.copyFileSync(agentsSrc, agentsDst);")
        p.append(f"      }}")

    p.append(f"      break; // story: {story}")
    return "\n".join(p)


def helpers_uninstall_case(cfg: dict) -> str:
    fn = cfg["fn"]
    setup_id = cfg["setup_id"]
    home = cfg["home"]
    sub = cfg["skills_sub"]
    kind = cfg["kind"]
    ctx = cfg.get("context", {})
    hooks = cfg.get("hooks")
    story = cfg["story"]

    p = []
    p.append(f"    case '{setup_id}':")
    if setup_id != fn:
        p.append(f"    case '{fn}':")

    if kind == "skill_dir":
        p.append(f"      {{")
        p.append(f"        const skillsDir = path.join(homeDir, '{home}', '{sub}');")
        p.append(f"        if (fs.existsSync(skillsDir)) {{")
        p.append(f"          for (const entry of fs.readdirSync(skillsDir, {{ withFileTypes: true }})) {{")
        p.append(f"            if (!entry.isSymbolicLink()) continue;")
        p.append(f"            removeSymlink(path.join(skillsDir, entry.name));")
        p.append(f"          }}")
        p.append(f"        }}")
        p.append(f"      }}")
    else:
        p.append(f"      {{")
        p.append(f"        const rulesDir = path.join(homeDir, '{home}', '{sub}');")
        p.append(f"        if (fs.existsSync(rulesDir)) {{")
        p.append(f"          for (const f of fs.readdirSync(rulesDir)) {{")
        p.append(f"            removeSymlink(path.join(rulesDir, f));")
        p.append(f"          }}")
        p.append(f"        }}")
        p.append(f"      }}")

    if ctx.get("mode") in ("symlink", "copy"):
        p.append(f"      removeSymlink(path.join(homeDir, '{home}', '{ctx['file']}'));")
    if hooks is True:
        p.append(f"      removeSymlink(path.join(homeDir, '{home}', 'hooks', 'pre-tool-git-guard.sh'));")
    p.append(f"      break; // story: {story}")
    return "\n".join(p)


def test_hub_sh(cfg: dict) -> str:
    fn = cfg["fn"]
    setup_id = cfg["setup_id"]
    label = cfg["label"]
    story = cfg["story"]
    p = prefix(cfg)
    hooks = cfg.get("hooks")
    manifest = cfg.get("manifest")

    hook_checks = ""
    if hooks is True:
        hook_checks = f"""grep -q '{p}_HOOK_SRC=' "$INSTALL_SH" && pass 'install.sh: hook src' || fail 'install.sh: missing hook src'
grep -q 'pre-tool-git-guard.sh' "$INSTALL_SH" && pass 'install.sh: git-guard hook' || fail 'install.sh: missing git-guard hook'
"""
    elif hooks == "plugin":
        hook_checks = f"""grep -q 'scripts/hooks/{fn}/plugin' "$INSTALL_SH" && pass 'install.sh: plugin hook template' || fail 'install.sh: missing plugin template'
"""

    manifest_checks = ""
    if manifest:
        manifest_checks = f"""grep -q 'id: {fn}' "$TARGETS_YAML" && pass 'targets.yaml: {fn} row' || fail 'targets.yaml: missing {fn} row'
grep -q 'adapter: {fn}' "$TARGETS_YAML" && pass 'targets.yaml: {fn} adapter' || fail 'targets.yaml: missing {fn} adapter'
grep -q '{manifest}' "$TARGETS_YAML" && pass 'targets.yaml: {manifest}' || fail 'targets.yaml: missing {manifest}'
grep -q 'install_{fn}()' "$REPO_ROOT/scripts/verify-install.sh" && pass 'verify-install: install_{fn} assertion' || fail 'verify-install: missing install_{fn} assertion'
"""

    return f"""#!/usr/bin/env bash
# story: {story}
# Regression tests for {label} install hub wiring (Wave B).
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${{BASH_SOURCE[0]}}")/.." && pwd)"
PASS=0
FAIL=0

pass() {{ echo "PASS: $1"; PASS=$((PASS + 1)); }}
fail() {{ echo "FAIL: $1" >&2; FAIL=$((FAIL + 1)); }}

echo "=== test-{fn}-hub.sh ==="

INSTALL_SH="$REPO_ROOT/scripts/install.sh"
HELPERS_JS="$REPO_ROOT/scripts/lib/install-helpers.js"
SETUP_JS="$REPO_ROOT/bin/setup.js"
TARGETS_YAML="$REPO_ROOT/scripts/targets.yaml"

grep -q 'install_{fn}()' "$INSTALL_SH" && pass 'install.sh: install_{fn}()' || fail 'install.sh: missing install_{fn}()'
grep -q 'uninstall_{fn}()' "$INSTALL_SH" && pass 'install.sh: uninstall_{fn}()' || fail 'install.sh: missing uninstall_{fn}()'
grep -q '{p}_SKILLS_DIR=' "$INSTALL_SH" && pass 'install.sh: skills dir var' || fail 'install.sh: missing skills dir var'
grep -q 'install_{fn}' "$INSTALL_SH" && grep -q 'uninstall_{fn}' "$INSTALL_SH" && pass 'install.sh: dispatch wired' || fail 'install.sh: dispatch missing {fn}'

DRY_OUT="$(bash "$INSTALL_SH" --dry-run 2>&1)"
grep -q '{label} →' <<< "$DRY_OUT" && pass 'dry-run: {label} section' || fail 'dry-run: missing {label} section'
DRY_UNINSTALL="$(bash "$INSTALL_SH" --dry-run --uninstall 2>&1)"
grep -q '{label} →' <<< "$DRY_UNINSTALL" && pass 'dry-run uninstall: {label} section' || fail 'dry-run uninstall: missing {label} section'

grep -q "case '{setup_id}'" "$HELPERS_JS" && pass 'install-helpers: {setup_id} case' || fail 'install-helpers: missing {setup_id} case'
{hook_checks}
SETUP_SRC="$(cat "$SETUP_JS")"
echo "$SETUP_SRC" | grep -q "SUPPORTED_IDS = new Set" && pass 'setup.js: SUPPORTED_IDS set' || fail 'setup.js: missing SUPPORTED_IDS'
grep -q "'{setup_id}'" <<< "$(sed -n "/SUPPORTED_IDS = new Set/,/);/p" "$SETUP_JS")" && pass 'setup.js: {setup_id} in SUPPORTED_IDS' || fail 'setup.js: {setup_id} not in SUPPORTED_IDS'

{manifest_checks}
bash -n "$INSTALL_SH" && pass 'bash -n install.sh' || fail 'bash -n install.sh'
node --check "$HELPERS_JS" && pass 'node --check install-helpers.js' || fail 'node --check install-helpers.js'
node --check "$SETUP_JS" && pass 'node --check setup.js' || fail 'node --check setup.js'

echo "test-{fn}-hub: $PASS passed, $FAIL failed"
[[ "$FAIL" -eq 0 ]] || exit 1
"""


def targets_row(cfg: dict) -> str:
    fn = cfg["fn"]
    label = cfg["label"]
    rendered = cfg["rendered"]
    ctx = cfg.get("context", {})
    manifest = cfg.get("manifest")
    mode = ctx.get("mode", "native")
    contracts = [f"      - {manifest}"] if manifest else ["      - agents_md_exists"]
    wire_file = ctx.get("file") or ctx.get("wire") or "AGENTS.md"
    skill_block = ""
    if cfg["kind"] == "rules_file":
        skill_block = f"""    skill:
      adapter: {fn}
      output: {rendered}"""
    else:
        skill_block = f"""    skill:
      adapter: {fn}
      output: {rendered}"""
    ctx_mode = mode if mode != "config-bridge" else "config-bridge"
    ctx_extra = ""
    if mode == "config-bridge":
        ctx_extra = f"""
      bridge_file: {ctx['bridge']}
      bridge_key: {ctx['key']}"""
    return f"""  - id: {fn}
    name: {label}
    tier: opt_in
{skill_block}
    context:
      adapter: {fn}
      mode: {ctx_mode}
      file: {wire_file}{ctx_extra}
    contracts:
{chr(10).join(contracts)}
"""


def patch_install_sh(cfg: dict, content: str) -> str:
    fn = cfg["fn"]
    block = install_sh_block(cfg)
    # Remove existing section if present
    pattern = rf"# ── .*? \({cfg['story']}\).*?(?=# ── |# ── main)"
    old_pattern = rf"# ── {re.escape(cfg['label'])}.*?(?=# ── |# ── main)"
    codex_old = r"# ── Codex CLI \(e37s15\).*?(?=# ── main)"
    for pat in [pattern, old_pattern, codex_old if fn == "codex" else r"(?!x)x"]:
        content = re.sub(pat, "", content, flags=re.DOTALL)

    marker = "# ── main ──────────────────────────────────────────────────────────────────────"
    if marker not in content:
        raise SystemExit("install.sh: main marker not found")
    content = content.replace(marker, block + marker)

    # Ensure dispatch — chain after previous epic in WSJF order (or cursor for e65)
    main_part = content.split(marker, 1)[1]
    fn_inst = f"install_{fn}"
    fn_uninst = f"uninstall_{fn}"
    epic_idx = HUB_ORDER.index(cfg.get("_epic_id", "e65"))
    anchor_fn = "cursor" if epic_idx == 0 else HUB_EPICS[HUB_ORDER[epic_idx - 1]]["fn"]
    if f"  {fn_inst}\n" not in main_part:
        content = re.sub(
            rf"(  install_{anchor_fn}\n)",
            rf"\1  {fn_inst}\n",
            content,
            count=1,
        )
    if f"  {fn_uninst}\n" not in main_part:
        content = re.sub(
            rf"(  uninstall_{anchor_fn}\n)",
            rf"\1  {fn_uninst}\n",
            content,
            count=1,
        )

    if f"# story: {cfg['story']}" not in content.split("\n")[0:5]:
        content = content.replace(
            "# story: e74s02",
            f"# story: e74s02\n# story: {cfg['story']}",
            1,
        )
    return content


def patch_setup_js(cfg: dict, content: str) -> str:
    sid = cfg["setup_id"]
    m = re.search(r"const SUPPORTED_IDS = new Set\(\[(.*?)\]\);", content, re.DOTALL)
    if not m:
        raise SystemExit("setup.js: SUPPORTED_IDS not found")
    if f"'{sid}'" in m.group(1):
        return content
    content = re.sub(
        r"(const SUPPORTED_IDS = new Set\(\[[^\]]+)\]\);",
        rf"\1, '{sid}']);",
        content,
        count=1,
    )
    if f"// story: {cfg['story']}" not in content:
        content = content.replace(
            "// story: e74s02",
            f"// story: e74s02\n// story: {cfg['story']}",
            1,
        )
    return content


def insert_case_in_function(content: str, func_name: str, anchor_case: str, new_case: str) -> str:
    sid = new_case.split("'")[1]
    if f"case '{sid}'" in content:
        return content
    func_match = re.search(rf"function {func_name}\([^)]*\) \{{", content)
    if not func_match:
        raise SystemExit(f"function not found: {func_name}")
    start = func_match.start()
    # find matching closing brace for function (naive: next function or uninstall section)
    rest = content[start:]
    next_func = re.search(r"\nfunction \w+\(", rest[1:])
    end = start + (next_func.start() + 1 if next_func else len(rest))
    section = content[start:end]
    if f"case '{sid}'" in section:
        return content
    idx = section.find(anchor_case)
    if idx == -1:
        raise SystemExit(f"anchor {anchor_case} not found in {func_name}")
    new_section = section[:idx] + new_case + "\n" + section[idx:]
    return content[:start] + new_section + content[end:]


def patch_helpers(cfg: dict, content: str) -> str:
    story = cfg["story"]
    if f"story: {story}" in content:
        return content
    g = helpers_global_case(cfg)
    content = insert_case_in_function(content, "installGlobal", "    case 'cursor':", g)
    l = helpers_local_case(cfg)
    content = insert_case_in_function(content, "installLocal", "    case 'cursor':", l)
    u = helpers_uninstall_case(cfg)
    if cfg["fn"] == "codex":
        old = """    case 'codex':
      removeSymlink(path.join(homeDir, '.codex', 'AGENTS.md'));
      break;"""
        if old in content:
            content = content.replace(old, u)
        else:
            content = insert_case_in_function(content, "uninstallTool", "    case 'cursor':", u)
    else:
        content = insert_case_in_function(content, "uninstallTool", "    case 'cursor':", u)
    if f"// story: {story}" not in content.split("\n")[0:10]:
        content = content.replace(
            "// story: e74s02",
            f"// story: e74s02\n// story: {story}",
            1,
        )
    return content


def patch_verify_install(cfg: dict, content: str) -> str:
    fn = cfg["fn"]
    setup_id = cfg["setup_id"]
    p = prefix(cfg)
    story = cfg["story"]
    if f"story: {story}" in content:
        return content

    if fn == "opencode":
        content = content.replace(
            'echo "$DRY_OUT" | grep -qi \'opencode\' && ta_fail "install references opencode" || ta_pass "install has no opencode reference"',
            'echo "$DRY_OUT" | grep -qi \'OpenCode →\' && ta_pass "install includes OpenCode" || ta_fail "install missing OpenCode"',
        )
        content = content.replace(
            '! grep -q \'install_opencode\\|print_opencode_instructions\' "$REPO_ROOT/scripts/install.sh" && ta_pass "source: no opencode functions" || ta_fail "source: opencode functions remain"',
            'grep -q \'install_opencode()\' "$REPO_ROOT/scripts/install.sh" && ta_pass "source: install_opencode()" || ta_fail "source: missing install_opencode()"',
        )

    block = f"""grep -q 'install_{fn}()' "$REPO_ROOT/scripts/install.sh" && ta_pass "source: install_{fn}()" || ta_fail "source: missing install_{fn}()"
grep -q 'uninstall_{fn}()' "$REPO_ROOT/scripts/install.sh" && ta_pass "source: uninstall_{fn}()" || ta_fail "source: missing uninstall_{fn}()"
grep -q '{p}_SKILLS_DIR=' "$REPO_ROOT/scripts/install.sh" && ta_pass "source: {fn} skills dir" || ta_fail "source: missing {fn} skills dir"
grep -q "'{setup_id}'" "$REPO_ROOT/bin/setup.js" && grep -q 'SUPPORTED_IDS' "$REPO_ROOT/bin/setup.js" && ta_pass "setup.js: {setup_id} supported" || ta_fail "setup.js: {setup_id} not in SUPPORTED_IDS"
grep -q "case '{setup_id}'" "$REPO_ROOT/scripts/lib/install-helpers.js" && ta_pass "install-helpers: {setup_id} case" || ta_fail "install-helpers: missing {setup_id} case"
"""
    anchor = 'echo ""\necho "──────────────────────────────────────────"'
    content = content.replace(anchor, block + anchor)
    content = content.replace(
        "# story: e74s02",
        f"# story: e74s02\n# story: {story}",
        1,
    )
    return content


def patch_targets(cfg: dict, content: str) -> str:
    fn = cfg["fn"]
    manifest = cfg.get("manifest")
    if manifest and manifest not in content and f"id: {fn}" in content:
        content = re.sub(
            rf"(  - id: {fn}\n(?:    .*\n)*?    contracts:\n(?:      - [^\n]+\n)+)",
            rf"\1      - {manifest}\n",
            content,
            count=1,
        )
        return content
    if f"\n  - id: {fn}\n" in content:
        return content
    row = targets_row(cfg)
    content = content.rstrip() + "\n\n  # Fleet Wave B\n" + row
    return content


def apply_epic(epic_id: str) -> None:
    cfg = dict(HUB_EPICS[epic_id])
    cfg["_epic_id"] = epic_id
    fn = cfg["fn"]
    print(f"Applying Wave B hub for {epic_id} ({fn})...")

    test_path = REPO / f"scripts/test-{fn}-hub.sh"
    test_path.write_text(test_hub_sh(cfg))
    test_path.chmod(0o755)

    install_path = REPO / "scripts/install.sh"
    install_path.write_text(patch_install_sh(cfg, install_path.read_text()))

    helpers_path = REPO / "scripts/lib/install-helpers.js"
    helpers_path.write_text(patch_helpers(cfg, helpers_path.read_text()))

    setup_path = REPO / "bin/setup.js"
    setup_path.write_text(patch_setup_js(cfg, setup_path.read_text()))

    verify_path = REPO / "scripts/verify-install.sh"
    verify_path.write_text(patch_verify_install(cfg, verify_path.read_text()))

    if cfg.get("manifest"):
        targets_path = REPO / "scripts/targets.yaml"
        targets_path.write_text(patch_targets(cfg, targets_path.read_text()))

    print(f"  wrote test-{fn}-hub.sh and patched hub files")


def main(argv: list[str]) -> int:
    if len(argv) < 2:
        print("Usage: generate-wave-b-hub.py <e65|e68|...|all>", file=sys.stderr)
        return 1
    target = argv[1]
    ids = list(HUB_EPICS.keys()) if target == "all" else [target]
    for eid in ids:
        if eid not in HUB_EPICS:
            print(f"Unknown epic: {eid}", file=sys.stderr)
            return 1
        apply_epic(eid)
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
