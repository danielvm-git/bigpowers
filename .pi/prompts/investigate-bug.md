---
description: Investigate a bug or issue by exploring the codebase to find root cause, then write a TDD-based fix plan to specs/bugs/BUG-*.md. Use when user reports a bug, wants to investigate a problem, mentions "triage", or wants to plan a fix.
---


# Investigate Bug

**Boundary**: End-to-end bug entry point — history check → RCA (via `diagnose-root`) → fix approach → TDD plan → bug file. Delegates the 4-phase RCA to `diagnose-root`; does not re-implement it.

Investigate a reported problem, find its root cause, and write a TDD fix plan to `specs/bugs/BUG-*.md`. This is a mostly hands-off workflow — minimize questions to the user.

## Process

### 0. Read previous bug history

Before starting diagnosis:

1. Read `specs/bugs/registry.yaml` (if it exists) — check for prior bugs in the same `scope` or with similar symptoms.
2. If a relevant prior bug is found, read the corresponding `specs/bugs/BUG-*.md` file to understand previous root cause analysis and fix approach.
3. Note in your investigation whether this is a recurrence, a related issue, or novel.

### 1. Capture the problem

Get a brief description of the issue from the user. If they haven't provided one, ask ONE question: "What's the problem you're seeing?"

Do NOT ask follow-up questions yet. Start investigating immediately.

### 2. Explore and diagnose (4-phase RCA)

Run the 4-phase root-cause analysis via the `diagnose-root` skill (Reproduce → Isolate → Hypothesize → Verify). That skill is the canonical RCA engine — do not re-implement the phases here.

Also look at:
- Recent changes to affected files (`git log --oneline <file>`)
- Existing tests (what's tested, what's missing)
- Similar patterns elsewhere in the codebase that work correctly

> **HARD GATE** — Do NOT proceed to Step 3 (Fix Approach) until `diagnose-root` Phase 4 produces a verified root cause. "It probably is X" is not verified.

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

Save the investigation and fix plan to `specs/bugs/BUG-NNN-slug.md`. Create the `specs/bugs/` directory if it doesn't exist.

After writing, append a row to `specs/bugs/registry.yaml` with: bug_id (same timestamp), date, severity, priority, scope, summary, and file path. Create `specs/bugs/registry.yaml` if it doesn't exist.

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
