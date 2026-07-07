#!/usr/bin/env bash
# story: e45s14
# check-import-boundaries.sh — enforce specs/import-boundaries.json in CI
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BOUNDARIES="$REPO_ROOT/specs/import-boundaries.json"

if [[ ! -f "$BOUNDARIES" ]]; then
  echo "FAIL: missing $BOUNDARIES"
  exit 1
fi

python3 - "$REPO_ROOT" "$BOUNDARIES" <<'PY'
import json, re, sys
from pathlib import Path

root = Path(sys.argv[1])
rules_path = Path(sys.argv[2])
rules = json.loads(rules_path.read_text(encoding="utf-8"))

def glob_match(pattern: str, path: str) -> bool:
    import fnmatch
    return fnmatch.fnmatch(path, pattern)

violations = []

for boundary in rules.get("boundaries", []):
    from_pat = boundary["from"]
    allow = boundary.get("allow", [])
    deny = boundary.get("deny", [])

    for sh in root.glob("scripts/**/*.sh"):
        rel = sh.relative_to(root).as_posix()
        if not glob_match(from_pat, rel):
            continue
        text = sh.read_text(encoding="utf-8", errors="replace")
        for line in text.splitlines():
            m = re.match(r'^\s*(?:source|\.)\s+["\']?([^"\']+)["\']?', line)
            if not m:
                continue
            target = m.group(1)
            if target.startswith("$"):
                continue
            if not target.startswith("scripts/") and not target.startswith("guard-git/"):
                if any(glob_match(d, target) for d in deny):
                    violations.append(f"{rel}: forbidden source {target}")
                continue
            rel_target = target
            if not (Path(root / rel_target).exists() or glob_match(rel_target, rel_target)):
                pass
            allowed = any(glob_match(a, rel_target) for a in allow)
            if not allowed:
                violations.append(f"{rel}: source {rel_target} not in allowlist for {from_pat}")

if violations:
    print("IMPORT BOUNDARY FAIL:")
    for v in violations:
        print(f"  {v}")
    sys.exit(1)

print(f"IMPORT BOUNDARIES OK ({len(rules.get('boundaries', []))} rules)")
PY
