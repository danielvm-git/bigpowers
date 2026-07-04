#!/usr/bin/env python3
"""story: e38s01 — deterministic spec-to-code coverage matrix builder (Python engine).

Parses release-plan.yaml + execution-status.yaml, greps codebase for story tags,
builds oracle-tiered coverage matrix, emits JSON + markdown + OKF wiki.

Usage: called by scripts/trace-stories.sh with positional args:
  python3 scripts/lib/trace-stories.py <repo_root> <matrix_json> <trace_md>
      <okf_dir> <strict> <mode>

Oracle tiers (TEA-inspired):
  Tier 1: explicit story tag → confidence high
  Tier 2: file-name heuristic match → confidence medium
  Tier 3: epic capsule task reference → confidence low
"""

import json, os, re, subprocess, sys
from pathlib import Path
from datetime import datetime, timezone

ROOT = Path(sys.argv[1])
MATRIX_JSON = Path(sys.argv[2])
TRACE_MD = Path(sys.argv[3])
OKF_DIR = Path(sys.argv[4])
STRICT = int(sys.argv[5])
MODE = sys.argv[6]

# -----------------------------------------------------------------------
# 1. Parse release-plan.yaml → story inventory
# -----------------------------------------------------------------------
def parse_simple_yaml(text: str) -> dict:
    """Parse flat and one-level-nested YAML including lists of objects."""
    root: dict = {}
    stack: list = [(0, root, None, None)]
    skip_until_indent = None
    for i, raw in enumerate(text.splitlines()):
        stripped = raw.strip()
        if not stripped or stripped.startswith("#"):
            continue
        indent = len(raw) - len(raw.lstrip())
        if skip_until_indent is not None:
            if indent > skip_until_indent:
                continue
            else:
                skip_until_indent = None
        while len(stack) > 1:
            if indent < stack[-1][0]:
                stack.pop()
            elif indent == stack[-1][0]:
                if isinstance(stack[-1][1], list) and stripped.startswith("- "):
                    break
                elif isinstance(stack[-1][1], dict) and stripped.startswith("- "):
                    entry_container = stack[-1][1]
                    entry_parent = stack[-1][2]
                    entry_key = stack[-1][3]
                    if entry_parent is not None and entry_key is not None:
                        if not isinstance(entry_parent.get(entry_key), list):
                            entry_parent[entry_key] = []
                            stack[-1] = (stack[-1][0], entry_parent[entry_key], entry_parent, entry_key)
                            break
                    stack.pop()
                else:
                    stack.pop()
            else:
                break
        container = stack[-1][1]
        parent_dict = stack[-1][2]
        key_in_parent = stack[-1][3]
        if stripped.startswith("- "):
            inner = stripped[2:]
            if isinstance(container, dict) and parent_dict is not None and key_in_parent is not None:
                if not isinstance(parent_dict.get(key_in_parent), list):
                    orig_indent = stack[-1][0]
                    parent_dict[key_in_parent] = []
                    container = parent_dict[key_in_parent]
                    stack[-1] = (orig_indent, container, parent_dict, key_in_parent)
            if ":" in inner:
                k, _, v = inner.partition(":")
                k = k.strip(); v = v.strip()
                if v in ("|", ">", "|-", ">-", "|+", ">+"):
                    item = {k: v}; container.append(item)
                    skip_until_indent = indent; continue
                item = {k: _yaml_scalar(v) if v else None}
                container.append(item)
                if v == "":
                    stack.append((indent, item, container, k))
            else:
                container.append(_yaml_scalar(inner))
            continue
        if ":" not in stripped:
            continue
        key, _, val = stripped.partition(":")
        key = key.strip(); val = val.strip()
        if val in ("|", ">", "|-", ">-", "|+", ">+"):
            if isinstance(container, list) and container:
                container[-1][key] = val
            elif isinstance(container, dict):
                container[key] = val
            skip_until_indent = indent; continue
        if isinstance(container, list) and container:
            container[-1][key] = _yaml_scalar(val) if val else None
            if val == "":
                nxt = {}; container[-1][key] = nxt
                stack.append((indent, nxt, container[-1], key))
        elif isinstance(container, dict):
            if val == "":
                nxt = {}; container[key] = nxt
                stack.append((indent, nxt, container, key))
            else:
                container[key] = _yaml_scalar(val)
    return root

def _yaml_scalar(val: str):
    val = val.strip('"').strip("'")
    if val in ("true", "false"): return val == "true"
    if val in ("null", "~", ""): return None
    try: return int(val)
    except ValueError:
        try: return float(val)
        except ValueError: return val

