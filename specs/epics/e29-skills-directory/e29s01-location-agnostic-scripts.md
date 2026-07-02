# Story e29s01: Location-agnostic skill discovery in all consumer scripts

**type:** refactor
**context:** infra
**bcps:** 3

## Context

Eight scripts discover skill sources by globbing the repo root (`$REPO_ROOT/*/`
or `*/SKILL.md`). Before any directory moves, every script must resolve skill
sources through one shared rule: **use `skills/` when it exists, else the repo
root**. This ships green with skills still at root (zero behavior change) and
makes e29s02 a pure `git mv` with no simultaneous logic edits — the atomic-ship
risk (npm postinstall runs sync-skills.sh + install.sh) is confined to one
mechanical commit.

Zoom-out: the scripts are the generation layer for all derived artifacts
(.cursor/rules, .gemini/extensions, .pi, SKILL-INDEX.md, skills-lock.json) and
the ~/.claude/skills symlink installer. Callers: npm `postinstall`/`version`
hooks, `.github/workflows/sync-skills.yml`, release-branch gates. Contracts
preserved: artifact output paths, SKILL.md frontmatter schema, symlink names,
lockfile skill count.

## Steps

1. Add a `SKILLS_ROOT` resolution block to `scripts/sync-skills.sh` (after
   `REPO_ROOT`): `SKILLS_ROOT="$REPO_ROOT"; [[ -d "$REPO_ROOT/skills" ]] && SKILLS_ROOT="$REPO_ROOT/skills"`.
   Replace both skill-enumeration globs (line 30 main loop, line ~167 opencode
   loop) and the `.mdc` allowlist check at line ~199 with `$SKILLS_ROOT`.
   → verify: `bash scripts/sync-skills.sh && git diff --quiet .cursor .gemini .pi && echo OK`

2. Apply the same resolution to `scripts/install.sh` (line 69 symlink loop).
   → verify: `grep -q 'SKILLS_ROOT' scripts/install.sh && bash -n scripts/install.sh && echo OK`

3. Apply it to `scripts/check-skill-size.sh` (line 47), `scripts/audit-catalog.sh`
   (lines 23, 36 — the `.pi/skills` loop at line 15 reads a generated path and
   stays as-is), `scripts/run-skill-verify.sh` (line 73),
   `scripts/add-model-frontmatter.sh`, `scripts/regenerate-lockfile.sh`.
   → verify: `grep -L 'SKILLS_ROOT' scripts/check-skill-size.sh scripts/audit-catalog.sh scripts/run-skill-verify.sh scripts/add-model-frontmatter.sh scripts/regenerate-lockfile.sh | wc -l | awk '{if($1==0) print "OK"; else print "FAIL"}'`

4. Update `scripts/generate-skill-index.sh`: use `SKILLS_ROOT` for enumeration
   AND fix the verify text it embeds into SKILL-INDEX.md (line 162,
   `find . -maxdepth 2 -name "SKILL.md"`) to a location-agnostic form, e.g.
   `find . skills -maxdepth 2 -name "SKILL.md" 2>/dev/null | grep -v '.cursor\|.gemini\|.pi' | sort -u`.
   → verify: `grep -q 'SKILLS_ROOT' scripts/generate-skill-index.sh && echo OK`

5. Prove zero drift with skills still at root: run the full generation chain
   twice; artifacts, index, and lockfile must be byte-identical.
   → verify: `bash scripts/sync-skills.sh && git diff --quiet .cursor .gemini .pi SKILL-INDEX.md skills-lock.json && echo OK`

## Verification Script

1. Run `bash scripts/sync-skills.sh` — skill count printed must equal the count before the change
2. Run `git status` — no modified files under .cursor/, .gemini/, .pi/, no SKILL-INDEX.md diff
3. Run `mkdir -p /tmp/probe-skills && bash -c 'cd /tmp && :'` — no-op sanity; then spot-check: `SKILLS_ROOT` logic by creating a scratch clone with skills/ and confirming enumeration switches (optional)
4. Run `npm run compliance` — score unchanged

## Out of scope

- Moving any directory (e29s02)
- Workflow/CI trigger paths (e29s02)
- Root file cleanup and doctrine text (e29s03)

## Risks

- A missed glob in a less-traveled script (add-model-frontmatter, regenerate-lockfile)
  only fails when that script next runs — step 3's grep -L check covers presence,
  and e29s02 step 4 re-runs the full chain from the new layout to catch stragglers.
- `validate-doctrine.sh` and `generate-reference-tables.sh` showed no root globs
  in exploration; re-grep during implementation to confirm (`grep -n 'SKILL.md' scripts/*.sh`).
