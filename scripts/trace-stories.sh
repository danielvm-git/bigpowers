#!/usr/bin/env bash
# trace-stories.sh — deterministic spec-to-code coverage matrix builder
# Parses specs/release-plan.yaml + specs/execution-status.yaml, greps the
# codebase for story: eNNsNN tags, cross-references, and emits a coverage matrix.
#
# Oracle tiers (TEA-inspired):
#   Tier 1: explicit story tag → confidence high
#   Tier 2: file-name heuristic match → confidence medium
#   Tier 3: epic capsule task reference → confidence low
#
# Usage:
#   bash scripts/trace-stories.sh            # full matrix, stdout
#   bash scripts/trace-stories.sh --strict   # exit non-zero on P0 uncovered
#   bash scripts/trace-stories.sh --json     # emit JSON to specs/traceability-matrix.json
#   bash scripts/trace-stories.sh --help     # this message
#
# Exit codes:
#   0 — matrix built successfully (or --help printed)
#   1 — input file missing or unparseable
#   2 — --strict mode: P0 story has 0% coverage

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MATRIX_JSON="$REPO_ROOT/specs/traceability-matrix.json"
TRACE_MD="$REPO_ROOT/specs/TRACEABILITY_LATEST.md"
RELEASE_PLAN="$REPO_ROOT/specs/release-plan.yaml"
EXEC_STATUS="$REPO_ROOT/specs/execution-status.yaml"
OKF_DIR="$REPO_ROOT/specs/codebase-wiki"

MODE=""
STRICT=0

# ---------------------------------------------------------------------------
# CLI flags
# ---------------------------------------------------------------------------
while [[ $# -gt 0 ]]; do
  case "$1" in
    --help|-h)
      cat <<'USAGE'
Usage: trace-stories.sh [flags]

Build a deterministic spec-to-code coverage matrix from story tags.

Flags:
  --strict   Exit non-zero if any P0 story has 0% code coverage.
  --json     Emit JSON matrix to specs/traceability-matrix.json.
  --help     Print this message and exit.

Exit codes:
  0  Matrix built successfully.
  1  Required input file missing or unparseable.
  2  --strict mode: one or more P0 stories have 0% code coverage.

Input files (required):
  specs/release-plan.yaml       Story inventory (id, title, wsjf, bcps).
  specs/execution-status.yaml   Story statuses (done, active, backlog).

Output files:
  specs/traceability-matrix.json  Machine-readable coverage matrix.
  specs/TRACEABILITY_LATEST.md    Human-readable report.
  specs/codebase-wiki/            OKF-conformant derived bundle.
USAGE
      exit 0
      ;;
    --strict)
      STRICT=1
      shift
      ;;
    --json)
      MODE="json"
      shift
      ;;
    *)
      echo "trace-stories.sh: unknown flag: $1" >&2
      echo "Try --help for usage." >&2
      exit 1
      ;;
  esac
done

# ---------------------------------------------------------------------------
# Input existence checks
# ---------------------------------------------------------------------------
if [[ ! -f "$RELEASE_PLAN" ]]; then
  echo "trace-stories.sh: release-plan.yaml: not found at $RELEASE_PLAN" >&2
  exit 1
fi

if [[ ! -f "$EXEC_STATUS" ]]; then
  echo "trace-stories.sh: execution-status.yaml: not found at $EXEC_STATUS" >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# Matrix builder (Python — no external deps beyond stdlib)
