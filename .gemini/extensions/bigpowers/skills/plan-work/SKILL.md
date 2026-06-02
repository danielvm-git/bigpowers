---
name: plan-work
description: "Write detailed implementation tasks into the active epic shard (specs/epics/eNN-*.yaml). Every task must include a runnable verify command. Use when user needs step-by-step plan with evidence, or after plan-release."
---


# Plan Work

Produce a detailed, verifiable implementation plan in the **active epic shard** (`specs/epics/eNN-*.yaml` under the target story's `tasks[]`). Every step must be paired with a runnable verify command — "I think it works" is not a step.

> **HARD GATE** — Do NOT proceed with a plan until the task's success criteria are clear. If success is ambiguous, run `define-success` first to convert the task into "step → verify: <cmd>" pairs.
>
> **RECURSIVE DISCIPLINE** — This lifecycle apply to EVERY task, including updating these skills. Never skip planning because a task is "meta" or "just documentation."

## Pre-flight

Before writing the plan, check if `define-success` has been run. If the task's success criteria are unclear, run `define-success` first to convert the task into "step → verify: <cmd>" pairs.

Read any existing `specs/` files: `release-plan.yaml`, `requirements/SCOPE_LATEST.yaml`, active `epics/*.yaml`, `plans/TECH_STACK_LATEST.md`, `requirements/GLOSSARY_LATEST.yaml`.

> **ZOOM-OUT MANDATE** (v1.17.0 Guardrails) — If this plan modifies an existing module, function, or behavior:
> 1. State the module's **purpose** — what is it responsible for?
> 2. Name the **callers** — who depends on it?
> 3. List the **contracts** — what invariants or interfaces must be preserved?
> 
> If you cannot answer all three without deep code archaeology, the scope is misunderstood. Stop and clarify with the user before writing steps.

If this plan touches an existing module or symbol, run `assess-impact` first to understand the blast radius before writing steps.

> **DISCOVERY MANDATE** (v1.18.0 Guardrails) — For any step involving external API integration (e.g., macOS CGEventTap, AWS SDK, Third-party libraries):
> 1. You MUST perform a `google_web_search` or `grep_search` of local documentation to verify the API signature and constraints.
> 2. You MUST quote at least one technical detail (method name, parameter, or error case) from your discovery in the step's context.
> 
> Plans that skip discovery for complex integrations are [SUS] and should be rejected.

> **MULTIPLE INTERPRETATIONS (HARD GATE)** — If the task statement admits ≥2 valid interpretations, you must list them and get a decision from the user before drafting any steps. Do not assume intent.

> **COMPLEXITY PUSHBACK (HARD GATE)** — Every step introducing a new abstraction (class, interface, helper, layer) MUST include a one-sentence "Reason for Depth": _"This abstraction is needed because [forcing function]..."_. If the sentence cannot be filled with a non-trivial reason, the abstraction is premature. Delete it and use inline code instead.

> **SLOPCHECK (HARD GATE)** — For every external package proposed in the plan, run slopcheck (or manual registry check) and tag: `[OK]`, `[SUS]`, or `[SLOP]`. `[SUS]` and `[SLOP]` require explicit human approval before the step may execute. Document tags inline next to the package name.

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

**Red-flag check**: before moving to Step 3, name any rationalization you caught yourself making — skipping a gate, adding out-of-scope steps, omitting a verify command. Write them out; do not suppress them.

### 3. Write epic shard tasks

Append tasks under the relevant story in `specs/epics/{epic-id}-*.yaml` (`tasks[]` with `desc` + `verify`). Update `specs/release-plan.yaml` if a new story is needed. Run `bash scripts/sync-status-from-epics.sh` after structural changes.

<plan-template>

### Story [X.Y]: [title] — Implementation Steps

**type:** feat | fix | refactor  
**context:** domain | infra  
**Context**: [One paragraph: what this story implements and why]

## Steps

1. [Step description] (ref: ADR-NNNN or commit SHA) → verify: `<runnable command>`

2. [Step description] (ref: ADR-NNNN or commit SHA) → verify: `<runnable command>`

3. [Step description] (ref: ADR-NNNN or commit SHA) → verify: `<runnable command>`

...

## Verification Script (Step-by-Step)

[A human-readable, step-by-step script for the user to verify the story's outcome. Focus on user-observable behavior.]

1. [Action 1: e.g. Start the server]
2. [Action 2: e.g. Open browser to http://localhost:3000]
3. [Action 3: e.g. Click 'Login']
4. [Observation: e.g. Verify that the login modal appears]

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

After writing epic tasks, suggest `kickoff-branch` (if not already on a feature branch) then `build-epic`, `execute-plan`, or `develop-tdd`.
