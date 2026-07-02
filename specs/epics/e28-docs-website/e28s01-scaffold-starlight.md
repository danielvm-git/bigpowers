# Story e28s01: Scaffold Astro Starlight site in website/ with local dev

**type:** feat
**context:** infra
**bcps:** 3

## Context

Create a new Astro Starlight documentation site in `website/` within the bigpowers
monorepo. The site is a generated artifact target — no content is hand-written in
website/src/content/. All pages are produced by the prebuild script (e28s02) from
existing repo sources: README.md, skills/*/SKILL.md, docs/, specs/adr/.

Starlight is chosen because it's the official Astro docs framework, supports MDX
out of the box, and has built-in SEO, search, and sidebar navigation.

## Steps

1. Scaffold Astro Starlight project in `website/` via `npm create astro@latest`
   with the starlight template (`--template starlight`), TypeScript: no, deps: yes,
   git: no (already in git repo).
   → verify: `test -f website/astro.config.mjs && test -f website/package.json`

2. Configure `astro.config.mjs`: set `title: "bigpowers"`, `description` from
   README lede, GitHub edit link to main branch, and disable the Starlight default
   sidebar in favor of auto-generated sidebar from the prebuild (e28s02).
   → verify: `grep -q 'title: .bigpowers.' website/astro.config.mjs && grep -q 'github' website/astro.config.mjs`

3. Strip the Starlight starter content: remove `website/src/content/docs/` default
   pages (guides/, reference/) and replace `website/src/content/docs/index.mdx` with
   a minimal placeholder that the prebuild will overwrite.
   → verify: `test ! -f website/src/content/docs/guides/example.md && test -f website/src/content/docs/index.mdx`

4. Add npm workspace scripts to root `package.json`: `"site:dev": "cd website && npm run dev"`,
   `"site:build": "cd website && npm run build"`, `"site:preview": "cd website && npm run preview"`.
   → verify: `grep -q 'site:dev' package.json && grep -q 'site:build' package.json`

5. Add `website/` to `.npmignore` so the site and its node_modules are excluded
   from the published npm package.
   → verify: `grep -q '^website' .npmignore`

6. Install and verify local dev server starts without errors.
   → verify: `cd website && timeout 5 npm run dev 2>&1 | grep -q 'localhost' || true; cd website && npm run build 2>&1 | grep -v 'error'`

## Verification Script

1. Run `npm run site:dev` — confirm the Starlight dev server starts on localhost:4321
2. Run `npm run site:build` — confirm zero build errors
3. Run `npm run site:preview` — confirm the preview server serves the built site
4. Check `.npmignore` contains `website/`

## Out of scope

- Generating any site content (that's e28s02)
- SEO configuration (that's e28s03)
- Deploy workflow (that's e28s04)
- Custom Starlight theme/components (can be added later)

## Risks

- Starlight major version changes between now and deployment could break config;
  pin the version in `website/package.json`.
- `npm create astro` is interactive; may need `--` flags or a non-interactive mode.
