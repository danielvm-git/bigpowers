#!/usr/bin/env python3
# story: e38s01
# trace-matrix.py — deterministic spec-to-code coverage matrix builder (Python engine).
# Called by scripts/trace-stories.sh. Not meant to be run standalone without args.
#
# Oracle tiers (TEA-inspired):
#   Tier 1: explicit story tag → confidence high
#   Tier 2: file-name heuristic match → confidence medium
#   Tier 3: epic capsule task reference → confidence low

import json, os, re, sys, time
from pathlib import Path
from datetime import datetime, timezone

# Add parent or current directory to sys.path so we can import local helper modules
sys.path.insert(0, str(Path(__file__).parent))

from simple_yaml import parse_simple_yaml
from trace_renderer import emit_matrix_json, emit_trace_md, emit_okf_bundle

ROOT = Path(sys.argv[1])
MATRIX_JSON = Path(sys.argv[2])
TRACE_MD = Path(sys.argv[3])
OKF_DIR = Path(sys.argv[4])
STRICT = int(sys.argv[5])
MODE = sys.argv[6]

# Parse release plan for epics/stories
release_plan_path = ROOT / "specs" / "release-plan.yaml"
release_text = release_plan_path.read_text(encoding="utf-8")
release = parse_simple_yaml(release_text)

# Parse execution status
exec_path = ROOT / "specs" / "execution-status.yaml"
exec_text = exec_path.read_text(encoding="utf-8")
exec_status = parse_simple_yaml(exec_text)
dev_status = exec_status.get("development_status", {})

# -----------------------------------------------------------------------
# 2. Build story inventory from release-plan.yaml
# -----------------------------------------------------------------------
stories: dict[str, dict] = {}
epics = release.get("epics", [])
if not isinstance(epics, list):
    epics = []

for epic in epics:
    if not isinstance(epic, dict):
        continue
    eid = epic.get("id", "")
    ebcp = epic.get("bcps", 0)
    etitle = epic.get("title", "")
    ewsjf = epic.get("wsjf", 0)
    
    # Check for capsule_dir with stories
    capsule_dir = epic.get("capsule_dir", "")
    if capsule_dir:
        capsule_path = ROOT / "specs" / capsule_dir / "epic.yaml"
        if capsule_path.exists():
            cap_text = capsule_path.read_text(encoding="utf-8")
            cap = parse_simple_yaml(cap_text)
            cap_stories = cap.get("stories", [])
            if isinstance(cap_stories, list):
                for s in cap_stories:
                    if isinstance(s, dict):
                        sid = s.get("id", "")
                        stories[sid] = {
                            "id": sid,
                            "title": s.get("title", ""),
                            "epic_id": eid,
                            "epic_title": etitle,
                            "bcp": s.get("bcp", 0),
                            "wsjf": float(ewsjf),
                            "description": s.get("description", "")
                        }
    
    # Also check legacy flat epics (file: epics/eNN-*.yaml patterns)
    file_key = epic.get("file", "")
    if file_key and not capsule_dir:
        legacy_path = ROOT / "specs" / file_key
        if legacy_path.exists():
            leg_text = legacy_path.read_text(encoding="utf-8")
            leg = parse_simple_yaml(leg_text)
            leg_stories = leg.get("stories", [])
            if isinstance(leg_stories, list):
                for s in leg_stories:
                    if isinstance(s, dict):
                        sid = s.get("id", "")
                        stories[sid] = {
                            "id": sid,
                            "title": s.get("title", ""),
                            "epic_id": eid,
                            "epic_title": etitle,
                            "bcp": s.get("bcp", 0),
                            "wsjf": float(ewsjf),
                            "description": s.get("description", "")
                        }

# -----------------------------------------------------------------------
# 3. Grep codebase for story: eNNsNN tags
# -----------------------------------------------------------------------
import subprocess
result = subprocess.run(
    ["grep", "-rn", "--include=*.md", "--include=*.sh", "--include=*.py",
     "--include=*.js", "--include=*.ts", "--include=*.yaml", "--include=*.yml",
     "-E", r"story:\s*e\d{2}s\d{2}", str(ROOT)],
    capture_output=True, text=True, cwd=str(ROOT)
)

tag_inventory: list[dict] = []
for line in result.stdout.splitlines():
    m = re.match(r"^(.+?):(\d+):(.*story:\s*(e\d{2}s\d{2}).*)$", line)
    if m:
        fpath = m.group(1)
        fline = int(m.group(2))
        sid = m.group(4)
        # Make path relative to repo root
        try:
            fpath = str(Path(fpath).relative_to(ROOT))
        except ValueError:
            pass
        tag_inventory.append({"file": fpath, "line": fline, "story_id": sid})

# -----------------------------------------------------------------------
# 4. Resolve each story through oracle tiers
# -----------------------------------------------------------------------
# Collect all file basenames for heuristic matching
all_files = []
for root_dir, dirs, files in os.walk(str(ROOT)):
    # Skip generated/artifacts
    dirs[:] = [d for d in dirs if d not in (".git", "node_modules", ".cursor")]
    for f in files:
        all_files.append(str(Path(root_dir, f).relative_to(ROOT)))

