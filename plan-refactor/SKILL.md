---
name: plan-refactor
model: sonnet
description: Create a detailed refactor plan with tiny commits via user interview, then save it as specs/REFACTOR_LATEST.md. Use when user wants to plan a refactor, create a refactoring RFC, or break a refactor into safe incremental steps.
---

# Plan Refactor
> **HARD GATE** — **HARD GATE** — Before refactoring, document the current behavior and why it is wrong. Extract one invariant that must be preserved. If you skip this, you will break things you don't expect.


Create a detailed refactor plan through a user interview. Save output to `specs/REFACTOR_LATEST.md`.

## Steps

1. Ask the user for a long, detailed description of the problem they want to solve and any potential ideas for solutions.

2. Explore the repo to verify their assertions and understand the current state of the codebase.

3. Ask whether they have considered other options, and present other options to them.

4. Interview the user about the implementation. Be extremely detailed and thorough.

5. Hammer out the exact scope of the implementation. Work out what you plan to change and what you plan not to change.

6. Look in the codebase to check for test coverage of this area. If there is insufficient test coverage, ask the user what their plans for testing are.

7. Break the implementation into a plan of tiny commits. Remember Martin Fowler's advice: "make each refactoring step as small as possible, so that you can always see the program working."

8. Save the refactor plan to `specs/REFACTOR_LATEST.md`. Create the `specs/` directory if it doesn't exist.

<refactor-plan-template>

## Problem Statement

The problem that the developer is facing, from the developer's perspective.

## Solution

The solution to the problem, from the developer's perspective.

## Commits

A LONG, detailed implementation plan. Write the plan in plain English, breaking down the implementation into the tiniest commits possible. Each commit should leave the codebase in a working state.

Each commit entry follows this format:
```
N. <commit description> → verify: <runnable command>
```

## Decision Document

A list of implementation decisions that were made:

- The modules that will be built/modified
- The interfaces of those modules that will be modified
- Technical clarifications from the developer
- Architectural decisions
- Schema changes, API contracts, specific interactions

Do NOT include specific file paths or code snippets. They may end up being outdated very quickly.

## Testing Decisions

- A description of what makes a good test (only test external behavior, not implementation details)
- Which modules will be tested
- Prior art for the tests (i.e. similar types of tests in the codebase)

## Out of Scope

A description of the things that are out of scope for this refactor.

## Further Notes (optional)

Any further notes about the refactor.

</refactor-plan-template>

After writing `specs/REFACTOR_LATEST.md`, suggest running `kickoff-branch` next to create a refactor branch.
