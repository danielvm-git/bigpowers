---
bug_id: BUG-2026-07-03-trace-stories-613-line
status: open
severity: low
scope: refactor
title: "trace-stories.sh 613-line waiver contradicts CONVENTIONS context-window justification"
---

# BUG-2026-07-03T134000: trace-stories.sh 613-line waiver contradicts CONVENTIONS' own context-window justification

## Problem

**Actual behavior:** `scripts/trace-stories.sh` is 613 lines. It carries a documented waiver in the compliance suite ("splitting degrades readability") that directly contradicts CONVENTIONS.md's own justification for the 300-line cap: files should fit in a single context window.

**Expected behavior:** Either split the file into modules (parse phase, match phase, report phase) OR document the exception in CONVENTIONS.md alongside the naming exceptions table, with the specific rationale and a review date.

**How to reproduce:**
1. `wc -l scripts/trace-stories.sh` → 613
2. Read CONVENTIONS.md: "Max 300 lines per file" with context-window rationale
3. Read `specs/verifications/features/conventions.feature` — carries the waiver with "splitting degrades readability" as rationale
4. These two documents contradict each other on the same principle

## Root Cause Analysis

The 300-line cap exists for a reason: agents have limited context windows, and monolithic files force full reads instead of targeted reads. The waiver's "splitting degrades readability" argument could apply to any file — if accepted here, it undermines the cap everywhere. The contradiction erodes the conventions' authority.

Two options:
1. **Split trace-stories.sh** into `trace-stories-parse.sh` + `trace-stories-match.sh` + `trace-stories-report.sh` (or source-able functions). The file is naturally phase-structured and would split cleanly.
2. **Document the exception in CONVENTIONS.md** with specific rationale (e.g., "the parse-match-report phases are tightly coupled; splitting introduces grep-fragile inter-script state") and a review date.

**Risk level:** LOW — no functional defect. The risk is architectural: a living counterexample to the conventions' own rules.

## TDD Fix Plan

### Option A (preferred): Split trace-stories.sh
1. Extract parse phase into `scripts/lib/trace-stories-parse.sh` (story tag discovery)
2. Extract match phase into `scripts/lib/trace-stories-match.sh` (file-to-story mapping)
3. Keep `scripts/trace-stories.sh` as the orchestration entry point (≤150 lines)
4. Remove the waiver from conventions.feature
**verify:** `wc -l scripts/trace-stories.sh | awk '{if($1<=300) print "OK: "$1" lines"; else print "FAIL: "$1}'`

### Option B: Document the exception
1. Add an entry to CONVENTIONS.md's naming exceptions table (or a new "file-size exceptions" table)
2. Include: file path, line count, rationale, review date
3. Update the waiver documentation in conventions.feature to reference CONVENTIONS.md
**verify:** `grep -q 'trace-stories.sh.*613\|file-size exception' CONVENTIONS.md && echo OK`

## Acceptance Criteria

- [ ] trace-stories.sh ≤300 lines (A) OR documented exception in CONVENTIONS.md (B)
- [ ] The contradiction between the waiver and the cap's rationale is resolved
- [ ] `bash scripts/trace-stories.sh --strict` still passes
- [ ] Compliance waiver removed or updated to reference CONVENTIONS.md
- [ ] CI trace gate still green

## Resolution

**Open** — registered 2026-07-03 from PLAN-AUDIT red-team gap list (P3 #12).
