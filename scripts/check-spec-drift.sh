#!/usr/bin/env bash
# story: e39s03
# Compare spec-file mtimes against implementing source-file mtimes,
# mark suspect links, write to specs/drift-report.json
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/python-env.sh"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TRACE_MATRIX="$REPO_ROOT/specs/traceability-matrix.json"
DRIFT_REPORT="$REPO_ROOT/specs/drift-report.json"

show_help() {
  cat <<EOF
Usage: $(basename "$0") [OPTION]

Compare spec/story mtimes vs implementing file mtimes to detect drift.
Output: specs/drift-report.json with suspect and broken links.

Options:
  --help    Show this help and exit
EOF
}

if [ "$#" -eq 1 ] && [ "$1" = "--help" ]; then
  show_help
  exit 0
fi

if [ ! -f "$TRACE_MATRIX" ]; then
  echo "[ERROR] Traceability matrix not found: $TRACE_MATRIX" >&2
  echo "[ERROR] Run scripts/trace-stories.sh first" >&2
  exit 1
fi

$PYTHON -c "
import json, os, sys

with open('$TRACE_MATRIX') as f:
    matrix = json.load(f)

drift = {
    'meta': {
        'generated_by': 'scripts/check-spec-drift.sh',
        'source': 'specs/traceability-matrix.json',
        'timestamp': __import__('datetime').datetime.now(__import__('datetime').timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')
    },
    'suspect_links': [],
    'broken_links': [],
    'summary': {'suspect': 0, 'broken': 0, 'ok': 0}
}

repo_root = '$REPO_ROOT'

stories = matrix.get('stories', [])
assert isinstance(stories, list), 'stories must be a list'

for entry in stories:
    story_id = entry.get('id', '')
    spec_path = entry.get('spec_path', '')
    links = entry.get('links', [])

    if not links:
        drift['broken_links'].append({
            'story_id': story_id,
            'reason': 'no trace links',
            'severity': 'broken'
        })
        drift['summary']['broken'] += 1
        continue

    impl_files = [link['file'] for link in links if link.get('file')]

    if not impl_files:
        drift['broken_links'].append({
            'story_id': story_id,
            'reason': 'no implementing files in trace links',
            'severity': 'broken'
        })
        drift['summary']['broken'] += 1
        continue

    suspect_files = []

    for impl_file in impl_files:
        impl_full = os.path.join(repo_root, impl_file) if not os.path.isabs(impl_file) else impl_file
        if os.path.exists(impl_full):
            impl_mtime = os.path.getmtime(impl_full)
            if spec_path and os.path.exists(spec_path):
                spec_mtime = os.path.getmtime(spec_path)
                if impl_mtime > spec_mtime:
                    suspect_files.append({
                        'file': impl_file,
                        'impl_mtime': impl_mtime,
                        'spec_mtime': spec_mtime,
                        'age_seconds': impl_mtime - spec_mtime
                    })
        else:
            drift['broken_links'].append({
                'story_id': story_id,
                'spec': spec_path,
                'file': impl_file,
                'reason': 'implementing file does not exist',
                'severity': 'broken'
            })
            drift['summary']['broken'] += 1

    if suspect_files:
        drift['suspect_links'].append({
            'story_id': story_id,
            'spec': spec_path,
            'files': suspect_files
        })
        drift['summary']['suspect'] += 1
    else:
        drift['summary']['ok'] += 1

with open('$DRIFT_REPORT', 'w') as f:
    json.dump(drift, f, indent=2)

print(f'OK: {drift[\"summary\"][\"ok\"]} clean, {drift[\"summary\"][\"suspect\"]} suspect, {drift[\"summary\"][\"broken\"]} broken')
"
