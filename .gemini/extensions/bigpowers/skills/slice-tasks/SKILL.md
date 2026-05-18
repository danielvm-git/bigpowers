---
name: slice-tasks
description: "Break a plan, spec, or PRD into independently-grabbable tasks using tracer-bullet vertical slices. Saves to specs/TASKS.md. Use when user wants to convert a plan into tasks, create implementation tickets, or break down work into slices."
---


# Slice Tasks

Break a plan into independently-grabbable tasks using vertical slices (tracer bullets). Output saved to `specs/TASKS.md`.

## Process

### 1. Gather context

Work from whatever is already in the conversation context. If the user references `specs/SCOPE.md`, read it first.

### 2. Explore the codebase (optional)

If you have not already explored the codebase, do so to understand the current state of the code.

### 3. Draft vertical slices

Break the plan into **tracer bullet** tasks. Each task is a thin vertical slice that cuts through ALL integration layers end-to-end, NOT a horizontal slice of one layer.

Slices may be 'HITL' or 'AFK'. HITL slices require human interaction, such as an architectural decision or a design review. AFK slices can be implemented and merged without human interaction. Prefer AFK over HITL where possible.

<vertical-slice-rules>
- Each slice delivers a narrow but COMPLETE path through every layer (schema, API, UI, tests)
- A completed slice is demoable or verifiable on its own
- Prefer many thin slices over few thick ones
</vertical-slice-rules>

### 4. Quiz the user

Present the proposed breakdown as a numbered list. For each slice, show:

- **Title**: short descriptive name
- **Type**: HITL / AFK
- **Blocked by**: which other slices (if any) must complete first
- **User stories covered**: which user stories this addresses (if the source material has them)

Ask the user:

- Does the granularity feel right? (too coarse / too fine)
- Are the dependency relationships correct?
- Should any slices be merged or split further?
- Are the correct slices marked as HITL and AFK?

Iterate until the user approves the breakdown.

### 5. Write specs/TASKS.md

Save the approved task breakdown to `specs/TASKS.md`. Create the `specs/` directory if it doesn't exist.

<tasks-template>
# Tasks

## Slices

### 1. [Slice title]
- **Type:** HITL / AFK
- **Blocked by:** None / #2, #3
- **User stories:** 1, 3, 5
- **What to build:** A concise description of this vertical slice end-to-end behavior.
- **Acceptance criteria:**
  - [ ] Criterion 1
  - [ ] Criterion 2

### 2. [Slice title]
...
</tasks-template>

After writing `specs/TASKS.md`, suggest running `plan-work` next to produce a detailed implementation plan.
