---
bug_id: BUG-2026-07-24-installer-spinner-freezes-during-sync
status: open
severity: low
scope: install
title: "bigpowers setup spinner freezes during sync-skills.sh instead of animating"
discovered: user-reported (screenshot of frozen spinner)
created: 2026-07-24
---

## Summary

**Actual:** A prior fix (commit f3589d9d) stopped the clack spinner cleanly
before invoking `bash scripts/sync-skills.sh --distribute-only` via
`runInherited()` (synchronous `execSync` + `stdio: 'inherit'`), avoiding the
garbled-line glitch. But there is no animated indicator *during* that step —
the user sees a clean checkpoint, then raw child-process text, with no
spinner motion while the sync itself runs.

**Expected:** A genuinely animating spinner throughout the sync-skills.sh
call, so the CLI visibly communicates "still working" rather than appearing
to pause between checkpoints.

## Root Cause Analysis

`execSync` is fully synchronous — it blocks the Node event loop until the
child process exits. `@clack/prompts`' spinner animates via a `setInterval`
that requires the event loop to be free to tick. No amount of spinner
API usage can produce visible motion while `execSync` blocks the loop; the
two are architecturally incompatible.

The only way to get real animation during the sync step is to run the child
process asynchronously (`child_process.spawn`), keeping the event loop free,
and capture its stdout/stderr instead of inheriting it directly (inherited
output would otherwise print over/around the spinner's own redraw, same
class of glitch as before).

## TDD Fix Plan

1. **RED**: `bin/setup.js` has no async child-process helper; the only sync
   path is `runInherited` (execSync).
   **GREEN**: Add an async `runInheritedAsync(cmd)` using
   `child_process.spawn`, returning a Promise that resolves on exit code 0
   and rejects otherwise, capturing stdout/stderr into a buffer instead of
   inheriting.
   **verify**: `node --check bin/setup.js` passes; calling the new function
   against a trivial command (e.g. `bash -c 'sleep 0.2 && echo ok'`) resolves
   successfully.

2. **RED**: The sync-skills step still calls the synchronous `runInherited`,
   so the spinner cannot animate during it.
   **GREEN**: Replace the `s.stop(...)` / `runInherited(...)` / `s.start(...)`
   sequence with: keep the spinner *running* (`s.message('Syncing skills...')`),
   `await runInheritedAsync(...)`, and on success `s.message(...)` a summary
   line derived from the captured output (e.g. the "X skills synced" line);
   on failure, stop the spinner with an error and print the captured output
   for diagnosis.
   **verify**: manually run `bigpowers setup` (or `node bin/setup.js`) and
   observe continuous spinner motion through the sync step, with no garbled
   output and a clear pass/fail summary line afterward.

3. **RED**: No regression guard exists for "sync-skills invocation must stay
   async."
   **GREEN**: Extend `scripts/test-install-distribute-only.sh` (or a new
   assertion) to grep for `spawn(` / `runInheritedAsync` and absence of a bare
   synchronous `runInherited('bash scripts/sync-skills.sh` call in the sync
   step.
   **verify**: the test passes.

**REFACTOR**: None — `runInherited` (sync) stays as-is for any other simple,
fast, non-spinner-adjacent calls; only the sync-skills.sh call site changes.

## Acceptance Criteria

- [ ] Spinner visibly animates throughout the sync-skills.sh call (manual
      verification — no automated TTY-animation test is practical here)
- [ ] No garbled/merged output on success or failure
- [ ] Failure path still surfaces the real error output to the user
- [ ] Regression assertion added
- [ ] `npm run compliance && bash scripts/run-verification-gates.sh` green
