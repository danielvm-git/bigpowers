---
bug_id: BUG-2026-07-04-filesize-gate-python-blindspot
status: fixed
severity: medium
scope: ci
title: "File-size compliance gates scan shell only — large Python trace-engine files breach caps invisibly; CONVENTIONS/waivers reference a phantom 613-line file"
---

# BUG-2026-07-04-filesize-gate-python-blindspot

## Problem

**Actual behavior:** The two file-size compliance steps
(`and-files-should-be-small-enough-to-avoid-context-window-truncation-300-lines.sh`
and `and-files-should-remain-under-500-lines-newspaper-metaphor.sh`) scan only
`*.sh`. The traceability engine was refactored out of `scripts/trace-stories.sh`
(once 613 lines, now **69 lines**) into `scripts/lib/*.py`. Two of those Python
files now breach the caps and nothing checks them:

- `scripts/lib/trace-matrix.py` — **523 lines** (over both 300 and 500)
- `scripts/lib/trace-stories.py` — **301 lines** (over 300)

Compounding it, `CONVENTIONS.md`'s "File-Size Exceptions" table and
`specs/verifications/waivers.yaml` still documented `scripts/trace-stories.sh`
at 613 lines — a file that no longer exists at that size — so the waivers were
protecting a phantom while the real over-cap files went unrecorded.

**Expected behavior:** File-size gates cover project Python as well as shell.
Over-cap files are honestly documented in the exceptions table, and waivers
reference the files that actually breach.

**How to reproduce:**
1. `wc -l scripts/lib/trace-matrix.py` → 523; `wc -l scripts/lib/trace-stories.py` → 301
2. `wc -l scripts/trace-stories.sh` → 69 (not 613)
3. `grep 'name "\*' specs/verifications/steps/and-files-should-*.sh` → `*.sh` only
4. `npm run compliance` → 88/88 PASS — the Python breaches are invisible to the gate

## Root Cause Analysis

Discovered during a `map-codebase` cold re-scan. When `trace-stories.sh` was
split into a thin orchestrator + `scripts/lib/*.py`, the size problem migrated
from shell to Python, but the compliance gate's `find` predicate was never
widened past `*.sh`. The exceptions table and waivers were updated to reference
the old shell file rather than the new Python files (a prior fix,
BUG-2026-07-03-trace-stories-613-line, mirrored the stale 613-line description
instead of noticing the refactor).

**Risk level:** MEDIUM — no runtime defect, but a real gate blind spot: any new
Python file could grow past the cap undetected, defeating the context-window
rationale the cap exists for.

## Fix (applied 2026-07-04)

1. Extended both file-size step scripts to scan `*.py` as well as `*.sh`.
2. Rewrote `CONVENTIONS.md`'s File-Size Exceptions table: removed the phantom
   `trace-stories.sh` (613) row, added `trace-matrix.py` (523, split candidate)
   and `trace-stories.py` (301), corrected `audit-compliance.sh` to 300, and
   added a note explaining the refactor.
3. Updated both `waivers.yaml` file-size waivers to reference the real Python
   files and note that trace-stories.sh (69) and audit-compliance.sh (300) are
   no longer covered.

## Acceptance Criteria

- [x] File-size steps scan `.py` in addition to `.sh`
- [x] CONVENTIONS.md exceptions table lists the real over-cap files, not the phantom .sh
- [x] waivers.yaml references the .py files; stale trace-stories.sh 613 removed
- [x] `npm run compliance` still passes (waived steps stay out of denominator)

## Resolution

**Fixed** — 2026-07-04. Left `trace-matrix.py` (523) as a documented split
candidate for a future plan-refactor rather than splitting the engine in this
pass. **Verify:** file-size steps now contain `-o -name "*.py"`; compliance
88/88 PASS; golden suite green.
