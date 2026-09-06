---
bug_id: BUG-2026-09-05-golden-gate-missing-node-deps
status: open
severity: high
scope: ci
title: "golden-suite omp-extension gate fails: CI never installs node deps, so smoke's typebox import is unresolvable"
issue: https://github.com/danielvm-git/bigpowers/issues/119
related: BUG-2026-09-05-pi-omp-extension-load-crash
---

# BUG-2026-09-05 (II): omp-extension golden gate needs node_modules; CI never installs it

## Problem

- **Actual**: CI run `33981866073` (main @ `9b8453ce`, Golden Anti-Vacuity Suite)
  fails `verification-gates`: 39/40 gates pass, `[omp-extension] FAIL (.26s, exit 1)`.
  Root error inside the gate:

  ```text
  Error [ERR_MODULE_NOT_FOUND]: Cannot find package 'typebox'
  imported from .../extensions/omp-hooks.ts
  ```

- **Expected**: `verification-gates` green; the `omp-extension` gate (the runtime
  load smoke added in a4875651 for #119) executes and passes.

- **Reproduce**:
  1. `gh run view 33981866073 --repo danielvm-git/bigpowers --log-failed`
  2. Locally: `rm -rf node_modules && bash scripts/validate-omp-extension.sh` →
     runtime load smoke FAIL with `ERR_MODULE_NOT_FOUND: typebox`.
  3. `npm ci && bash scripts/validate-omp-extension.sh` → PASS.

## Root Cause Analysis

a4875651 (#119 fix, released 2.88.1) did three coupled things:

1. Ported `extensions/omp-hooks.ts` from the nonexistent `pi.zod` to
   `import { Type } from "typebox"` — correct for real pi (pi bundles TypeBox and
   virtualises `typebox` for extensions via jiti aliases), so npm consumers are fine.
2. Added `typebox ^1.3.7` to **devDependencies** (package-lock: 1.3.27).
3. Made `scripts/validate-omp-extension.sh` execute `node scripts/omp-smoke.ts`
   as a deterministic runtime-load regression gate (registered in
   `scripts/lib/golden-suite-gates.sh` as `omp-extension`), run by
   `bash scripts/run-verification-gates.sh`.

The missing coupling: **`.github/workflows/golden-suite.yml` never installs node
dependencies.** The `verification-gates` job does checkout → setup-node →
python deps → gates. Every other gate is bash/python and needs no node_modules,
so the suite historically ran dependency-free. The new smoke runs under plain
Node ESM (NOT pi's aliased loader), so `import { Type } from "typebox"` must
resolve from `node_modules` — which does not exist on the runner → exit 1.

Why it was missed at a4875651: the fix was verified locally (node_modules present,
smoke passed) and against pi's real loader — both environments have TypeBox. CI,
the only environment without node_modules, was not exercised before merge.

`docs-site.yml` and `publish.yml` already run `npm ci` — golden-suite.yml is the
outlier now that one gate genuinely needs Node packages.

**Security impact: NONE** — availability/CI defect only.

## Fix Plan

### Step 1 — RED (already captured)
- CI evidence: run 33981866073, `[omp-extension] FAIL`, gate log above.
- Local evidence: pre-`npm ci` failure reproduced; post-`npm ci` green
  (81 commands, bigpowers_skill tool, session_start + tool_call handlers).

### Step 2 — GREEN (minimal fix)
Add one step to the `verification-gates` job in `.github/workflows/golden-suite.yml`,
after "Install Python deps" and before "Run verification gates":

```yaml
      - name: Install Node deps
        run: npm ci
```

Notes:
- Full `npm ci` (NOT `--omit=dev`) — `typebox` is a devDependency.
- Lockfile-pinned (`package-lock.json`, typebox 1.3.27) → deterministic.
- Keep the `# story: e51s04` tag in the workflow header (traceability).

Considered and rejected:
- Moving the runtime smoke behind a "skip if no node_modules" guard → makes the
  gate vacuous in CI; violates the anti-vacuity doctrine this suite exists to
  enforce (G-08/G-10).
- Making the smoke import via pi's loader to pick up bundled TypeBox → adds
  `@earendil-works/pi-coding-agent` as a devDependency and the same `npm ci`
  requirement, for no behavior gain.

### Step 3 — validate-fix
1. `npm ci && bash scripts/validate-omp-extension.sh` → exit 0.
2. `bash scripts/run-verification-gates.sh` → 40/40 PASS locally.
3. Preflight: `npm run compliance && bash scripts/run-verification-gates.sh &&
   bash scripts/sync-skills.sh && bash scripts/trace-stories.sh --strict`.
4. Push branch + PR; `gh pr checks` green on the PR (this is the environment
   that actually lacked node_modules — local green alone is NOT sufficient;
   that is exactly how this bug shipped).

### Step 4 — release-branch
Merge to main; confirm the next push-triggered golden-suite run is 40/40 green.

## Files to change

- `.github/workflows/golden-suite.yml` — add `npm ci` step to verification-gates job.

## Lessons (add to BUG-2026-09-05-pi-omp-extension-load-crash.md on close)

The #119 fix's validation matrix omitted the only environment that lacks
node_modules (CI runner). Rule going forward: any new CI gate that executes
node code must either declare its dependencies in the workflow (npm ci) or
prove it needs none.

## Commit message (proposed)

`fix(ci): run npm ci before verification gates so omp-extension smoke resolves typebox`
