#!/usr/bin/env bash
# bp-yaml-set.sh — patch a dotted key in a specs YAML file
# Usage: bp-yaml-set.sh <file> <dotted.key> <value>
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/python-env.sh"
FILE="${1:?file}"
KEY="${2:?dotted.key}"
VAL="${3:?value}"
$PYTHON "$REPO_ROOT/scripts/yaml-tools.py" set "$FILE" "$KEY" "$VAL"
