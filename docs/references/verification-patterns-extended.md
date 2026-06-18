# Verification Patterns: Documentation, Config, and Plan

**Source of Truth:** `docs/references/verification-patterns.md` (pinned)  
**Purpose:** Extended verification patterns for non-code outputs — documentation, config/manifest files, and implementation plans.

---

## Documentation Verification

### Pattern 1: File Exists & Has Content

```bash
verify: test -f docs/API.md && wc -l docs/API.md | awk '{if ($1 >= 50) print "✅ Doc complete"}'
```

**Pass Criterion:** File exists with ≥50 lines

### Pattern 2: Markdown Syntax Valid

```bash
verify: npx remark docs/ --quiet && echo "✅ Markdown valid"
```

**Pass Criterion:** No markdown errors

### Pattern 3: Links Are Accessible

```bash
verify: npx markdown-link-check docs/API.md && echo "✅ Links work"
```

**Pass Criterion:** All links return 200

### Pattern 4: Documentation Completeness

```bash
verify: grep -q "## API Reference" docs/API.md && \
        grep -q "### Request" docs/API.md && \
        grep -q "### Response" docs/API.md && \
        echo "✅ API doc complete"
```

**Pass Criterion:** All required sections present

---

## Config/Manifest Verification

### Pattern 1: YAML/JSON Valid

```bash
verify: npx yamllint .github/workflows/*.yml && echo "✅ YAML valid"
```

**Pass Criterion:** No syntax errors

### Pattern 2: Config Keys Present

```bash
verify: jq '.scripts.build' package.json > /dev/null && echo "✅ Build script exists"
```

**Pass Criterion:** All required keys present and non-empty

### Pattern 3: Config Referenced in Code

```bash
verify: grep -r "DATABASE_URL" src/ > /dev/null && echo "✅ Config used"
```

**Pass Criterion:** Config key found in code (not just declared)

---

## Plan Verification

### Pattern 1: Plan Structure Valid

```bash
verify: grep -q "^### Step" specs/release-plan.yaml && \
        grep -q "verify:" specs/release-plan.yaml && \
        echo "✅ Plan structure valid"
```

**Pass Criterion:** Plan has ≥1 step with verify: command

### Pattern 2: All Verify Commands Runnable

```bash
verify: bash -n <(grep "verify:" specs/release-plan.yaml | sed 's/verify: //' | while read cmd; do echo "$cmd"; done) && echo "✅ All verify commands valid"
```

**Pass Criterion:** All verify commands have valid bash syntax

### Pattern 3: Success Criteria Defined

```bash
verify: grep -q "Success Criteria" specs/release-plan.yaml && \
        grep -c "- \[ \]" specs/release-plan.yaml | awk '{if ($1 >= 3) print "✅ Success criteria defined"}' && \
        echo "✅ Success criteria complete"
```

**Pass Criterion:** ≥3 checkboxes defined

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

**Verify:**
```bash
bash scripts/verify-code.sh
```
```

---

## See Also

- [`verification-patterns.md`](verification-patterns.md) — Core code verification patterns and anti-patterns
- [`orchestration.md`](orchestration.md) — Which phase uses which verification
- `plan-work (SKILL.md)` — How to write steps with verify: commands
