# Verification Patterns: How to Test Different Output Types

**Purpose:** Define verification patterns for different types of outputs (code, docs, configs, plans) to ensure every step has a measurable success criterion.

---

## Code Verification

### Pattern 1: Unit Test Pass

```bash
verify: npm test -- UserService.test.ts
```

**What it checks:**
- Does the new code pass its unit tests?
- Are edge cases covered?
- Are mocks in place where needed?

**Pass Criterion:** Exit code 0, all assertions pass

### Pattern 2: Type Check Pass

```bash
verify: npx tsc --noEmit
```

**What it checks:**
- Are there no type errors?
- Are all imports/exports correctly typed?

**Pass Criterion:** Zero type errors

### Pattern 3: Lint Pass

```bash
verify: npx eslint src/ --max-warnings 0
```

**What it checks:**
- Does the code follow style rules?
- Are there suspicious patterns?

**Pass Criterion:** Zero lint warnings

### Pattern 4: Integration Test Pass

```bash
verify: npm test -- integration/
```

**What it checks:**
- Does the code work with other modules?
- Are APIs compatible?

**Pass Criterion:** All integration tests pass

### Pattern 5: Coverage Threshold

```bash
verify: npm test -- --coverage --collectCoverageFrom='src/**/*.ts' && npx nyc check-coverage --lines 95
```

**What it checks:**
- Is code coverage ≥95%?
- Are critical paths tested?

**Pass Criterion:** Coverage ≥ threshold

### Pattern 6: Code Quality Score

```bash
verify: npm run audit-code && echo "✅ Code quality passed"
```

**What it checks:**
- Does code follow CONVENTIONS.md?
- Are there code smells (Clean Code heuristics)?

**Pass Criterion:** audit-code returns all ✅

---

## Documentation Verification

### Pattern 1: File Exists & Has Content

```bash
verify: test -f docs/API.md && wc -l docs/API.md | awk '{if ($1 >= 50) print "✅ Doc complete"}'
```

**What it checks:**
- Is the documentation file created?
- Is it substantive (not just a stub)?

**Pass Criterion:** File exists with ≥50 lines

### Pattern 2: Markdown Syntax Valid

```bash
verify: npx remark docs/ --quiet && echo "✅ Markdown valid"
```

**What it checks:**
- Are headers, links, images valid?
- Are there broken references?

**Pass Criterion:** No markdown errors

### Pattern 3: Links Are Accessible

```bash
verify: npx markdown-link-check docs/API.md && echo "✅ Links work"
```

**What it checks:**
- Do all hyperlinks point to valid resources?
- Are no links broken?

**Pass Criterion:** All links return 200

### Pattern 4: Documentation Completeness

```bash
verify: grep -q "## API Reference" docs/API.md && \
        grep -q "### Request" docs/API.md && \
        grep -q "### Response" docs/API.md && \
        echo "✅ API doc complete"
```

**What it checks:**
- Are all required sections present?
- Is the doc structured?

**Pass Criterion:** All sections present

---

## Config/Manifest Verification

### Pattern 1: YAML/JSON Valid

```bash
verify: npx yamllint .github/workflows/*.yml && echo "✅ YAML valid"
```

**What it checks:**
- Is the YAML/JSON syntactically correct?
- Can it be parsed?

**Pass Criterion:** No syntax errors

### Pattern 2: Config Keys Present

```bash
verify: jq '.scripts.build' package.json > /dev/null && echo "✅ Build script exists"
```

**What it checks:**
- Are required configuration keys defined?
- Are values non-empty?

**Pass Criterion:** All required keys present and non-empty

### Pattern 3: Config Referenced in Code

```bash
verify: grep -r "DATABASE_URL" src/ > /dev/null && echo "✅ Config used"
```

**What it checks:**
- Is the configuration actually used?
- Not just declared but unused?

**Pass Criterion:** Config key found in code

---

## Plan Verification

### Pattern 1: Plan Structure Valid

```bash
verify: grep -q "^### Step" specs/release-plan.yaml && \
        grep -q "verify:" specs/release-plan.yaml && \
        echo "✅ Plan structure valid"
```

**What it checks:**
- Does the plan have steps?
- Does each step have a verify: command?

**Pass Criterion:** Plan has ≥1 step with verify: command

### Pattern 2: All Verify Commands Runnable

```bash
verify: bash -n <(grep "verify:" specs/release-plan.yaml | sed 's/verify: //' | while read cmd; do echo "$cmd"; done) && echo "✅ All verify commands valid"
```

**What it checks:**
- Is each verify: command valid bash syntax?
- Will they run without syntax errors?

**Pass Criterion:** All verify commands have valid syntax

### Pattern 3: Success Criteria Defined

```bash
verify: grep -q "Success Criteria" specs/release-plan.yaml && \
        grep -c "- \[ \]" specs/release-plan.yaml | awk '{if ($1 >= 3) print "✅ Success criteria defined"}' && \
        echo "✅ Success criteria complete"
```

**What it checks:**
- Are success criteria defined?
- Are there measurable checkpoints?

**Pass Criterion:** ≥3 checkboxes defined

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

### ❌ Vague Verify Commands

```bash
# BAD: Doesn't prove anything
verify: npm test
verify: "did my best"
verify: # just look at the output

# GOOD: Specific, measurable
verify: npm test -- UserService.test.ts && echo "✅ Tests pass"
verify: npx tsc --noEmit && echo "✅ No type errors"
```

### ❌ Unrunnable Verify Commands

```bash
# BAD: Assumes context/environment
verify: npm test  # doesn't specify which tests

# GOOD: Runnable from clean state
verify: npm test -- src/UserService.test.ts
```

### ❌ Verify Command With No Exit Code

```bash
# BAD: Doesn't fail clearly
verify: echo "looks good"

# GOOD: Fails if something is wrong
verify: npm test && npm run audit-code && echo "✅ Ready to ship"
```

---

## Verification Automation

For repetitive steps, create reusable verification scripts:

```bash
# scripts/verify-code.sh
#!/bin/bash
set -e

npm test
npx tsc --noEmit
npx eslint src/

echo "✅ All code verifications passed"
```

Then reference in plan:

```markdown
### Step 3: Implement UserService

[description]

**Verify:**
```bash
bash scripts/verify-code.sh
```
```

---

## See Also

- orchestration.md — Which phase uses which verification?
- plan-work (SKILL.md) — How to write steps with verify: commands
- verify: grep "verify:" specs/release-plan.yaml | wc -l
