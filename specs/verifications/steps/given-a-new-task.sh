#!/usr/bin/env bash
# Given a new task — context setup; passes if bigpowers skills exist
[ -d "skills/elaborate-spec" ] && [ -d "skills/plan-work" ] && exit 0
echo "bigpowers skill directories not found"
exit 1
