---
name: fix-report
description: End-to-end bug fix workflow covering triage, diagnosis, TDD implementation, and GitHub reporting. Use when fixing bugs with GitHub tracking.
---

# Fix and Report

A disciplined workflow for fixing bugs and keeping GitHub issues in sync.

## Process

### Phase 1: Triage & Diagnose
1. **Capture**: Get the problem description or error.
2. **Investigate**: Explore the codebase to find the root cause.
3. **Report**: Create a GitHub issue using `gh issue create` with the initial findings.
4. **Analysis**: State the root cause, location, and trigger condition.

### Phase 2: Plan & TDD
1. **Fix Plan**: List files to change, why, and risk level.
2. **TDD Cycles**: Design a series of RED-GREEN cycles (test first, then code).
   - **RED**: Write a test that fails due to the bug.
   - **GREEN**: Minimal code change to fix it.

### Phase 3: Implement & Prevent
1. **Execute**: Implement the fix following the TDD plan.
2. **Prevent**: Add prevention mechanisms (type guards, Zod schemas, assertions, etc.).
3. **Regression**: Ensure a permanent regression test is in place.

### Phase 4: Verify & Log
1. **Verify**: Run full test suite, type check, and linter.
2. **Log**: Update `docs/bugs/bug-log.csv` (create if missing). See [REFERENCE.md](REFERENCE.md) for format.
3. **Report**: Update the GitHub issue with the final **Bug Fix Report**.

### Phase 5: Handoff
1. **Git Commands**: Provide Conventional Commit commands for the user to run.
2. **Summary**: Print the issue URL and a one-line fix summary.

## Guidelines
- **Minimum Fix**: No refactors or cleanups unless related to the bug.
- **Always Test**: A bug fix without a regression test is incomplete.
- **GitHub First**: Create/link the issue early to track progress.

See [REFERENCE.md](REFERENCE.md) for detailed templates and logging formats.