# ---------------------------------------------------------------------------
python3 - "$REPO_ROOT" "$MATRIX_JSON" "$TRACE_MD" "$OKF_DIR" "$STRICT" "$MODE" <<'PYEOF'
import json, os, re, sys, time
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
    # Each stack entry: (indent, container, parent_dict, key_in_parent)
    stack: list = [(0, root, None, None)]
    skip_until_indent = None  # skip block scalar continuation lines (| and >)
    for i, raw in enumerate(text.splitlines()):
        stripped = raw.strip()
        if not stripped or stripped.startswith("#"):
            # Reset block-scalar skip on blank lines
            continue
        indent = len(raw) - len(raw.lstrip())
        
        # Skip block scalar continuation (| and > in YAML)
        if skip_until_indent is not None:
            if indent > skip_until_indent:
                continue
            else:
                skip_until_indent = None
        
        # Pop stack until we're at the right nesting level
        # Don't pop list containers at same indent — sibling items stay in same list
        while len(stack) > 1:
            if indent < stack[-1][0]:
                stack.pop()
            elif indent == stack[-1][0]:
                # Same indent: pop dicts (moving to sibling key), keep lists (sibling items)
                if isinstance(stack[-1][1], list) and stripped.startswith("- "):
                    break  # stay in same list for next item
                elif isinstance(stack[-1][1], dict) and stripped.startswith("- "):
                    # dict at same indent with upcoming list item — convert to list
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
                    stack.pop()  # other same-indent transitions
            else:
                break  # indent > stack indent — staying inside
        
        container = stack[-1][1]
        parent_dict = stack[-1][2]
        key_in_parent = stack[-1][3]
        
        # List item
        if stripped.startswith("- "):
            inner = stripped[2:]
            # Convert dict to list if needed (preserve original indent from dict push)
            if isinstance(container, dict) and parent_dict is not None and key_in_parent is not None:
                if not isinstance(parent_dict.get(key_in_parent), list):
                    orig_indent = stack[-1][0]
                    parent_dict[key_in_parent] = []
                    container = parent_dict[key_in_parent]
                    stack[-1] = (orig_indent, container, parent_dict, key_in_parent)
            
            if ":" in inner:
                k, _, v = inner.partition(":")
                k = k.strip()
                v = v.strip()
                # Detect block scalars in list items too
                if v in ("|", ">", "|-", ">-", "|+", ">+"):
                    item = {k: v}
                    container.append(item)
                    skip_until_indent = indent
                    continue
                item = {k: _yaml_scalar(v) if v else None}
                container.append(item)
                if v == "":
                    stack.append((indent, item, container, k))
            else:
                container.append(_yaml_scalar(inner))
            continue
        
        # Key: value
        if ":" not in stripped:
            continue
        key, _, val = stripped.partition(":")
        key = key.strip()
        val = val.strip()
        
        # Detect block scalars (|, >, |- etc.)
        if val in ("|", ">", "|-", ">-", "|+", ">+"):
            if isinstance(container, list) and container:
                container[-1][key] = val  # store the marker
            elif isinstance(container, dict):
                container[key] = val
            skip_until_indent = indent
            continue
        
        if isinstance(container, list) and container:
            # Inside a list item dict
            container[-1][key] = _yaml_scalar(val) if val else None
            if val == "":
                nxt = {}
                container[-1][key] = nxt
                stack.append((indent, nxt, container[-1], key))
        elif isinstance(container, dict):
            if val == "":
                # Store as dict first; will convert to list if next line is "-"
                nxt = {}
                container[key] = nxt
                stack.append((indent, nxt, container, key))
            else:
                container[key] = _yaml_scalar(val)
    return root


def _yaml_scalar(val: str):
    """Convert a YAML scalar string to Python type."""
    val = val.strip('"').strip("'")
    if val in ("true", "false"):
        return val == "true"
    if val in ("null", "~", ""):
        return None
    try:
        return int(val)
    except ValueError:
        try:
            return float(val)
        except ValueError:
            return val

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
# Tier 1: explicit story tag (already captured above)
# Tier 2: file-name heuristic match
# Tier 3: epic capsule task reference

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
        "dark_stories": dark_stories,
        "dark_count": len(dark_stories),
        "orphan_tags": orphan_tags,
        "orphan_count": len(orphan_tags),
        "stale_tags": stale_tags,
        "stale_count": len(stale_tags),
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
# 6. Emit TRACEABILITY_LATEST.md (human-readable report)
# -----------------------------------------------------------------------
lines = []
lines.append("# Traceability Matrix")
lines.append("")
lines.append(f"**Generated:** {datetime.now(timezone.utc).strftime('%Y-%m-%d %H:%M:%S UTC')}")
lines.append(f"**Total stories:** {len(stories)}")
lines.append(f"**Tagged stories:** {len(tagged_sids & set(stories.keys()))}")
lines.append(f"**Dark stories:** {len(dark_stories)}")
lines.append(f"**Orphan tags:** {len(orphan_tags)}")
lines.append(f"**Stale tags:** {len(stale_tags)}")
lines.append("")
lines.append("## Oracle Stats")
lines.append("")
lines.append(f"- **High** (explicit tag): {matrix['summary']['oracle_stats']['high']}")
lines.append(f"- **Medium** (file heuristic): {matrix['summary']['oracle_stats']['medium']}")
lines.append(f"- **Low** (task reference): {matrix['summary']['oracle_stats']['low']}")
lines.append("")

