#!/usr/bin/env bash
# validate-specs-yaml.sh — real-parse gate + required keys for state,
# release-plan, execution-status.
#
# BUG-2026-07-03-validate-specs-no-real-parser: this validator used to only
# grep for key strings, so a structurally flattened/corrupt YAML file that
# still contained those strings passed vacuously. It now really parses every
# specs/**/*.yaml with PyYAML first, and runs the required-key checks
# against the *parsed* objects, not against grep.
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SPECS="${1:-$REPO_ROOT/specs}"

err=0

# ── Phase 1: real parse pass — every specs/**/*.yaml must be valid YAML ──────
parse_report="$(python3 -c "
import sys, glob, os
import yaml

specs = sys.argv[1]
bad = []
for f in sorted(glob.glob(os.path.join(specs, '**', '*.yaml'), recursive=True)):
    # Test fixtures (e.g. specs/verifications/fixtures/corrupt-yaml/) hold
    # deliberately-broken YAML for the G-07/G-08 negative-path golden checks.
    # Skip them when scanning a real specs/ tree — but still validate them
    # when a fixture dir is itself the target (G-08 invokes this script
    # with the fixture dir as $SPECS directly).
    rel = os.path.relpath(f, specs)
    if rel.startswith('verifications' + os.sep + 'fixtures' + os.sep):
        continue
    try:
        yaml.safe_load(open(f))
    except yaml.YAMLError as e:
        bad.append((f, str(e).splitlines()[0] if str(e) else type(e).__name__))

for f, msg in bad:
    print(f'PARSE ERROR: {f}: {msg}')

sys.exit(1 if bad else 0)
" "$SPECS")" || err=1

if [[ -n "$parse_report" ]]; then
  echo "$parse_report"
fi

if [[ "$err" -ne 0 ]]; then
  echo "validate-specs-yaml: FAIL — one or more specs/**/*.yaml files are not valid YAML"
  exit 1
fi

# ── Phase 2: required-key checks against the parsed objects, not grep ────────
need_key() {
  local file="$1" py_check="$2" msg="$3"
  if [[ ! -f "$file" ]]; then
    echo "missing: $file"
    err=1
    return
  fi
  if ! python3 -c "
import sys, yaml
d = yaml.safe_load(open(sys.argv[1])) or {}
sys.exit(0 if ($py_check) else 1)
" "$file" 2>/dev/null; then
    echo "$file: $msg"
    err=1
  fi
}

need_key "$SPECS/state.yaml" "isinstance(d.get('active_flow'), str)" 'missing active_flow'
need_key "$SPECS/release-plan.yaml" "isinstance(d.get('release'), dict)" 'missing release block'
need_key "$SPECS/release-plan.yaml" "isinstance(d.get('release'), dict) and 'version' in d['release']" 'missing release.version'
need_key "$SPECS/release-plan.yaml" "isinstance(d.get('epics'), list) and len(d['epics']) > 0" 'missing epics list'
need_key "$SPECS/execution-status.yaml" "isinstance(d.get('development_status'), dict)" 'missing development_status'

# ── Phase 3: every epic's `file` reference must exist, read from the parsed object ──
if [[ -f "$SPECS/release-plan.yaml" ]]; then
  missing_files="$(python3 -c "
import sys, os, yaml
specs = sys.argv[1]
d = yaml.safe_load(open(os.path.join(specs, 'release-plan.yaml'))) or {}
for epic in d.get('epics') or []:
    if not isinstance(epic, dict):
        continue
    f = epic.get('file')
    if f and not os.path.isfile(os.path.join(specs, f)):
        print(os.path.join(specs, f))
" "$SPECS")"
  if [[ -n "$missing_files" ]]; then
    while IFS= read -r path; do
      [[ -z "$path" ]] && continue
      echo "release-plan: missing epic file $path"
      err=1
    done <<< "$missing_files"
  fi
fi

if [[ "$err" -ne 0 ]]; then
  exit 1
fi
echo "validate-specs-yaml: OK"
