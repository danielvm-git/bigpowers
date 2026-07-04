#!/usr/bin/env bash
# golden-g09-yaml-roundtrip.sh — yaml-tools.py Lossless Round-Trip Self-Test (G-09)
#
# Proves yaml-tools.py's `set` command preserves structure it doesn't touch
# (BUG-2026-07-03-yaml-roundtrip-corruption bug class). The old hand-rolled
# parser/dumper had no concept of YAML lists or block scalars and flattened
# both on every write. This feeds `set` a fixture containing an epics[] list
# (nested dicts + a flow-style list) and a block scalar (`note: >`), changes
# one unrelated field, and asserts:
#   1. the file still parses as valid YAML afterward
#   2. the epics[] list still has the same length and nested keys
#   3. fields untouched by the `set` call keep their original values
#   4. the targeted field actually changed
#
# Usage: bash scripts/golden-g09-yaml-roundtrip.sh
# Exit 0: round trip is lossless
# Exit 1: round trip destroyed structure (corruption bug is back)

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FIXTURE="$REPO_ROOT/specs/verifications/fixtures/yaml-roundtrip/sample.yaml"
TOOL="$REPO_ROOT/scripts/yaml-tools.py"

echo "=== G-09: yaml-tools.py Lossless Round-Trip Self-Test ==="

if [[ ! -f "$FIXTURE" ]]; then
  echo "ERROR: fixture not found: $FIXTURE"
  exit 1
fi

WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT
cp "$FIXTURE" "$WORKDIR/sample.yaml"

python3 "$TOOL" set "$WORKDIR/sample.yaml" release.version "9.9.9-test"

set +e
RESULT="$(python3 -c "
import sys, yaml

try:
    with open(sys.argv[1]) as f:
        d = yaml.safe_load(f)
except yaml.YAMLError as e:
    print('FAIL: file no longer parses as YAML:', str(e).splitlines()[0])
    sys.exit(1)

errors = []

if d.get('release', {}).get('version') != '9.9.9-test':
    errors.append('targeted field release.version was not updated')

epics = d.get('epics')
if not isinstance(epics, list) or len(epics) != 2:
    errors.append(f'epics[] list destroyed: expected 2 items, got {epics!r}')
else:
    if epics[0].get('id') != 'e19' or epics[0].get('wsjf') != 4.7:
        errors.append('epics[0] fields not preserved')
    if 'note' not in epics[0] or 'Delivered' not in epics[0].get('note', ''):
        errors.append('epics[0].note (block scalar) not preserved')
    if epics[1].get('id') != 'e40' or epics[1].get('depends_on') != ['e39', 'e28']:
        errors.append('epics[1] fields (incl. flow-style list) not preserved')

if d.get('release', {}).get('codename') != 'Deepening':
    errors.append('release.codename (untouched sibling field) not preserved')

if d.get('bigpowers_version') != '2.58.7':
    errors.append('bigpowers_version (untouched top-level field) not preserved')

if errors:
    for e in errors:
        print('FAIL:', e)
    sys.exit(1)

print('OK: round trip is lossless')
sys.exit(0)
" "$WORKDIR/sample.yaml")"
EXIT=$?
set -e

echo "$RESULT"

if [[ $EXIT -eq 0 ]]; then
  echo -e "${GREEN}PASS${NC} yaml-tools.py round trip is lossless"
  echo "G-09: PASS"
  exit 0
else
  echo -e "${RED}FAIL${NC} yaml-tools.py round trip destroyed structure"
  echo "G-09: FAIL — same bug class as BUG-2026-07-03-yaml-roundtrip-corruption"
  exit 1
fi
