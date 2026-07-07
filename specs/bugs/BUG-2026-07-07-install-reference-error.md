# BUG: bigpowers CLI crashes with ReferenceError on bare invocation

**Date:** 2026-07-07
**Severity:** P1 (blocks `bigpowers --version` and bare `bigpowers` for fresh installs)

## Observed Behavior

Running `bigpowers --version` or bare `bigpowers` on a fresh install (no setup yet) crashes:

```
console.log(`🚀 bigpowers v${pkg.version} — skills not yet installed.`);
                             ^
ReferenceError: pkg is not defined
```

## Expected Behavior

Both commands should print the version string and guide the user to run `bigpowers setup`.

## Root Cause

`bin/bigpowers.js` has 5 control-flow branches that reference `pkg.version`:

1. `setup`/`install` handler (line 34) — had `const pkg`
2. `update` handler (line 45) — had `const pkg`
3. `status` → installed branch (line 55) — had `const pkg`
4. Default → installed branch (line 81) — had `const pkg`
5. **Default → not-installed branch (line 85) — was MISSING `const pkg`**

Branch 5 was the only one missing the declaration. `const` is block-scoped, so the other declarations in sibling `if/else` blocks were inaccessible.

## Fix Applied

**File:** `bin/bigpowers.js`

Added `const pkg = require(path.join(ROOT, 'package.json'));` at module level (line 13), then removed all 5 block-scoped duplicates. This:

- Fixes the ReferenceError
- Eliminates a DRY violation (5 → 1 declaration)
- Prevents recurrence — any new branch automatically has `pkg`

## Hardening

**Mechanism:** Invariant hoisting — `pkg` is now loaded once at module scope. Future branches cannot "forget" to declare it.

**Verification:**

```bash
bigpowers --version   # exit 0, shows version
bigpowers             # exit 0, shows version
bigpowers status      # exit 0, shows skill count
bigpowers help        # exit 0, shows help text
```

## Commit

```
4d47e471 fix(install): add missing pkg declaration in CLI default handler
```
