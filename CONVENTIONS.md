# Conventions

## GitHub & Git Operations

- Use `gh pr create` not `git push` + manual PR
- Use `gh repo clone` not `git clone` for GitHub repos
- Use `gh run view` / `gh run watch` for CI status
- Verify auth with `gh auth status` before operations
- Never call GitHub REST API directly (curl, fetch, etc.)
- Never create GitHub issues from automated workflows — produce local .md files in specs/ instead

## specs/ — All Planning Output Goes Here

Every skill that produces written output writes to `specs/` at the project root:

| Document | Path |
|----------|------|
| Domain context + ADRs | `specs/CONTEXT.md` + `specs/adr/` |
| Domain glossary | `specs/UBIQUITOUS_LANGUAGE.md` |
| Scope definition | `specs/SCOPE.md` |
| Task breakdown | `specs/TASKS.md` |
| Implementation plan | `specs/PLAN.md` (or `specs/PLAN-<feature>.md`) |
| Refactor plan | `specs/REFACTOR.md` |
| Spike learnings | `specs/SPIKE-<name>.md` |
| Bug investigation | `specs/DIAGNOSIS.md` |
| QA session log | `specs/BUG-LOG.md` |

## Code Style

- Functions: 4–20 lines. Split if longer.
- Files: under 500 lines, ideally 200–300. Split by responsibility.
- One thing per function, one responsibility per module (SRP).
- Names: specific and unique. Avoid `data`, `handler`, `Manager`, `Service`. Prefer names whose grep returns < 5 hits in this codebase.
- Types: explicit. No `any`, no untyped public functions.
- No code duplication. Extract shared logic into a function/module.
- Early returns over nested ifs. Max 2 levels of indentation.
- Exception messages must include the offending value and expected shape.
- SOLID beyond SRP: favor interfaces over concrete types (DIP) when injecting dependencies.

## Comments

- Keep your own comments. Never strip them on refactor — they carry intent and provenance.
- Write WHY, not WHAT.
- Docstrings on public functions: intent + one usage example.
- Reference issue numbers / commit SHAs when a line exists because of a specific bug.
- No obvious comments that restate the code.

## Tests (F.I.R.S.T — Uncle Bob Ch 9)

- Tests run headless with a single command (recorded in CLAUDE.md).
- Every new function gets a test. Every bug fix gets a regression test.
- Mocks for external I/O are named fake classes, not inline stubs.
- Tests are **F**ast, **I**ndependent, **R**epeatable, **S**elf-Validating, **T**imely.

## Dependencies

- Inject dependencies through constructor/parameter, not global/import.
- Wrap third-party libs behind a thin project-owned interface.

## Structure

- Follow the framework convention (Rails, Django, Next.js, etc.).
- Predictable paths: controller/model/view, src/lib/test.
- Prefer small focused modules over god files.

## Formatting

- Use the language default formatter (cargo fmt, gofmt, prettier, black, rubocop -A).
- Configured in pre-commit and on-save. No style debates beyond that.

## Logging

- Structured JSON for debugging / observability.
- Plain text only for user-facing CLI output.

## Defensive Code

- Retry with backoff (for API/network calls in skill implementations)
- Timeout (for long-running operations)
- Graceful degradation (when external services/dependencies fail)

The agent implements defensive code only for categories explicitly listed here.