# Story coverage table
lines.append("## Story Coverage")
lines.append("")
lines.append("| Story | Title | Epic | BCP | WSJF | Status | Links |")
lines.append("|-------|-------|------|-----|------|--------|-------|")
for s in matrix_stories:
    lines.append(f"| {s['id']} | {s['title'][:60]} | {s['epic_id']} | {s['bcp']} | {s['wsjf']} | {s['status']} | {s['link_count']} |")
lines.append("")

# Findings
if dark_stories:
    lines.append("## Dark Stories (no code links)")
    lines.append("")
    for ds in dark_stories:
        sinfo = stories.get(ds, {})
        lines.append(f"- **{ds}**: {sinfo.get('title', 'Unknown')} (status: {dev_status.get(ds, '?')})")
    lines.append("")

if orphan_tags:
    lines.append("## Orphan Tags (tag in code, no matching story)")
    lines.append("")
    for ot in orphan_tags:
        lines.append(f"- `{ot}`")
    lines.append("")

if stale_tags:
    lines.append("## Stale Tags (story done, tag still in code)")
    lines.append("")
    for st in stale_tags:
        lines.append(f"- `{st}`")
    lines.append("")

TRACE_MD.parent.mkdir(parents=True, exist_ok=True)
TRACE_MD.write_text("\n".join(lines), encoding="utf-8")

# -----------------------------------------------------------------------
# 7. Emit OKF bundle (specs/codebase-wiki/)
# -----------------------------------------------------------------------
OKF_DIR.mkdir(parents=True, exist_ok=True)

# Generate index.md
idx_lines = []
idx_lines.append("---")
idx_lines.append("type: Index")
idx_lines.append(f"generated_at: {datetime.now(timezone.utc).isoformat()}")
idx_lines.append(f"total_concepts: {len(stories)}")
idx_lines.append("---")
idx_lines.append("")
idx_lines.append("# Codebase Wiki — Story Traceability")
idx_lines.append("")
idx_lines.append("Auto-generated OKF bundle from trace-stories.sh.")
idx_lines.append("")
idx_lines.append("| Story | Title | Confidence | Links |")
idx_lines.append("|-------|-------|------------|-------|")
for s in matrix_stories:
    confs = {l["confidence"] for l in s["links"]}
    max_conf = "high" if "high" in confs else ("medium" if "medium" in confs else ("low" if confs else "none"))
    idx_lines.append(f"| [{s['id']}](./{s['id']}.md) | {s['title'][:60]} | {max_conf} | {s['link_count']} |")
idx_lines.append("")
(OKF_DIR / "index.md").write_text("\n".join(idx_lines), encoding="utf-8")

# Generate one concept per story
for s in matrix_stories:
    concept = []
    concept.append("---")
    concept.append(f"type: Story")
    concept.append(f"id: {s['id']}")
    concept.append(f"epic: {s['epic_id']}")
    concept.append(f"bcps: {s['bcp']}")
    concept.append(f"wsjf: {s['wsjf']}")
    concept.append(f"implementation_status: {s['status']}")
    max_confs = set()
    for l in s["links"]:
        max_confs.add(l["confidence"])
    conf = "high" if "high" in max_confs else ("medium" if "medium" in max_confs else ("low" if max_confs else "none"))
    concept.append(f"coverage_status: {'covered' if s['link_count'] > 0 else 'dark'}")
    concept.append(f"confidence: {conf}")
    concept.append("links:")
    for l in s["links"]:
        concept.append(f"  - file: {l['file']}")
        concept.append(f"    line: {l['line']}")
        concept.append(f"    confidence: {l['confidence']}")
        concept.append(f"    method: {l['method']}")
    concept.append("---")
    concept.append("")
    concept.append(f"# {s['id']}: {s['title']}")
    concept.append("")
    concept.append(f"**Epic:** {s['epic_id']} — {s.get('epic_title', 'Unknown')}")
    concept.append(f"**Status:** {s['status']}")
    concept.append(f"**BCP:** {s['bcp']} | **WSJF:** {s['wsjf']}")
    concept.append("")
    if s["links"]:
        concept.append("## Implemented In")
        concept.append("")
        for l in s["links"]:
            concept.append(f"- `{l['file']}` (line {l['line']}, confidence: {l['confidence']}, method: {l['method']})")
    else:
        concept.append("*No code links found — this is a dark story.*")
    concept.append("")
    (OKF_DIR / f"{s['id']}.md").write_text("\n".join(concept), encoding="utf-8")

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
PYEOF
