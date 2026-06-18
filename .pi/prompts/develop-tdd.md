---
description: Test-driven development with red-green-refactor loop using vertical slices. Use for features (epic tasks) or bugs (specs/bugs/BUG-*.md).
---


# Develop TDD

> **HARD GATE** — Do NOT proceed if on `main` or `master`. Run `kickoff-branch` first to create a feature branch or worktree.
>
> **HARD GATE** — Do NOT write code before you have a plan. New feature: `plan-work` → epic capsule tasks. Bug: `investigate-bug` → `specs/bugs/BUG-*.md` (or use `fix-bug` orchestrator).
>
> **RECURSIVE DISCIPLINE** — This lifecycle applies to EVERY task, including updating these skills. Never skip planning because a task is "meta" or "just documentation."

## Philosophy

Tests verify behavior through public interfaces, not implementation details. A good test reads like a specification. See [REFERENCE.md](REFERENCE.md) for the horizontal-slice anti-pattern and TDD phase detail.

## Red Flags

If you catch yourself thinking these, stop and reconsider — you are likely deviating from production-grade craft.

| Red Flag | Reality |
| :--- | :--- |
| "This is too simple to need tests." | Simple code is where bugs hide. If it's simple, the test is cheap. |
| "I'll refactor this later." | "Later" is when technical debt becomes bankruptcy. Refactor while Green. |
| "The tests are already comprehensive." | If you're adding behavior, you need a new test. Coverage ≠ Correctness. |
| "I'm just fixing a small bug." | Small bugs often indicate deep interface flaws. Investigate root cause. |
| "I need to mock this internal class." | Mocking internals couples tests to implementation. Mock only I/O. |
| "This refactor is out of scope." | Leave the code cleaner than you found it (Boy Scout Rule). |

## Workflow

### 1. Planning

- [ ] Read active `specs/epics/*/epic.yaml` story tasks or `specs/bugs/BUG-*.md` — understand verify steps
- [ ] Confirm interface changes and behaviors to test (prioritize)
- [ ] Design interfaces for testability — identify [deep modules](deep-modules.md) opportunities
- [ ] Get user approval on the plan

Apply the **enforce-first** F.I.R.S.T rubric: Fast, Independent, Repeatable, Self-Validating, Timely.

### 2. Tracer Bullet

Write ONE test that confirms ONE thing about the system:

```
RED:    Write test for first behavior → test fails → commit: test(<scope>): ...
GREEN:  Write minimal code to pass → test passes → commit: feat(<scope>): ...
REFACTOR (optional): clean up → commit: refactor(<scope>): ...
```

### 3. Incremental Loop

> **STREAM CONTINUITY** — When writing file content, output in continuous chunks of ~200 lines. Do not pause. Emit a placeholder comment rather than going silent.

For each remaining behavior: RED → GREEN → REFACTOR (optional). One test at a time. Commit after every GREEN phase.

### 4. Visual Slices (UI alternate workflow)

For UI components where behavioral unit testing is brittle: extract logic into a Controller/ViewModel/Hook (pure TDD), then use Visual Slices for the View layer. See [REFERENCE.md](REFERENCE.md) for the full Visual Slices procedure.

### 5. Refactor

After all tests pass: extract duplication, deepen modules, apply SOLID principles. **Never refactor while RED.**

### 6. Verify

After every behavior cycle, run the verify command from the active epic task. Show evidence before declaring the step done.

### 7. Manual Verification Handover

Once all tests pass: locate the Verification Script in the active epic capsule, present it to the user step-by-step, and wait for confirmation of behavioral correctness.

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

## Handoff

Gate: READY -> next: verify-work
Writes: state.yaml handoff.next_skill = verify-work

---

# Deep Modules

From "A Philosophy of Software Design":

**Deep module** = small interface + lots of implementation

```
┌─────────────────────┐
│   Small Interface   │  ← Few methods, simple params
├─────────────────────┤
│                     │
│                     │
│  Deep Implementation│  ← Complex logic hidden
│                     │
│                     │
└─────────────────────┘
```

**Shallow module** = large interface + little implementation (avoid)

```
┌─────────────────────────────────┐
│       Large Interface           │  ← Many methods, complex params
├─────────────────────────────────┤
│  Thin Implementation            │  ← Just passes through
└─────────────────────────────────┘
```

When designing interfaces, ask:

- Can I reduce the number of methods?
- Can I simplify the parameters?
- Can I hide more complexity inside?

---

# Interface Design for Testability

Good interfaces make testing natural:

