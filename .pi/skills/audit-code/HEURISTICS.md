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
