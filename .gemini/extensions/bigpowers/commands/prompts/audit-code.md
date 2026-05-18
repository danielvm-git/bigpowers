
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
- [ ] Changes are surgical: only code strictly required for the task; no refactoring, reorganization, or cleanup outside task scope (Boy Scout Rule applied surgically, not broadly)

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

---

# Clean Code Heuristics (Chapter 17)

A summary of Robert C. Martin's catalogue of code smells and heuristics, used as the technical benchmark for `audit-code`.

## Comments (C)
- **C1: Inappropriate Information**: Comments should only hold technical notes. Metadata (author, change history) belongs in Git.
- **C2: Obsolete Comment**: Update or delete comments that are no longer accurate.
- **C3: Redundant Comment**: Don't describe code that adequately describes itself (e.g., `i++; // increment i`).
- **C4: Poorly Written Comment**: If you write a comment, spend time making it the best it can be.
- **C5: Commented-Out Code**: Delete it. Git remembers it.

## Environment (E)
- **E1: Build Requires More Than One Step**: Building should be a single trivial operation (e.g., `bash install.sh`).
- **E2: Tests Require More Than One Step**: Running all tests should be one simple command (e.g., `npm test`).

## Functions (F)
- **F1: Too Many Arguments**: 0 is ideal, 1-2 is fine, 3 requires special justification. Never > 3.
- **F2: Output Arguments**: Avoid them. If a function changes state, it should change the state of its owning object.
- **F3: Flag Arguments**: Boolean arguments are a smell that the function does > 1 thing.
- **F4: Dead Function**: Discard methods that are never called.

## General (G)
- **G1: Multiple Languages in One Source File**: Try to minimize the mixing of languages (e.g., HTML inside Java).
- **G5: Duplication (DRY)**: **The root of all evil.** Every time you see duplication, it's a missed opportunity for abstraction.
- **G6: Code at Wrong Level of Abstraction**: High-level concepts in base classes; low-level details in derivatives.
- **G25: Replace Magic Numbers with Named Constants**: No "naked" numbers or strings.
- **G28: Encapsulate Conditionals**: Prefer `if (shouldBePublished())` over complex boolean logic.
- **G29: Avoid Negative Conditionals**: Prefer `if (buffer.shouldCompact())` over `if (!buffer.shouldNotCompact())`.
- **G30: Functions Should Do One Thing**: If a function can be split into sections, it's doing too much.
- **G31: Hidden Temporal Couplings**: If execution order matters, make the dependency explicit via arguments.
- **G34: Functions Should Descend Only One Level of Abstraction**: The Stepdown Rule.

## Naming (N)
- **N1: Choose Descriptive Names**: Names should reveal intent and be updated as code evolves.
- **N4: Unambiguous Names**: Names should make the working of a function/variable clear.
- **N7: Names Should Describe Side-Effects**: Describe everything the function is or does.

## Tests (T)
- **T1: Insufficient Tests**: A test suite should test everything that could possibly break.
- **T4: An Ignored Test Is a Question about an Ambiguity**: Document the reason for `@Ignore`.
- **T5: Test Boundary Conditions**: Most bugs happen at the boundaries; test them exhaustively.
- **T8: Test Coverage Patterns Can Be Revealing**: Analyze what code is *not* executed to find gaps.
- **T9: Tests Should Be Fast**: Slow tests don't get run.