def slugify(text: str) -> str:
    """Convert title to a kebab-case slug."""
    text = re.sub(r"[^a-zA-Z0-9\s-]", "", text.lower())
    return re.sub(r"\s+", "-", text.strip())

def heuristic_match(story_title: str, file_path: str) -> bool:
    """Check if file-path contains keywords from story title."""
    slug = slugify(story_title)
    words = slug.split("-")
    fname = Path(file_path).stem.lower()
    # Must match at least 2 significant keywords
    sig_words = [w for w in words if len(w) > 2]
    if len(sig_words) < 2:
        sig_words = words
    matches = sum(1 for w in sig_words if w in fname)
    return matches >= min(2, len(sig_words))

def find_task_references(story_id: str) -> list[dict]:
    """Find epic capsule task YAML files that reference this story's verify paths."""
    refs = []
    epics_dir = ROOT / "specs" / "epics"
    if not epics_dir.exists():
        return refs
    for task_yaml in epics_dir.rglob("*tasks.yaml"):
        try:
            content = task_yaml.read_text(encoding="utf-8")
            if f"story_id: {story_id}" in content or story_id in content:
                rel = str(task_yaml.relative_to(ROOT))
                refs.append({"file": rel, "type": "task_yaml"})
        except Exception:
            pass
    return refs

# Build the coverage matrix
matrix_stories = []
tagged_sids = set(t["story_id"] for t in tag_inventory)
tag_index: dict[str, list] = {}
for t in tag_inventory:
    tag_index.setdefault(t["story_id"], []).append(t)

dark_stories = []
orphan_tags = []
stale_tags = []

for sid, sinfo in sorted(stories.items()):
    links = []
    sid_status = dev_status.get(sid, "backlog")
    
    # Tier 1: explicit tags
    if sid in tag_index:
        for t in tag_index[sid]:
            links.append({"file": t["file"], "line": t["line"], "confidence": "high", "method": "explicit_tag"})
    
    # Tier 2: file-name heuristic
    for fpath in all_files:
        if heuristic_match(sinfo["title"], fpath):
            # Don't add if already covered by explicit tag
            if not any(l["file"] == fpath for l in links):
                links.append({"file": fpath, "line": 0, "confidence": "medium", "method": "file_heuristic"})
    
    # Tier 3: task references
    task_refs = find_task_references(sid)
    for tr in task_refs:
        existing_files = {l["file"] for l in links}
        if tr["file"] not in existing_files:
            links.append({"file": tr["file"], "line": 0, "confidence": "low", "method": "task_reference"})
    
    matrix_stories.append({
        "id": sid,
        "title": sinfo["title"],
        "epic_id": sinfo["epic_id"],
        "epic_title": sinfo["epic_title"],
        "bcp": sinfo["bcp"],
        "wsjf": sinfo["wsjf"],
        "status": sid_status,
        "links": links,
        "link_count": len(links)
    })
    
    # Classify findings
    if len(links) == 0 and sid_status != "backlog":
        dark_stories.append(sid)

# Check for orphan tags (tag in code, not in story inventory)
for sid in sorted(tagged_sids):
    if sid not in stories:
        orphan_tags.append(sid)

# Check for stale tags (story done, tag still in code)
for sid in sorted(tagged_sids):
    if sid in stories and dev_status.get(sid) == "done":
        stale_tags.append(sid)

# Emit outputs via trace_renderer
matrix = emit_matrix_json(MATRIX_JSON, stories, tagged_sids, dark_stories, orphan_tags, stale_tags, matrix_stories)
emit_trace_md(TRACE_MD, stories, tagged_sids, dark_stories, orphan_tags, stale_tags, matrix_stories, matrix, dev_status)
emit_okf_bundle(OKF_DIR, stories, matrix_stories)

# -----------------------------------------------------------------------
# 8. Strict mode — exit non-zero on P0 uncovered
# -----------------------------------------------------------------------
if STRICT:
    # P0 = top WSJF quartile among stories
    if matrix_stories:
        wsjf_sorted = sorted(set(s["wsjf"] for s in matrix_stories), reverse=True)
        cutoff_idx = max(0, len(wsjf_sorted) // 4 - 1)
        p0_threshold = wsjf_sorted[cutoff_idx] if cutoff_idx < len(wsjf_sorted) else 0
        
        uncovered_p0 = []
        for s in matrix_stories:
            if s["wsjf"] >= p0_threshold and len(s["links"]) == 0:
                uncovered_p0.append(s["id"])
        
        if uncovered_p0:
            print(f"trace-stories.sh: STRICT FAIL — P0 stories with 0% coverage: {', '.join(uncovered_p0)}", file=sys.stderr)
            sys.exit(2)

sys.exit(0)
