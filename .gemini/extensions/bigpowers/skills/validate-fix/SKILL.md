---
name: validate-fix
description: "Prove a fix works before declaring done — re-run the failing test, run the full suite, typecheck, lint, and harden against recurrence. Use after implementing a bug fix, when user says "is this fixed?", or before closing an investigation."
---


# Validate Fix

Prove the fix works. "I think it works" is not evidence. Run the suite, show the output, then harden against recurrence.

## Checklist

### 1. Re-run the originally failing test

```bash
# Run the specific test that captured the bug
<test command for the failing test>
```

- [ ] Previously failing test now passes

### 2. Run the full test suite

```bash
# Run all tests — no filtering
<full test command from CLAUDE.md>
```

- [ ] All tests pass (zero regressions)

### 3. Type check

```bash
<typecheck command>
```

- [ ] No type errors introduced

### 4. Lint

```bash
<lint command>
```

- [ ] No lint violations introduced

### 5. Harden against recurrence

For every bug fixed, add at least one prevention layer:

| Mechanism | When to use |
|-----------|-------------|
| Type guard | Input could be the wrong shape |
| Schema validation (Zod, Pydantic, etc.) | External data crossing a boundary |
| Invariant assertion | Internal state that must always hold |
| Lint rule | Pattern that's easy to repeat by mistake |
| Environment check at startup | Missing config causes silent failure |

- [ ] At least one hardening mechanism added
- [ ] Hardening mechanism is tested

### 6. Update specs/DIAGNOSIS.md

If a `specs/DIAGNOSIS.md` exists for this bug, append the resolution:

```markdown
## Resolution

**Fixed:** [date]
**Root cause confirmed:** [one sentence]
**Fix applied:** [what was changed]
**Hardening added:** [type guard / schema / assertion / lint rule]
**Evidence:** all tests pass (`<verify command>`)
**Commit:** `fix(<scope>): <description>`
```

- [ ] specs/DIAGNOSIS.md updated with resolution

### 7. Show evidence

Do not declare done without showing the terminal output. Print:
- The passing test output
- The full suite result line (`X passed, 0 failed`)
- The typecheck and lint exit codes

## Rules

- **Never use `@ts-ignore`, `as any`, or `// eslint-disable`** to "fix" a bug — these suppress the symptom without fixing the root cause
- **Never mark the task done if any test is still failing**
- **The verify command from specs/DIAGNOSIS.md or specs/PLAN.md must pass**

Suggest next skill: `audit-code` → `commit-message`.
