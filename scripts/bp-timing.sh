#!/usr/bin/env bash
# bp-timing.sh — Record skill invocation timings for stocktake effectiveness analysis.
# Usage: bash scripts/bp-timing.sh start <skill-name>
#        bash scripts/bp-timing.sh end <skill-name>
# Requires: python3 (for YAML-safe state updates)
set -euo pipefail

STATE_YAML="specs/state.yaml"
TIMINGS_KEY="metrics.skill_timings"

usage() {
  echo "Usage: $0 start|end <skill-name>" >&2
  exit 1
}

[ $# -ne 2 ] && usage

ACTION="$1"
SKILL="$2"

case "$ACTION" in
  start)
    STAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    python3 -c "
import yaml, sys
try:
    with open('$STATE_YAML') as f:
        data = yaml.safe_load(f) or {}
except: data = {}

metrics = data.setdefault('metrics', {})
timings = metrics.setdefault('skill_timings', {})

if '$SKILL' not in timings:
    timings['$SKILL'] = {'calls': 0, 'total_seconds': 0, 'avg_seconds': 0}

timings['$SKILL']['_start'] = '$STAMP'
with open('$STATE_YAML', 'w') as f:
    yaml.dump(data, f, default_flow_style=False, sort_keys=False, allow_unicode=True)
" 2>/dev/null || echo "WARN: timing start failed (yaml tools missing?)" >&2
    ;;

  end)
    STAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    python3 -c "
import yaml
from datetime import datetime

with open('$STATE_YAML') as f:
    data = yaml.safe_load(f) or {}

metrics = data.setdefault('metrics', {})
timings = metrics.setdefault('skill_timings', {})

if '$SKILL' in timings and '_start' in timings['$SKILL']:
    start_t = datetime.fromisoformat(timings['$SKILL']['_start'].replace('Z','+00:00'))
    end_t = datetime.fromisoformat('$STAMP'.replace('Z','+00:00'))
    elapsed = (end_t - start_t).total_seconds()

    entry = timings['$SKILL']
    entry['calls'] = entry.get('calls', 0) + 1
    entry['total_seconds'] = entry.get('total_seconds', 0) + elapsed
    entry['avg_seconds'] = entry['total_seconds'] / entry['calls']
    del entry['_start']

with open('$STATE_YAML', 'w') as f:
    yaml.dump(data, f, default_flow_style=False, sort_keys=False, allow_unicode=True)
" 2>/dev/null || echo "WARN: timing end failed" >&2
    ;;

  *)
    usage
    ;;
esac
