
# Enforce FIRST
> **HARD GATE** — **HARD GATE** — Before shipping, ALL enforcement checks must pass: lint, typecheck, tests, coverage gates. Do NOT disable or skip checks to get to green.


Apply the F.I.R.S.T rubric per CONVENTIONS.md §Tests to evaluate and improve tests.

This skill is typically invoked internally by `develop-tdd` during the test-writing phase. It can also be run standalone on an existing test suite.

## Modes

- Default: full F.I.R.S.T audit (all 5 criteria)
- --quick: Check Fast, Independent, and Self-Validating criteria only (per CONVENTIONS.md §Tests). Used by build-epic step 6 as a mechanical gate after audit-code. Skips Repeatable and Timely which require contextual judgment.

## The F.I.R.S.T Rubric

See CONVENTIONS.md §Tests for the canonical F.I.R.S.T rubric definition, checklists, and fix patterns.

## Applying the rubric

For each failing criterion:
1. Identify which tests violate it
2. Describe the fix
3. Apply the fix
4. Re-run the suite to confirm it still passes

Report: "F.I.R.S.T audit complete. X criteria passed, Y fixed."
