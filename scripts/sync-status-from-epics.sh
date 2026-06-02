#!/usr/bin/env bash
# sync-status-from-epics.sh — seed execution-status.yaml keys from epic shards
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SPECS="$REPO_ROOT/specs"
OUT="$SPECS/execution-status.yaml"
EPICS="$SPECS/epics"

python3 - "$EPICS" "$OUT" <<'PY'
import re
import sys
from pathlib import Path

epics_dir = Path(sys.argv[1])
out = Path(sys.argv[2])
keys: dict[str, str] = {}

existing_path = epics_dir.parent / "execution-status.yaml"
if existing_path.exists():
    existing = existing_path.read_text(encoding="utf-8")
    for m in re.finditer(r"^  ([a-z0-9._-]+):\s*(\S+)", existing, re.M):
        keys[m.group(1)] = m.group(2)

for epic_file in sorted(epics_dir.glob("e*.yaml")):
    text = epic_file.read_text(encoding="utf-8")
    em = re.search(r"^id:\s*(e\d+)", text, re.M)
    if em:
        eid = em.group(1)
        keys.setdefault(eid, "backlog")
    for sm in re.finditer(r"^\s+- id:\s*(e\d+s\d+)", text, re.M):
        keys.setdefault(sm.group(1), "backlog")

for folder in sorted(epics_dir.glob("e*/")):
    epic_yaml = folder / "epic.yaml"
    if epic_yaml.exists():
        text = epic_yaml.read_text(encoding="utf-8")
        em = re.search(r"^id:\s*(e\d+)", text, re.M)
        if em:
            keys.setdefault(em.group(1), "backlog")
    for story in (folder / "stories").glob("e*s*.md"):
        m = re.match(r"(e\d+s\d+)", story.name)
        if m:
            keys.setdefault(m.group(1), "backlog")

lines = ["development_status:"]
for k in sorted(keys.keys()):
    lines.append(f"  {k}: {keys[k]}")
lines.append("")
out.write_text("\n".join(lines), encoding="utf-8")
print(f"sync-status-from-epics: wrote {out} ({len(keys)} keys)")
PY
