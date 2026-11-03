---
bug_id: BUG-2026-11-03-pi-shell-hook-dead
status: fixed
severity: high
scope: hooks / omp
title: "hooks/pre/bash.sh has not parsed since #118 — the pi/OMP shell fallback guard never ran"
files_changed: "hooks/pre/bash.sh"
approach: "Hoist the -m regex into a variable: parentheses inside [[ =~ ]] must come from a variable, not the literal pattern, or bash rejects the whole file at parse time"
risk_level: low
commit_message: "fix(hooks): make the pi/OMP fallback hook parse and run the normalizer"
---

# BUG-2026-11-03: the pi/OMP guard hook is a syntax error

Found while adding the argv normalizer to this file for #184.

## Problem

- **Actual:** `bash -n hooks/pre/bash.sh` fails on `main`:
  ```
  hooks/pre/bash.sh: line 33: syntax error in conditional expression: unexpected token `)'
  hooks/pre/bash.sh: line 33: syntax error near `-m[[:space:]]+"([^"]+)"'
  ```
  Bash parses the entire file before running it, so the hook has **never executed a single check**
  since it was introduced in `274894fe` (#118). Every runtime that invokes this fallback as a
  process got a parse error instead of a verdict — silently, because hooks fail open.
- **Expected:** the documented shell fallback (`hooks/pre/bash.sh`, "Blocks dangerous git commands
  and enforces Conventional Commits") enforces what its header says.

## Root Cause Analysis

1. **Reproduce:** `git show main:hooks/pre/bash.sh | bash -n /dev/stdin` → the message above.
2. **Isolate:** `[[ "$COMMAND" =~ -m[[:space:]]+"([^"]+)" ]]`. In bash ≥ 3.2 the right-hand side of
   `=~` inside `[[ ]]` is parsed for the conditional expression itself; the unquoted `([^"]+)`
   group's `)` terminates the conditional and the rest is a syntax error.
3. **Hypothesize:** putting the pattern in a variable (`[[ "$COMMAND" =~ $COMMIT_MSG_RE ]]`) makes
   the group parentheses part of the data, not the syntax.
4. **Verify:** `bash -n hooks/pre/bash.sh` passes, and the hook now emits
   `{"decision":"block",…}` for a destructive command (fixture section (d)).

## Why it went unnoticed

Nothing parsed the file: no gate runs `bash -n` on `hooks/`, and a broken hook fails open, so the
only symptom would be a guard that quietly allows everything. `scripts/validate-omp-extension.sh`
validates `extensions/omp-hooks.ts`, not its shell fallback — the same blind spot family as
BUG-2026-07-26-story-verify-never-executed ("a gate that never executes").

## Fix

Hoist the regex to `COMMIT_MSG_RE` and parse the pattern from the variable. One line of behaviour
unchanged; the hook now parses and runs.

## Regression guard

Section (d) of `scripts/test-guard-git-normalize.sh` runs `bash -n hooks/pre/bash.sh` and asserts
the hook emits block JSON for a destructive command and uses the normalized classifier.
