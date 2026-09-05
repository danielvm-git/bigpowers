---
bug_id: BUG-2026-09-05-pi-omp-extension-load-crash
status: open
severity: critical
scope: extensions / pi
title: "extensions/omp-hooks.ts calls pi.setLabel() during load → pi aborts at startup for every package consumer (#119)"
issue: https://github.com/danielvm-git/bigpowers/issues/119
---

# BUG-2026-09-05: OMP extension crashes pi at startup (#119)

## Problem

- **Actual**: After `pi install npm:bigpowers` (v2.88.0), running `pi` aborts during
  startup with:
  ```text
  Error: Failed to load extension ".../node_modules/bigpowers/extensions/omp-hooks.ts":
  Failed to load extension: Extension runtime not initialized. Action methods cannot be
  called during extension loading.
  ```
  pi is unusable until the package is removed (or started with `pi -ne`).
- **Expected**: `pi` starts normally; the bigpowers extension registers its slash
  commands, `bigpowers_skill` tool, and the git-safety `tool_call` guard without
  crashing startup.
- **Reproduce**: `pi install npm:bigpowers && pi` → crash. Environment:
  `@earendil-works/pi-coding-agent` v0.84.4, bigpowers v2.88.0.

**Security impact: NONE** — availability defect (startup abort), not unauthorized access.

## Root Cause Analysis

### Primary root cause — action method called during load

`extensions/omp-hooks.ts:241` calls `pi.setLabel("bigpowers")` synchronously in the
extension factory body:

```ts
export default function bigpowers(pi: ExtensionAPI) {
  const z = pi.zod;
  pi.setLabel("bigpowers");   // ← throws during load
  ...
```

pi's extension loader wires a two-phase API (verified in the installed pi runtime,
`dist/core/extensions/loader.js`):

- During **load**, the runtime installs throwing stubs for *action* methods:
  `createExtensionRuntime()` sets `setLabel: notInitialized`, where `notInitialized`
  throws exactly `"Extension runtime not initialized. Action methods cannot be called
  during extension loading."` (`loader.js:135-137`). Real implementations are bound
  later by `runner.bindCore()` / `commit()`.
- **Registration** methods (`registerCommand`, `registerTool`, `on`, `registerFlag`,
  …) are valid during load — they write to the extension object, not the runtime.
- `api.setLabel()` delegates straight to `runtime.setLabel()` with **no** load-phase
  queueing (unlike `registerProvider`, which is queued via `applyRuntimeChange`).
  So calling it in the factory body throws immediately, the whole extension fails to
  load, and pi aborts startup — there is no graceful per-extension skip.

Secondary defect in the same call: pi's real `setLabel(entryId, label)` takes **two**
args and sets/clears a bookmark label on a specific session **entry** (shown in the
`/tree` selector) — verified in pi 0.85.1 source `src/core/extensions/types.ts:1394`
and `docs/extensions.md:1508`. It is not an "extension display name" setter. So
`pi.setLabel("bigpowers")` is wrong even post-load: `"bigpowers"` would be an `entryId`
with `label=undefined`, i.e. "clear the label on entry 'bigpowers'". There is no API to
set an extension's name — identity comes from its path/manifest. The call has no valid
purpose and must be **removed**, not relocated.

Note (queueing): only `pi.registerProvider()` calls made in the factory are queued and
flushed after the runner initialises (`docs/extensions.md:1742`; loader.ts routes them
through `applyRuntimeChange`/`pendingProviderRegistrations`). Action methods like
`setLabel` are **not** queued — they hit the throwing stub. The documented factory
pattern (`docs/extensions.md:156-180`) is: register tools/commands/shortcuts/flags in
the factory body; perform actions (incl. `setLabel`, `ctx.ui.*`) inside `pi.on(...)`
handlers. omp-hooks already follows this everywhere except the stray `setLabel` line —
its `session_start` handler correctly uses `ctx.ui.notify`, and its `sendUserMessage`/
`sendMessage` calls run only inside handlers.

### Second root cause — masked `pi.zod` crash (fork-API mismatch)

The extension was ported from `@oh-my-pi/pi-coding-agent` (a zod-based fork) but the
issue's users run `@earendil-works/pi-coding-agent`. Two API assumptions do not hold on
earendil pi and both abort load:
- `pi.setLabel(...)` (above).
- `const z = pi.zod; … parameters: z.object({…})` — earendil pi has **no `zod`** on the
  ExtensionAPI at all (verified: zero occurrences of "zod" in pi 0.85.1 source). Tool
  parameter schemas use **TypeBox** (`import { Type } from "typebox"`, `docs/extensions.md`).
  So `pi.zod` is `undefined` and `z.object(...)` throws
  `Cannot read properties of undefined (reading 'object')` during `registerTool`.

