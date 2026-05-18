---
name: plan-work
description: "Write a detailed implementation plan to specs/RELEASE-PLAN.md. Every step must include a runnable verify command (Karpathy verification template). Use when user has a task to implement and needs a step-by-step plan with evidence checkpoints, or after plan-release produces specs/RELEASE-PLAN.md."
---


# Plan Work

Produce a detailed, verifiable implementation plan in `specs/RELEASE-PLAN.md`. Every step must be paired with a runnable verify command — "I think it works" is not a step.

> **HARD GATE** — Do NOT proceed with a plan until the task's success criteria are clear. If success is ambiguous, run `define-success` first to convert the task into "step → verify: <cmd>" pairs.
>
> **RECURSIVE DISCIPLINE** — This lifecycle apply to EVERY task, including updating these skills. Never skip planning because a task is "meta" or "just documentation."

## Pre-flight

Before writing the plan, check if `define-success` has been run. If the task's success criteria are unclear, run `define-success` first to convert the task into "step → verify: <cmd>" pairs.

Read any existing `specs/` files: RELEASE-PLAN.md, SCOPE.md, TASKS.md, CONTEXT.md, UBIQUITOUS_LANGUAGE.md.

If this plan touches an existing module or symbol, run `assess-impact` first to understand the blast radius before writing steps.

## Process

### 1. Explore the codebase

Use the Agent tool with subagent_type=Explore to understand:
- Affected modules and their current interfaces
- Existing test patterns to follow
- Any similar features already implemented (prior art)
- Dependencies that will be needed

### 2. Draft steps

Break the implementation into the smallest possible steps where each step:
- Leaves the codebase in a working state (tests pass)
- Has exactly one observable outcome
- Can be verified with a single runnable command

### 3. Write specs/RELEASE-PLAN.md

Append the detailed steps under the relevant story in `specs/RELEASE-PLAN.md`. Create the `specs/` directory if it doesn't exist.

<plan-template>

### Story [X.Y]: [title] — Implementation Steps

**Context**: [One paragraph: what this story implements and why]

## Steps

1. [Step description] → verify: `<runnable command>`

2. [Step description] → verify: `<runnable command>`

3. [Step description] → verify: `<runnable command>`

...

## Out of scope

- [Explicit exclusions]

## Risks

- [Anything that could go wrong and how to detect it early]

</plan-template>

### 4. Verify step format rules

Every step MUST follow this exact format:
```
N. <What to do> → verify: <runnable command that proves it worked>
```

Good examples:
```
1. Add User model with email and name fields → verify: npm test -- user.test.ts
2. Add POST /users endpoint → verify: curl -s -X POST http://localhost:3000/users -d '{"email":"a@b.com"}' | jq .id
3. Add email uniqueness constraint → verify: npm test -- user-uniqueness.test.ts
```

Bad examples (no verify command):
```
1. Implement the user creation flow
2. Write tests for the API
```

### 5. Review with user

Before finalizing, confirm:
- Does the step order make sense?
- Is the granularity right (not too coarse, not too fine)?
- Are the verify commands actually runnable in this project?

After writing `specs/RELEASE-PLAN.md`, suggest `kickoff-branch` (if not already on a feature branch) then `execute-plan` or `develop-tdd`.