release_text = (ROOT / "specs" / "release-plan.yaml").read_text(encoding="utf-8")
release = parse_simple_yaml(release_text)
exec_text = (ROOT / "specs" / "execution-status.yaml").read_text(encoding="utf-8")
exec_status = parse_simple_yaml(exec_text)
dev_status = exec_status.get("development_status", {})

# -----------------------------------------------------------------------
# 2. Build story inventory
# -----------------------------------------------------------------------
stories: dict[str, dict] = {}
epics = release.get("epics", [])
if not isinstance(epics, list):
    epics = []
for epic in epics:
    if not isinstance(epic, dict):
        continue
    eid = epic.get("id", ""); ebcp = epic.get("bcps", 0)
    etitle = epic.get("title", ""); ewsjf = epic.get("wsjf", 0)
    capsule_dir = epic.get("capsule_dir", "")
    if capsule_dir:
        capsule_path = ROOT / "specs" / capsule_dir / "epic.yaml"
        if capsule_path.exists():
            cap = parse_simple_yaml(capsule_path.read_text(encoding="utf-8"))
            for s in cap.get("stories", []) or []:
                if isinstance(s, dict):
                    sid = s.get("id", "")
                    stories[sid] = {"id": sid, "title": s.get("title", ""),
                        "epic_id": eid, "epic_title": etitle,
                        "bcp": s.get("bcp", 0), "wsjf": float(ewsjf),
                        "description": s.get("description", "")}
    file_key = epic.get("file", "")
    if file_key and not capsule_dir:
        legacy_path = ROOT / "specs" / file_key
        if legacy_path.exists():
            leg = parse_simple_yaml(legacy_path.read_text(encoding="utf-8"))
            for s in leg.get("stories", []) or []:
                if isinstance(s, dict):
                    sid = s.get("id", "")
                    stories[sid] = {"id": sid, "title": s.get("title", ""),
                        "epic_id": eid, "epic_title": etitle,
                        "bcp": s.get("bcp", 0), "wsjf": float(ewsjf),
                        "description": s.get("description", "")}

# -----------------------------------------------------------------------
# 3. Grep codebase for story tags
# -----------------------------------------------------------------------
result = subprocess.run(
    ["grep", "-rn", "--include=*.md", "--include=*.sh", "--include=*.py",
     "--include=*.js", "--include=*.ts", "--include=*.yaml", "--include=*.yml",
     "-E", r"story:\s*e\d{2}s\d{2}", str(ROOT)],
    capture_output=True, text=True, cwd=str(ROOT))

tag_inventory: list[dict] = []
tagged_sids: set[str] = set()
tag_index: dict[str, list] = {}
for line in result.stdout.splitlines():
    m = re.match(r"^(.+?):(\d+):(.*story:\s*(e\d{2}s\d{2}).*)$", line)
    if m:
        fpath = m.group(1); fline = int(m.group(2)); sid = m.group(4)
        try: fpath = str(Path(fpath).relative_to(ROOT))
        except ValueError: pass
        tag_inventory.append({"file": fpath, "line": fline, "story_id": sid})
        tagged_sids.add(sid)
        tag_index.setdefault(sid, []).append({"file": fpath, "line": fline})

# -----------------------------------------------------------------------
# 4. Oracle tiers
# -----------------------------------------------------------------------
EXCLUDE_DIRS = {".git", "node_modules", ".cursor", ".gemini", ".pi"}
EXCLUDE_PREFIXES = ("specs/archive/", "specs/codebase-wiki/")

def _is_excluded(rel_path: str) -> bool:
    """True if path is in an excluded dir or under an excluded prefix."""
    parts = rel_path.split(os.sep)
    if any(d in EXCLUDE_DIRS for d in parts):
        return True
    return any(rel_path.startswith(p) for p in EXCLUDE_PREFIXES)

all_files = []
for root_dir, dirs, files in os.walk(str(ROOT)):
    dirs[:] = [d for d in dirs if d not in EXCLUDE_DIRS]
    for f in files:
        rel = str(Path(root_dir, f).relative_to(ROOT))
        if not _is_excluded(rel):
            all_files.append(rel)

def slugify(text: str) -> str:
    text = re.sub(r"[^a-zA-Z0-9\s-]", "", text.lower())
    return re.sub(r"\s+", "-", text.strip())

