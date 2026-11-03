#!/usr/bin/env bash
# story: e51s04
# golden-g12-status-consistency.sh — Planning SoT Consistency Gate (G-12)
#
# CONVENTIONS.md § specs/ declares specs/execution-status.yaml the sole SoT for
# story state. Nothing enforced that. sync-status-from-epics.sh is a *seeder*:
# it preloads keys from execution-status.yaml itself and uses setdefault(), so
# an existing key keeps its old value and epic.yaml's stories[].status is never
# read. Story status written by build-epic step 8 into a capsule could therefore
# disagree with the SoT forever, undetected
# (BUG-2026-07-26-planning-sot-drift).
#
# This gate makes the two agree or fails.
#
# Authority model (CONVENTIONS.md § specs/): execution-status.yaml is the sole
# SoT for story state; a capsule's stories[].status is derived. Capsules under
# specs/epics/archive/ are frozen historical records — an archived shard that
# still reads 'todo' while the SoT reads 'done' is normal history, not drift, so
# archive/ is excluded. Status vocabulary is normalised before comparison
# ('passing' == 'done'; 'todo'/'planned'/'not-started' == 'backlog').
#
# Checks:
#   1. A LIVE capsule must not disagree with execution-status.yaml (both the
#      stories: and development_status: sections). In practice this catches a
#      capsule marked done by build-epic step 8 whose SoT was never updated.
#   2. Every capsule_dir in release-plan.yaml must resolve to a real directory.
#   3. A live capsule must not also exist under archive/ — two shards for one
#      epic makes "which status is authoritative" undecidable.
#   4. A live epic's own status must agree across development_status, epics:,
#      release-plan.yaml and epic.yaml, and match its stories: all stories
#      done means the epic is done, and a done epic has no open story.
#   5. Tracked source tagged `story: <id>` for a live story the SoT still calls
#      backlog is shipped work that was never recorded.
#   Checks 4-5: BUG-2026-11-03-epic-status-rollup-drift.
#
# Usage: bash scripts/golden-g12-status-consistency.sh [--self-test]
# Exit 0: SoT is consistent
# Exit 1: drift detected (or, under --self-test, the gate failed to detect
#         deliberately injected drift — a vacuous gate, G-08 bug class)

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/python-env.sh"
source "$(dirname "${BASH_SOURCE[0]}")/lib/skill-common.sh"
resolve_repo_root

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

SELF_TEST=0
[[ "${1:-}" == "--self-test" ]] && SELF_TEST=1

