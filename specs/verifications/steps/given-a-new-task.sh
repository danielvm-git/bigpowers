#!/usr/bin/env bash
# Given a new task — context setup; passes if bigpowers skills exist
[ -d "elaborate-spec" ] && [ -d "plan-work" ] && exit 0
echo "bigpowers skill directories not found"
exit 1
