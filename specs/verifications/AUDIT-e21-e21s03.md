# Audit: e21s03 — CI-aware skills via AGENTS.md

**Date:** 2026-06-22
**Story:** e21s03 — CI-aware skills — read preflight commands from AGENTS.md
**Files:** `verify-work/SKILL.md` (+3 lines), `scripts/bp-read-agents.sh` (new, 53 lines)

## Result: PASS

All sections pass. Key notes:
- Fixed `set -e` interaction with `&&` conditionals — replaced with `if/fi` guards.
- `extract_command` is 10 lines, under the 20-line cap.
- Script gracefully no-ops when no AGENTS.md/CLAUDE.md/CURSOR.md found.
