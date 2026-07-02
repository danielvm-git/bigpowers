# Plan Work — Reference

## Output file formats

### Story spec: `specs/epics/<capsule>/eNNsYY-<slug>.md`

Populated countable-story-format with all 20 sections. Minimum maturity: 3 (Countable). Acceptance criteria in §17.

### Task checklist: `specs/epics/<capsule>/eNNsYY-tasks.yaml`

```yaml
story_id: e01s01
title: Login
status: todo
bcps: 3
tasks:
  - id: 1
    description: "Add login form component tests"
    verify: "npm test -- login-form.test.tsx"
    status: todo
```

Update `specs/epics/<capsule>/epic.yaml` manifest to list the story and its BCPs. Run `bash scripts/sync-status-from-epics.sh` after structural changes.

## Plan template

```
### Story [X.Y]: [title] — Implementation Steps

**type:** feat | fix | refactor
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
