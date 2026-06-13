#!/usr/bin/env bash
# Given a high-stakes task — context setup; passes if bigpowers skills exist
[ -d "plan-work" ] && [ -d "audit-code" ] && [ -d "request-review" ] && exit 0
echo "bigpowers skill directories not found"
exit 1