This second crash was **masked** in production: `setLabel` (line 241) throws before
`registerTool` (line ~260), so users only ever saw the first error. Removing only
`setLabel` moves the startup abort 20 lines down — pi still exits. #119's expected
behavior ("slash commands register without crashing") requires fixing **both**. The
type-only import specifier was also wrong (`@oh-my-pi/...`); corrected to
`@earendil-works/pi-coding-agent`.

### Why CI/tests missed it

`scripts/omp-smoke.ts:24` builds a fake `pi` whose `setLabel: () => {}` is a permissive
no-op that never throws and does not model pi's load-phase guard. The smoke test loaded
the extension "successfully" against an API that doesn't enforce the real contract, so a
load-time action-method call passed CI. `scripts/validate-omp-extension.sh` is a static
symbol grep and never executes the factory, so it could not catch it either.

### How the extension is even discovered (context)

The published manifest declares `pi: { skills, prompts }` and a separate
`omp: { extensions: ["extensions/omp-hooks.ts"] }`. pi **never reads** the `omp` key
(`readPiManifest` reads only the `pi` key). Discovery is **settings-form dependent** —
verified empirically on pi 0.84.4 and 0.85.1 with the published 2.88.0 tarball:
- **Plain-string settings entry** (`"packages": ["npm:bigpowers"]` — what
  `pi install npm:bigpowers` writes): `collectPackageResources` sees the existing `pi`
  manifest, adds only the declared types (skills/prompts), and returns early — the
  `extensions/` directory is **NOT scanned**, and the extension is not loaded at all
  (no crash; pi proceeds to model/API checks).
- **Object/filter-form entry** (`"packages": [{"source": "npm:bigpowers"}]`): pi routes
  through `collectDefaultResources(pkgRoot, "extensions", …)`, finds no `pi.extensions`
  entry, and falls back to **auto-scanning the `extensions/` directory**
  (`docs/packages.md:162` — "`extensions/` loads `.ts` and `.js` files"), discovering
  `omp-hooks.ts` → the load-time crash fires (reproduced verbatim on 0.84.4 and 0.85.1).
  The reporter's crash trace shows the extension resolved from the installed npm
  package, consistent with this path (or an explicit `-e`/filtered settings entry).
So:
- The crash reproduces regardless of the `omp` key, but only when the extension is
  actually loaded (filtered form / `-e` / declared path) — plain-string installs
  silently don't load it.
- `omp.extensions` is dead configuration (pi ignores it); `validate-omp-extension.sh`
  validates a key the runtime never consumes.
- The documented model (`docs/packages.md:120-162`) is that a package with a `pi`
  manifest loads **only the resource types it declares**; auto-scan is the "no manifest"
  path. bigpowers has a `pi` manifest without `extensions`, so declaring `pi.extensions`
  is both the fix for the dead key and the way to make extension loading intentional and
  robust rather than reliant on the configured-source scan fallback.

## Fix Plan (TDD — red → green → refactor)

### Step 1 — Regression guard first (RED)

**Preferred (authoritative) — test against pi's REAL loader.** pi publicly exports
`createExtensionRuntime` and `discoverAndLoadExtensions` (verified in 0.85.1
`src/index.ts` + the published `dist/index.js`). `loadExtensionFromFactory` is **NOT**
publicly exported from the published package — use `discoverAndLoadExtensions` instead,
which runs the genuine load-phase runtime (throwing `notInitialized` stubs) over a
configured path, reproducing the exact production crash with zero fakes — verified
empirically on pi 0.85.1 (`dist/index.js` exports checked):
```js
import { discoverAndLoadExtensions } from "@earendil-works/pi-coding-agent";
const result = await discoverAndLoadExtensions(["/abs/path/extensions/omp-hooks.ts"], cwd);
// Before fix: result.errors = ["Failed to load extension: Extension runtime not
//   initialized. Action methods cannot be called during extension loading."]
// After fix: result.errors.length === 0
```
This needs `@earendil-works/pi-coding-agent` as a devDependency. If that dep is
undesirable in CI, use the fallback.

**Fallback — harden the existing `scripts/omp-smoke.ts` fake** to model the contract:
- Track a `loading` flag: true while `await bigpowers(pi)` runs, false afterward.
- Make **action** methods throw while `loading` is true, using pi's exact message
  (`setLabel`, `sendUserMessage`, `sendMessage`, `appendEntry`, `setSessionName`,
  `setModel`, `getActiveTools`, `setActiveTools`, `getCommands`, `setThinkingLevel`).
