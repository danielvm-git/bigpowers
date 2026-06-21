

# Quick Fix

Fast-track for trivial data-only fixes that do not require the full bug-fix chain.

When a bug fix is purely data — an add-missing-key, a typo correction, a config value update — the standard 6-skill chain (investigate-bug → diagnose-root → develop-tdd → kickoff-branch → verify-work → release-branch) is wasteful overhead. Quick-fix collapses it to 2 skills: **quick-fix** then **release-branch**.

## Entry Criteria (ALL must be true)

Before invoking quick-fix, evaluate every item in this checklist:

1. **Purely data change** — adding a missing key, fixing a typo, updating a config value, correcting a constant
2. **No logic change** — no function signature, condition, loop, or control flow is modified
3. **No refactor risk** — the change does not reorganize or rename existing structures
4. **No API surface change** — no exported symbol, interface, or contract changes
5. **Verifiable with a single assertion** — one test, one curl, one grep can prove it works
6. **Affects ≤ 1 file**
7. **Affects ≤ 5 lines changed**

## Guardrails (HARD ABORT — all must pass)

If ANY guardrail triggers, **abort immediately** and suggest `investigate-bug` instead:

| Guardrail | Check |
|-----------|-------|
| **>1 file** | The fix touches more than one file |
| **>5 lines** | The diff exceeds 5 lines |
| **Logic change** | Any function signature, condition, or loop is modified |
| **Complex verify** | The verify command is more than one pipeline |
| **Test breakage** | Running `npm test` or equivalent breaks any existing test |

> **Fallback:** If any guardrail triggers, tell the user: *"This fix exceeds quick-fix guardrails. Use `investigate-bug` for the full TDD bug-fix chain instead."*

## Fast-Path Workflow

Only 2 skills needed for eligible fixes:

```
quick-fix  →  apply change, run one-line verify, commit with fix:
release-branch  →  merge and ship (existing skill)
```

**Skipped skills (with justification):**

| Skipped skill | Why skipped |
|---------------|-------------|
| `investigate-bug` | Root cause is obvious (data gap, not logic error) |
| `diagnose-root` | No isolation needed — the data point is the root cause |
| `develop-tdd` | No logic to test — single assertion proves correctness |
| `kickoff-branch` | Change is so small it does not warrant a separate worktree |

> Justification is included in the `fix:` commit body so the audit trail is preserved.

## Process

### 1. Evaluate entry criteria

Run the entry criteria checklist above. If any criterion fails → abort, suggest `investigate-bug`.

### 2. Apply the fix

Make the data change — add the missing key, fix the typo, update the value. Keep it to ≤5 lines in 1 file.

### 3. Verify

Run the single-assertion verify command. Example:

```bash
grep -q "Bosnia" src/flags.js && echo "FIX VERIFIED" || echo "FIX FAILED"
```

### 4. Commit

```bash
git add <file>
git commit -m "fix(<scope>): <description>"
git commit --amend -m "fix(<scope>): <description>

Skipped skills (justified for data-only change):
- investigate-bug: root cause is a data gap, not a logic error
- diagnose-root: the missing data point is the root cause
- develop-tdd: single assertion proves correctness
- kickoff-branch: change is too small for a separate worktree"
```

### 5. Release

Invoke `release-branch` to merge and ship.

## Verify

```bash
test -f quick-fix/SKILL.md && echo "OK: skill file exists" || echo "FAIL: no skill file"
grep -q "name: quick-fix" quick-fix/SKILL.md && echo "OK: frontmatter" || echo "FAIL: frontmatter"
grep -qi "data.only\|trivial\|fast.path\|guardrail\|abort" quick-fix/SKILL.md && echo "OK: entry criteria and guardrails"
grep -q "quick-fix" SKILL-INDEX.md && echo "OK: in SKILL-INDEX"
```

## Example

### Bosnia flag missing from FLAGS dictionary

```gherkin
Given a bug where FLAGS dictionary is missing entry "Bosnia"
And no logic depends on the missing entry (purely a data gap)
When the agent invokes quick-fix
Then the missing entry is added to the dictionary
And a one-line verify confirms the key exists: grep -q "Bosnia" src/flags.js
And a fix: commit is created with the skipped-skills rationale in the body
And the change is ready for release-branch
```
