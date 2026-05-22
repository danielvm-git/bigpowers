---
name: develop-tdd
description: Test-driven development with red-green-refactor loop using vertical slices. Use when user wants to build features or fix bugs using TDD, mentions "red-green-refactor", wants integration tests, asks for test-first development, or wants to implement a task from specs/PLAN.md.
---

# Develop TDD

> **HARD GATE** — Do NOT proceed if on `main` or `master`. Run `kickoff-branch` first to create a feature branch or worktree.
>
> **HARD GATE** — Do NOT write code before you have a plan. If you are starting a new task, run `plan-work` to create `specs/PLAN.md`. If you are fixing a bug, run `investigate-bug` to create `specs/DIAGNOSIS.md`.
>
> **RECURSIVE DISCIPLINE** — This lifecycle apply to EVERY task, including updating these skills. Never skip planning because a task is "meta" or "just documentation."

## Philosophy

**Core principle**: Tests should verify behavior through public interfaces, not implementation details. Code can change entirely; tests shouldn't.

**Good tests** are integration-style: they exercise real code paths through public APIs. They describe _what_ the system does, not _how_ it does it. A good test reads like a specification — "user can checkout with valid cart" tells you exactly what capability exists. These tests survive refactors because they don't care about internal structure.

**Bad tests** are coupled to implementation. They mock internal collaborators, test private methods, or verify through external means. The warning sign: your test breaks when you refactor, but behavior hasn't changed.

See [tests.md](tests.md) for examples and [mocking.md](mocking.md) for mocking guidelines.

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

## Red Flags

If you find yourself thinking these things, you are likely deviating from production-grade craft. Stop and reconsider.

| Red Flag | Reality |
| :--- | :--- |
| "This is too simple to need tests." | Simple code is where bugs hide. If it's simple, the test is cheap. |
| "I'll refactor this later." | "Later" is when technical debt becomes a bankruptcy. Refactor while Green. |
| "The tests are already comprehensive." | If you're adding behavior, you need a new test. Coverage != Correctness. |
| "I'm just fixing a small bug." | Small bugs often indicate deep interface flaws. Investigate root cause. |
| "I need to mock this internal class." | Mocking internals couples tests to implementation. Mock only I/O. |
| "This refactor is out of scope." | Leave the code cleaner than you found it (Boy Scout Rule). |

## Workflow

### 1. Planning

Before writing any code:

- [ ] Read `specs/PLAN.md` or `specs/DIAGNOSIS.md` if they exist — understand the task and verify steps
- [ ] Confirm with user what interface changes are needed
- [ ] Confirm with user which behaviors to test (prioritize)
- [ ] Identify opportunities for [deep modules](deep-modules.md) (small interface, deep implementation)
- [ ] Design interfaces for [testability](interface-design.md)
- [ ] List the behaviors to test (not implementation steps)
- [ ] Get user approval on the plan

Ask: "What should the public interface look like? Which behaviors are most important to test?"

**You can't test everything.** Confirm with the user exactly which behaviors matter most. Focus testing effort on critical paths and complex logic.

Apply the **enforce-first** F.I.R.S.T rubric when writing tests: Fast, Independent, Repeatable, Self-Validating, Timely.

### 2. Tracer Bullet

Write ONE test that confirms ONE thing about the system:

```
RED:    Write test for first behavior → test fails
GREEN:  Write minimal code to pass → test passes
COMMIT: git commit -m "feat/fix(<scope>): first tracer bullet..."
```

This is your tracer bullet — proves the path works end-to-end.

### 3. Incremental Loop

> **STREAM CONTINUITY** — When writing file content, output in continuous chunks of ~200 lines. Do not pause between sections. Continue immediately until complete. If you need time to think, emit a placeholder heading rather than going silent.

For each remaining behavior:

```
RED:    Write next test → fails
GREEN:  Minimal code to pass → passes
COMMIT: git commit -m "<type>(<scope>): <behavior description>"
```

Rules:

- One test at a time
- Only enough code to pass current test
- Don't anticipate future tests
- Keep tests focused on observable behavior
- **Atomic Commits**: Commit after every GREEN phase to record progress and prevent large diffs.

### 4. Visual Slices (UI Alternate Workflow)

For UI components (SwiftUI, React, Flutter) where behavioral unit testing is brittle or low-signal:

1. **Test-First Logic**: Extract logic (state transitions, formatting, validation) into a separate Controller, ViewModel, or Hook. This logic MUST follow pure TDD (Red-Green-Refactor).
2. **Visual Verification**: For the View/Component itself, use "Visual Slices":
   - **RED**: Write the component signature and a basic preview/test snapshot that fails (or displays placeholder).
   - **GREEN**: Implement the UI and verify visually via manual run, preview, or snapshot test.
   - **REFINE**: Adjust styling and layout until it matches the "rich aesthetics" requirement.
3. **COMMIT**: git commit -m "feat(ui): <component name> visual slice verified"

### 5. Refactor

After all tests pass, look for [refactor candidates](refactoring.md):

- [ ] Extract duplication
- [ ] Deepen modules (move complexity behind simple interfaces)
- [ ] Apply SOLID principles where natural
- [ ] Consider what new code reveals about existing code
- [ ] Run tests after each refactor step

**Never refactor while RED.** Get to GREEN first.

### 5. Verify step

After every behavior cycle, run the verify command from `specs/PLAN.md` if one exists for this step. Show evidence before declaring the step done.

## Checklist Per Cycle

```
[ ] Test describes behavior, not implementation
[ ] No test is ignored without an explicit ambiguity note (T4)
[ ] Boundary conditions tested: empty, max, min, off-by-one (T5)
[ ] Tests verify behavior through public interface only — no private methods (T8)
[ ] Test would survive internal refactor
[ ] Code is minimal for this test
[ ] No speculative features added
[ ] Every new abstraction has an explicit "Reason for Depth" justification
[ ] Progress committed (Conventional Commits)
[ ] verify: command passes
```
