# Develop TDD — Reference

## Anti-Pattern: Horizontal Slices

**DO NOT write all tests first, then all implementation.** This is "horizontal slicing" — treating RED as "write all tests" and GREEN as "write all code."

This produces **crap tests**:
- Tests written in bulk test _imagined_ behavior, not _actual_ behavior
- You end up testing the _shape_ of things rather than user-facing behavior
- Tests become insensitive to real changes

**Correct approach**: Vertical slices via tracer bullets. One test → one implementation → repeat.

```
WRONG (horizontal):
  RED:   test1, test2, test3, test4, test5
  GREEN: impl1, impl2, impl3, impl4, impl5

RIGHT (vertical):
  RED→GREEN: test1→impl1
  RED→GREEN: test2→impl2
  RED→GREEN: test3→impl3
  ...
```

> The Red Flags table lives in [SKILL.md](SKILL.md#red-flags) — it is core behavioral guidance, not reference detail.

## TDD Phases (Detail)

### Red Phase

Write a failing test first:
- Test describes the desired observable behavior through the public interface
- Run the test to confirm it fails for the right reason (not a syntax error, not a typo)
- Commit: `git commit -m "test(<scope>): <description>"`

### Green Phase

Write the minimum code to make the test pass:
- No extra logic, no anticipated future cases, no premature optimization
- Focus only on making the current test pass
- Commit: `git commit -m "feat(<scope>): <description>"` or `"fix(<scope>): <description>"`

### Refactor Phase

Improve structure without changing behavior:
- Extract duplication, apply SOLID principles where natural, deepen modules
- Run tests after each refactor step to ensure behavior is preserved
- Commit: `git commit -m "refactor(<scope>): <description>"`
- Apply the Boy Scout Rule: leave the code cleaner than you found it

## Visual Slices (UI Alternate Workflow)

For UI components (SwiftUI, React, Flutter) where behavioral unit testing is brittle or low-signal:

1. **Test-First Logic**: Extract logic (state transitions, formatting, validation) into a Controller, ViewModel, or Hook. This logic MUST follow pure TDD.
2. **Visual Verification**: For the View/Component itself:
   - **RED**: Write the component signature and a basic preview/snapshot that fails (or displays placeholder).
   - **GREEN**: Implement the UI and verify visually via manual run, preview, or snapshot test.
   - **REFINE**: Adjust styling and layout until it matches the design.
3. **COMMIT**: `git commit -m "feat(ui): <component name> visual slice verified"`
