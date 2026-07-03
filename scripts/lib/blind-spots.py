#!/usr/bin/env python3
"""story: e38s04 — TEA-inspired heuristic blind-spot detector (Python engine).

Reads execution-status.yaml + traceability-matrix.json, runs 6 structural
quality checks, and emits specs/blind-spots.json.

Usage: called by scripts/check-blind-spots.sh with positional args:
  python3 scripts/lib/blind-spots.py <repo_root> <blind_spots_json>
      <exec_status_yaml> <matrix_json> <verifications_dir> <epics_dir>
"""

import json, os, re, sys
from pathlib import Path
from datetime import datetime, timezone

ROOT = Path(sys.argv[1])
BLIND_SPOTS_JSON = Path(sys.argv[2])
EXEC_STATUS = Path(sys.argv[3])
MATRIX_JSON = Path(sys.argv[4])
VERIFICATIONS_DIR = Path(sys.argv[5])
EPICS_DIR = Path(sys.argv[6])

findings: list[dict] = []

def parse_exec_status(path: Path) -> dict[str, str]:
    status: dict[str, str] = {}
    if not path.exists():
        return status
    text = path.read_text(encoding="utf-8")
    lines = text.splitlines()
    in_dev_status = False
    for line in lines:
        stripped = line.strip()
        if stripped.startswith("development_status:"):
            in_dev_status = True
            continue
        if not in_dev_status:
            if stripped and not stripped.startswith(" ") and not stripped.startswith("#"):
                if ":" in stripped:
                    in_dev_status = False
            continue
        if ":" in stripped and not stripped.startswith("#"):
            m = re.match(r'\s+(\S+):\s*"([^"]*)"', stripped)
            if m:
                status[m.group(1)] = m.group(2)
    return status

dev_status = parse_exec_status(EXEC_STATUS)

matrix_data: dict | None = None
if MATRIX_JSON.exists():
    matrix_data = json.loads(MATRIX_JSON.read_text(encoding="utf-8"))

tagged_files: dict[str, list[str]] = {}
file_story_counts: dict[str, set[str]] = {}
if matrix_data:
    for s in matrix_data.get("stories", []):
        sid = s["id"]
        for link in s.get("links", []):
            f = link["file"]
            tagged_files.setdefault(sid, []).append(f)
            file_story_counts.setdefault(f, set()).add(sid)

CODE_EXTENSIONS = {".sh", ".py", ".js", ".ts", ".jsx", ".tsx", ".md", ".yaml", ".yml", ".cjs", ".mjs", ".json"}
SKIP_DIRS = {".git", "node_modules", ".cursor", ".gemini", ".pi", "specs", "dist", "build", "__pycache__", ".bigpowers"}

def is_code_file(p: Path) -> bool:
    return p.suffix in CODE_EXTENSIONS and not any(s in p.parts for s in SKIP_DIRS)

all_code_files: list[str] = []
for root, dirs, files in os.walk(str(ROOT)):
    dirs[:] = [d for d in dirs if d not in SKIP_DIRS]
    rel_root = str(Path(root).relative_to(ROOT))
    for fname in files:
        fpath = Path(root) / fname
        if is_code_file(fpath):
            all_code_files.append(str(fpath.relative_to(ROOT)))

TEST_PATTERNS = [
    re.compile(r"(^|/)test(s)?/", re.IGNORECASE),
    re.compile(r"(^|/)__tests__/", re.IGNORECASE),
    re.compile(r"\.test\.", re.IGNORECASE),
    re.compile(r"\.spec\.", re.IGNORECASE),
    re.compile(r"_test\.", re.IGNORECASE),
    re.compile(r"test_", re.IGNORECASE),
]

def has_test_files(code_files: list[str]) -> bool:
    for cf in code_files:
        cf_path = Path(cf)
        cf_dir = cf_path.parent
        cf_stem = cf_path.stem
        for tf in all_code_files:
            tp = Path(tf)
            if tp.parent == cf_dir:
                for pat in TEST_PATTERNS:
                    if pat.search(tp.name) and cf_stem in tp.name:
                        return True
            for tdn in ["tests", "test", "__tests__"]:
                test_dir = cf_dir / tdn
                if str(test_dir) in tf:
                    if cf_stem in tp.name:
                        return True
    return False

# Check A: verify-gap
for sid, sstatus in dev_status.items():
    if sstatus == "done":
        verify_file = VERIFICATIONS_DIR / f"{sid}-verify.yaml"
        if not verify_file.exists():
            findings.append({
                "check": "verify-gap",
                "story_id": sid,
                "severity": "HIGH",
                "description": f"Story {sid} is marked done but no verification evidence exists at specs/verifications/{sid}-verify.yaml",
                "remediation": f"Run verify-work for {sid} or create the verification evidence file"
            })

