---
bug_id: BUG-2026-11-03-omp-hooks-stderr-leak
status: open
severity: medium
scope: extensions / omp-hooks
title: "tool_call hook leaks git's fatal: not a git repository onto the TUI when a bash command cds outside the session repo"
files_changed: "extensions/omp-hooks.ts, scripts/omp-smoke.ts, scripts/validate-omp-extension.sh"
approach: "Give the branch probe a silent stdio (mirroring inGitRepo) and short-circuit with inGitRepo(cwd) so no git process is spawned for a non-repo target; assert the silence from the shell gate by capturing the smoke's stderr"
risk_level: low
commit_message: "fix(omp): keep the tool_call branch probe quiet outside a git repo"
---

# BUG-2026-11-03: tool_call hook paints git's stderr over the TUI

Reported as issue #189 (triaged and validated by @bertalanv).

## Problem

- **Actual:** in a pi session rooted inside a git repository, any bash command that changes into a
  directory that is not a repository prints
  `fatal: not a git repository (or any of the parent directories): .git`
  straight onto the terminal — over the TUI input line. The text is not part of the tool result, is
  absent from the session file, and vanishes on the next redraw, so the input box looks corrupted.
  No git command is needed in the user's command: `cd /tmp/scratch && ls` is enough.
- **Expected:** a guard that inspects a command stays invisible; its failures are returned, never
  painted on the agent's tty.
- **Found in:** 2.88.17, still present in 2.90.0. Platform-independent (fd inheritance, not a
  terminal quirk).

## Root Cause Analysis

1. **Reproduce (this host, node 24):**
   ```bash
   cd /tmp/leak-probe && node -e '
     const { execSync } = require("node:child_process");
     try { execSync("git rev-parse --abbrev-ref HEAD", { encoding:"utf-8", timeout:3000, cwd: process.cwd() }); }
     catch { console.log("caught"); }' 2>err.txt
   # stdout: caught     stderr: fatal: not a git repository (or any of the parent directories): .git
   ```
   The exception is caught, the message is already written: `execSync` without a `stdio` option
   inherits the parent's fd 2.
2. **Isolate:** `extensions/omp-hooks.ts` `tool_call` handler →
   `currentBranch(commandGitCwd(command, …))` (`omp-hooks.ts:420`). `commandGitCwd()` returns the
   directory the command will run in (the last `cd <path>` / `git -C <path>`, added for #154), and
   `currentBranch()` (`omp-hooks.ts:207`) runs `git rev-parse --abbrev-ref HEAD` **without**
   `stdio`, unlike its neighbour `inGitRepo()` (`omp-hooks.ts:193`) which passes `stdio: "ignore"`.
3. **Hypothesis:** every `tool_call` whose resolved cwd is a non-repo directory writes the fatal to
   the agent's stderr; the `catch` returns `"unknown"`, so the guard still behaves, only loudly.
4. **Verify:** the repo's own silent-probe check (added with the fix) fails before the fix and
   passes after it — `bash scripts/validate-omp-extension.sh`, section 7.

### Why it regressed

#146/#147 stopped git guards screaming outside repos, but the early bail at `omp-hooks.ts:419`
only checks `process.cwd()` (the session root). The per-command target directory from #154 is
never probed silently, so the earlier protection does not reach it.

## Fix

- `currentBranch()`: `stdio: ["ignore", "pipe", "ignore"]` — capture stdout, discard the noise
  (issue's suggested one-liner).
- `currentBranch()`: return `"unknown"` early when `!inGitRepo(cwd)`, so a non-repo target spawns
  no git process at all (also removes two pointless spawns for `git commit` commands).

Both are fail-closed: `"unknown"` already means "not a protected branch" downstream, and the
protected-branch checks are unchanged for real repos.

## Regression guard

`scripts/omp-smoke.ts` gains an opt-in probe (`OMP_SMOKE_SILENT_TOOL_CALL=1`) that invokes the real
`tool_call` handler with `cd <non-repo temp dir> && ls`, and
`scripts/validate-omp-extension.sh` runs it with stderr captured, failing if `fatal:` appears.
The guard is on the gate that already runs in CI, so the leak cannot come back silently.
