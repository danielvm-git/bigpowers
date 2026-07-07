#!/usr/bin/env bash
# story: e45s25
# Compile CONVENTIONS.md risk tiers → versioned specs/rule-matrix.json
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/python-env.sh"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CONVENTIONS="$REPO_ROOT/CONVENTIONS.md"
OUTPUT="$REPO_ROOT/specs/rule-matrix.json"
MATRIX_VERSION="1.0.0"

show_help() {
  cat <<EOF
Usage: $(basename "$0") [OPTION]

Compile CONVENTIONS.md § Risk Tiers into specs/rule-matrix.json.
P0/P1/P2/P3 entries are diffable across git tags.

Options:
  --stdout   Print JSON to stdout instead of writing file
  --help     Show this help and exit
EOF
}

STDOUT_ONLY=0
if [ "$#" -eq 1 ]; then
  case "$1" in
    --help) show_help; exit 0 ;;
    --stdout) STDOUT_ONLY=1 ;;
    *) echo "[ERROR] Unknown option: $1" >&2; exit 1 ;;
  esac
fi

if [ ! -f "$CONVENTIONS" ]; then
  echo "[ERROR] CONVENTIONS.md not found at $CONVENTIONS" >&2
  exit 1
fi

$PYTHON - "$CONVENTIONS" "$OUTPUT" "$MATRIX_VERSION" "$STDOUT_ONLY" <<'PY'
import hashlib
import json
import re
import sys
from datetime import datetime, timezone

conventions_path, output_path, matrix_version, stdout_only = sys.argv[1:5]
stdout_only = stdout_only == "1"

with open(conventions_path, encoding="utf-8") as f:
    content = f.read()

source_hash = hashlib.sha256(content.encode("utf-8")).hexdigest()[:16]

# Extract Risk Tiers section
m = re.search(
    r"^## Risk Tiers \(Effective Rule Matrix\)\s*\n(.*?)(?=^## |\Z)",
    content,
    re.MULTILINE | re.DOTALL,
)
if not m:
    print("[ERROR] CONVENTIONS.md missing '## Risk Tiers (Effective Rule Matrix)'", file=sys.stderr)
    sys.exit(1)

section = m.group(1)
tier_re = re.compile(r"^### (P[0-3]) —[^\n]*\n(.*?)(?=^### |\Z)", re.MULTILINE | re.DOTALL)
rule_re = re.compile(
    r"^- \*\*\[([^\]]+)\]\*\*:\s*(.+?)\.\s*\(([^)]+)\)\s*$",
    re.MULTILINE,
)

tiers: dict[str, list[dict]] = {"P0": [], "P1": [], "P2": [], "P3": []}

for tier_match in tier_re.finditer(section):
    tier = tier_match.group(1)
    body = tier_match.group(2)
    for rule_match in rule_re.finditer(body):
        rule_id, text, enforce_raw = rule_match.groups()
        enforce = [s.strip().strip("`") for s in enforce_raw.split(",")]
        tiers[tier].append(
            {
                "id": rule_id,
                "text": text.strip(),
                "enforce": enforce,
            }
        )

for tier in tiers:
    if not tiers[tier]:
        print(f"[ERROR] No rules parsed for tier {tier}", file=sys.stderr)
        sys.exit(1)

doc = {
    "matrix_version": matrix_version,
    "generated_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    "source": "CONVENTIONS.md",
    "source_section": "Risk Tiers (Effective Rule Matrix)",
    "source_hash": source_hash,
    "tiers": tiers,
}

payload = json.dumps(doc, indent=2, sort_keys=True) + "\n"

if stdout_only:
    print(payload, end="")
else:
    import os

    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    with open(output_path, "w", encoding="utf-8") as out:
        out.write(payload)
    total = sum(len(v) for v in tiers.values())
    print(f"OK: wrote {output_path} ({total} rules, matrix_version={matrix_version})")
PY
