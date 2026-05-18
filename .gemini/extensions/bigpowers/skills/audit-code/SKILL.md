---
name: audit-code
description: "Self-review checklist for the coding agent to run before dispatching a reviewer. Checks CONVENTIONS.md compliance, Boy Scout Rule, test coverage, types, and SOLID. Produces a pass/fail checklist. Use before request-review, before committing, or when user asks for a code quality check."
---


# Audit Code

Run this self-review before asking anyone else to look at the code. The goal is to catch everything that is clearly wrong or missing — so the reviewer can focus on design and architecture, not hygiene.

**Distinct from `request-review`:** This is the coding agent checking its own work. No second agent is involved. Run this first; run `request-review` after this passes.

## Checklist

### CONVENTIONS.md Compliance

- [ ] All output files are in `specs/` (no docs written to project root)
- [ ] No `gh issue create` calls anywhere in new/modified skills or scripts
- [ ] `gh` used only for PRs and repo clone operations
- [ ] No GitHub REST API called directly (no curl/fetch to api.github.com)

### Scope

- [ ] Changes are limited to what was asked — nothing extra refactored or reorganized
- [ ] No speculative features added
- [ ] No files touched outside the stated scope

### Boy Scout Rule

- [ ] Every file I touched is cleaner than when I found it
- [ ] No dead code left behind
- [ ] No commented-out code blocks

### Types and Safety

- [ ] No `any` types introduced (TypeScript) or untyped public functions (Python/Go/etc.)
- [ ] No `@ts-ignore` or `// eslint-disable` added
- [ ] No `as unknown as X` casts that bypass type safety

### Test Coverage

- [ ] Every new function has at least one test
- [ ] Every bug fix has a regression test
- [ ] Tests verify behavior through public interfaces (not implementation details)
- [ ] Tests are F.I.R.S.T compliant (use `enforce-first` if unsure)

### SOLID

- [ ] Single Responsibility: no function or module doing two unrelated things
- [ ] Open/Closed: extended through interfaces, not by modifying stable code
- [ ] Dependency Inversion: dependencies injected, not imported globally where avoidable
- [ ] No `any` as a substitute for a proper interface

### Code Style (CONVENTIONS.md)

- [ ] Functions: 4–20 lines; split if longer
- [ ] Files: under 500 lines (ideally 200–300)
- [ ] Names: specific and unique (grep returns < 5 hits for each name)
- [ ] No duplication — shared logic extracted
- [ ] Early returns over nested ifs; max 2 levels of indentation
- [ ] Comments explain WHY, not WHAT

## Output

Report the checklist with ✓ / ✗ per item. For each ✗, describe what needs to be fixed.

If all items pass: suggest running `request-review` for an independent second opinion.
If any items fail: fix them before proceeding.
