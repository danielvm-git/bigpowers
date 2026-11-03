#!/usr/bin/env bash
# story: e86 / GH #182
# Mechanical audit-code pass gate before commit / release.
set -euo pipefail

STAGE="${1:-commit}"

AUDIT_PASSED=false

# Check specs/AUDIT_LATEST.md
if [[ -f specs/AUDIT_LATEST.md ]]; then
  if grep -qiE "VERDICT:[[:space:]]*PASS|RESULT:[[:space:]]*PASS" specs/AUDIT_LATEST.md; then
    AUDIT_PASSED=true
  fi
fi

# Check specs/execution-status.yaml
if [[ "$AUDIT_PASSED" == "false" ]] && [[ -f specs/execution-status.yaml ]]; then
  if grep -qE "audit_passed:[[:space:]]*true" specs/execution-status.yaml 2>/dev/null; then
    AUDIT_PASSED=true
  fi
fi

if [[ "$AUDIT_PASSED" == "false" ]]; then
  echo "ERROR [$STAGE]: audit-code check is missing or did not pass (Issue #182)." >&2
  echo "Remediation: Run audit-code and ensure all checks pass before advancing to $STAGE." >&2
  echo "If audit fails, loop back to develop-tdd to address findings." >&2
  exit 1
fi

echo "PASS [$STAGE]: audit-code verified."
exit 0
