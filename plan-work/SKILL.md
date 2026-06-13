---
name: plan-work
model: opus
description: "PLANNING SPINE STEP 3 of 3 — Plan the work: write detailed implementation tasks into the active epic capsule (specs/epics/eNN-slug/). Produces countable-story-format .md specs and runnable -tasks.yaml files. Use after slice-tasks (step 2). Not a substitute for scope-work (step 1) or slice-tasks (step 2)."
---

# Plan Work

> **Spine position:** Step 3 — scope-work → slice-tasks → plan-work.

Produce a detailed, verifiable implementation plan in the **active epic capsule directory** (`specs/epics/eNN-slug/`). Output: a story spec `.md` file (countable-story-format) and a decoupled `eNNsYY-tasks.yaml` with runnable verify commands. "I think it works" is not a step.

> **HARD GATE** — Do NOT proceed with a plan until the task's success criteria are clear. If success is ambiguous, run `define-success` first to convert the task into "step → verify: <cmd>" pairs.
>
> **RECURSIVE DISCIPLINE** — This lifecycle applies to EVERY task, including updating these skills. Never skip planning because a task is "meta" or "just documentation."

## Pre-flight

Read: `release-plan.yaml`, `product/SCOPE_LATEST.yaml`, active `epics/<capsule>/epic.yaml`, `tech-architecture/tech-stack.md`, `product/GLOSSARY_LATEST.yaml`.

> **ZOOM-OUT MANDATE** (v1.17.0) — If modifying an existing module: (1) State the module's **purpose**. (2) Name its **callers**. (3) List its **contracts**. Cannot answer all three? Stop — scope is misunderstood.

If this plan touches an existing module, run `assess-impact` first to understand blast radius.

> **DISCOVERY MANDATE** (v1.18.0) — For external API integration, verify the API signature via local docs or search and quote at least one technical detail in the step's context.

> **MULTIPLE INTERPRETATIONS (HARD GATE)** — If the task admits ≥2 valid interpretations, list them and get a user decision before drafting any steps.

> **COMPLEXITY PUSHBACK (HARD GATE)** — Every new abstraction MUST include a one-sentence "Reason for Depth." If it can't be filled non-trivially, the abstraction is premature — use inline code instead.

> **SLOPCHECK (HARD GATE)** — For every external package, tag it `[OK]`, `[SUS]`, or `[SLOP]`. `[SUS]`/`[SLOP]` require human approval before execution.

## Invocation modes

- Default: full plan with zoom-out mandate, impact assessment, slopcheck
- `--fast`: Skip zoom-out and impact assessment. Use for tasks under 3 BCPs with no module interface changes.

## Process

1. **Explore** — Use `Explore` subagent to understand affected modules, existing test patterns, similar prior art, and dependencies.

2. **Draft steps** — Break implementation into the smallest possible steps where each step leaves the codebase working, has one observable outcome, and can be verified with a single command. Red-flag check: name any rationalization you caught before moving to step 3.

3. **Write capsule story spec + tasks** — Output two files inside the active epic capsule. See [REFERENCE.md](REFERENCE.md) for file formats and the plan-template.

4. **Verify step format** — Every step MUST follow: `N. <What to do> → verify: <runnable command>`. See [REFERENCE.md](REFERENCE.md) for good/bad examples.

5. **Review with user** — Confirm step order, granularity, and that verify commands are runnable in this project.

After writing capsule tasks, suggest `kickoff-branch` (if not already on a feature branch) then `build-epic`, `execute-plan`, or `develop-tdd`.

## Handoff

Gate: READY -> next: kickoff-branch
Writes: state.yaml handoff.next_skill = kickoff-branch