- Keep **registration** methods (`registerCommand`, `registerTool`, `on`, `registerProvider`-style queueing) callable during load; don't fake `zod` (the real API has none — the fake should mirror that, i.e. no `zod` property, so a `pi.zod` regression is caught too).
- Assert the factory loads without throwing, then exercise handlers (as today).

Either harness must **fail** against current `omp-hooks.ts`, reproducing the crash
deterministically.

### Step 2 — Minimal fix (GREEN, two edits — NOT complete without both)
**2a.** Delete line 241 `pi.setLabel("bigpowers")` from `extensions/omp-hooks.ts`.
**2b. Mandatory companion:** port the `bigpowers_skill` tool schema from `pi.zod` to
TypeBox. earendil pi has no `zod` on the ExtensionAPI (verified: zero "zod" occurrences
in pi 0.85.1 source; tool schemas use `Type.Object({...})` from `typebox`) — so removing
`setLabel` alone merely moves the abort 20 lines down to
`Cannot read properties of undefined (reading 'object')` inside `registerTool`
(verified empirically: loading a setLabel-stripped copy of omp-hooks.ts through pi's
real loader fails with exactly that second error). Replace `const z = pi.zod` and
`z.object(...)` with `Type.Object({...})` / `Type.String` / `Type.Enum` (or
`Type.Union`+`Type.Literal`) / `Type.Optional`. Nothing else in the factory calls an
action method during load (`registerCommand`/`registerTool`/`on` are registration;
`sendUserMessage`/`sendMessage` run only inside handlers post-load).
Re-run the hardened smoke → **green**. Do NOT close Step 2 until both 2a and 2b are in.

### Step 3 — Manifest correctness (recommended, separable)
Promote discovery from the dead `omp.extensions` key to the key pi actually reads
(exact form per `docs/packages.md:124` — arrays support globs and `!exclusions`):
- Add `"extensions": ["extensions/omp-hooks.ts"]` to the `pi` manifest key in
  `package.json` (drop `omp.extensions`, or keep it only as informational metadata).
- Update `scripts/validate-omp-extension.sh` to assert `pi.extensions` (not
  `omp.extensions`).
- This makes discovery explicit rather than relying on the configured-source directory
  scan; the extension still loads (pi de-dupes by resolved path, so no double-load), but
  intent is now declared and validated. Do this in the SAME PR as the crash fix so the
  patch release ships a coherent, correctly-declared manifest.

### Step 4 — Validate (validate-fix)
- Hardened `scripts/omp-smoke.ts` green.
- `bash scripts/validate-omp-extension.sh` green.
- Real-world proof: `npm pack`, install the tarball into a scratch dir, and run pi
  headlessly against it (e.g. `pi -p "/verify-context ping"` or `pi` cold start) to
  confirm no startup crash and that slash commands register.
- Preflight: `npm run compliance && bash scripts/run-verification-gates.sh &&
  bash scripts/sync-skills.sh && bash scripts/trace-stories.sh --strict`.

## Files changed

- `extensions/omp-hooks.ts` — remove load-time `pi.setLabel("bigpowers")`; port tool
  schema from `pi.zod` to TypeBox (`Type.Object/Union/Literal/String/Optional`); fix
  type-only import to `@earendil-works/pi-coding-agent`.
- `scripts/omp-smoke.ts` — model pi's load-phase action-method guard (RED→GREEN test);
  drop the now-unused zod fake.
- `scripts/validate-omp-extension.sh` — assert `pi.extensions`; run the runtime load
  smoke as a gate (was never executed in CI before).
- `package.json` — add `pi.extensions`; remove dead top-level `omp.extensions`; add
  `typebox` devDependency (runtime schema import; pi supplies its own copy at load).

## Validation evidence

- `node scripts/omp-smoke.ts` → exit 0 (fails on pre-fix code with pi's exact error).
- `bash scripts/validate-omp-extension.sh` → "OMP extension validation passed" (exit 0).
- **Real pi 0.85.1**: `npm pack` → load the tarball's extension through pi's own
  `discoverAndLoadExtensions` with an isolated agent dir → `{commands:81, tools:1,
  toolName:"bigpowers_skill", handlers:["session_start","tool_call"]}`, 0 load errors,
  exit 0. Pre-fix this rejected with the `setLabel` error, then the `pi.zod` error.

## Commit message (proposed)

`fix(extensions): stop omp-hooks crashing pi at startup — drop load-time setLabel, port zod→TypeBox (#119)`
