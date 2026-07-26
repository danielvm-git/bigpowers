---
name: plan-work
model: opus
description: "PLANNING SPINE STEP 3 of 3 — Plan the work: write detailed implementation tasks into the active epic capsule (specs/epics/eNN-slug/). Produces countable-story-format .md specs and runnable -tasks.yaml files. Use after slice-tasks (step 2). Not a substitute for scope-work (step 1) or slice-tasks (step 2)."
disable-model-invocation: true
---

# story: e45s29

# Plan Work

> **Spine position:** Step 3 — scope-work → slice-tasks → plan-work.

Produce a detailed, verifiable implementation plan in the **active epic capsule directory** (`specs/epics/eNN-slug/`). Output: a story spec `.md` file (countable-story-format) and a decoupled `eNNsYY-tasks.yaml` with runnable verify commands. "I think it works" is not a step.

> **HARD GATE** — Do NOT proceed with a plan until the task's success criteria are clear. If success is ambiguous, convert the task into "step → verify: `<cmd>`" pairs here before writing tasks — every task ships a runnable `verify:` or the plan is not done.
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

> **Timing:** `bash scripts/bp-timing.sh start plan-work` at invocation; `bash scripts/bp-timing.sh end plan-work` before handoff.

1. **Explore** — Use `Explore` subagent to understand affected modules, existing test patterns, similar prior art, and dependencies.

2. **Draft steps** — Break implementation into the smallest possible steps where each step leaves the codebase working, has one observable outcome, and can be verified with a single command. Red-flag check: name any rationalization you caught before moving to step 3.

3. **Write capsule story spec + tasks** — Output two files inside the active epic capsule. See [REFERENCE.md](REFERENCE.md) for file formats and the plan-template. Each task MUST include a `risk:` field (`P0` | `P1` | `P2` | `P3`) based on BCP + story type heuristics (see REFERENCE.md). If a test plan artifact (`specs/tech-architecture/eNN-TEST_PLAN_LATEST.md`) exists, read it and inherit its P0/P1 risk classifications and scenario IDs (`SC-eNNsYY-P0-NN`). Each task optionally includes a `security:` field (`none` / `low` / `medium` / `high`) sourced from the epic's `specs/security/epics/<id>/THREAT_MODEL.md`. Tasks with `security: medium` or `security: high` MUST include "no new security findings in affected paths" in their verify steps. Each task should also include an `allure:` block to drive test reporting: `severity:` maps risk to Allure severity (`P0→critical`, `P1→high`, `P2→normal`, `P3→minor`), and `categories:` is a list of relevant tags like `"Security Review"`, wave names, or test categories (see REFERENCE.md for the full template).

   **Requirement delta tags (e45s29):** When a story modifies existing behavior, the story spec § Requirements MUST use OpenSpec-style delta tags with mandatory before/after content:

   | Tag | When | Required content |
   |-----|------|------------------|
   | `ADDED` | New requirement | Full requirement text |
   | `MODIFIED` | Changed behavior | **Before:** prior behavior · **After:** new behavior |
   | `REMOVED` | Retired requirement | **Before:** what existed · **After:** (removed) + rationale |
   | `RENAMED` | ID or title change only | **Before:** old ID/title · **After:** new ID/title |

   Net-new stories (greenfield) use `ADDED` only. `MODIFIED`/`REMOVED`/`RENAMED` without before/after blocks fail the plan-work gate.

4. **Verify step format** — Every step MUST follow: `N. <What to do> → verify: <runnable command>`. See [REFERENCE.md](REFERENCE.md) for good/bad examples.

4a. **Cross-artifact consistency pass (HARD GATE — e45s04)** — Before handoff, run:

```bash
bash scripts/lib/plan-consistency-check.sh specs/epics/<capsule>/
```

Print CRITICAL / HIGH / MED findings. **CRITICAL or HIGH blocks code generation** — fix capsule artifacts first. MED requires explicit user acknowledgment.

4b. **tasks.yaml failing ledger (e45s06)** — Every new task entry starts with `status: failing`. Only flip to `status: passing` after its `verify:` command exits 0 during `develop-tdd` or `verify-work`. Never pre-mark passing at plan time.

5. **Review with user** — Confirm step order, granularity, and that verify commands are runnable in this project.

## Lifecycle Gates (e45s09)

| Gate | When | Pass condition |
|------|------|----------------|
| **Pre-Implementation** | Before `kickoff-branch` / first RED commit | Root-cause stated for bugs; `assess-impact` done for module changes; plan-consistency-check PASS |
| **Validation** | Story marked done | All tasks `status: passing`; verify evidence in `specs/verifications/` |
| **Reopen-don't-refile** | Regression on shipped story | Reopen existing story/bug — do not create duplicate capsule entries |

After writing capsule tasks, suggest `kickoff-branch` (if not already on a feature branch) then `build-epic`, `execute-plan`, or `develop-tdd`.

## Verify

→ verify: `test -f scripts/lib/plan-consistency-check.sh && EPIC=$(ls -d specs/epics/*/ 2>/dev/null | grep -v archive | sort | head -1) && test -n "$EPIC" && bash scripts/lib/plan-consistency-check.sh "$EPIC" >/dev/null 2>&1`



## Handoff

Gate: READY -> next: kickoff-branch
Writes: state.yaml handoff.next_skill = kickoff-branch


<!-- story: e01s01 -->
<!-- story: e02s02 -->
<!-- story: e06s01 -->
<!-- story: e06s02 -->

---

