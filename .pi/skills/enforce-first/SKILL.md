---
name: enforce-first
description: "Apply the F.I.R.S.T test quality rubric (per CONVENTIONS.md §Tests) to a test suite or individual tests. Use when develop-tdd is writing tests, when test quality needs to be checked, or when user mentions F.I.R.S.T or \"test quality\"."
model: haiku
---


# Enforce FIRST
> **HARD GATE** — **HARD GATE** — Before shipping, ALL enforcement checks must pass: lint, typecheck, tests, coverage gates. Do NOT disable or skip checks to get to green.


Apply the F.I.R.S.T rubric per CONVENTIONS.md §Tests to evaluate and improve tests.

This skill is typically invoked internally by `develop-tdd` during the test-writing phase. It can also be run standalone on an existing test suite.

## Modes

- Default: full F.I.R.S.T audit (all 5 criteria)
- --quick: Check F (Fast), I (Independent), and S (Self-Validating) only. Used by build-epic step 6 as a mechanical gate after audit-code. Skips R (Repeatable) and T (Timely) which require contextual judgment.

## The F.I.R.S.T Rubric

The canonical F.I.R.S.T definition lives in CONVENTIONS.md §Tests. This skill operationalizes each criterion:

- **F (Fast):** No real I/O; suite target < 30s
- **I (Independent):** No shared state; any order, same result
- **R (Repeatable):** No machine deps; passes identically on CI and locally
- **S (Self-Validating):** Assertions, not console.log; descriptive failures
- **T (Timely):** Written with code; regression tests for every fix

For the full rubric with checklists and fix patterns, see CONVENTIONS.md §Tests.

## Applying the rubric

For each failing criterion:
1. Identify which tests violate it
2. Describe the fix
3. Apply the fix
4. Re-run the suite to confirm it still passes

Report: "F.I.R.S.T audit complete. X criteria passed, Y fixed."