check_tree() {
  # $1 = specs dir to check
  $PYTHON - "$1" <<'PY'
import sys, re, subprocess
from pathlib import Path
import yaml

specs = Path(sys.argv[1])
repo = specs.parent
epics_dir = specs / "epics"
exec_path = specs / "execution-status.yaml"
rp_path = specs / "release-plan.yaml"

problems = []
archived_skipped = 0

# Status vocabulary normalisation — different skills have written different
# words for the same state over the repo's history.
ALIASES = {
    "passing": "done",
    "complete": "done",
    "completed": "done",
    "todo": "backlog",
    "planned": "backlog",
    "not-started": "backlog",
}


def norm(v):
    return ALIASES.get(str(v).strip().lower(), str(v).strip().lower())


exec_data = yaml.safe_load(exec_path.read_text(encoding="utf-8")) or {}
dev = exec_data.get("development_status") or {}
stories = exec_data.get("stories") or {}

# --- Check 1: LIVE epic.yaml story status vs execution-status.yaml ---
for epic_file in sorted(epics_dir.rglob("epic.yaml")):
    rel = epic_file.relative_to(specs)
    if "archive" in epic_file.relative_to(epics_dir).parts:
        archived_skipped += 1
        continue

    try:
        ed = yaml.safe_load(epic_file.read_text(encoding="utf-8")) or {}
    except Exception as exc:
        problems.append(f"unparseable epic shard {rel}: {exc}")
        continue

    for story in ed.get("stories") or []:
        if not isinstance(story, dict):
            continue
        sid = story.get("id")
        declared = story.get("status")
        if not sid or not declared:
            continue
        if not re.match(r"^e\d+s\d+$", str(sid)):
            continue

        sot_detail = stories.get(sid, {})
        sot_detail = sot_detail.get("status") if isinstance(sot_detail, dict) else None
        sot_summary = dev.get(sid)

        if sot_detail is not None and norm(sot_detail) != norm(declared):
            problems.append(
                f"{sid}: {rel} says '{declared}' but execution-status.yaml "
                f"stories.{sid}.status says '{sot_detail}'"
            )
        if sot_summary is not None and norm(sot_summary) != norm(declared):
            problems.append(
                f"{sid}: {rel} says '{declared}' but execution-status.yaml "
                f"development_status.{sid} says '{sot_summary}'"
            )

# --- Check 2: release-plan.yaml capsule_dir resolves ---
if rp_path.exists():
    rp = yaml.safe_load(rp_path.read_text(encoding="utf-8")) or {}
    for ep in rp.get("epics") or []:
        if not isinstance(ep, dict):
            continue
        cd = ep.get("capsule_dir")
        if cd and not (specs / cd).is_dir():
            problems.append(
                f"{ep.get('id')}: release-plan.yaml capsule_dir '{cd}' does not exist"
            )

# --- Check 3: no epic has both a live and an archived capsule ---
archive_dir = epics_dir / "archive"
if archive_dir.is_dir():
    live = {p.name for p in epics_dir.iterdir() if p.is_dir() and p.name != "archive"}
    for p in archive_dir.iterdir():
        if p.is_dir() and p.name in live:
            problems.append(
                f"{p.name}: capsule exists both live and under archive/ — "
                f"authoritative status is undecidable"
            )

# --- Check 4: epic status agrees across files and with its stories ---
# release-plan.yaml says 'scoped' and 'released' where execution-status.yaml
# says 'backlog' and 'done' (BUG-2026-11-03-epic-status-rollup-drift).
EPIC_ALIASES = {"scoped": "backlog", "released": "done"}


def epic_norm(v):
    n = norm(v)
    return EPIC_ALIASES.get(n, n)


rp_status = {}
if rp_path.exists():
    for ep in (yaml.safe_load(rp_path.read_text(encoding="utf-8")) or {}).get("epics") or []:
        if isinstance(ep, dict) and ep.get("id"):
            rp_status[ep["id"]] = ep.get("status")
epic_sections = exec_data.get("epics") or {}
live_story_status = {}

for epic_file in sorted(epics_dir.rglob("epic.yaml")):
    if "archive" in epic_file.relative_to(epics_dir).parts:
        continue
    ed = yaml.safe_load(epic_file.read_text(encoding="utf-8")) or {}
    eid = str(ed.get("id") or "")
    if not re.match(r"^e\d+$", eid):
        continue
    detail = epic_sections.get(eid)
    sources = {
        "development_status": dev.get(eid),
        "epics": detail.get("status") if isinstance(detail, dict) else None,
        "release-plan.yaml": rp_status.get(eid),
        str(epic_file.relative_to(specs)): ed.get("status"),
    }
    seen = {k: v for k, v in sources.items() if v}
    if len({epic_norm(v) for v in seen.values()}) > 1:
        problems.append(
            f"{eid}: epic status disagrees — "
            + ", ".join(f"{k}={v}" for k, v in seen.items())
        )

    sids = [
        str(s["id"]) for s in ed.get("stories") or []
        if isinstance(s, dict) and re.match(r"^e\d+s\d+$", str(s.get("id", "")))
    ]
    for sid in sids:
        if dev.get(sid) is not None:
            live_story_status[sid] = norm(dev[sid])
    states = [live_story_status.get(sid) for sid in sids]
    if not sids or None in states or not dev.get(eid):
        continue
    all_done = all(st == "done" for st in states)
    epic_sot = epic_norm(dev[eid])
    if all_done and epic_sot != "done":
        problems.append(
            f"{eid}: all {len(sids)} stories are done in execution-status.yaml "
            f"but the epic is '{dev[eid]}'"
        )
    if epic_sot == "done" and not all_done:
        open_ids = [sid for sid, st in zip(sids, states) if st != "done"]
        problems.append(f"{eid}: epic is done but {', '.join(open_ids)} are not")

# --- Check 5: tracked source tagged with a story the SoT calls backlog ---
# A story whose code shipped outside build-epic (e82, PR #118) stays 'backlog'
# in every status file, so the agreement checks above cannot see it.


def source_files():
    if (repo / ".git").exists():
        listed = subprocess.run(
            ["git", "-C", str(repo), "ls-files"], capture_output=True, text=True
        ).stdout.splitlines()
        paths = [repo / p for p in listed]
    else:
        paths = [p for p in repo.rglob("*") if p.is_file()]
    for p in paths:
        top = p.relative_to(repo).parts[0]
        # specs/ holds plans, dot-dirs and website/ hold generated copies.
        if top.startswith(".") or top in ("specs", "website", "node_modules"):
            continue
        yield p


backlog = {sid for sid, st in live_story_status.items() if st == "backlog"}
tagged = {}
for path in source_files() if backlog else ():
    try:
        text = path.read_text(encoding="utf-8", errors="ignore")
    except OSError:
        continue
    for line in re.findall(r"story:[^\n]*", text):
        for sid in re.findall(r"\be\d+s\d+\b", line):
            if sid in backlog:
                tagged.setdefault(sid, path.relative_to(repo))
for sid, path in sorted(tagged.items()):
    problems.append(
        f"{sid}: execution-status.yaml says backlog but {path} carries its "
        f"story tag — shipped work never recorded"
    )

if archived_skipped:
    print(f"  info: {archived_skipped} archived capsule(s) skipped (frozen history)")

if problems:
    for p in problems:
        print(f"  DRIFT {p}")
    print(f"\n{len(problems)} inconsistencies")
    sys.exit(1)

print("  ok  : epic shards, execution-status.yaml and release-plan.yaml agree")
sys.exit(0)
PY
}

