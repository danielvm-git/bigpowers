"""Wave B hub patchers for install surface files."""
from __future__ import annotations

import re
import sys
from pathlib import Path

from wave_b_hub_config import HUB_EPICS, HUB_ORDER, prefix
from wave_b_hub_codegen_install import install_sh_block
from wave_b_hub_codegen_helpers import (
    helpers_global_case,
    helpers_local_case,
    helpers_uninstall_case,
    targets_row,
    test_hub_sh,
)

REPO = Path(__file__).resolve().parents[2]

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
            'grep -qi \'opencode\' <<< "$DRY_OUT" && ta_fail "install references opencode" || ta_pass "install has no opencode reference"',
            'grep -q \'OpenCode →\' <<< "$DRY_OUT" && ta_pass "install includes OpenCode" || ta_fail "install missing OpenCode"',
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


