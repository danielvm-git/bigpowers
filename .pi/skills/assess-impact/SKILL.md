---
name: assess-impact
description: "Analyze the blast radius of a proposed change before any code is written. Maps dependents, affected stories, and test coverage. Produces specs/IMPACT_LATEST.md. Use before plan-work on any non-trivial change, when touching a shared module, or when the user asks \"what does this break?\"."
model: sonnet
---


# Assess Impact

> **HARD GATE** — Run this skill before `plan-work` whenever a change touches an existing module, symbol, or file used by more than one caller. Skip only for net-new code with no existing dependents.

Find the blast radius of the proposed change before a single line is written.

## Modes

- Default: full impact analysis (dependents + affected stories + test coverage mapping)
- --lightweight: Fast fan-in/fan-out only (<10s). Maps callers and imports without test coverage mapping. Used by build-epic step 2 as a pre-plan gate. Risk score > 7 triggers a mandatory grill-me session before proceeding.

## Process

### 1. Identify the target

Name the symbol, module, or file being changed. If the user hasn't specified, ask one question: "What exactly are you changing?"

### 2. Find dependents

```
grep -rn "[symbol-name]" . --include="*.ts" | grep -v node_modules
git log --oneline -10 -- [file-path]
```

→ verify: `grep -rn "[target]" . | wc -l`

### 3. Map to release plan stories

Read `specs/release-plan.yaml + epic capsule directories` (if it exists). For each dependent found in Step 2, identify which story owns that module. List stories that will be affected by the change.

→ verify: `grep -c "Story" specs/release-plan.yaml + epic capsule directories 2>/dev/null || echo "no release plan"`

### 4. List test coverage

Find tests that exercise the target:

```
grep -rn "[symbol-name]" . --include="*.test.*" --include="*.spec.*"
```

→ verify: `grep -rn "[target]" . --include="*.test.*" | wc -l`

### 5. Classify risk

| Level | Condition |
|-------|-----------|
| Low   | ≤ 2 callers, all covered by tests |
| Medium | 3–10 callers, partial test coverage |
| High  | > 10 callers, or shared API/interface, or no tests |

### 6. Write specs/IMPACT_LATEST.md

```
## Target
[symbol or file being changed]

## Dependents ([count])
- [file]: [caller or usage]

## Affected Stories
- Story [X.Y]: [title]

## Test Coverage
- [test file]: covers [scenario]
- Gap: [untested behavior]

## Risk: Low / Medium / High
[One-sentence rationale]

## Recommended action
[Proceed / Add tests first / Discuss design]
```

→ verify: `grep "Risk:" specs/IMPACT_LATEST.md`

Suggest `plan-work` once risk is understood and any test gaps are noted.

## Risk score gating

In `--lightweight` mode (used by build-epic step 2), assign a numeric risk score (1–10):
- Fan-in (how many callers): 0–4 points
- Fan-out (how many dependencies the module itself uses): 0–3 points  
- Recent churn (git log --oneline -5 count): 0–3 points

**Risk score > 7**: Gate — require a `grill-me` session before proceeding to implementation. Document the grill-me result in the impact report at `specs/IMPACT-<epic>-<story>.md`.
