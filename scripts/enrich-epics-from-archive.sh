#!/usr/bin/env bash
# enrich-epics-from-archive.sh — populate specs/epics from archive RELEASE-PLAN.md
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ARCHIVE="${1:-$REPO_ROOT/specs/archive/RELEASE-PLAN.md}"
SPECS="$REPO_ROOT/specs"

python3 - "$ARCHIVE" "$SPECS" <<'PY'
import json
import re
import sys
from pathlib import Path

archive = Path(sys.argv[1])
specs = Path(sys.argv[2])
text = archive.read_text(encoding="utf-8")

epic_re = re.compile(
    r"^### WS(\d+)\s+—\s+(.+?)\s+·\s+WSJF\s+([\d.]+)\s*$", re.M
)
sections = []
for m in epic_re.finditer(text):
    start = m.end()
    nxt = epic_re.search(text, start)
    end = nxt.start() if nxt else len(text)
    sections.append((m.group(1), m.group(2).strip(), float(m.group(3)), text[start:end]))

status_lines = []
for n, title, wsjf, body in sections:
    eid = f"e{int(n):02d}"
    slug = re.sub(r"[^a-z0-9]+", "-", title.lower()).strip("-")[:40]
    fname = f"epics/{eid}-{slug}.yaml"
    epic_path = specs / fname

    tasks_raw = []
    for line in body.splitlines():
        lm = re.match(r"^-\s+\[[ xX]\]\s+(.+)$", line.strip())
        if lm:
            tasks_raw.append(lm.group(1).strip())
    verify_m = re.search(r"→\s*verify:\s*`([^`]+)`", body)
    epic_verify = verify_m.group(1) if verify_m else None

    sid = f"{eid}s01"
    story_tasks = []
    for i, t in enumerate(tasks_raw, start=1):
        tid = f"{eid}s{i:02d}" if len(tasks_raw) > 1 else sid
        story_tasks.append({"desc": t, "verify": epic_verify or "true"})
        status_lines.append(f"  {tid}: done")

    if not story_tasks and epic_verify:
        story_tasks.append({"desc": title, "verify": epic_verify})

    stories_yaml = []
    if len(story_tasks) == 1:
        stories_yaml.append(
            {
                "id": sid,
                "title": title,
                "tasks": story_tasks,
            }
        )
        status_lines.append(f"  {eid}: done")
    else:
        for i, t in enumerate(tasks_raw, start=1):
            tid = f"{eid}s{i:02d}"
            stories_yaml.append(
                {
                    "id": tid,
                    "title": t[:80],
                    "tasks": [{"desc": t, "verify": epic_verify or "true"}],
                }
            )
        status_lines.append(f"  {eid}: done")

    tj = json.dumps(title)
    lines = [
        f"id: {eid}",
        f"title: {tj}",
        f"wsjf: {wsjf}",
        "covers: []",
        "stories:",
    ]
    for st in stories_yaml:
        lines.append(f"  - id: {st['id']}")
        lines.append(f"    title: {json.dumps(st['title'])}")
        lines.append("    tasks:")
        for task in st["tasks"]:
            lines.append(f"      - desc: {json.dumps(task['desc'])}")
            lines.append(f"        verify: {json.dumps(task['verify'])}")
    epic_path.parent.mkdir(parents=True, exist_ok=True)
    epic_path.write_text("\n".join(lines) + "\n", encoding="utf-8")

exec_path = specs / "execution-status.yaml"
exec_path.write_text(
    "development_status:\n" + "\n".join(dict.fromkeys(status_lines)) + "\n",
    encoding="utf-8",
)
print(f"enrich-epics: wrote {len(sections)} epics + execution-status.yaml")
PY

bash "$REPO_ROOT/scripts/validate-specs-yaml.sh" "$SPECS"