# Plan Work — Reference

## Navigation

| Lines | Section |
|-------|---------|
| 1 | Title |
| 3–14 | Navigation |
| 16–38 | Output file formats |
| 40–71 | Plan template |
| 73–91 | Verify step format rules |
| 93–131 | Sub-operations (risk, define-success, zoom-out, slopcheck, delta tags) |

## Output file formats

### Story spec: `specs/epics/<capsule>/eNNsYY-<slug>.md`

Populated countable-story-format with all 20 sections. Minimum maturity: 3 (Countable). Acceptance criteria in §17.

### Task checklist: `specs/epics/<capsule>/eNNsYY-tasks.yaml`

```yaml
story_id: e01s01
title: Login
status: failing
bcps: 3
tasks:
  - id: 1
    description: "Add login form component tests"
    verify: "npm test -- login-form.test.tsx"
    risk: P1
    status: failing   # flip to passing only after verify exits 0 (e45s06)
    allure:
      severity: high              # P0→critical, P1→high, P2→normal, P3→minor
      categories:
        - "Auth"
        - "Security Review"
```

**Allure severity mapping:**
- `P0` → `critical`
- `P1` → `high`
- `P2` → `normal`
- `P3` → `minor`

`categories` is a list of relevant tags — wave names, test categories (e.g. `"unit"`, `"integration"`), or thematic groupings (e.g. `"Security Review"`).

Update `specs/epics/<capsule>/epic.yaml` manifest to list the story and its BCPs. Run `bash scripts/sync-status-from-epics.sh` after structural changes.

## Plan template

```
### Story [X.Y]: [title] — Implementation Steps

**type:** feat | fix | refactor
**risk:** P0 | P1 | P2 | P3
**context:** domain | infra
**Context**: [One paragraph: what this story implements and why]

## Steps

1. [Step description] (ref: ADR-NNNN or commit SHA) → verify: `<runnable command>`
2. [Step description] (ref: ADR-NNNN or commit SHA) → verify: `<runnable command>`
...

## Verification Script (Step-by-Step)

[A human-readable, step-by-step script for the user to verify the story's outcome.]

1. [Action 1: e.g. Start the server]
2. [Action 2: e.g. Open browser to http://localhost:3000]
3. [Observation: e.g. Verify that the login modal appears]

## Out of scope

- [Explicit exclusions]

## Risks

- [Anything that could go wrong and how to detect it early]
```

## Verify step format rules

Every step MUST follow this exact format:
```
N. <What to do> → verify: <runnable command that proves it worked>
```

**Good examples:**
```
1. Add User model with email and name fields → verify: npm test -- user.test.ts
2. Add POST /users endpoint → verify: curl -s -X POST http://localhost:3000/users -d '{"email":"a@b.com"}' | jq .id
3. Add email uniqueness constraint → verify: npm test -- user-uniqueness.test.ts
```

**Bad examples (no verify command):**
```
1. Implement the user creation flow
2. Write tests for the API
```

## Sub-operations

### Risk Assignment Heuristics

Every task and story MUST be assigned a `risk:` level (P0, P1, P2, P3). When `specs/tech-architecture/eNN-TEST_PLAN_LATEST.md` exists for the epic, defer to its scenario risk mapping (`SC-eNNsYY-P0-NN`). Otherwise, apply these heuristics based on BCP and story type:

- **P0**: Critical path, data loss risk, auth/security boundary, external integration, or high BCP (≥ 5).
- **P1**: Core feature logic, state mutations, standard business value (BCP 3-4).
- **P2**: Utility functions, UI layout changes, display-only data, low risk (BCP 2).
- **P3**: Documentation, cosmetic tweaks, CSS variables, zero behavioral change (BCP 1).

`verify-work` scales its UAT depth based on this field.

### Requirement delta tags (e45s29)

When modifying existing behavior in story spec § Requirements:

```markdown
#### MODIFIED: User can reset password via email link
**Before:** Password reset required admin approval.
**After:** Self-service reset via signed email link (expires 1h).

#### REMOVED: Legacy OAuth1 login
**Before:** OAuth1 provider supported for enterprise SSO.
**After:** (removed) — provider deprecated; OAuth2 only.
```

Tags: `ADDED`, `MODIFIED`, `REMOVED`, `RENAMED`. `MODIFIED`/`REMOVED`/`RENAMED` without before/after → plan-work gate FAIL.

### Define Success

Before planning, convert task statements into observable "step → verify: <cmd>" pairs:
- Break the task into observable outcomes (behaviors) rather than implementation steps
- Write pairs in the format: `[What must be true] → verify: <runnable command>`
- Challenge completeness: are all required behaviors covered?
- Get user confirmation: "Does this capture everything the task requires?"
- Once confirmed, these pairs become the skeleton for plan-work steps

### Zoom-Out Check

When modifying an existing module, confirm scope is understood:
- State the module's **purpose** — what is it responsible for?
- Name the **callers** — who depends on it?
- List the **contracts** — what invariants or interfaces must be preserved?

If you cannot answer all three without deep code archaeology, scope is misunderstood. Clarify with the user before writing steps.

### Slopcheck

For every external package proposed in the plan, tag each with one of:
- `[OK]` — package is mature, actively maintained, appropriate scope
- `[SUS]` — suspiciously broad, has maintenance concerns, or unclear fit
- `[SLOP]` — unmaintained, known security issues, or out of scope

`[SUS]` and `[SLOP]` require explicit human approval before the step may execute. Document tags inline next to the package name.
