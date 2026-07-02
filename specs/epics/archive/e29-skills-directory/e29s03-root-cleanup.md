# Story e29s03: Root cleanup and doctrine update

**type:** docs
**context:** infra
**bcps:** 1

## Context

With skills under `skills/`, finish the landing-page goal: move the two
non-tool-read root markdown files into `docs/`, and update the doctrine files
so agents and contributors learn the new layout. CLAUDE.md, GEMINI.md,
CONVENTIONS.md, README.md, LICENSE, CHANGELOG.md, CONTRIBUTING.md stay at root
(tool-read or GitHub-surfaced). README edits are additive only — its canonical
structure is preserved (see memory: readme-must-stay-complete).

## Steps

1. `git mv COMMIT-MESSAGE.md docs/ && git mv RELEASE.md docs/`, then fix any
   inbound references (`grep -rn 'COMMIT-MESSAGE.md\|RELEASE.md' --exclude-dir={.git,node_modules,.cursor,.gemini,.pi}`).
   → verify: `test -f docs/COMMIT-MESSAGE.md && test -f docs/RELEASE.md && ! test -f COMMIT-MESSAGE.md && ! test -f RELEASE.md && echo OK`

2. Update CLAUDE.md Architecture/Conventions sections and CONVENTIONS.md to
   state that skill sources live in `skills/<verb-noun>/SKILL.md`; update the
   "Never" rules if they reference root skill paths.
   → verify: `grep -q 'skills/' CLAUDE.md && grep -q 'skills/' CONVENTIONS.md && echo OK`

3. Update README.md and CONTRIBUTING.md path references to skill sources
   (additive edits; no structural changes to README).
   → verify: `! grep -n '](\./[a-z-]*/SKILL.md' README.md CONTRIBUTING.md && echo OK`

4. Confirm the landing-page target: root entry count at or below 25.
   → verify: `test $(ls -1 | wc -l) -le 25 && echo OK`

## Verification Script

1. Open the repo on GitHub — README content starts within one screen of the folder list
2. Skim CLAUDE.md and CONVENTIONS.md — layout description matches reality
3. Run `npm run compliance` — score unchanged

## Out of scope

- Moving CLAUDE.md, GEMINI.md, CONVENTIONS.md, CONTRIBUTING.md, LICENSE,
  CHANGELOG.md, opencode.json, index.js, playwright.config.ts
- README restructuring of any kind

## Risks

- semantic-release or CI may reference RELEASE.md by path — the step-1 grep
  sweep catches this before the move lands.
