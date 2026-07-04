#!/usr/bin/env bash
# And files should remain under 500 lines (Newspaper Metaphor)
# Scans shell + project Python (Python added 2026-07-04,
# BUG-2026-07-04-filesize-gate-python-blindspot — scripts/lib/*.py holds the
# real traceability engine and was previously unscanned).
FAILS=$(find scripts/ specs/verifications/steps/ \( -name "*.sh" -o -name "*.py" \) 2>/dev/null | xargs wc -l 2>/dev/null | awk '$1 > 500 && $2 != "total" {print $2}')

if [[ -z "$FAILS" ]]; then
  exit 0
else
  echo "Files exceeding 500 lines: $FAILS"
  exit 1
fi
