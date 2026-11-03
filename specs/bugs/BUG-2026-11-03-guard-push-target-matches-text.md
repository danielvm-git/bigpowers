---
bug_id: BUG-2026-11-03-guard-push-target-matches-text
status: open
severity: medium
scope: hooks / guard-git
title: "Protected-branch push check matches the word 'main' anywhere in the command, so an unrelated echo or comment blocks a legitimate feature push"
files_changed: "hooks/pre-tool-use.sh, extensions/omp-hooks.ts"
approach: "Decide the push target from the normalized argv of each git push invocation (remote + refspec), not from a substring match over the whole command string"
risk_level: low
commit_message: "fix(hooks): derive push targets from git argv, not from command text"
---

# BUG-2026-11-03: guard blocks a feature push because of an echo

Hit live while pushing the #184 fix branch.

## Problem

- **Actual:** `hooks/pre-tool-use.sh` and `extensions/omp-hooks.ts` decide "does this push go to a
  protected branch?" with a regex over the **whole command string**:
  ```ts
  const PROTECTED_BRANCH_RE = /(?:^|\s|[:])(?:main|master)(?:\s|$)/;
  if (PROTECTED_BRANCH_RE.test(command)) return true;   // → block
  ```
  Any mention of the word counts, including prose. This was blocked:
  ```bash
  cd .claude/worktrees/guard-git-flag-normalize && git push -u origin fix/guard-git-flag-normalize; \
    echo "=== commits ahead of main ==="; git log --oneline main..HEAD
  ```
  Verdict: `BLOCKED: Direct push to protected branch. Use kickoff-branch + release-branch.`
  The push was to `fix/guard-git-flag-normalize`; the only occurrence of the protected name was
  inside an `echo` label followed by a space.
- **Expected:** the guard judges the push *target* — remote and refspec — from the argv of the
  `git push` invocation. Text in an unrelated argument, `echo`, comment or heredoc is not a target.

## Root Cause

Same class as #184: the check reasons about the raw command string instead of the parsed invocation.
`git push <remote> <refspec>` is exactly the shape the normalizer already produces for
`classify_git_argv`, but the push-target logic was never migrated to it.

## Why it matters

- Over-blocking is a papercut on legitimate work: it fired on a feature-branch push, and the only
  "fix" available to the agent was to rewrite its own command to avoid a word — i.e. the guard
  trains agents to disguise commands instead of making them safe.
- The inverse risk stays open: `git push origin main` inside a quoted argument or an `echo` would be
  treated as a protected push even when it is not one, while a genuinely protected push assembled
  through a variable (`git push "$REMOTE" "$BRANCH"`) is not detected at all.

## Fix approach (not implemented)

1. Reuse `gitInvocations()` / its Python twin: for every `push` invocation, take the first
   non-flag argument as the remote and the remaining refspecs.
2. Block when a refspec names a protected branch (`main`, `master`, `refs/heads/main`, `:main`), or
   when the refspec is absent and the current branch is protected.
3. Add fixture rows for both directions: prose mentioning the branch must allow; `push origin main`
   in any flag order must block.

## Evidence

```
$ printf '{"command": "cd /tmp && git push -u origin fix/x; echo \\"ahead of main \\"; git log main..HEAD"}' \
    | bash hooks/pre-tool-use.sh   # exit 2 — blocked, push target was fix/x
```