1. **Accept dependencies, don't create them**

   ```typescript
   // Testable
   function processOrder(order, paymentGateway) {}

   // Hard to test
   function processOrder(order) {
     const gateway = new StripeGateway();
   }
   ```

2. **Return results, don't produce side effects**

   ```typescript
   // Testable
   function calculateDiscount(cart): Discount {}

   // Hard to test
   function applyDiscount(cart): void {
     cart.total -= discount;
   }
   ```

3. **Small surface area**
   - Fewer methods = fewer tests needed
   - Fewer params = simpler test setup

---

# When to Mock

Mock at **system boundaries** only:

- External APIs (payment, email, etc.)
- Databases (sometimes - prefer test DB)
- Time/randomness
- File system (sometimes)

Don't mock:

- Your own classes/modules
- Internal collaborators
- Anything you control

## Designing for Mockability

At system boundaries, design interfaces that are easy to mock:

**1. Use dependency injection**

Pass external dependencies in rather than creating them internally:

```typescript
// Easy to mock
function processPayment(order, paymentClient) {
  return paymentClient.charge(order.total);
}

// Hard to mock
function processPayment(order) {
  const client = new StripeClient(process.env.STRIPE_KEY);
  return client.charge(order.total);
}
```

**2. Prefer SDK-style interfaces over generic fetchers**

Create specific functions for each external operation instead of one generic function with conditional logic:

```typescript
// GOOD: Each function is independently mockable
const api = {
  getUser: (id) => fetch(`/users/${id}`),
  getOrders: (userId) => fetch(`/users/${userId}/orders`),
  createOrder: (data) => fetch('/orders', { method: 'POST', body: data }),
};

// BAD: Mocking requires conditional logic inside the mock
const api = {
  fetch: (endpoint, options) => fetch(endpoint, options),
};
```

The SDK approach means:
- Each mock returns one specific shape
- No conditional logic in test setup
- Easier to see which endpoints a test exercises
- Type safety per endpoint

---

# Refactor Candidates

After TDD cycle, look for:

- **Duplication** → Extract function/class
- **Long methods** → Break into private helpers (keep tests on public interface)
- **Shallow modules** → Combine or deepen
- **Feature envy** → Move logic to where data lives
- **Primitive obsession** → Introduce value objects
- **Existing code** the new code reveals as problematic

---

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

---

# Good and Bad Tests

## Good Tests

**Integration-style**: Test through real interfaces, not mocks of internal parts.

```typescript
// GOOD: Tests observable behavior
test("user can checkout with valid cart", async () => {
  const cart = createCart();
  cart.add(product);
  const result = await checkout(cart, paymentMethod);
  expect(result.status).toBe("confirmed");
});
```

Characteristics:

- Tests behavior users/callers care about
- Uses public API only
- Survives internal refactors
- Describes WHAT, not HOW
- One logical assertion per test

## Bad Tests

**Implementation-detail tests**: Coupled to internal structure.

```typescript
// BAD: Tests implementation details
test("checkout calls paymentService.process", async () => {
  const mockPayment = jest.mock(paymentService);
  await checkout(cart, payment);
  expect(mockPayment.process).toHaveBeenCalledWith(cart.total);
});
```

Red flags:

- Mocking internal collaborators
- Testing private methods
- Asserting on call counts/order
- Test breaks when refactoring without behavior change
- Test name describes HOW not WHAT
- Verifying through external means instead of interface

```typescript
// BAD: Bypasses interface to verify
test("createUser saves to database", async () => {
  await createUser({ name: "Alice" });
  const row = await db.query("SELECT * FROM users WHERE name = ?", ["Alice"]);
  expect(row).toBeDefined();
});

// GOOD: Verifies through interface
test("createUser makes user retrievable", async () => {
  const user = await createUser({ name: "Alice" });
  const retrieved = await getUser(user.id);
  expect(retrieved.name).toBe("Alice");
});
```

## Clean Test Heuristics (Uncle Bob, Ch 17)

Apply these specific heuristics to maintain a high-quality suite:

- **T1: Insufficient Tests**: A test suite should test everything that could possibly break. Don't stop at "it seems to work."
- **T4: Ignored Tests**: Never ignore a test without documenting the ambiguity. An ignored test is a silent warning of a gap in understanding.
- **T5: Test Boundary Conditions**: Most bugs happen at the edges. Test the exact boundaries (e.g., empty strings, max integers, off-by-one indices).
- **T6: Exhaustively Test Near Bugs**: Bugs congregate. If you find one, there are likely others nearby; test that area thoroughly.
- **T9: Tests Should Be Fast**: Slow tests don't get run. Keep them fast so they remain part of the core developer loop.
