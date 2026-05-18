---
name: diagnose-root
description: "Run a 4-phase root cause analysis on an active problem: reproduce, isolate, hypothesize, verify. Use when a bug is confirmed but the root cause is unclear, when investigation needs to go deeper than symptoms, or when user mentions "root cause" or "why is this happening"."
---


# Diagnose Root

Systematic 4-phase root cause analysis. Do not guess or jump to fixes — work through each phase in order.

## Phase 1: Reproduce

Establish a reliable reproduction case before touching anything.

- [ ] Run the failing test or reproduce the user-reported behavior
- [ ] Confirm the failure is consistent (not intermittent)
- [ ] Document the exact inputs, environment, and observed output
- [ ] Note the difference between actual and expected behavior

**Do not proceed to Phase 2 until you can reproduce reliably.**

If you cannot reproduce: ask the user for more context — environment variables, data state, exact steps. Intermittent failures are diagnosed differently (add logging first, come back when it recurs).

## Phase 2: Isolate

Narrow down where in the system the failure originates.

- [ ] Identify the code path from the entry point to the failure
- [ ] Use `git log --oneline <file>` on affected files — was this recently changed?
- [ ] Binary-search the call stack: which layer first produces wrong output?
- [ ] Check: is the input correct but the processing wrong, or is the input already wrong when it arrives?
- [ ] Eliminate innocent modules one by one

Target: a single function, method, or module where the wrong behavior first appears.

## Phase 3: Hypothesize

Form a precise, falsifiable hypothesis about the root cause.

Write it down: "The bug occurs because [specific condition] causes [specific behavior] instead of [expected behavior]."

Generate at least 2 alternative hypotheses. For each one:
- What evidence would confirm it?
- What evidence would rule it out?

Rank by probability given what you observed in Phase 2.

## Phase 4: Verify

Test your top hypothesis without modifying production code yet.

- [ ] Add a targeted assertion or log that would fire if your hypothesis is correct
- [ ] Run the reproduction case
- [ ] If the assertion fires → hypothesis confirmed; document root cause
- [ ] If not → return to Phase 3 with the new evidence

**Document the verified root cause** in one paragraph: what was wrong, why it was wrong, and what the minimal fix is.

Suggest next skill: `validate-fix` to implement and prove the fix, or `investigate-bug` to write it to `specs/DIAGNOSIS.md` if not already done.
