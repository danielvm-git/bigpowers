---
bug_id: BUG-2026-11-03-cli-nontty-silent-noop
status: fixed
severity: high
scope: cli / installer
title: "With no TTY, `bigpowers setup` and `bigpowers update` draw the first menu, install nothing and exit 0 — a silent no-op that reports success"
files_changed: "bin/setup.js, bin/bigpowers.js, scripts/lib/cli-version.js (new), scripts/test-bigpowers-cli.sh (new), scripts/lib/golden-suite-gates.sh, README.md"
approach: "Add a documented non-interactive mode (--yes, --tools, --scope, --help), make `update` replay the persisted install manifest, and fail fast with an actionable message when a prompt would be required but no TTY exists"
risk_level: medium
commit_message: "fix(cli): never prompt without a TTY; add a non-interactive install mode"
---

# BUG-2026-11-03: prompting commands are silent no-ops without a TTY

## Problem

- **Actual:** in an agent/CI shell (stdin is a pipe or `/dev/null`), both `bigpowers update` and
  `bigpowers install` printed the banner and the first menu —
  ```
  ◆  Existing installation detected. How would you like to proceed?
  ```
  — then exited **0** having installed nothing. No error, no summary, no "cancelled".
- **Expected:** a command that cannot proceed must say so and exit non-zero; a command that can
  proceed without input (`update`) must do so.

## Root Cause Analysis

1. **Reproduce** with an isolated HOME so the real one is untouched:
   ```bash
   HOME=/tmp/bp-fakehome perl -e 'alarm 12; exec @ARGV' bigpowers setup < /dev/null
   → exit=0  elapsed=0s  output stops at the first menu  (nothing installed)
   ```
   Same with a pipe on stdin (`printf '' | …`).
2. **Isolate:** `bin/setup.js` has **no** argv parsing and **no** TTY check. `main()` is an
   uninterrupted chain of `@clack/prompts` calls (`select` → `select` → `multiselect` → `confirm`).
   With stdin at EOF each promise never settles, the event loop empties, and Node exits 0. `isCancel()`
   never runs, so even "Cancelled." is never printed. `update` and `install` both delegate here.
3. **Hypothesize:** the installer assumes a human whenever it is invoked. Two things are missing:
   (a) a non-interactive mode with documented flags, (b) a guard that refuses to prompt when there is
   no TTY, instead of rendering a menu nobody can answer.
4. **Verify:** with the fix, the same purchase gives exit 2 and an actionable line for `setup`
   without `--yes`, and a real, reported re-sync for `update` (symlinks appear in the isolated HOME).

## Why `update` was unrecoverable rather than merely annoying

`update` has no choices to make — it refreshes what is already installed. But nothing records *what*
is installed: `detectExistingInstall()` only checks the `~/.claude/skills/survey-context` symlink, so
the installer cannot replay a previous run (tools + scope) and is forced back into a menu.

## Fix

- `scripts/lib/cli-version.js` — shared fresh-read version helper (also fixes
  BUG-2026-11-03-cli-update-stale-version).
- `bin/setup.js` — documented flags `--yes`, `--tools=a,b`, `--scope=global|local`, `--uninstall`,
  `--help`:
  - **interactive** only when stdin is a TTY and no `--yes`;
  - **no TTY and no `--yes`** → exit 2 with the exact command to run (`bigpowers setup --yes
    --tools=claude`);
  - after any successful install, persist `{version, scope, tools}` to
    `~/.bigpowers/install-state.json` (global) or `./.bigpowers/install-state.json` (local).
- `bin/bigpowers.js` — `update` is non-interactive by construction: it delegates with
  `BIGPOWERS_NONINTERACTIVE=1` and replays the manifest; with no manifest and no install it prints
  `Run: bigpowers setup` and exits 1. `BIGPOWERS_SKIP_SELF_UPDATE=1` skips the npm fetch (offline/CI).

## Regression guard

`scripts/test-bigpowers-cli.sh` (gate `bigpowers-cli`):
- `setup` without a TTY and without `--yes` → exit **2**, message names `--yes`, finishes fast;
- `update` without a TTY → exit 0, **no** menu text, and `$HOME/.pi/agent/skills/survey-context` is a
  symlink afterwards (it actually installed);
- `setup --yes --tools=pi` → same, no prompts;
- every CLI call runs under an `alarm` watchdog, so a reintroduced hang fails the gate instead of
  blocking CI.

## Evidence

```
=== test-bigpowers-cli.sh ===
  PASS (1) readPackageVersion sees the on-disk version after the file changes
  PASS (2) setup without a TTY and without --yes fails fast with guidance (exit 2)
  PASS (3) update without a TTY installs from the manifest and prints no menu
  PASS (4) setup --yes --tools=pi installs without prompting
  PASS (5) update banner reports the installed version
5 passed, 0 failed
```