# Check B: test-gap
for sid, files in tagged_files.items():
    if dev_status.get(sid) in ("done", "active"):
        if not has_test_files(files):
            code_only = [f for f in files if Path(f).suffix in {".sh", ".py", ".js", ".ts", ".jsx", ".tsx"} and "SKILL.md" not in f]
            if code_only:
                findings.append({
                    "check": "test-gap",
                    "story_id": sid,
                    "severity": "MEDIUM",
                    "description": f"Story {sid} has {len(code_only)} tagged code file(s) with no matching test files",
                    "remediation": f"Add test coverage for the tagged files: {', '.join(code_only[:3])}"
                })

# Check C: epic-orphan
if EPICS_DIR.exists():
    for epic_dir in sorted(EPICS_DIR.iterdir()):
        if not epic_dir.is_dir() or epic_dir.name == "archive":
            continue
        epic_yaml = epic_dir / "epic.yaml"
        if not epic_yaml.exists():
            continue
        for task_file in sorted(epic_dir.glob("e*[0-9]-tasks.yaml")):
            sid_match = re.match(r"(e\d+s\d+)", task_file.name)
            if not sid_match:
                continue
            sid = sid_match.group(1)
            sstatus = dev_status.get(sid, "backlog")
            if sstatus in ("done", "active") and sid not in tagged_files:
                findings.append({
                    "check": "epic-orphan",
                    "story_id": sid,
                    "severity": "LOW",
                    "description": f"Story {sid} has capsule tasks but no story tags found in any code file",
                    "remediation": f"Add `// story: {sid}` tags to implementing files"
                })

# Check D: stale-tag
stale_from_matrix: set[str] = set()
if matrix_data:
    stale_from_matrix = set(matrix_data.get("summary", {}).get("stale_tags", []))

for sid in stale_from_matrix:
    findings.append({
        "check": "stale-tag",
        "story_id": sid,
        "severity": "LOW",
        "description": f"Story {sid} is marked done but still has story tags in code",
        "remediation": f"Remove `// story: {sid}` tags from files or confirm the story should remain done"
    })

# Check E: double-tag
for fpath, sids in file_story_counts.items():
    if len(sids) > 1:
        findings.append({
            "check": "double-tag",
            "file": fpath,
            "severity": "MEDIUM",
            "description": f"File '{fpath}' is tagged with multiple stories: {', '.join(sorted(sids))}",
            "remediation": "Review whether this file genuinely implements multiple stories. If it's a shared utility, this is acceptable."
        })

# Check F: bootstrap-testless
for sid in sorted(dev_status.keys()):
    if dev_status[sid] in ("active",):
        if sid in tagged_files:
            code_files = tagged_files[sid]
            code_only = [f for f in code_files if Path(f).suffix in {".sh", ".py", ".js", ".ts", ".jsx", ".tsx"} and "SKILL.md" not in f]
            if code_only and not has_test_files(code_files):
                findings.append({
                    "check": "bootstrap-testless",
                    "story_id": sid,
                    "severity": "HIGH",
                    "description": f"Active story {sid} has {len(code_only)} tagged code file(s) but no test files detected",
                    "remediation": f"Add test files for: {', '.join(code_only[:3])}"
                })

# Deduplicate
seen: set[tuple] = set()
deduped: list[dict] = []
for f in findings:
    key = (f["check"], f.get("story_id", f.get("file", "")))
    if key not in seen:
        seen.add(key)
        deduped.append(f)
findings = deduped

# Emit blind-spots.json
high_count = sum(1 for f in findings if f["severity"] == "HIGH")
medium_count = sum(1 for f in findings if f["severity"] == "MEDIUM")
low_count = sum(1 for f in findings if f["severity"] == "LOW")

blind_spots = {
    "generated_at": datetime.now(timezone.utc).isoformat(),
    "version": "1.0",
    "summary": {
        "total_findings": len(findings),
        "high": high_count,
        "medium": medium_count,
        "low": low_count
    },
    "findings": findings
}

BLIND_SPOTS_JSON.parent.mkdir(parents=True, exist_ok=True)
BLIND_SPOTS_JSON.write_text(json.dumps(blind_spots, indent=2), encoding="utf-8")

print(f"check-blind-spots.sh: {len(findings)} findings ({high_count} HIGH, {medium_count} MEDIUM, {low_count} LOW)")
for f in findings:
    print(f"  [{f['severity']}] {f['check']}: {f['description'][:100]}")

if high_count > 0:
    print(f"\n⚠️  {high_count} HIGH-severity finding(s) — review specs/blind-spots.json")
    sys.exit(1)

sys.exit(0)
