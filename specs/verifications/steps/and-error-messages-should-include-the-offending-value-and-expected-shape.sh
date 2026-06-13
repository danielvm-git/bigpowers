#!/usr/bin/env bash
# And error messages should include the offending value and expected shape
# Check: audit-compliance.sh includes the failing file/step in error output.
if grep -q 'echo.*\$FEATURE_FILE\|echo.*\$step_script\|echo.*\$evidence' scripts/audit-compliance.sh 2>/dev/null; then
  exit 0
else
  echo "audit-compliance.sh error messages do not include offending values"
  exit 1
fi
