# Story e29s02: Relocate skill sources to skills/ and re-point CI

**type:** refactor
**context:** infra
**bcps:** 3

## Context

With every consumer script location-agnostic (e29s01), move all skill source
directories from the repo root into `skills/` in one mechanical commit and
re-point the CI trigger paths. This is the atomic core: the npm `postinstall`
hook runs `sync-skills.sh && install.sh`, so the move and the already-shipped
script logic must be in the same published version — e29s01 guarantees that by
landing the logic first in a form that works with both layouts.

History is preserved via `git mv` (git tracks renames; `git log --follow`
works per file).

## Steps

1. Move every root directory containing a SKILL.md:
   `mkdir skills && for d in */; do [ -f "$d/SKILL.md" ] && git mv "${d%/}" "skills/${d%/}"; done`
   → verify: `! ls ./*/SKILL.md 2>/dev/null && test $(find skills -maxdepth 2 -name SKILL.md | wc -l) -eq $(python3 -c "import json;print(len(json.load(open('skills-lock.json'))['skills']))") && echo OK`

2. Update `.github/workflows/sync-skills.yml`: change SKILL.md path triggers
   (e.g. `*/SKILL.md` / `**/SKILL.md`) to `skills/**/SKILL.md` and any
   drift-gate steps that reference root skill paths.
   → verify: `python3 -c "import yaml; yaml.safe_load(open('.github/workflows/sync-skills.yml'))" && grep -q 'skills/' .github/workflows/sync-skills.yml && echo OK`

3. Update the e28 capsule (`specs/epics/e28-docs-website/epic.yaml` and any
   e28 story specs) — replace `*/SKILL.md` glob references with
   `skills/*/SKILL.md` so the docs-site generator is specified against the
   new layout. e28 is still `todo`; this edits intent, not history.
   → verify: `! grep -rn '\.\./\*/SKILL.md\|[^/]\*/SKILL.md' specs/epics/e28-docs-website/ && echo OK`

4. Regenerate everything from the new layout and prove idempotence: run
   `sync-skills.sh` twice, regenerate SKILL-INDEX.md and skills-lock.json;
   second run must produce zero diff, skill count unchanged.
   → verify: `bash scripts/sync-skills.sh && bash scripts/sync-skills.sh && git diff --quiet .cursor .gemini .pi SKILL-INDEX.md skills-lock.json && echo OK`

5. Reinstall the global symlinks (they point at the old root paths and are
   now dangling) and confirm the installed set matches the lockfile.
   → verify: `bash scripts/install.sh >/dev/null && test $(ls ~/.claude/skills | wc -l) -ge $(python3 -c "import json;print(len(json.load(open('skills-lock.json'))['skills']))") && echo OK`

6. Sweep for stragglers: grep the whole repo (excluding generated dirs,
   node_modules, specs/archive) for root-relative skill path references.
   → verify: `! grep -rn --exclude-dir={.git,node_modules,.cursor,.gemini,.pi,archive} '"\./[a-z-]*/SKILL.md"\|(\./\*/SKILL' scripts/ bin/ dashboard/ .github/ && echo OK`

## Verification Script

1. Open https://github.com/danielvm-git/bigpowers on the feature branch — root shows ~20 entries, README visible without scrolling past skill folders
2. Run `git log --follow skills/develop-tdd/SKILL.md` — history predates the move
3. Run `bash scripts/sync-skills.sh` — same skill count as before the epic, 0 FAIL
4. In a Claude Code session, confirm a symlinked skill (e.g. survey-context) still loads from ~/.claude/skills
5. Run `npm run compliance` — score unchanged

## Out of scope

- Root markdown cleanup and doctrine text (e29s03)
- Any skill rename or content change
- e28 implementation (only its spec globs are touched)

## Risks

- Published-package skew: if a release ships between e29s01 and e29s02, npm
  postinstall still works because e29s01 logic supports both layouts. Do NOT
  split e29s02 itself across releases.
- Dangling ~/.claude/skills symlinks between step 1 and step 5 on the dev
  machine — reinstall immediately after the move (step 5) in the same session.
- Open PRs/branches touching skill files will conflict with the rename —
  land or rebase them before merging this story.
