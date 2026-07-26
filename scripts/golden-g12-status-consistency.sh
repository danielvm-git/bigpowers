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
import sys, re
from pathlib import Path
import yaml

specs = Path(sys.argv[1])
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

  if [[ $injected_exit -ne 0 ]]; then
    echo -e "${GREEN}PASS${NC} G-12 detected injected drift (exit $injected_exit)"
    echo "G-12 self-test: PASS"
    exit 0
  fi
  echo -e "${RED}FAIL${NC} G-12 passed on deliberately drifted specs — vacuous gate"
  echo "G-12 self-test: FAIL — same bug class as G-08 / BUG-2026-07-26-planning-sot-drift"
  exit 1
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
