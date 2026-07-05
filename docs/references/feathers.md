# Michael Feathers: Working Effectively with Legacy Code

**Purpose:** Documents Michael Feathers' key concepts — seams, characterization tests, and the "legacy code is code without tests" definition — and how bigpowers skills embody these practices for safe code modification.

**Credit:** Michael Feathers. Key work: *Working Effectively with Legacy Code* (2004).

---

## What is Legacy Code?

Feathers gave the software industry its most pragmatic definition: **legacy code is code without tests**. This definition shifts the focus from code age or technology to *testability*: if you can't verify that a change is safe, you're working with legacy code regardless of when it was written.

---

## Seams

A **seam** is a place in the code where you can alter behavior without editing the code at that point. Feathers identifies several seam types:

| Seam Type | What it enables | Example |
|---|---|---|
| **Object Seam** | Replace a dependency with a test double | Inject a mock instead of a real database connection |
| **Link Seam** | Replace a library at link time | Swap a production .so/.dll with a test version |
| **Preprocessing Seam** | Use `#ifdef` or macros to substitute code | Compile with `TEST` flag to use test implementations |

The key insight: finding seams is the prerequisite for getting legacy code under test. Without a seam, you can't isolate the code you want to test from its dependencies.

---

## Characterization Tests

When you don't know what legacy code does, write **characterization tests** — tests that capture the code's *current* behavior, whether correct or not. These tests:

1. **Characterize** what the code actually does (not what it should do)
2. **Pin** the current behavior so changes can be compared against it
3. **Enable safe refactoring** by detecting unintended behavioral changes

Once characterization tests are in place, you can refactor with confidence — any behavior change (intended or not) is caught immediately.

---

## The Legacy Code Change Algorithm

Feathers describes a systematic approach for changing legacy code:

1. **Identify change points** — where do you need to modify?
2. **Find test points** — where can you observe the behavior?
3. **Break dependencies** — use seams to isolate the change area
4. **Write characterization tests** — pin current behavior
5. **Make the change** — refactor and add the new behavior
6. **Refactor the tests** — clean up characterization tests if needed

---

## How bigpowers uses

| Feathers Concept | bigpowers Skill | How it's embodied |
|---|---|---|
| Characterization tests | `investigate-bug` | Writes pinning tests to capture current (broken) behavior before fixing |
| Seam identification | `investigate-bug` | Identifies object/link seams as part of bug investigation |
| Legacy code definition | `develop-tdd` | Red-green-refactor requires tests before changes — no code without tests |
| Break dependencies | `plan-refactor` | Plans refactors to extract seams before behavioral changes |
| Safe modification | `audit-code` | Gates changes with verification that existing behavior is preserved |

---

## See Also

- [`kent-beck.md`](kent-beck.md) — Beck's TDD origins (characterization tests are a variant of TDD)
- [`fowler.md`](fowler.md) — Fowler's refactoring catalog (what you do after characterization tests pass)
- [`uncle-bob.md`](uncle-bob.md) — Martin's Clean Code (the target state you're working toward)
- [`investigate-bug`](../../skills/investigate-bug/SKILL.md) — the bigpowers skill that operationalizes Feathers' algorithm
