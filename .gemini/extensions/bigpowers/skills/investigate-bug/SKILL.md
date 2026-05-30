---
name: investigate-bug
description: "Investigate a bug or issue by exploring the codebase to find root cause, then write a TDD-based fix plan to specs/bugs/BUG-*.md. Use when user reports a bug, wants to investigate a problem, mentions "triage", or wants to plan a fix."
---


# Investigate Bug

Investigate a reported problem, find its root cause, and write a TDD fix plan to `specs/bugs/BUG-*.md`. This is a mostly hands-off workflow — minimize questions to the user.

## Process

### 0. Read previous bug history

Before starting diagnosis:

1. Read `specs/bugs/BUG-LOG.md` (if it exists) — check for prior bugs in the same `scope` or with similar symptoms.
2. If a relevant prior bug is found, read the corresponding `specs/bugs/BUG-*.md` file to understand previous root cause analysis and fix approach.
3. Note in your investigation whether this is a recurrence, a related issue, or novel.

### 1. Capture the problem

Get a brief description of the issue from the user. If they haven't provided one, ask ONE question: "What's the problem you're seeing?"

Do NOT ask follow-up questions yet. Start investigating immediately.

### 2. Explore and diagnose (4-phase RCA)

Use the Agent tool with subagent_type=Explore to investigate the codebase. Run these phases in order:

**Phase 1 — Reproduce**: Confirm the failure is consistent. Document exact inputs, environment, and observed vs. expected output. Do not proceed until you can reproduce reliably.

**Phase 2 — Isolate**: Trace the code path from entry point to failure. Binary-search the call stack to find which layer first produces wrong output. Target: a single function or module where the wrong behavior first appears.

**Phase 3 — Hypothesize**: Write a falsifiable hypothesis: "The bug occurs because [condition] causes [behavior] instead of [expected]." Generate at least 2 alternatives. Rank by probability.

**Phase 4 — Verify**: Add a targeted assertion or log that fires if your top hypothesis is correct. Run the reproduction case. If confirmed, document the root cause. If not, return to Phase 3 with new evidence.

> **HARD GATE** — Do NOT proceed to Step 3 (Fix Approach) until Phase 4 produces a verified root cause. "It probably is X" is not verified.

Also look at:
- Recent changes to affected files (`git log --oneline <file>`)
- Existing tests (what's tested, what's missing)
- Similar patterns elsewhere in the codebase that work correctly

### 3. Identify the fix approach

Based on your investigation, determine:

- The minimal change needed to fix the root cause
- Which modules/interfaces are affected
- What behaviors need to be verified via tests
- Whether this is a regression, missing feature, or design flaw
- Risk level: Low / Medium / High

### 4. Design TDD fix plan

Create a concrete, ordered list of RED-GREEN cycles. Each cycle is one vertical slice:

- **RED**: Describe a specific test that captures the broken/missing behavior
- **GREEN**: Describe the minimal code change to make that test pass

Rules:
- Tests verify behavior through public interfaces, not implementation details
- One test at a time, vertical slices (NOT all tests first, then all code)
- Each test should survive internal refactors
- Include a final refactor step if needed
- **Durability**: Only suggest fixes that would survive radical codebase changes. Tests assert on observable outcomes (API responses, UI state, user-visible effects), not internal state.

### 5. Write the bug file

Save the investigation and fix plan to `specs/bugs/BUG-YYYY-MM-DDTHHMMSS.md`. Create the `specs/bugs/` directory if it doesn't exist.

After writing, append a row to `specs/bugs/BUG-LOG.md` with: bug_id (same timestamp), date, severity, priority, scope, summary, and file path. Create `specs/bugs/BUG-LOG.md` if it doesn't exist.

<diagnosis-template>

# BUG-YYYY-MM-DDTHHMMSS: [short title]

## Problem

A clear description of the bug or issue, including:
- What happens (actual behavior)
- What should happen (expected behavior)
- How to reproduce (if applicable)

## Root Cause Analysis

Describe what you found during investigation:
- The code path involved
- Why the current code fails
- Any contributing factors
- Risk level: Low / Medium / High

Do NOT include specific file paths, line numbers, or implementation details that couple to current code layout. Describe modules, behaviors, and contracts instead.

## TDD Fix Plan

A numbered list of RED-GREEN cycles:

1. **RED**: Write a test that [describes expected behavior]
   **GREEN**: [Minimal change to make it pass]
   **verify**: [runnable command]

2. **RED**: Write a test that [describes next behavior]
   **GREEN**: [Minimal change to make it pass]
   **verify**: [runnable command]

**REFACTOR**: [Any cleanup needed after all tests pass]

## Acceptance Criteria

- [ ] Criterion 1
- [ ] Criterion 2
- [ ] All new tests pass
- [ ] Existing tests still pass

## Resolution

<!-- filled in by validate-fix -->

</diagnosis-template>

After writing the bug file, print a one-line summary of the root cause and suggest running `kickoff-branch` next to create a fix branch.
