---
bug_id: BUG-2026-08-07-interactive-uninstall-silent-noop
status: fixed
severity: high
scope: installer
title: "Interactive menu Uninstall reports success while leaving symlinks in place"
---

# BUG-2026-08-07-interactive-uninstall-silent-noop: Interactive menu Uninstall reports success while leaving symlinks in place

## Problem

`bigpowers install` → existing install detected → **Uninstall** → select tools → confirm
prints `✓ <tool> — removed` for every selected tool and ends with `Uninstall complete.`,
but for a majority of tool/mode combinations no file is actually removed.

**Reproduce:** `bigpowers install`, choose `Uninstall`, select any of qwen / codebuddy /
cline / kilo / trae / windsurf / opencode / copilot (any install mode), or select *any*
tool after a **Local** install. Output claims success; the symlinks/files remain on disk.

**Expected:** Uninstall removes exactly what install created, for every tool the menu
offers, in whichever mode (global or local) was actually installed.

## Root Cause Analysis

`bin/setup.js:handleUninstall()` calls `uninstallTool(toolId, ROOT)` in a try/catch and
prints `✓ removed` whenever the call doesn't throw. `uninstallTool()` in
`scripts/lib/install-helpers.js` never throws for an unhandled case — a `switch` with no
matching `case` just falls through silently. Two independent gaps triggered this:

### Gap 1 — 8 of 18 menu tools had no uninstall case at all

`installGlobal()` has a `case` for every id in `bin/setup.js`'s `SUPPORTED_IDS` (18 ids).
`uninstallTool()` only had cases for 10: `claude, gemini, pi, hermes, zcode, mimo,
antigravity/agy, cursor, codex`. The uninstall menu still offers all 18 (it filters by
`SUPPORTED_IDS`, not by "has an uninstall case"), so selecting `qwen`, `codebuddy`,
`cline`, `kilo`/`kilocode`, `trae`, `windsurf`, `opencode`, or `copilot` fell through the
switch, did nothing, and reported `✓ removed`.

Also found in the same pass: the existing `codex` case removed a hook path install never
creates and never removed the `~/.codex/AGENTS.md` symlink install *does* create.

### Gap 2 — uninstall never looks at a local install at all

`installLocal()` (used when the user picks the **Local** install mode) writes symlinks
under `process.cwd()` — e.g. `./.claude/skills`, `./.pi/agent/skills`,
`./.cursor/rules`, `./.codex/AGENTS.md`. `uninstallTool()` only ever read
`os.homedir()`-rooted paths; it has no `cwd` awareness whatsoever. `handleUninstall()`
never asks global-vs-local before calling it. Confirmed by direct repro (before fix):

```
local pi skills linked before uninstall: 81
local pi skills remaining after uninstallTool(pi): 81   <- unchanged
```

This affects every tool that supports local install (`claude, gemini, pi, hermes, zcode,
mimo, antigravity/agy, cursor, codex` — 9 of the 10 originally-handled ids), independent
of Gap 1.

## Fix

`scripts/lib/install-helpers.js`:
- Added the 8 missing uninstall cases, each mirroring exactly what `installGlobal`
  creates for that tool (skill symlinks, `AGENTS.md`/`QWEN.md`, rules `*.md`, git-guard
  hooks). Added two helpers: `removeManagedSkillLinks` (repo-rooted OR
  `bigpowers`-substring match, matching the existing zcode/mimo/antigravity convention)
  and `removeManagedFile` (kilo/windsurf/copilot write `AGENTS.md` as a plain **copy**,
  not a symlink — the symlink-only remover silently skipped it).
- Fixed `codex` to also remove `~/.codex/AGENTS.md`.
- Added local-path cleanup to all 9 originally-handled cases, resolving `cwd =
  process.cwd()` inside `uninstallTool()` (mirroring how `installLocal()` resolves its
  own targets) so the same call now cleans whichever scope — global, local, or both —
  actually has bigpowers symlinks. Added a stricter `removeRepoRootedSkillLinks` helper
  for `claude`/`pi` specifically, since their original matching was `startsWith(repoRoot)`
  only; reusing the broader helper there would let uninstall delete symlinks pointing at
  an unrelated bigpowers checkout elsewhere on disk (e.g. a second clone) — kept that
  narrower.
- `antigravity`/`agy` local cleanup explicitly skips touching `cwd/.agents/skills` when
  `cwd === repoRoot`: that path is this repo's own tracked skill-source tree (the
  installer's rendered-skill *input*), not an install target, and must never be deleted
  by uninstall.

`scripts/test-install-helpers.js`:
- Round-trip tests for `qwen` (symlinked skills) and `copilot` (copied `AGENTS.md`).
- A **drift guard**: parses `SUPPORTED_IDS` out of `bin/setup.js` and asserts every id
  has a matching `case` in `uninstallTool` — verified by mutation test to fail cleanly
  the moment a case is removed.
- Local install/uninstall round-trip for `pi`, `claude` (skill-symlink dirs), `cursor`,
  `gemini` (single linked dir), `codex` (linked file) — spanning every install shape.
  Verified by mutation test (`git stash` the source fix, rerun): fails immediately
  (`uninstallTool(qwen) must remove repo-rooted skill symlinks`) without the fix,
  confirming the guard is load-bearing, not vacuous.

## Verify

```bash
node scripts/test-install-helpers.js
# → test-install-helpers: ALL PASS
```

Also checked and found **not** a gap: `scripts/test-install-helpers.sh` (the wrapper for
this selftest) is already wired into CI via the `install-helpers` gate in
`scripts/lib/golden-suite-gates.sh`, which `scripts/run-verification-gates.sh` runs, which
`.github/workflows/golden-suite.yml` runs on every push. An earlier pass through this
investigation incorrectly flagged CI wiring as missing — it was a grep miss (searched
`run-verification-gates.sh` and `.github/workflows/` directly, not the gate list file the
runner sources).
