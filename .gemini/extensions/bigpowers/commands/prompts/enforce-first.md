
# Enforce FIRST
> **HARD GATE** — **HARD GATE** — Before shipping, ALL enforcement checks must pass: lint, typecheck, tests, coverage gates. Do NOT disable or skip checks to get to green.


Apply the F.I.R.S.T rubric (Uncle Bob, Clean Code Chapter 9) to evaluate and improve tests.

This skill is typically invoked internally by `develop-tdd` during the test-writing phase. It can also be run standalone on an existing test suite.

## Modes

- Default: full F.I.R.S.T audit (all 5 criteria)
- --quick: Check F (Fast), I (Independent), and S (Self-Validating) only. Used by build-epic step 6 as a mechanical gate after audit-code. Skips R (Repeatable) and T (Timely) which require contextual judgment.

## The F.I.R.S.T Rubric

### F — Fast

Tests must run quickly. Slow tests don't get run. They don't get trusted.

- [ ] No real network calls (use fakes/stubs for external I/O)
- [ ] No real database (use in-memory or transaction-rollback strategies)
- [ ] No `sleep` or arbitrary timeouts in test code
- [ ] The full suite runs in under 30 seconds (target; adjust to project size)

**Fix:** Replace slow I/O with named fake classes. Never inline anonymous stubs.

### I — Independent

Tests must not depend on each other. Running in any order must produce the same result.

- [ ] No shared mutable state between tests
- [ ] Each test sets up its own data and tears it down
- [ ] No test assumes another test ran first
- [ ] Tests can be run individually (e.g. `npm test -- mytest.test.ts`) and pass

**Fix:** Move setup into `beforeEach`. Use factory functions to build test data.

### R — Repeatable

Tests must pass consistently in any environment.

- [ ] No dependency on machine-specific paths, ports, or environment variables (unless explicitly injected)
- [ ] No dependency on current time without mocking the clock
- [ ] No flakiness — a test that sometimes fails is worse than no test
- [ ] Tests pass on CI the same way they pass locally

**Fix:** Inject time, randomness, and environment as parameters. Pin seeds for anything random.

### S — Self-Validating

Tests must report pass or fail automatically. No human inspection required.

- [ ] Tests use assertions (`expect`, `assert`, etc.) — not just `console.log`
- [ ] Failure messages are descriptive enough to diagnose without reading the test body
- [ ] No tests that "pass" by default when the feature is broken

**Fix:** Add assertion messages. Use matchers that describe the expected behavior.

### T — Timely

Tests must be written at the right time — before or immediately with the code they test.

- [ ] Tests are written in the same commit as the code (or the commit before, if TDD)
- [ ] No "I'll add tests later" patterns
- [ ] Bug fixes include a regression test that would have caught the bug

**Fix:** Run `develop-tdd` — it enforces the timely principle by design.

## Applying the rubric

For each failing criterion:
1. Identify which tests violate it
2. Describe the fix
3. Apply the fix
4. Re-run the suite to confirm it still passes

Report: "F.I.R.S.T audit complete. X criteria passed, Y fixed."
