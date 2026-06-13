#!/usr/bin/env bash
# And files should remain under 500 lines (Newspaper Metaphor)
FAILS=$(find scripts/ specs/verifications/steps/ -name "*.sh" 2>/dev/null | xargs wc -l 2>/dev/null | awk '$1 > 500 && $2 != "total" {print $2}')

if [[ -z "$FAILS" ]]; then
  exit 0
else
  echo "Files exceeding 500 lines: $FAILS"
  exit 1
fi
