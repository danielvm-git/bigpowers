---
bug_id: BUG-2026-08-31-pi-scripts-provisioning
status: open
severity: high
scope: cli / install
title: "Package installs provision skills but never scripts/ — lifecycle skills' script calls and verify gates fail in every consumer project (#116)"
---

# BUG-2026-08-31: no scripts/ provisioning for package consumers (#116)

## Problem

- **Actual**: After `pi install npm:bigpowers` (package lands at `~/.pi/agent/npm/node_modules/bigpowers/`, skills load from its `.pi/skills` manifest), every lifecycle skill that invokes tooling fails inside a consumer project: `bash scripts/run-skill-verify.sh` → `No such file or directory`, and `→ verify:` gates like `test -d specs/bugs && test -f scripts/run-skill-verify.sh` fail, so agents skip gates or hand-vendor scripts. Reported in [#116](https://github.com/danielvm-git/bigpowers/issues/116).
- **Expected**: A consumer project that installed the bigpowers package has a working `scripts/` (and `specs/` scaffolding) so skill commands and verify gates resolve — regardless of install vector (pi, `npm i -g`, `npx`).
- **Reproduce**: `pi install npm:bigpowers && cd <any project without a bigpowers checkout> && bash scripts/run-skill-verify.sh` → missing. Same class of failure for any non-checkout install: the scripts tree ships in the tarball but nothing ever links or copies it into the project.

**Security impact: NONE** — missing files, not unauthorized access; the defect degrades verification ergonomics only.

## Root Cause Analysis

### Reproduce

44 of 81 `SKILL.md` files reference `scripts/…` project-relative (e.g. `skills/fix-bug/SKILL.md:22` `bash scripts/run-verification-gates.sh`; verify gate at `:69`). Those paths only resolve when cwd **is** the bigpowers repo (the dev/dogfood flow). In a consumer project cwd they point at nothing.

### Isolate

- `package.json` `pi` key declares only `skills` + `prompts` — and pi's package contract (pi.dev packages.md) has **no resource type for arbitrary project files**, so `pi install` cannot provision `scripts/` even in principle.
- No lifecycle script exists (deliberately: BUG-2026-06-24T045323 removed `postinstall` after tarball-path breakage; `bin/bigpowers.js:4` documents "No npm lifecycle scripts needed").
- `installGlobal`/`installLocal` (`scripts/lib/install-helpers.js`) link **skills only** per tool — neither path ever provisions a project-local `scripts/` or `specs/`. `bin/bigpowers.js` dispatches only `setup|install|update|status|help`; there is no `init`.
- The scripts tree **does** ship in the npm tarball (`.npmignore` does not exclude `scripts/`) — the package at `~/.pi/agent/npm/node_modules/bigpowers/scripts/` contains all 105 scripts, unreachable from consumer cwd.

### Hypothesize

SKILL.md bodies are the contract: they assume project-root `scripts/`. Rather than rewriting 81 skill bodies to package-resolve paths (large generated-artifact churn, breaks the dev flow's readability), provision the project: a `bigpowers init` command that symlinks the package's `scripts/` into the consumer project and scaffolds `specs/bugs/` + `specs/verifications/`, guarded by `assertReplaceable` (landed in PR #114) so a user's pre-existing `scripts/` is never clobbered. This fixes pi, global-npm, and npx consumers with one mechanism under this repo's control.

### Verify

Sandbox: fake package root + fake consumer cwd → run `initProject(repoRoot)` → `test -f scripts/run-skill-verify.sh` succeeds in the consumer dir, `specs/bugs/` exists; with a pre-existing non-managed `scripts/` → throws "Refusing to replace"; with cwd === repoRoot → no-op (repo already has real scripts/).

**Contributing factors**: (1) the dogfood flow (cwd == repo) masked the gap since inception; (2) pi's manifest couldn't express the need; (3) the removed postinstall left no other provisioning hook.

**Prior art**: BUG-2026-08-07-gemini-hooks-missing-npm-package (package consumers missing files the installer assumes); BUG-2026-06-24T045323 (postinstall removal — why a lifecycle-script fix is off the table).

**Risk level**: High — every package consumer's verify gates fail; agents workaround with unvetted hand-vendored scripts.

## TDD Fix Plan

1. **RED**: Extend `scripts/test-install-helpers.js`: `initProject(repoRoot)` in a fake consumer cwd (a) creates `scripts` symlink → `scripts/run-skill-verify.sh` resolvable, (b) scaffolds `specs/bugs/` + `specs/verifications/`, (c) **throws** when `scripts/` exists non-managed (regular file/dir), (d) `initProjectRemove()` removes only the managed symlink + empty scaffolds, (e) no-ops when cwd === repoRoot.
   **GREEN**: implement `initProject`/`initProjectRemove` in `scripts/lib/install-helpers.js` (reuse `linkDir` + `assertReplaceable`), `bin/init.js` + `bigpowers init [--remove]` dispatch, README "pi Support" documents `npx bigpowers init`.
   **verify**: `bash scripts/test-install-helpers.sh` ALL PASS; manual sandbox repro above.

2. **RED** (follow-up from PR #114 review): symlink-target managed-check uses prefix `startsWith(REPO_ROOT)` without a separator — sibling path `/x/bigpowers-evil` passes as managed. Test: foreign symlink to `<REPO_ROOT>-evil/x.sh` must be **refused**.
   **GREEN**: `target === REPO_ROOT || target.startsWith(REPO_ROOT + path.sep)` in `assertReplaceable`.
   **verify**: suite green, boundary case PASS.

## Acceptance Criteria

- [ ] `bigpowers init` in a consumer project makes `bash scripts/run-skill-verify.sh` (and `test -d specs/bugs`) succeed
- [ ] Refuses — never clobbers — a pre-existing non-managed `scripts/`
- [ ] No-op inside the bigpowers repo itself; `--remove` cleans managed artifacts
- [ ] README pi section documents the provisioning step; issue #116 answered
- [ ] Existing gates green: `test-install-helpers.sh`, `run-skill-verify.sh`, `run-verification-gates.sh`, `npm run compliance`, `sync-skills.sh` clean diff
- [ ] Regression checks wired for both init behavior and the prefix-boundary fix

## Resolution

**Pending** — fix lands via PR `fix/pi-scripts-provisioning` (Closes #116).
