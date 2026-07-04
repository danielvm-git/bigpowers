#!/usr/bin/env bash
# And files should be small enough to avoid context window truncation (< 300 lines)
# Check: no shell script OR project Python file exceeds 300 lines.
# Python added 2026-07-04 (BUG-2026-07-04-filesize-gate-python-blindspot) — the
# traceability engine moved from trace-stories.sh into scripts/lib/*.py, so a
# .sh-only scan let large Python files breach the cap invisibly.
FAILS=$(find . -maxdepth 3 \( -name "*.sh" -o -name "*.py" \) | grep -v '^\./\.' | xargs wc -l 2>/dev/null | awk '$1 > 300 && $2 != "total" {print $2}')

if [[ -z "$FAILS" ]]; then
  exit 0
else
  echo "Scripts exceeding 300 lines: $FAILS"
  exit 1
fi