if [[ "$SELF_TEST" -eq 1 ]]; then
  echo "=== G-12 self-test: prove the gate can fail ==="
  TMP=$(mktemp -d)
  trap 'rm -rf "$TMP"' EXIT
  # Copy only what check_tree reads — specs/ as a whole is ~28MB and the copy
  # would dominate the gate's runtime.
  mkdir -p "$TMP/specs"
  cp -R "$REPO_ROOT/specs/epics" "$TMP/specs/epics"
  cp "$REPO_ROOT/specs/execution-status.yaml" "$TMP/specs/"
  cp "$REPO_ROOT/specs/release-plan.yaml" "$TMP/specs/"

  # Inject drift into a LIVE capsule. Archived shards are excluded from the
  # check, so mutating one would prove nothing — the gate would rightly stay
  # silent and the self-test would report a false vacuity failure.
  $PYTHON - "$TMP/specs" <<'PY'
import sys, re
from pathlib import Path
import yaml

specs = Path(sys.argv[1])
epics_dir = specs / "epics"
exec_path = specs / "execution-status.yaml"
data = yaml.safe_load(exec_path.read_text(encoding="utf-8")) or {}

for epic_file in sorted(epics_dir.rglob("epic.yaml")):
    if "archive" in epic_file.relative_to(epics_dir).parts:
        continue
    ed = yaml.safe_load(epic_file.read_text(encoding="utf-8")) or {}
    for story in ed.get("stories") or []:
        if not isinstance(story, dict):
            continue
        sid, st = story.get("id"), story.get("status")
        if sid and st and re.match(r"^e\d+s\d+$", str(sid)):
            flipped = "backlog" if st != "backlog" else "done"
            data.setdefault("stories", {}).setdefault(sid, {})["status"] = flipped
            data.setdefault("development_status", {})[sid] = flipped
            exec_path.write_text(
                yaml.dump(data, default_flow_style=False, sort_keys=False),
                encoding="utf-8",
            )
            print(f"injected: {sid} {st} -> {flipped} (live capsule)")
            sys.exit(0)
