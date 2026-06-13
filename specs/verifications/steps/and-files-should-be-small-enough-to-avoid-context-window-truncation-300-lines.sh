#!/usr/bin/env bash
# And files should be small enough to avoid context window truncation (< 300 lines)
# Check: no shell script exceeds 300 lines.
FAILS=$(find . -maxdepth 3 -name "*.sh" | grep -v '^\./\.' | xargs wc -l 2>/dev/null | awk '$1 > 300 && $2 != "total" {print $2}')

if [[ -z "$FAILS" ]]; then
  exit 0
else
  echo "Scripts exceeding 300 lines: $FAILS"
  exit 1
fi
