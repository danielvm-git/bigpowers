---
bug_id: BUG-2026-11-03-cli-nontty-silent-noop
status: open
severity: medium
scope: cli / installer
title: "With no TTY, `bigpowers setup` and `bigpowers update` draw the first menu, install nothing and exit 0 — a silent no-op that reports success"
files_changed: "bin/setup.js, bin/bigpowers.js (proposed)"
approach: "Documented non-interactive mode (--yes, --tools, --scope, --help), a persisted install manifest so `update` can replay a run, and fail-fast with an actionable message when a prompt is required but no TTY exists"
risk_level: medium
commit_message: "fix(cli): never prompt without a TTY; add a non-interactive install mode"
---

# BUG-2026-11-03: prompting commands are silent no-ops without a TTY

**Status: open — logged, not fixed.** Discovered while investigating
`BUG-2026-11-03-cli-update-stale-version` (the actual cause of the version mismatch the user hit).
It is a real defect but a different one; fixing it needs a non-interactive installer, which does not
belong in a version-reporting fix.

## Problem

- **Actual:** in an agent/CI shell (stdin is a pipe or `/dev/null`), both `bigpowers update` and
  `bigpowers setup` print the banner and the first menu —
  ```
  ◆  Existing installation detected. How would you like to proceed?
  ```
  — then exit **0** having installed nothing. No error, no summary, not even "Cancelled".
- **Expected:** a command that cannot proceed says so and exits non-zero; a command that can proceed
  without input (`update` has no choices to make) does so.

## Root Cause

`bin/setup.js` has no argv parsing and no TTY check: `main()` is an uninterrupted chain of
`@clack/prompts` calls. With stdin at EOF each promise never settles, the event loop empties and Node
exits 0. `isCancel()` never runs, so even the cancel path is skipped. `update` and `install` both
delegate to the same function, so both are affected.

Compounding it, nothing records *what* was installed — `detectExistingInstall()` only checks the
`~/.claude/skills/survey-context` marker — so `update` cannot replay a previous run (scope + tools)
and is forced back into a menu it cannot show.

## Reproduce

```bash
mkdir -p /tmp/bp-fakehome/.claude/skills
ln -sfn "$PWD" /tmp/bp-fakehome/.claude/skills/survey-context
HOME=/tmp/bp-fakehome bigpowers setup < /dev/null   # → eval'd exit 0, elapsed 0s, nothing installed
printf '' | HOME=/tmp/bp-fakehome bigpowers setup   # → same with a pipe on stdin
```

## Proposed fix (not implemented)

- Flags `--yes`, `--tools=a,b`, `--scope=global|local`, `--uninstall`, `--help`.
- Interactive only when stdin is a TTY and no `--yes`; otherwise exit 2 with the exact command to run.
- Persist `{version, scope, tools}` to `~/.bigpowers/install-state.json` after a successful install;
  `bigpowers update` replays it with no prompt at all.

## Regression guard (to add with the fix)

A gate that runs each command under an `alarm` watchdog with an isolated HOME and asserts: exit 2 and
guidance for `setup` without `--yes`; exit 0, no menu text and a real symlink for `update`.