def heuristic_match(story_title: str, file_path: str) -> bool:
    slug = slugify(story_title)
    words = slug.split("-")
    fname = Path(file_path).stem.lower()
    sig_words = [w for w in words if len(w) > 2]
    if len(sig_words) < 2: sig_words = words
    matches = sum(1 for w in sig_words if w in fname)
    return matches >= min(2, len(sig_words))

def find_task_references(story_id: str) -> list[dict]:
    refs = []
    epics_dir = ROOT / "specs" / "epics"
    if not epics_dir.exists(): return refs
    for task_yaml in epics_dir.rglob("*tasks.yaml"):
        try:
            content = task_yaml.read_text(encoding="utf-8")
            if f"story_id: {story_id}" in content or story_id in content:
                refs.append({"file": str(task_yaml.relative_to(ROOT)), "type": "task_yaml"})
        except Exception: pass
    return refs

matrix_stories = []
dark_stories = []
for sid, sinfo in sorted(stories.items()):
    links = []
    sid_status = dev_status.get(sid, "backlog")
    if sid in tag_index:
        for t in tag_index[sid]:
            links.append({"file": t["file"], "line": t["line"], "confidence": "high", "method": "explicit_tag"})
    for fpath in all_files:
        if heuristic_match(sinfo["title"], fpath):
            if not any(l["file"] == fpath for l in links):
                links.append({"file": fpath, "line": 0, "confidence": "medium", "method": "file_heuristic"})
    for tr in find_task_references(sid):
        existing = {l["file"] for l in links}
        if tr["file"] not in existing:
            links.append({"file": tr["file"], "line": 0, "confidence": "low", "method": "task_reference"})
    matrix_stories.append({
        "id": sid, "title": sinfo["title"], "epic_id": sinfo["epic_id"],
        "epic_title": sinfo["epic_title"], "bcp": sinfo["bcp"], "wsjf": sinfo["wsjf"],
        "status": sid_status, "links": links, "link_count": len(links)
    })
    if len(links) == 0 and sid_status != "backlog":
        dark_stories.append(sid)

orphan_tags = [sid for sid in sorted(tagged_sids) if sid not in stories]
stale_tags = [sid for sid in sorted(tagged_sids) if sid in stories and dev_status.get(sid) == "done"]

# -----------------------------------------------------------------------
# 5. Emit matrix JSON
# -----------------------------------------------------------------------
matrix = {
    "generated_at": datetime.now(timezone.utc).isoformat(),
    "matrix_version": "1.0",
    "stories": matrix_stories,
    "summary": {
        "total_stories": len(stories),
        "tagged_stories": len(tagged_sids & set(stories.keys())),
        "dark_stories": dark_stories, "dark_count": len(dark_stories),
        "orphan_tags": orphan_tags, "orphan_count": len(orphan_tags),
        "stale_tags": stale_tags, "stale_count": len(stale_tags),
        "oracle_stats": {
            "high": sum(1 for s in matrix_stories for l in s["links"] if l["confidence"] == "high"),
            "medium": sum(1 for s in matrix_stories for l in s["links"] if l["confidence"] == "medium"),
            "low": sum(1 for s in matrix_stories for l in s["links"] if l["confidence"] == "low")
        }
    }
}
MATRIX_JSON.parent.mkdir(parents=True, exist_ok=True)
MATRIX_JSON.write_text(json.dumps(matrix, indent=2), encoding="utf-8")

# -----------------------------------------------------------------------
# 6. Emit TRACEABILITY_LATEST.md
# -----------------------------------------------------------------------
lines = ["# Traceability Matrix", "",
    f"**Generated:** {datetime.now(timezone.utc).strftime('%Y-%m-%d %H:%M:%S UTC')}",
    f"**Total stories:** {len(stories)}",
    f"**Tagged stories:** {len(tagged_sids & set(stories.keys()))}",
    f"**Dark stories:** {len(dark_stories)}",
    f"**Orphan tags:** {len(orphan_tags)}",
    f"**Stale tags:** {len(stale_tags)}",
    "", "## Oracle Stats", "",
    f"- **High** (explicit tag): {matrix['summary']['oracle_stats']['high']}",
    f"- **Medium** (file heuristic): {matrix['summary']['oracle_stats']['medium']}",
    f"- **Low** (task reference): {matrix['summary']['oracle_stats']['low']}",
    "", "## Story Coverage", "",
    "| Story | Title | Epic | BCP | WSJF | Status | Links |",
    "|-------|-------|------|-----|------|--------|-------|"]
