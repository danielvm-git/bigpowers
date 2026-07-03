#!/usr/bin/env bash
# story: e38s04
# check-blind-spots.sh — TEA-inspired heuristic blind-spot detector
# Reads execution-status.yaml + traceability-matrix.json, runs 6 structural
# quality checks beyond percentage coverage, and emits specs/blind-spots.json.
#
# Checks:
#   a. verify-gap       — story done but no verification evidence
#   b. test-gap          — code tagged but no test file references
#   c. epic-orphan       — capsule task with no story tag anywhere
#   d. stale-tag         — story done but tag still in code
#   e. double-tag        — same file tagged with multiple stories
#   f. bootstrap-testless — new story without test-related tag or files
#
# Severities: HIGH / MEDIUM / LOW
#
# Usage:
#   bash scripts/check-blind-spots.sh            # full scan, emit JSON
#   bash scripts/check-blind-spots.sh --help     # this message
#
# Exit codes:
#   0 — no HIGH-severity findings
#   1 — one or more HIGH-severity findings (or input files missing)

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BLIND_SPOTS_JSON="$REPO_ROOT/specs/blind-spots.json"
EXEC_STATUS="$REPO_ROOT/specs/execution-status.yaml"
MATRIX_JSON="$REPO_ROOT/specs/traceability-matrix.json"
VERIFICATIONS_DIR="$REPO_ROOT/specs/verifications"
EPICS_DIR="$REPO_ROOT/specs/epics"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --help|-h)
      cat <<'USAGE'
Usage: check-blind-spots.sh [flags]

Run 6 heuristic blind-spot checks on the codebase.

Flags:
  --help   Print this message and exit.

Checks:
  verify-gap        Story done, no verify evidence.
  test-gap          Code tagged, no test file references.
  epic-orphan       Capsule task with no story tag.
  stale-tag         Done story, tag still in code.
  double-tag        File tagged with multiple stories.
  bootstrap-testless New story without test coverage.

Output: specs/blind-spots.json

Exit codes:
  0  No HIGH-severity findings.
  1  One or more HIGH-severity findings (or input files missing).
USAGE
      exit 0
      ;;
    *)
      echo "check-blind-spots.sh: unknown flag: $1" >&2
      echo "Try --help for usage." >&2
      exit 1
      ;;
  esac
done

# ---------------------------------------------------------------------------
# Input existence checks
# ---------------------------------------------------------------------------
if [[ ! -f "$EXEC_STATUS" ]]; then
  echo "check-blind-spots.sh: execution-status.yaml: not found at $EXEC_STATUS" >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# Detector logic (Python stdlib only)
# ---------------------------------------------------------------------------
python3 - "$REPO_ROOT" "$BLIND_SPOTS_JSON" "$EXEC_STATUS" "$MATRIX_JSON" "$VERIFICATIONS_DIR" "$EPICS_DIR" <<'PYEOF'
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

# -----------------------------------------------------------------------
# Parse execution-status.yaml → flat dict of story_id → status
# -----------------------------------------------------------------------
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
            # Stop if we hit another top-level key
            if stripped and not stripped.startswith(" ") and not stripped.startswith("#"):
                if ":" in stripped:
                    in_dev_status = False
            continue
        if ":" in stripped and not stripped.startswith("#"):
            # Lines like '  e38s04: "done"'
            m = re.match(r'\s+(\S+):\s*"([^"]*)"', stripped)
            if m:
                status[m.group(1)] = m.group(2)
    return status

dev_status = parse_exec_status(EXEC_STATUS)

# -----------------------------------------------------------------------
# Read traceability matrix (if available)
# -----------------------------------------------------------------------
matrix_data: dict | None = None
if MATRIX_JSON.exists():
    matrix_data = json.loads(MATRIX_JSON.read_text(encoding="utf-8"))

# Build indexes from matrix
tagged_files: dict[str, list[str]] = {}  # story_id → [files]
file_story_counts: dict[str, set[str]] = {}  # file → set of story_ids
if matrix_data:
    for s in matrix_data.get("stories", []):
        sid = s["id"]
        for link in s.get("links", []):
            f = link["file"]
            tagged_files.setdefault(sid, []).append(f)
            file_story_counts.setdefault(f, set()).add(sid)

# Enumerate all tracked code files (skip .git, node_modules, specs/)
CODE_EXTENSIONS = {".sh", ".py", ".js", ".ts", ".jsx", ".tsx", ".md", ".yaml", ".yml", ".cjs", ".mjs", ".json"}
SKIP_DIRS = {".git", "node_modules", ".cursor", ".gemini", ".pi", "specs", "dist", "build", "__pycache__", ".bigpowers"}

def is_code_file(p: Path) -> bool:
    return p.suffix in CODE_EXTENSIONS and not any(s in p.parts for s in SKIP_DIRS)

all_code_files: list[str] = []
for root, dirs, files in os.walk(str(ROOT)):
    # Prune skip dirs
    dirs[:] = [d for d in dirs if d not in SKIP_DIRS]
    rel_root = str(Path(root).relative_to(ROOT))
    for fname in files:
        fpath = Path(root) / fname
        if is_code_file(fpath):
            all_code_files.append(str(fpath.relative_to(ROOT)))

