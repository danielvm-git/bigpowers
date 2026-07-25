---
bug_id: BUG-2026-07-24-installer-runs-dev-maintenance-pipeline
status: fixed
severity: medium
scope: install
title: "bigpowers setup runs the full contributor dev-maintenance pipeline on end-user installs"
discovered: manual audit (user-reported, reproduced against a real npm tarball)
created: 2026-07-24
---

## Summary

**Actual:** `bin/setup.js` calls `bash scripts/sync-skills.sh` unconditionally
(`runInherited('bash scripts/sync-skills.sh')`, line ~255) with `cwd` set to the
package's own install directory. `sync-skills.sh` is the same script
`CONVENTIONS.md` tells bigpowers *contributors* to run after editing a
`SKILL.md` source — it does two unrelated things in one script:

1. **Skill distribution** — render skills into `.cursor/rules/`,
   `.gemini/extensions/`, `.pi/skills/`, etc. This is the only thing an end
   user wants from `bigpowers setup`.
2. **Internal dev-repo maintenance** (`scripts/lib/sync-post.sh` →
   `sync_post_run`) — regenerate `skills-lock.json`, `SKILL-INDEX.md`,
   `specs/SKILL-SEARCH-INDEX_LATEST.md`, edit `README.md`'s badge, regenerate
   `docs/references/model-profiles.md`, and regenerate
   `specs/epics-wiki/` + `specs/adr-wiki/` — bigpowers' own internal OKF
   documentation about its own epics/ADRs. None of this is relevant to an end
   user's project.

**Expected:** `bigpowers setup` should only distribute skills into the
selected tool directories. It should never regenerate bigpowers' own internal
lockfile/index/wiki artifacts inside the installed package directory.

## Reproduce

```bash
command npm pack --pack-destination /tmp/bp-sim
cd /tmp/bp-sim && tar -xzf bigpowers-*.tgz && mv package bigpowers-installed
cd bigpowers-installed
test -d specs && echo "unexpected: specs/ shipped" || echo "specs/ absent (expected — .npmignore excludes it)"
bash scripts/sync-skills.sh
# → creates specs/ from scratch, "generate-epics-wiki: 0 concept bundles",
#   "generate-adr-wiki: no ADR directory", regenerates skills-lock.json /
#   SKILL-INDEX.md inside the installed package dir. Exit 0 (no crash), but
#   entirely wasted work + directory clutter for every real end user.
```

**Root Cause Analysis:**

`bin/setup.js`'s `ROOT = path.resolve(path.dirname(__filename), '..')` always
resolves to the package's own install location — for `npm install -g
bigpowers`, that's the global node_modules package directory, not the end
user's project. `runInherited('bash scripts/sync-skills.sh')` runs the full
script with `cwd: ROOT`, so `sync-skills.sh`'s post-sync step
(`sync_post_run` in `scripts/lib/sync-post.sh`) always fires:

- `regenerate-lockfile.sh`, `generate-skill-index.sh`, `build-skill-index.sh`
  — redundant: these files are already correct in the shipped tarball.
- README.md badge `sed` edit — edits the package's own bundled README.
- `generate-reference-tables.sh` — guarded by `[[ -d "$REPO_ROOT/.git" ]]`,
  so it correctly no-ops for a real install (no `.git` shipped). This is the
  *only* existing guard, and it doesn't cover the OKF-wiki calls at all.
- `generate-epics-wiki.sh` / `generate-adr-wiki.sh` — **unconditional, no
  guard**. Degrades gracefully (`specs/` doesn't exist, so the glob finds
  nothing and each script no-ops to "0 concept bundles" / "no ADR
  directory"), but still creates a fresh `specs/` tree inside the installed
  package directory purely as a side effect.

No hard crash was reproduced (confirmed via direct execution against the
real packed tarball), but this write-into-the-install-directory pattern is a
latent reliability risk: on any system where the npm global prefix isn't
user-writable (common on system-managed Node installs requiring `sudo npm
install -g`), these writes would fail with `EACCES`, and `execSync(...,
{stdio:'inherit'})` in `bin/setup.js` throws on non-zero exit — crashing the
whole `bigpowers setup`/`bigpowers update` command even though the actual
useful step (symlinking skills into `~/.claude`, `~/.cursor`, etc. — user-
writable home paths) already ran moments earlier in the same script.

## TDD Fix Plan

1. **RED**: Running `bash scripts/sync-skills.sh --distribute-only` from a
   simulated end-user install directory (no `specs/`, no `.git`) currently
   has no such flag — `sync-skills.sh: unrecognized option` or falls through
   to full behavior.
   **GREEN**: Add a `--distribute-only` flag to `scripts/sync-skills.sh` that
   skips the call to `sync_post_run` (and therefore lockfile/index/README/
   reference-table/OKF-wiki regeneration) while still performing skill
   rendering into target tool directories.
   **verify**: `bash scripts/sync-skills.sh --distribute-only` in a directory
   with no `specs/` exits 0, writes `.cursor/rules/*.mdc` etc., and does NOT
   create `specs/epics-wiki/`, `skills-lock.json`, or `SKILL-INDEX.md`.

2. **RED**: `bin/setup.js` still calls the full pipeline (no flag passed).
   **GREEN**: Change `runInherited('bash scripts/sync-skills.sh')` to
   `runInherited('bash scripts/sync-skills.sh --distribute-only')`.
   **verify**: re-run the reproduction above; `bigpowers setup` output no
   longer prints "Generating OKF wikis..." nor "regenerate-lockfile"/
   "generate-skill-index" lines against a simulated end-user install.

3. **RED**: No regression test guards this behavior going forward.
   **GREEN**: Add `scripts/test-install-distribute-only.sh` (or extend an
   existing install test) asserting that a `--distribute-only` sync run
   against a `specs/`-less fixture directory produces skill artifacts but no
   `specs/epics-wiki/`, `skills-lock.json`, or `SKILL-INDEX.md`.
   **verify**: `bash scripts/test-install-distribute-only.sh` passes.

**REFACTOR**: None planned — this is additive (a new flag), not a behavior
change for the existing contributor dev workflow (`bash scripts/sync-skills.sh`
with no flag keeps doing exactly what it does today).

## Acceptance Criteria

- [ ] `bash scripts/sync-skills.sh --distribute-only` skips lockfile/index/
      README/reference-table/OKF-wiki regeneration
- [ ] `bin/setup.js` invokes sync-skills.sh with `--distribute-only`
- [ ] Existing contributor workflow (`bash scripts/sync-skills.sh`, no flag)
      is unchanged — full compliance suite still passes
- [ ] Regression test added and passing
- [ ] `npm run compliance && bash scripts/run-verification-gates.sh` green
