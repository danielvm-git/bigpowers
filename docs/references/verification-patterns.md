# Verification Patterns: How to Test Different Output Types

**Purpose:** Define verification patterns for different types of outputs to ensure every step has a measurable success criterion.

For documentation, config, and plan patterns see [`verification-patterns-extended.md`](verification-patterns-extended.md).

---

## Code Verification

### Pattern 1: Unit Test Pass

```bash
verify: npm test -- UserService.test.ts
```

**Pass Criterion:** Exit code 0, all assertions pass

### Pattern 2: Type Check Pass

```bash
verify: npx tsc --noEmit
```

**Pass Criterion:** Zero type errors

### Pattern 3: Lint Pass

```bash
verify: npx eslint src/ --max-warnings 0
```

**Pass Criterion:** Zero lint warnings

### Pattern 4: Integration Test Pass

```bash
verify: npm test -- integration/
```

**Pass Criterion:** All integration tests pass

### Pattern 5: Coverage Threshold

```bash
verify: npm test -- --coverage --collectCoverageFrom='src/**/*.ts' && npx nyc check-coverage --lines 95
```

**Pass Criterion:** Coverage ≥ 95%

### Pattern 6: Code Quality Score

```bash
verify: npm run audit-code && echo "✅ Code quality passed"
```

**Pass Criterion:** audit-code returns all ✅

---

## Verification Checklist Template

Every step should include:

```markdown
### Step N: [Description]

[What to do and why]

**Verify:**
```bash
[runnable command that proves it worked]
```

**Pass Criterion:** [What does "pass" mean?]
**Fail Criterion:** [What would "fail" look like?]
**Time Estimate:** [How long should this take?]
```

---

## Common Anti-Patterns (DON'T DO)

### Vague Verify Commands

```bash
# BAD: Doesn't prove anything
verify: npm test
verify: "did my best"

# GOOD: Specific, measurable
verify: npm test -- UserService.test.ts && echo "✅ Tests pass"
verify: npx tsc --noEmit && echo "✅ No type errors"
```

### Unrunnable Verify Commands

```bash
# BAD: Assumes context/environment
verify: npm test  # doesn't specify which tests

# GOOD: Runnable from clean state
verify: npm test -- src/UserService.test.ts
```

### Verify Command With No Exit Code

```bash
# BAD: Doesn't fail clearly
verify: echo "looks good"

# GOOD: Fails if something is wrong
verify: npm test && npm run audit-code && echo "✅ Ready to ship"
```

---

## See Also

- [`verification-patterns-extended.md`](verification-patterns-extended.md) — Doc, config, and plan patterns
- [`orchestration.md`](orchestration.md) — Which phase uses which verification
- `plan-work (SKILL.md)` — How to write steps with verify: commands
- `verify: grep "verify:" specs/release-plan.yaml | wc -l`