# -----------------------------------------------------------------------
# Helper: find test files for a given code file
# -----------------------------------------------------------------------
TEST_PATTERNS = [
    re.compile(r"(^|/)test(s)?/", re.IGNORECASE),
    re.compile(r"(^|/)__tests__/", re.IGNORECASE),
    re.compile(r"\.test\.", re.IGNORECASE),
    re.compile(r"\.spec\.", re.IGNORECASE),
    re.compile(r"_test\.", re.IGNORECASE),
    re.compile(r"test_", re.IGNORECASE),
]

def has_test_files(code_files: list[str]) -> bool:
    """Check if any file in the repo looks like a test for the given code files."""
    for cf in code_files:
        cf_path = Path(cf)
        cf_dir = cf_path.parent
        cf_stem = cf_path.stem
        for tf in all_code_files:
            tp = Path(tf)
            # Same directory test file
            if tp.parent == cf_dir:
                for pat in TEST_PATTERNS:
                    if pat.search(tp.name) and cf_stem in tp.name:
                        return True
            # Tests dir sibling
            test_dir_names = ["tests", "test", "__tests__"]
            for tdn in test_dir_names:
                test_dir = cf_dir / tdn
                if str(test_dir) in tf:
                    if cf_stem in tp.name:
                        return True
    return False

# -----------------------------------------------------------------------
# Check A: verify-gap — story done but no verify evidence
# -----------------------------------------------------------------------
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

# -----------------------------------------------------------------------
# Check B: test-gap — code tagged but no test file references
# -----------------------------------------------------------------------
for sid, files in tagged_files.items():
    if dev_status.get(sid) in ("done", "active"):
        if not has_test_files(files):
            # Only flag if there are actual code files (not just docs)
            code_only = [f for f in files if Path(f).suffix in {".sh", ".py", ".js", ".ts", ".jsx", ".tsx"} and "SKILL.md" not in f]
            if code_only:
                findings.append({
                    "check": "test-gap",
                    "story_id": sid,
                    "severity": "MEDIUM",
                    "description": f"Story {sid} has {len(code_only)} tagged code file(s) with no matching test files",
                    "remediation": f"Add test coverage for the tagged files: {', '.join(code_only[:3])}"
                })

# -----------------------------------------------------------------------
# Check C: epic-orphan — capsule task with no story tag in any code file
# -----------------------------------------------------------------------
if EPICS_DIR.exists():
    for epic_dir in sorted(EPICS_DIR.iterdir()):
        if not epic_dir.is_dir() or epic_dir.name == "archive":
            continue
        epic_yaml = epic_dir / "epic.yaml"
        if not epic_yaml.exists():
            continue
        # Extract story IDs from epic capsule task files
        for task_file in sorted(epic_dir.glob("e*[0-9]-tasks.yaml")):
            # e.g., e38s04-tasks.yaml → e38s04
            sid_match = re.match(r"(e\d+s\d+)", task_file.name)
            if not sid_match:
                continue
            sid = sid_match.group(1)
            # Check if story has any tagged files (explicit or heuristic)
            sstatus = dev_status.get(sid, "backlog")
            if sstatus in ("done", "active") and sid not in tagged_files:
                findings.append({
                    "check": "epic-orphan",
                    "story_id": sid,
                    "severity": "LOW",
                    "description": f"Story {sid} has capsule tasks but no story tags found in any code file",
                    "remediation": f"Add `// story: {sid}` tags to implementing files"
                })

# -----------------------------------------------------------------------
# Check D: stale-tag — story done but tag still in code
# -----------------------------------------------------------------------
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

# -----------------------------------------------------------------------
# Check E: double-tag — same file tagged with multiple stories
# -----------------------------------------------------------------------
for fpath, sids in file_story_counts.items():
    if len(sids) > 1:
        findings.append({
            "check": "double-tag",
            "file": fpath,
            "severity": "MEDIUM",
            "description": f"File '{fpath}' is tagged with multiple stories: {', '.join(sorted(sids))}",
            "remediation": "Review whether this file genuinely implements multiple stories. If it's a shared utility, this is acceptable."
        })

# -----------------------------------------------------------------------
# Check F: bootstrap-testless — new story (active/recent) without test evidence
# -----------------------------------------------------------------------
recent_threshold = 5  # flag active/done stories in the last 5 stories if no tests
active_and_recent = []
for sid in sorted(dev_status.keys()):
    if dev_status[sid] in ("active",):
        active_and_recent.append(sid)

for sid in active_and_recent:
    # Check if story has tagged code AND no test files for those
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

# -----------------------------------------------------------------------
# De-duplicate findings (same check + story_id)
# -----------------------------------------------------------------------
seen: set[tuple] = set()
deduped: list[dict] = []
for f in findings:
    key = (f["check"], f.get("story_id", f.get("file", "")))
    if key not in seen:
        seen.add(key)
        deduped.append(f)
findings = deduped

# -----------------------------------------------------------------------
# Emit blind-spots.json
# -----------------------------------------------------------------------
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

# Print summary to stdout
print(f"check-blind-spots.sh: {len(findings)} findings ({high_count} HIGH, {medium_count} MEDIUM, {low_count} LOW)")
for f in findings:
    print(f"  [{f['severity']}] {f['check']}: {f['description'][:100]}")

if high_count > 0:
    print(f"\n⚠️  {high_count} HIGH-severity finding(s) — review specs/blind-spots.json")
    sys.exit(1)

sys.exit(0)
PYEOF
