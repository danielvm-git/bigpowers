#!/bin/bash
# Ad-hoc verification: e39s02 agent-locks protocol
REPO="/Users/danielvm/Developer/bigpowers"
ERR=0
echo "=== e39s02 agent-locks verification ==="

echo -n "1. agent-locks.yaml: "
test -f "$REPO/specs/agent-locks.yaml" || { echo "MISSING"; ERR=1; }
LOCKS=$(yq '.locks | length' "$REPO/specs/agent-locks.yaml" 2>/dev/null)
[ "$LOCKS" = "0" ] && echo "OK (0 locks)" || { echo "FAIL ($LOCKS)"; ERR=1; }

echo -n "2. kickoff-branch: "
grep -q 'agent-locks' "$REPO/skills/kickoff-branch/SKILL.md" && echo "OK" || { echo "FAIL"; ERR=1; }

echo -n "3. release-branch: "
grep -q 'agent-locks' "$REPO/skills/release-branch/SKILL.md" && echo "OK" || { echo "FAIL"; ERR=1; }

echo -n "4. CI workflow: "
grep -rq 'agent-locks' "$REPO/.github/workflows/" && echo "OK" || { echo "FAIL"; ERR=1; }
echo -n "   24h threshold: "
grep -q 'timedelta(hours=24)' "$REPO/.github/workflows/agent-locks.yml" && echo "OK" || { echo "FAIL"; ERR=1; }
echo -n "   exit(1): "
grep -q 'sys.exit(1)' "$REPO/.github/workflows/agent-locks.yml" && echo "OK" || { echo "FAIL"; ERR=1; }
echo -n "   hourly cron: "
grep -q 'cron: "0 \* \* \* \*"' "$REPO/.github/workflows/agent-locks.yml" && echo "OK" || { echo "FAIL"; ERR=1; }

[ $ERR -eq 0 ] && echo "ALL CHECKS PASSED" || echo "SOME FAILED"
exit $ERR
