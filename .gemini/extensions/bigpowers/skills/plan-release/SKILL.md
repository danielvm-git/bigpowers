---
name: plan-release
description: "Convert elaborated specs into a structured release plan with Gherkin acceptance criteria and WSJF-sorted epics. Produces specs/RELEASE-PLAN.md. Use when a spec is clear and ready to plan, after elaborate-spec, or when the user wants a release plan broken into epics and stories."
---


# Plan Release

> **HARD GATE** — Do NOT run this skill unless `elaborate-spec` has produced a clear spec or the user has already defined the feature in detail. If the problem is still fuzzy, run `elaborate-spec` first.

Synthesize the conversation context into `specs/RELEASE-PLAN.md`. No new interview — only clarify if something is genuinely ambiguous.

## Process

### 1. Draft epics and stories

From the conversation context, define:
- **Epics** — major capability areas (Priority: P1/P2/P3 | Value: High/Med/Low | Effort: S/M/L)
- **Stories** — "As a [actor], I want [feature] so that [benefit]"

WSJF-sort epics: score = (Business Value + Time Criticality + Risk Reduction) / Job Size. Highest score first.

### 2. Write acceptance criteria (Gherkin)

For each story, write at least one happy-path and one edge-case scenario:

```
Acceptance Criteria:
  Feature: [name]
    Scenario: [happy path]
      Given [initial state]
      When  [user action]
      Then  [observable outcome]
    Scenario: [edge case]
      Given ...
      When  ...
      Then  ...
```

### 3. Write tasks with verify commands

Under each story, list implementation tasks:

```
Tasks:
  - [ ] Write failing test for scenario 1 → verify: <cmd>
  - [ ] Implement [module/function]       → verify: <cmd>
  - [ ] Integrate and smoke-test          → verify: <cmd>
```

Every task must have a `verify:` command. No verify command = not a task.

### 4. Save specs/RELEASE-PLAN.md

```
## Epic 1: [Name]
Priority: P1 | Value: High | Effort: M | WSJF: [score]

### Story 1.1: As a [actor], I want [feature] so that [benefit]
Status: [ ] Not started

Acceptance Criteria:
  Feature: ...
    Scenario: ...

Tasks:
  - [ ] ... → verify: <cmd>
```

→ verify: `grep -c "Scenario:" specs/RELEASE-PLAN.md`

### 5. Suggest next steps

- Run `assess-impact` before `plan-work` for any story touching existing modules.
- Run `plan-work` per story to produce the detailed step-by-step plan.
- Run `change-request` if a new requirement arrives mid-flight.