for s in matrix_stories:
    lines.append(f"| {s['id']} | {s['title'][:60]} | {s['epic_id']} | {s['bcp']} | {s['wsjf']} | {s['status']} | {s['link_count']} |")
lines.append("")
if dark_stories:
    lines.append("## Dark Stories (no code links)\n")
    for ds in dark_stories:
        si = stories.get(ds, {})
        lines.append(f"- **{ds}**: {si.get('title', 'Unknown')} (status: {dev_status.get(ds, '?')})")
    lines.append("")
if orphan_tags:
    lines.append("## Orphan Tags (tag in code, no matching story)\n")
    for ot in orphan_tags: lines.append(f"- `{ot}`")
    lines.append("")
if stale_tags:
    lines.append("## Stale Tags (story done, tag still in code)\n")
    for st in stale_tags: lines.append(f"- `{st}`")
    lines.append("")
TRACE_MD.parent.mkdir(parents=True, exist_ok=True)
TRACE_MD.write_text("\n".join(lines), encoding="utf-8")

# -----------------------------------------------------------------------
# 7. Emit OKF bundle (specs/codebase-wiki/)
# -----------------------------------------------------------------------
OKF_DIR.mkdir(parents=True, exist_ok=True)
idx_lines = ["---", "type: Index",
    f"generated_at: {datetime.now(timezone.utc).isoformat()}",
    f"total_concepts: {len(stories)}", "---", "",
    "# Codebase Wiki — Story Traceability", "",
    "Auto-generated OKF bundle from trace-stories.sh.", "",
    "| Story | Title | Confidence | Links |",
    "|-------|-------|------------|-------|"]
for s in matrix_stories:
    confs = {l["confidence"] for l in s["links"]}
    mc = "high" if "high" in confs else ("medium" if "medium" in confs else ("low" if confs else "none"))
    idx_lines.append(f"| [{s['id']}](./{s['id']}.md) | {s['title'][:60]} | {mc} | {s['link_count']} |")
idx_lines.append("")
(OKF_DIR / "index.md").write_text("\n".join(idx_lines), encoding="utf-8")
for s in matrix_stories:
    concept = ["---", f"type: Story", f"id: {s['id']}", f"epic: {s['epic_id']}",
        f"bcps: {s['bcp']}", f"wsjf: {s['wsjf']}",
        f"implementation_status: {s['status']}"]
    max_confs = {l["confidence"] for l in s["links"]}
    conf = "high" if "high" in max_confs else ("medium" if "medium" in max_confs else ("low" if max_confs else "none"))
    concept.extend([f"coverage_status: {'covered' if s['link_count'] > 0 else 'dark'}",
        f"confidence: {conf}", "links:"])
    for l in s["links"]:
        concept.extend([f"  - file: {l['file']}", f"    line: {l['line']}",
            f"    confidence: {l['confidence']}", f"    method: {l['method']}"])
    concept.extend(["---", "", f"# {s['id']}: {s['title']}", "",
        f"**Epic:** {s['epic_id']} — {s.get('epic_title', 'Unknown')}",
        f"**Status:** {s['status']}",
        f"**BCP:** {s['bcp']} | **WSJF:** {s['wsjf']}", ""])
    if s["links"]:
        concept.append("## Implemented In\n")
        for l in s["links"]:
            concept.append(f"- `{l['file']}` (line {l['line']}, confidence: {l['confidence']}, method: {l['method']})")
    else:
        concept.append("*No code links found — this is a dark story.*")
    concept.append("")
    (OKF_DIR / f"{s['id']}.md").write_text("\n".join(concept), encoding="utf-8")

# -----------------------------------------------------------------------
# 8. Strict mode
# -----------------------------------------------------------------------
if STRICT:
    if matrix_stories:
        wsjf_sorted = sorted(set(s["wsjf"] for s in matrix_stories), reverse=True)
        cutoff_idx = max(0, len(wsjf_sorted) // 4 - 1)
        p0_threshold = wsjf_sorted[cutoff_idx] if cutoff_idx < len(wsjf_sorted) else 0
        # Only flag non-backlog stories — backlog stories haven't been implemented yet
        uncovered_p0 = [s["id"] for s in matrix_stories
            if s["wsjf"] >= p0_threshold and len(s["links"]) == 0
            and s["status"] != "backlog"]
        if uncovered_p0:
            print(f"trace-stories.sh: STRICT FAIL — P0 stories with 0% coverage: {', '.join(uncovered_p0)}", file=sys.stderr)
            sys.exit(2)

sys.exit(0)
