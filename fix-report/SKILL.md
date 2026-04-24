---
name: fix-report
description: Disciplined bug-fix workflow covering triage, root cause analysis, TDD implementation, and automated GitHub reporting. Use when handling terminal errors, stack traces, bug reports, or when a disciplined fix with audit logging (CSV) and GitHub issue tracking is required.
---

# Fix and Report

A high-integrity workflow for fixing bugs, ensuring regression testing, and maintaining a GitHub-synced audit trail.

## Quick start

1. **Triage**: Find the bug location and root cause.
2. **Issue**: Create a GitHub issue with `gh issue create`.
3. **TDD**: Write a failing test, then the fix.
4. **Log**: Run `node fix-report/scripts/log-bug.js` to update `docs/bugs/bug-log.csv`.
5. **Close**: Update the GitHub issue with the final report.

## Workflows

### 1. Diagnosis & Issue Creation
- **Explore**: Use `git log` and codebase search to trace the error path.
- **Isolate**: Identify the exact trigger (state, input, or environment).
- **GitHub**: Create the issue early. See [REFERENCE.md](REFERENCE.md) for the Initial Triage template.

### 2. TDD Fix Cycle
- **Plan**: List affected files and rate risk (Low/Med/High).
- **Red**: Add a test case to the existing suite that reproduces the failure.
- **Green**: Apply the minimal fix. Follow existing style; no unrelated refactors.

### 3. Prevention & Verification
- **Harden**: Add a type guard, Zod schema update, or invariant check.
- **Verify**: Run `npm test`, `tsc`, and `lint`. Ensure ALL tests pass, not just the new one.
- **Audit**: Append the fix to `docs/bugs/bug-log.csv`. Use the helper script to ensure column alignment.

### 4. Reporting & Handoff
- **GitHub**: Post the final **Bug Fix Report** as a comment or update the issue body.
- **Git**: Provide the user with Conventional Commit commands (`fix(scope): ...`).

## Guidelines
- **Durability**: Write tests that assert on observable behavior (API/UI), not internal state.
- **No Suppression**: Never use `@ts-ignore` or `as any` to "fix" a bug.
- **Audit Trail**: Always update the CSV log; it's the project's memory of past failures.

See [REFERENCE.md](REFERENCE.md) for templates and [EXAMPLES.md](EXAMPLES.md) for scenarios.
