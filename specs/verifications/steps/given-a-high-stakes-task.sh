#!/usr/bin/env bash
# Given a high-stakes task — context setup; passes if bigpowers skills exist
[ -d "skills/plan-work" ] && [ -d "skills/audit-code" ] && [ -d "skills/request-review" ] && exit 0
echo "bigpowers skill directories not found"
exit 1
