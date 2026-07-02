
# Respond Review
> **HARD GATE** — **HARD GATE** — Every reviewer comment must be addressed (fix, disagree + document reason, or ask clarification). Do NOT ignore feedback and merge.


Work through reviewer findings systematically. Don't apply changes blindly — categorize first, then decide, then fix, then verify.

## Process

### 1. Read the full review report

Read every finding before acting on any of them. Get the full picture first.

### 2. Categorize findings

For each finding, assign a category:

| Category | Meaning | Action |
|----------|---------|--------|
| **must-fix** | Correctness bug, security issue, test failure, CONVENTIONS.md violation | Fix before proceeding |
| **should-fix** | Code quality issue, naming, clarity — worth fixing but not blocking | Fix if time allows |
| **consider** | Architectural suggestion, alternative approach — may or may not apply | Discuss with user |

Create a numbered list of all findings with their categories.

### 3. Confirm with user (for consider-category items)

For each "consider" item, briefly describe the trade-off and ask: "Apply, skip, or discuss?"

### 4. Apply must-fix items first

Fix every must-fix item. For each one:
- Describe what you're changing and why
- Make the change
- Run the verify command if one exists for this area

### 5. Apply should-fix items

Apply should-fix items. If any are large enough to warrant their own commit, note them separately.

### 6. Run the full suite

After all changes are applied:

```bash
<full test command>
<typecheck command>
<lint command>
```

- [ ] All tests pass
- [ ] No type errors
- [ ] No lint violations

### 7. Report

Summarize what was applied and what was skipped:

```
Applied (must-fix): #1, #2, #3
Applied (should-fix): #4
Skipped (consider): #5 — agreed with user to defer
All tests pass.
```

Suggest next skill: `commit-message`.
