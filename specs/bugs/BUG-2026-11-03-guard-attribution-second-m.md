---
bug_id: BUG-2026-11-03-guard-attribution-second-m
status: open
severity: high
scope: hooks / guard-git
title: "Co-authored-by check only inspects the first -m value, so a footer in a second -m or in -F passes the P1 rule"
files_changed: "hooks/pre-tool-use.sh, extensions/omp-hooks.ts"
approach: "Collect every message argument of a git commit invocation (all -m values, and -F/--file targets) and match the footer regex against each, in both the shell hook and the extension"
risk_level: medium
commit_message: "fix(hooks): inspect every commit message argument for AI attribution"
---

# BUG-2026-11-03: attribution footer escapes the guard

Found while exercising the neighbouring rules for #184. Logged, not fixed there: the fix belongs to
the P1 attribution rule and needs its own red/green cycle in both implementations.

## Problem

- **Actual:** `hooks/pre-tool-use.sh` extracts the message with a single match of the first `-m`
  value, then tests that one string for a `Co-authored-by:` line:
  ```bash
  if [[ "$COMMAND" =~ $COMMIT_MSG_RE ]]; then MSG="${BASH_REMATCH[1]}"; fi
  ...
  echo "$MSG" | grep -qiE '^co[- ]authored[- ]by:'
  ```
  So this passes the guard:
  ```bash
  git commit -m "fix(scope): subject" -m "Co-authored-by: some-agent <agent@example.com>"
  ```
  Verified: exit 0 (allowed) on the branch that fixes #184, with the second `-m` carrying the footer.
- **Expected:** CONVENTIONS.md § Git Attribution is a P1 rule — *no* commit may carry the footer.
  A commit whose second paragraph carries it is exactly the shape an agent emits.
- **Also unguarded:** `git commit -F file` and a message piped on stdin (`git commit -F -`), where
  the footer never appears in the command string at all.
- **Extension parity:** `extensions/omp-hooks.ts` has no attribution check whatsoever, so the
  primary implementation is weaker than the shell fallback here.

## Root Cause

The rule was written against a single-message mental model. `git commit` accepts repeated `-m`
(concatenated with blank lines), `-F`/`--file`, and `-F -`. A regex over the raw command cannot
enumerate them, which is the same class of mistake as #184: the guard reasons about a string, not
about argv.

## Fix approach (not implemented)

1. Reuse the argv view already built for #184: for each `commit` invocation collect every `-m` /
   `--message` value and every `-F` / `--file` argument.
2. Match `(?im)^\s*co[-\s]authored[-\s]by\s*:` against each collected message.
3. For `-F <path>` read the file (bounded) inside the repo; for `-F -` treat as unverifiable and
   block with a remediation message ("pass -m so the message can be checked").
4. Implement in `extensions/omp-hooks.ts` first (primary), mirror in the shell hooks, and add
   fixture rows to `specs/verifications/fixtures/guard-git-normalize.yaml` so parity is enforced.

## Why it is not in the #184 commit

#184 is about destructive git operations. Widening it to message attribution would ship an
unreviewed behaviour change inside a security fix, with new false-positive risk (any commit message
that *mentions* the footer). It gets its own cycle.

## Evidence

```
$ printf '{"command": "git commit -m \\"fix(x): y\\" -m \\"Co-authored-by: bot\\""}' | bash hooks/pre-tool-use.sh
$ echo $?
0        # allowed — expected 2
```
