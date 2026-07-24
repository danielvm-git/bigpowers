"""Generate helpers, hub tests, and targets rows for Wave B."""
from __future__ import annotations

from wave_b_hub_config import prefix

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


