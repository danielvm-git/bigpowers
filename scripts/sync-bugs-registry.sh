#!/usr/bin/env bash
# story: e45s03
# sync-bugs-registry.sh — rebuild specs/bugs/registry.yaml + OKF concept bundles
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/python-env.sh"
source "$(dirname "${BASH_SOURCE[0]}")/lib/skill-common.sh"
BUGS="$REPO_ROOT/specs/bugs"
mkdir -p "$BUGS"

$PYTHON - "$BUGS" "$REPO_ROOT" <<'PY'
import re
import sys
from pathlib import Path

bugs_dir = Path(sys.argv[1])
repo_root = Path(sys.argv[2])

# ---- Phase 1: Build registry.yaml ----
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

# ---- Phase 2: Emit OKF concept bundles (e45s03) ----
okf_count = 0
for e in entries:
    bug_id = e["id"]
    slug = bug_id.replace("BUG-", "").lower()
    bundle_path = bugs_dir / f"{bug_id}.okf.md"

    title_escaped = e["title"].replace('"', "'")
    refs = f"    - specs/bugs/{bug_id}.md"

    bundle = f"""---
okf_kind: concept
okf_version: "0.1"
id: "{bug_id}"
title: "{title_escaped}"
category: bug
tier: extended
severity: {e["severity"]}
status: {e["status"]}
generator: scripts/sync-bugs-registry.sh
references:
{refs}
---

# {title_escaped}

**Bug:** {bug_id} | **Severity:** {e["severity"]} | **Status:** {e["status"]} | **Scope:** {e.get("scope", "general")}
**Tier:** extended

See `specs/bugs/{bug_id}.md` for full investigation and fix details.
"""
    bundle_path.write_text(bundle, encoding="utf-8")
    okf_count += 1

print(f"sync-bugs-registry: {okf_count} OKF concept bundles -> {bugs_dir}/")
PY