print("ERROR: no live story with a status found to mutate", file=sys.stderr)
sys.exit(2)
PY

  set +e
  check_tree "$TMP/specs" >/dev/null 2>&1
  injected_exit=$?
  set -e

  if [[ $injected_exit -eq 0 ]]; then
    echo -e "${RED}FAIL${NC} G-12 passed on deliberately drifted specs — vacuous gate"
    echo "G-12 self-test: FAIL — same bug class as G-08 / BUG-2026-07-26-planning-sot-drift"
    exit 1
  fi
  echo -e "${GREEN}PASS${NC} G-12 detected injected story drift (exit $injected_exit)"

  # Checks 4 and 5 (BUG-2026-11-03-epic-status-rollup-drift) each get a fresh
  # copy and must fail with their own message, so one check firing cannot
  # hide the other being vacuous.
  for case in rollup tagged; do
    CASE_DIR="$TMP/$case"
    mkdir -p "$CASE_DIR/specs"
    cp -R "$REPO_ROOT/specs/epics" "$CASE_DIR/specs/epics"
    cp "$REPO_ROOT/specs/execution-status.yaml" "$REPO_ROOT/specs/release-plan.yaml" "$CASE_DIR/specs/"
    $PYTHON - "$CASE_DIR" "$case" <<'PY' || exit 1
import sys, re
from pathlib import Path
import yaml

root, case = Path(sys.argv[1]), sys.argv[2]
exec_path = root / "specs" / "execution-status.yaml"
data = yaml.safe_load(exec_path.read_text(encoding="utf-8")) or {}
dev = data.setdefault("development_status", {})

for epic_file in sorted((root / "specs" / "epics").glob("*/epic.yaml")):
    ed = yaml.safe_load(epic_file.read_text(encoding="utf-8")) or {}
    eid = str(ed.get("id") or "")
    stories = [s for s in ed.get("stories") or [] if isinstance(s, dict) and s.get("id")]
    if not stories or any(dev.get(s["id"]) != "done" for s in stories):
        continue
    if case == "rollup":
        dev[eid] = "backlog"
        print(f"injected: {eid} -> backlog with all stories done")
    else:
        sid = stories[0]["id"]
        dev[sid] = "backlog"
        if isinstance((data.get("stories") or {}).get(sid), dict):
            data["stories"][sid]["status"] = "backlog"
        stories[0]["status"] = "backlog"
        epic_file.write_text(yaml.dump(ed, sort_keys=False), encoding="utf-8")
        (root / "scripts").mkdir(exist_ok=True)
        (root / "scripts" / "shipped.sh").write_text(f"# story: {sid}\n", encoding="utf-8")
        print(f"injected: {sid} -> backlog with a tagged source file")
    exec_path.write_text(yaml.dump(data, default_flow_style=False, sort_keys=False), encoding="utf-8")
    sys.exit(0)
print("ERROR: no live epic with every story done found to mutate", file=sys.stderr)
sys.exit(2)
PY
    expect="all [0-9]+ stories are done"
    [[ "$case" == "tagged" ]] && expect="carries its story tag"
    set +e
    case_out=$(check_tree "$CASE_DIR/specs" 2>&1)
    set -e
    if ! grep -qE "$expect" <<<"$case_out"; then
      echo -e "${RED}FAIL${NC} G-12 missed injected $case drift — vacuous check"
      echo "G-12 self-test: FAIL — same bug class as G-08 / BUG-2026-11-03-epic-status-rollup-drift"
      exit 1
    fi
    echo -e "${GREEN}PASS${NC} G-12 detected injected $case drift"
  done
  echo "G-12 self-test: PASS"
  exit 0
fi

echo "=== G-12: Planning SoT Consistency ==="
set +e
output=$(check_tree "$REPO_ROOT/specs" 2>&1)
actual_exit=$?
set -e
echo "$output"

if [[ $actual_exit -eq 0 ]]; then
  echo -e "${GREEN}PASS${NC} planning SoT is consistent"
  echo "G-12: PASS"
  exit 0
fi
echo -e "${RED}FAIL${NC} planning SoT has drifted"
echo "G-12: FAIL — see BUG-2026-07-26-planning-sot-drift"
exit 1
