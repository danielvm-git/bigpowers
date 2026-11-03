---
bug_id: BUG-2026-11-03-cli-update-stale-version
status: fixed
severity: medium
scope: cli / installer
title: "`bigpowers update` prints the version the process started with, not what it just installed — the banner said v2.88.5 after installing v2.92.0"
files_changed: "scripts/lib/cli-version.js (new), bin/bigpowers.js, bin/setup.js, scripts/test-bigpowers-cli.sh (new), scripts/lib/golden-suite-gates.sh, README.md"
approach: "Read package.json from disk when the banner is rendered instead of reusing the require() cache populated before the self-update"
risk_level: low
commit_message: "fix(cli): report the installed version after a self-update"
---

# BUG-2026-11-03: update reported the pre-update version

## Problem

- **Actual:** after `npm install -g bigpowers@latest` succeeded inside `bigpowers update`, the banner
  read `v2.88.5` and the follow-up menu header read `bigpowers v2.88.5`. A later process
  (`bigpowers install`) reported `v2.92.0` for the same installation.
- **Expected:** the command whose job is to move you to v2.92.0 must not report v2.88.5.

## Root Cause Analysis

1. **Reproduce** (no npm needed):
   ```js
   const pkg = require(P + '/package.json');        // bin/bigpowers.js, module load
   fs.writeFileSync(P + '/package.json', '{"version":"2.92.0"}');   // npm install -g @latest
   require(P + '/setup.js');                        // bin/setup.js → require(ROOT/package.json)
   // parent: 2.88.5   setup banner: 2.88.5   on disk: 2.92.0
   ```
2. **Isolate:** `bin/bigpowers.js` requires `package.json` at startup for `pkg.version`, and
   `bin/setup.js` (required *after* the reinstall) requires the same resolved path — Node returns the
   **cached** module object. The file on disk is new; the version string is the one the process
   booted with. Only the banner is affected; nothing else reads `pkg` after install.
3. **Hypothesize:** version reporting must re-read the file at render time, not trust a cache that
   predates the write.
4. **Verify:** the same script with a cache-busting read prints `2.92.0` for both.

## Fix

`scripts/lib/cli-version.js` — `readPackageVersion(root)`, a `readFileSync` + `JSON.parse` with a
safe fallback. `bin/setup.js` uses it for the banner and the intro line; `bin/bigpowers.js` keeps
using `pkg.version` only for paths that cannot follow a reinstall (`status`, default message).

## Regression guard

`scripts/test-bigpowers-cli.sh` case 1: populates the require cache, rewrites `package.json`, then
asserts `readPackageVersion()` returns the new value. Case 5 asserts the banner of a real `update`
run carries the installed version.

## Evidence

```
1 passed: readPackageVersion sees the on-disk version after the file changes
5 passed: update banner reports the installed version
```
