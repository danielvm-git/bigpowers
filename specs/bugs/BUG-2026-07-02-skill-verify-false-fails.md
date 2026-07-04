---
bug_id: BUG-2026-07-02-skill-verify-false-fails
status: fixed
severity: medium
scope: ci
title: "skill-verify script reports false FAILs"
---

# BUG-2026-07-02T103911: skill-verify script reports false FAILs

## Problem

`bash scripts/run-skill-verify.sh` reports 33 FAIL / 1 PASS / 38 SKIP when the actual
skill health is mostly green. Two root causes produce false failures:

1. **Backtick command substitution**: Many `→ verify:` commands in SKILL.md are wrapped
   in backticks (e.g., `→ verify: \`grep ... | wc -l\``). The script runs them with
   `bash -c "$cmd"`, which executes the backtick content as a command substitution first,
   then tries to run the result as a command (producing "OK: command not found").

2. **Prose false-matches**: The grep `'→ verify:'` matches any line containing the arrow
   sequence, including frontmatter descriptions and template examples like
   `"step → verify: <cmd>" pairs` in `define-success` or
   `N. <commit description> → verify: <runnable command>` in `plan-refactor`.

## Root Cause Analysis

**Root cause 1 — Backtick interpolation**: `run_skill()` does:
```bash
cmd=$(grep '→ verify:' "$skill_md" | head -1 | sed 's/.*→ verify: *//')
output=$(timeout 10 bash -c "$cmd" 2>&1)
```
The extracted `cmd` includes backticks. Inside double-quoted `bash -c "$cmd"`, backticks
trigger command substitution — the inner command runs, its stdout becomes a word, and
bash tries to execute that word. Example: `` `echo OK` `` → bash tries to run `OK` → fails.

**Root cause 2 — Unguarded grep**: The regex `→ verify:` matches inside YAML frontmatter
(`description:` lines), prose paragraphs, and template examples — not just actual
verify: directives. The `head -1` grabs the first match, which is often description text.

**Risk level**: Low (no user-facing code affected; CI-only verification script)

## TDD Fix Plan

### 1. RED: Test that backtick-wrapped commands are stripped
**GREEN**: Strip leading/trailing backticks in `run_skill()` before execution
**verify**: `bash scripts/run-skill-verify.sh assess-impact` — should not show "OK: command not found"

### 2. RED: Test that prose lines are not matched as verify commands
**GREEN**: Anchor grep to match only lines where `→ verify:` starts the line (after optional whitespace/blockquote `>`)
**verify**: `bash scripts/run-skill-verify.sh define-success` — should SKIP (no real verify command)

### 3. REFACTOR: Remove dead verify commands that are prose, not runnable shell
Several SKILL.md files have verify: directives that are plain English, not shell:
- `grill-with-docs`: `dialogue log contains at least one \`https://\` doc URL...`
- `define-success` template line: `N. [What must be true] → verify: <runnable command>`
- `plan-refactor` template line: `N. <commit description> → verify: <runnable command>`

These should be either removed from the verify: line or refactored as real commands.

## Acceptance Criteria

- [ ] `run-skill-verify.sh` correctly strips backticks from extracted commands
- [ ] `run-skill-verify.sh` does not match prose/template lines as verify commands
- [ ] No "command not found" errors from backtick-substitution
- [ ] No syntax errors from `<` shell redirection in prose matches
- [ ] `fix-bug` PASS (requires `sync-bugs-registry.sh` to exist, or verify command updated)
- [ ] All previously-SKIP skills remain SKIP

## Acceptance Criteria

- [x] `run-skill-verify.sh` correctly strips backticks from extracted commands
- [x] `run-skill-verify.sh` does not match prose/template lines as verify commands
- [x] No "command not found" errors from backtick-substitution
- [x] No syntax errors from `<` shell redirection in prose matches
- [x] `fix-bug` PASS (verify command updated to check for script existence)
- [x] `grill-with-docs` PASS (verify command rewritten as runnable shell)
- [x] `setup-environment` PASS (verify command rewritten as runnable shell)
- [x] `verify-work` PASS (template `<story_id>` replaced with glob)
- [x] `simulate-agents` PASS (glob handling fixed)
- [x] `reset-baseline` PASS (missing closing backtick added)
- [x] macOS `timeout` command not found — portable fallback added

## Resolution

### Script fix (`scripts/run-skill-verify.sh`)
1. Anchored grep to `^(> )?→ verify:` — only matches verify directives at line start
2. Strip backticks via `sed 's/^`//; s/`$//'` before passing to `bash -c`
3. Added prose-detection heuristic — skips commands not starting with a shell-valid word
4. Added portable `timeout` fallback for macOS (perl alarm)

### SKILL.md fixes
- `reset-baseline/SKILL.md`: added missing closing backtick
- `grill-with-docs/SKILL.md`: replaced prose verify with runnable grep command
- `setup-environment/SKILL.md`: replaced prose verify with runnable test command
- `verify-work/SKILL.md`: replaced `<story_id>` template placeholder with glob
- `simulate-agents/SKILL.md`: fixed `test -f` with glob pattern
- `fix-bug/SKILL.md`: updated verify to not reference nonexistent script

### Results: 33 FAIL → 1 FAIL (legitimate: build-epic preconditions not met)
