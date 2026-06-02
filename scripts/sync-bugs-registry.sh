#!/usr/bin/env bash
# sync-bugs-registry.sh — rebuild specs/bugs/registry.yaml from BUG-*.md frontmatter
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUGS="$REPO_ROOT/specs/bugs"
mkdir -p "$BUGS"

python3 - "$BUGS" <<'PY'
import re
import sys
from pathlib import Path

bugs_dir = Path(sys.argv[1])
entries = []
for path in sorted(bugs_dir.glob("BUG-*.md")):
    text = path.read_text(encoding="utf-8")
    if not text.startswith("---"):
        continue
    end = text.find("---", 3)
    if end < 0:
        continue
    fm = text[3:end]
    data = {}
    for line in fm.splitlines():
        if ":" not in line:
            continue
        k, _, v = line.partition(":")
        data[k.strip()] = v.strip().strip('"').strip("'")
    bug_id = data.get("bug_id") or path.stem
    entry = {
        "id": bug_id,
        "status": data.get("status", "open"),
        "severity": data.get("severity", "medium"),
        "scope": data.get("scope", "general"),
        "title": data.get("title", path.stem),
        "file": f"bugs/{path.name}",
    }
    for opt in ("files_changed", "approach", "risk_level", "commit_message"):
        if data.get(opt):
            entry[opt] = data[opt]
    entries.append(entry)

out = bugs_dir / "registry.yaml"
lines = ["# AUTO-GENERATED — sync-bugs-registry.sh", "bugs:"]
for e in entries:
    lines.append(f"  - id: {e['id']}")
    lines.append(f"    status: {e['status']}")
    lines.append(f"    severity: {e['severity']}")
    lines.append(f"    scope: {e['scope']}")
    lines.append(f"    title: \"{e['title'].replace(chr(34), '')}\"")
    lines.append(f"    file: {e['file']}")
    for opt in ("files_changed", "approach", "risk_level", "commit_message"):
        if e.get(opt):
            val = e[opt].replace('"', "'")
            lines.append(f'    {opt}: "{val}"')
lines.append("")
out.write_text("\n".join(lines), encoding="utf-8")
print(f"sync-bugs-registry: {len(entries)} bugs -> {out}")
PY
