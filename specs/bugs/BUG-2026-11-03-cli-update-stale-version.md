---
bug_id: BUG-2026-11-03-cli-update-stale-version
status: fixed
severity: medium
scope: cli / installer
title: "`bigpowers update` prints the version the process booted with, so after installing v2.92.0 the banner still said v2.88.5 while `bigpowers install` correctly said v2.92.0"
files_changed: "scripts/lib/cli-version.js (new), bin/bigpowers.js, bin/setup.js, scripts/test-bigpowers-cli-version.sh (new), scripts/lib/golden-suite-gates.sh"
approach: "Read package.json from disk at render time instead of reusing the require() cache populated before the self-update, and route every user-facing version string through that one helper"
risk_level: low
commit_message: "fix(cli): report the installed version after a self-update"
---

# BUG-2026-11-03: `update` reported the version it replaced

User report: `bigpowers update` printed `v2.88.5` in the banner and in the menu header right after
`npm install -g bigpowers@latest` had installed 2.92.0; `bigpowers install` run immediately afterwards
printed `v2.92.0`. So one of the two was lying.

## Problem

- **Actual:** `update` → `v2.88.5`. `install` → `v2.92.0`. `update` is wrong: the installed package
  was 2.92.0 (confirmed with `npm ls -g` → `bigpowers@2.92.0`).
- **Expected:** the command whose job is to move you to 2.92.0 reports 2.92.0.

## Root Cause Analysis

1. **Reproduce** without npm, HOME or a TTY:
   ```js
   const pkg = require(P + '/package.json');                      // bin/bigpowers.js, module load: 2.88.5
   fs.writeFileSync(P + '/package.json', '{"version":"2.92.0"}');  // npm install -g bigpowers@latest
   require(P + '/setup.js');                                      // bin/setup.js → require(ROOT/package.json)
   // → startup 2.88.5 · setup banner 2.88.5 · on disk 2.92.0
   ```
   Scripted as case (2) of the regression gate, which fails with *"the banner reported the startup
   version (v2.88.5) after 2.92.0 was installed"*.
2. **Isolate:** `bin/bigpowers.js` requires `package.json` at startup. `bin/setup.js` — required only
   *after* the reinstall, so it is read from the new files on disk — then requires the same resolved
   `package.json` path, and Node returns the **cached** module object from the parent. The file is
   new; the version string is the one the process booted with. `install` looked correct because it is
   a fresh process: cache empty, file read fresh.
3. **Hypothesize:** version reporting must read the file at the moment it renders, not reuse a value
   captured before the write.
4. **Verify:** the same script prints `2.92.0` for the banner once the read goes through
   `readFileSync`.

## Fix

- `scripts/lib/cli-version.js` — `readPackageVersion(root)`: `readFileSync` + `JSON.parse`, `unknown`
  on failure.
- `bin/setup.js` — `BANNER` (a module-level template built from `pkg.version`) becomes
  `banner(version)`, and `main()` reads the version fresh before rendering the banner and the intro
  line. `pkg` is no longer required at all.
- `bin/bigpowers.js` — `status`, the "already installed" and the "skills not yet installed" lines use
  the same helper, so no user-facing string can carry a startup snapshot.

## Regression guard

`scripts/test-bigpowers-cli-version.sh` (golden gate `bigpowers-cli-version`):
1. `readPackageVersion()` returns the on-disk version after the same path was already `require`d and
   then rewritten — the mechanism itself;
2. a driver that mimics `update` (snapshot → overwrite → require `bin/setup.js`) asserts the banner
   carries 2.92.0 and fails explicitly if it carries the startup 2.88.5;
3. a static guard: neither `bin/setup.js` nor `bin/bigpowers.js` interpolates `pkg.version` into a
   user-facing line (the cache is invisible until the day a self-update happens, which is why this
   shipped).

## Evidence

```
=== test-bigpowers-cli-version.sh ===
  PASS (1) readPackageVersion sees the on-disk version after package.json is rewritten
  PASS (2) the banner after a self-update reports the installed version (2.92.0), not the startup one (2.88.5)
  PASS (3) neither bin/setup.js nor bin/bigpowers.js prints a cached pkg.version
3 passed, 0 failed
```

Pre-fix the same gate reported `0 passed, 3 failed`, with case (2) naming the reported symptom.

## Not in scope

The menu the two commands draw in a shell with no TTY is a separate defect, reproduced and logged as
`BUG-2026-11-03-cli-nontty-silent-noop` (still open) — it is not what made the version wrong, and
fixing it here would have mixed an installer redesign into a version-reporting fix.
