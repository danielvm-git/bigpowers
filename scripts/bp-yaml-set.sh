#!/usr/bin/env bash
# bp-yaml-set.sh — patch a dotted key in a specs YAML file
# Usage: bp-yaml-set.sh <file> <dotted.key> <value>
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FILE="${1:?file}"
KEY="${2:?dotted.key}"
VAL="${3:?value}"
python3 "$REPO_ROOT/scripts/yaml-tools.py" set "$FILE" "$KEY" "$VAL"
