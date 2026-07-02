# Story e28s05: Doctrine wiring — site content is generated, never edited

**type:** feat
**context:** docs
**bcps:** 1

## Context

The docs website is a generated artifact — pages under `website/src/content/docs/`
are produced by the prebuild script and MUST NOT be hand-edited. The Claude Code
and agent conventions must encode this prohibition so agents never attempt to
edit generated files directly.

Additionally, the README must link to the published site so visitors can discover
the interactive docs experience.

## Steps

1. Update `CLAUDE.md` **Never** section: add an entry forbidding direct edits
   to `website/src/content/docs/*` — agents must edit the source files
   (README.md, */SKILL.md, docs/, specs/adr/) and run the prebuild.
   Document the website as the fourth generated artifact target alongside
   `.cursor/`, `.gemini/`, `.pi/`.
   → verify: `grep -qi 'website' CLAUDE.md`

2. Update `CONVENTIONS.md`: add a section under "Agent Workflow Mandates"
   documenting the generated artifact targets and the rule that site content
   is never hand-edited. Reference the prebuild script.
   → verify: `grep -qi 'website' CONVENTIONS.md`

3. Update `README.md`: add a prominent link to the published site
   (`https://danielvm-git.github.io/bigpowers/`) near the top of the README
   (e.g., after the badges). The link text should be descriptive:
   "📖 [Browse the full documentation site](https://danielvm-git.github.io/bigpowers/)".
   → verify: `grep -q 'danielvm-git.github.io/bigpowers' README.md`

4. Add `website/src/content/` to `.gitignore` so generated site content is
   never committed. The prebuild runs during CI and local dev; generated
   files live only in the build output (`website/dist/`). Keep the `website/`
   entry in `.npmignore` from e28s01.
   → verify: `grep -q 'website/src/content' .gitignore`

5. Run `bash scripts/sync-skills.sh` to regenerate agent artifacts if any
   changes to SKILL.md were made during this story (none expected, but
   verify no drift).
   → verify: `bash scripts/sync-skills.sh && git diff --exit-code`

## Verification Script

1. Read `CLAUDE.md` — confirm the Never section lists website generated content
2. Read `CONVENTIONS.md` — confirm generated artifact targets are documented
3. Read `README.md` — confirm link to docs site is present and clickable
4. Check `.gitignore` — confirm `website/src/content/` is listed
5. Run `npm run site:build` — confirm prebuild regenerates all content without
   relying on committed generated files

## Out of scope

- Adding website-related skills (the prebuild is a script, not a bigpowers skill)
- CI enforcement that generated content matches sources (nice-to-have, not launch)
- Agent prompts that automatically regenerate the site on content changes

## Risks

- If `.gitignore` excludes `website/src/content/` too broadly, manual overrides
  or emergency hotfix pages become impossible — document the escape hatch
  (commit a specific file with `git add -f`)
- The site link in README goes to a 404 until e28s04 deploys — add the link
  after e28s04 is verified working
