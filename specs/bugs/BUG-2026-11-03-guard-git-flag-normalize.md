---
bug_id: BUG-2026-11-03-guard-git-flag-normalize
status: fixed
severity: high
scope: hooks / guard-git
title: "guard-git matches command substrings, so global flags and reordered options bypass the destructive-command deny list"
files_changed: "hooks/pre-tool-use.sh, hooks/pre/bash.sh, scripts/lib/git-argv.py (new), scripts/omp-guard-probe.ts (new), scripts/test-guard-git-normalize.sh (new), specs/verifications/fixtures/guard-git-normalize.yaml (new), extensions/omp-hooks.ts, scripts/lib/golden-suite-gates.sh, skills/guard-git/SKILL.md"
approach: "Tokenize the command (quote-aware), strip git's global options, then judge the (subcommand, arguments) pair against one rule table — implemented in scripts/lib/git-argv.py for the shell hooks and mirrored in extensions/omp-hooks.ts, with a fixture gate that fails if the two disagree"
risk_level: medium
commit_message: "fix(hooks): judge git argv instead of command substrings in guard-git"
---

# BUG-2026-11-03: guard-git bypassed by flag order

Issue #184 (defect family 5 / e86 — application & script security).

## Problem

- **Actual:** `DANGEROUS_PATTERNS` were literal substrings (`git reset --hard`, `push --force`, …)
  matched against the raw command. Any reordering, extra flag or global option walked straight
  through, and one sanctioned shape was blocked by mistake.
- **Expected:** the verdict depends on what the command *does*, not on how the tokens are ordered.

## Root Cause Analysis

1. **Reproduce:** the 29-row fixture table against the pre-fix hook →
   **20 correct, 8 bypassed, 1 false positive**:
   ```
   BYPASS: git reset -q --hard
   BYPASS: git reset --keep --hard
   BYPASS: git checkout -- .
   BYPASS: git checkout -f main
   BYPASS: git restore --staged --worktree .
   BYPASS: git -C /tmp/repo branch --delete --force feature/x
   BYPASS: git push origin main -f
   BYPASS: git push origin +main
   FALSE+: git push --force-with-lease origin main
   ```
2. **Isolate:** substring matching has no notion of a token. `reset -q --hard` contains the
   destructive token but not the literal `reset --hard`; `--force-with-lease` contains the literal
   `--force` but is not a force push.
3. **Hypothesize:** a real argv view — tokenize, drop global options that precede the subcommand,
   then match per-subcommand rules against the argument list — decides all 29 rows correctly.
4. **Verify:** (a) shell hook 29/29, (b) TS extension 29/29, (c) both agree on 29/29, (d) the
   neighbouring rules (commits, protected branch, gemini JSON, pi fallback) still hold.

## Fix

One rule table, two ports:

- `scripts/lib/git-argv.py` — used by `hooks/pre-tool-use.sh` and `hooks/pre/bash.sh`.
- `extensions/omp-hooks.ts` — `tokenizeArgs()`, `gitInvocations()`, `classifyGitInvocation()`,
  `dangerousGitCommand()`, called from the `tool_call` handler.

Rules: `reset` + `--hard`; `clean` with any `-f*` or `--force`; `branch -D` or `--delete` + force;
`checkout` with `-f`/`--force` or a `.` pathspec; `restore` with `--worktree` or `.`;
`push` with `-f`/`--force`/`+refspec` unless `--force-with-lease`.

Fallback: when the helper is unreachable (hook symlinked outside an installed package) the hooks
keep the legacy literal patterns rather than degrade to "allow everything".

## Regression guard

`guard-git-normalize` in `scripts/lib/golden-suite-gates.sh`, driven by
`specs/verifications/fixtures/guard-git-normalize.yaml` (29 rows, each with the bypass it pins).

## Evidence

```
=== test-guard-git-normalize.sh ===
  PASS (a) shell hook matches all 29 fixture rows
  PASS (b) TS extension matches all 29 fixture rows
  PASS (c) shell and TS agree on all 29 rows
  PASS (d) adjacent rules: commits, pushes, gemini JSON, pi fallback
4 passed, 0 failed
```

Discovered while testing this fix (logged separately, see the two bug files below):
- `hooks/pre/bash.sh` had a syntax error since #118, so the pi/OMP fallback never ran — fixed here.
- The Co-authored-by check only inspects the first `-m` value — still open.
