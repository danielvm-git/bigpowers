---
name: audit-code
description: Self-review checklist for the coding agent to run before dispatching a reviewer. Checks CONVENTIONS.md compliance, Boy Scout Rule, test coverage, types, and SOLID. Produces a pass/fail checklist. Use before request-review, before committing, or when user asks for a code quality check.
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

### SOLID and Heuristics

- [ ] Single Responsibility: no function or module doing two unrelated things
- [ ] Open/Closed: extended through interfaces, not by modifying stable code
- [ ] Dependency Inversion: dependencies injected, not imported globally where avoidable
- [ ] **Chapter 17 Heuristics**: Code is free of smells documented in `audit-code/HEURISTICS.md` (G, N, C, T)

### Code Style (CONVENTIONS.md)

- [ ] Functions: 4–20 lines; split if longer
- [ ] Functions: descend exactly one level of abstraction (The Stepdown Rule / G34)
- [ ] Files: under 300 lines (ideally 200–300)
- [ ] Names: specific and unique (grep returns < 5 hits for each name)
- [ ] No duplication — shared logic extracted (DRY / G5)
- [ ] Early returns over nested ifs; max 2 levels of indentation
- [ ] Conditionals: expressed as positives (G29)
- [ ] Comments explain WHY, not WHAT

### Agent Readability (Akita's Lens)

- [ ] Functions are small enough to fit in a standard context window (4–20 lines)
- [ ] Names are unique and specific enough to be `grep`-able (grep returns < 5 hits)
- [ ] Types are explicit (no `any`, no inferred return types for public APIs)
- [ ] Code avoids deep nesting (max 2 levels) and uses early returns

### Red Flags

Before reporting, name any rationalization you caught yourself making for skipping a checklist item. Silence is not acceptable — if you skipped an item, state the reason explicitly.

## Output

Report the checklist with ✓ / ✗ per item. For each ✗, describe what needs to be fixed.

If all items pass: suggest running `request-review` for an independent second opinion.
If any items fail: fix them before proceeding.
