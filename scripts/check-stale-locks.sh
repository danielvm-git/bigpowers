#!/usr/bin/env bash
# story: e39s02
# Validate that no agent lock in specs/agent-locks.yaml is >24h old.
set -euo pipefail

LOCK_FILE="specs/agent-locks.yaml"
if [ ! -f "$LOCK_FILE" ]; then
  echo "No agent-locks.yaml — skipping stale-lock check"
  exit 0
fi

python3 -c "
import yaml, datetime, sys

now = datetime.datetime.now(datetime.timezone.utc)
with open('$LOCK_FILE') as f:
    d = yaml.safe_load(f)

if not d or 'locks' not in d:
    print('No locks to validate')
    sys.exit(0)

stale = []
for lock in d['locks']:
    locked_at = datetime.datetime.fromisoformat(lock.get('locked_at', '1970-01-01T00:00:00Z'))
    if locked_at.tzinfo is None:
        locked_at = locked_at.replace(tzinfo=datetime.timezone.utc)
    age_hours = (now - locked_at).total_seconds() / 3600
    if age_hours > 24:
        stale.append(f'{lock[\"story_id\"]}: locked by {lock.get(\"locked_by\", \"?\")} for {age_hours:.1f}h')

if stale:
    print(f'::warning::Stale locks found (>24h):')
    for s in stale:
        print(f'  {s}')
else:
    print('No stale locks')
" 2>&1
