#!/usr/bin/env bash
# convert-legado.sh — RELEASE-PLAN.md + SCOPE.md → YAML layout (one-time migration helper)
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SPECS="$REPO_ROOT/specs"
RP_MD="$SPECS/RELEASE-PLAN.md"
SCOPE_MD="$SPECS/SCOPE.md"
STATE_MD="$SPECS/STATE.md"

mkdir -p "$SPECS/requirements/snapshots" "$SPECS/epics" "$SPECS/archive"

if [[ ! -f "$RP_MD" ]]; then
  echo "convert-legado: no $RP_MD — skip"
  exit 0
fi

# Archive legacy MD if YAML already exists (idempotent)
archive_if_needed() {
  local src="$1"
  [[ -f "$src" ]] || return 0
  local base
  base=$(basename "$src")
  if [[ ! -f "$SPECS/archive/$base" ]]; then
    cp "$src" "$SPECS/archive/$base"
    echo "archived: specs/archive/$base"
  fi
}

# Parse ### WSn — Title · WSJF X.X from RELEASE-PLAN.md
python3 - "$RP_MD" "$SPECS" <<'PY'
import json
import re
import sys
from pathlib import Path

rp = Path(sys.argv[1])
specs = Path(sys.argv[2])
text = rp.read_text(encoding="utf-8")

version = "3.0.0"
m = re.search(r"v(\d+\.\d+\.\d+)", text)
if m:
    version = m.group(1)

epics = []
for m in re.finditer(r"^### WS(\d+)\s+—\s+(.+?)\s+·\s+WSJF\s+([\d.]+)", text, re.M):
    n, title, wsjf = m.groups()
    eid = f"e{int(n):02d}"
    slug = re.sub(r"[^a-z0-9]+", "-", title.lower()).strip("-")[:40]
    epics.append((eid, title.strip(), float(wsjf), slug))

epic_lines = []
status_lines = []
for eid, title, wsjf, slug in epics:
    fname = f"epics/{eid}-{slug}.yaml"
    tj = json.dumps(title.strip())
    epic_lines.append(
        f"  - id: {eid}\n    title: {tj}\n    wsjf: {wsjf}\n    file: {fname}\n    mode: flat"
    )
    status_lines.append(f"  {eid}: done")

    epic_path = specs / fname
    if not epic_path.exists():
        epic_path.write_text(
            f"id: {eid}\ntitle: {tj}\nwsjf: {wsjf}\ncovers: []\nstories: []\n",
            encoding="utf-8",
        )

release_yaml = f"""release:
  version: "{version}"
  codename: Consolidation
  status: in_progress
  semantic_release: true
  bump_hint: minor
epics:
{chr(10).join(epic_lines)}
"""
(specs / "release-plan.yaml").write_text(release_yaml, encoding="utf-8")

exec_yaml = "development_status:\n" + "\n".join(status_lines) + "\n"
(specs / "execution-status.yaml").write_text(exec_yaml, encoding="utf-8")
print(f"convert-legado: wrote release-plan.yaml ({len(epics)} epics) + execution-status.yaml")
PY

# state.yaml from STATE.md or default
branch=$(git -C "$REPO_ROOT" branch --show-current 2>/dev/null || echo "main")
hash=$(git -C "$REPO_ROOT" rev-parse --short HEAD 2>/dev/null || echo "unknown")

if [[ ! -f "$SPECS/state.yaml" ]]; then
  cat > "$SPECS/state.yaml" <<EOF
active_flow: build_epic
active_epic_id: e01
active_story_id: null
release:
  target_version: "3.0.0"
  last_tag: null
  last_publish: null
epic_cycle:
  current_step: null
  next_skill: survey-context
  completed_steps: []
git:
  branch: $branch
  hash: $hash
handoff:
  last_step_completed: null
  open_decisions: []
  next_skill: survey-context
EOF
  echo "convert-legado: wrote state.yaml"
fi

# requirements/SCOPE stub from SCOPE.md if missing
if [[ -f "$SCOPE_MD" && ! -f "$SPECS/requirements/SCOPE_LATEST.yaml" ]]; then
  mkdir -p "$SPECS/requirements"
  python3 - "$SCOPE_MD" "$SPECS/requirements/SCOPE_LATEST.yaml" <<'PY'
import sys
from pathlib import Path
src = Path(sys.argv[1]).read_text(encoding="utf-8")
out = Path(sys.argv[2])
# Minimal YAML wrapper — full parse is manual follow-up
body = src.replace('"', '\\"').replace("\n", "\\n")
out.write_text(
    'version: "1"\n'
    'source: specs/SCOPE.md\n'
    'migrated: true\n'
    'summary: "See specs/archive/SCOPE.md for prose; refine this file with scope-work"\n',
    encoding="utf-8",
)
print("convert-legado: wrote requirements/SCOPE_LATEST.yaml (stub)")
PY
fi

if [[ ! -f "$SPECS/requirements/VISION_LATEST.yaml" ]]; then
  mkdir -p "$SPECS/requirements"
  cat > "$SPECS/requirements/VISION_LATEST.yaml" <<'EOF'
version: "1"
north_star: "Maintain senior-grade quality while scaling agentic autonomy"
success_criteria:
  - "Compliance suite >= 94%"
  - "59 skills synced and documented"
out_of_scope:
  - "Domain-specific scaffold skills"
  - "SaaS tracker integrations"
EOF
  echo "convert-legado: wrote requirements/VISION_LATEST.yaml"
fi

archive_if_needed "$RP_MD"
archive_if_needed "$SCOPE_MD"
archive_if_needed "$STATE_MD"

bash "$REPO_ROOT/scripts/validate-specs-yaml.sh" "$SPECS"
