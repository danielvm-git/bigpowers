# Plan Work — Reference

## Navigation

| Lines | Section |
|-------|---------|
| 1 | Title |
| 3–25 | Navigation |
| 26–27 | Output file formats |
| 28–31 | Story spec: `specs/epics/<capsule>/eNNsYY-<slug>.md` |
| 32–61 | Task checklist: `specs/epics/<capsule>/eNNsYY-tasks.yaml` |
| 62–64 | Plan template |
| 65–71 | Story [X.Y]: [title] — Implementation Steps |
| 72–77 | Steps |
| 78–85 | Verification Script (Step-by-Step) |
| 86–89 | Out of scope |
| 90–94 | Risks |
| 95–114 | Verify step format rules |
| 115–116 | Sub-operations |
| 117–127 | Risk Assignment Heuristics |
| 128–143 | Requirement delta tags (e45s29) |
| 144–152 | Define Success |
| 153–161 | Zoom-Out Check |
| 162–169 | Slopcheck |

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
