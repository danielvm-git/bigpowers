# Story e33s02: Source-mapping prebuild — pages generated from repo sources

**type:** feat
**context:** infra
**bcps:** 5

## Context

The site is a generated artifact — no content in `website/src/content/` is
hand-written. A prebuild script reads the bigpowers repo sources and produces
Astro-compatible .md/.mdx files organized into Starlight content collections.

Sources → pages mapping:
- `README.md` → Getting Started landing page
- `skills/*/SKILL.md` (72 files) → one page per skill, grouped by lifecycle phase
- `docs/*.md` → Guides section (excluding images/ and archive/)
- `specs/adr/*.md` → Architecture Decisions section
- `SKILL-INDEX.md` → Skill Index reference page (auto-generated, already exists)

## Steps

1. Create `website/scripts/prebuild.mjs` — the entry point that orchestrates
   all page generation. It clears `website/src/content/docs/` (preserving
   `index.mdx` placeholder) then calls sub-generators for each source.
   → verify: `test -f website/scripts/prebuild.mjs && node -c website/scripts/prebuild.mjs`

2. Implement README → landing page generator: read `README.md`, strip the
   top-level `# bigpowers` heading (Starlight provides its own hero), convert
   relative image paths to Starlight asset paths, write to
   `website/src/content/docs/index.mdx` with Starlight frontmatter (`title`,
   `description`).
   → verify: `node website/scripts/prebuild.mjs && grep -q 'title:' website/src/content/docs/index.mdx`

3. Implement skills page generator: iterate `../skills/*/SKILL.md`, parse frontmatter
   (`name`, `description`, `phase` from docs/references/model-profiles.md or
   inferred from skill directory), strip the YAML frontmatter block, write each
   skill body to `website/src/content/docs/skills/<name>.mdx` with Starlight
   frontmatter. The skill count must equal `ls -d ../skills/*/SKILL.md | wc -l` — no
   hardcoding.
   → verify: `test $(ls website/src/content/docs/skills/*.mdx | wc -l) -eq $(ls -d skills/*/SKILL.md | wc -l)`

4. Implement Starlight sidebar auto-generation: produce a
   `website/src/content/docs/skills/index.mdx` page that groups skills by
   lifecycle phase (Discover, Elaborate, Plan, Build, Verify, Release, Sustain)
   inferred from `docs/references/model-profiles.md`. Each phase becomes a
   collapsible sidebar group in `astro.config.mjs` sidebar config.
   → verify: `grep -q 'Discover' website/src/content/docs/skills/index.mdx && grep -q 'Build' website/src/content/docs/skills/index.mdx`

5. Implement docs/ → guides generator: copy `docs/*.md` (excluding images/,
   archive/) to `website/src/content/docs/guides/`, preserving directory
   structure. Add Starlight frontmatter with `title` inferred from the first
   `#` heading.
   → verify: `test -f website/src/content/docs/guides/PRINCIPLES.md`

6. Implement specs/adr/ → decisions generator: copy `specs/adr/*.md` to
   `website/src/content/docs/decisions/`, add frontmatter with ADR number as
   title, sort by ADR number descending (newest first in sidebar).
   → verify: `test -f website/src/content/docs/decisions/0001-verb-noun-naming.md`

7. Wire prebuild into `npm run site:build`: update root `package.json` so
   `site:build` runs prebuild before Astro build. Prebuild must exit non-zero
   on any generation failure.
   → verify: `grep -q 'prebuild' package.json && npm run site:build 2>&1 | grep -v 'error'`

8. Run full build and verify skill count assertion passes.
   → verify: `cd website && npm run prebuild && test $(ls src/content/docs/skills | wc -l) -eq $(ls -d ../skills/*/SKILL.md | wc -l)`

## Verification Script

1. Run `npm run site:build` — confirm zero errors
2. Inspect `website/src/content/docs/skills/` — confirm 72 skill pages
3. Inspect `website/src/content/docs/skills/index.mdx` — confirm skills grouped
   by lifecycle phase
4. Inspect `website/src/content/docs/guides/` — confirm docs/ content present
5. Inspect `website/src/content/docs/decisions/` — confirm ADRs present
6. Open `http://localhost:4321` — confirm all sections, sidebar navigation,
   and landing page render correctly

## Out of scope

- Custom Starlight components (use Starlight defaults)
- Search (Starlight Pagefind is built-in; enable in e33s03 if needed)
- Internationalization
- Dark/light theme customization beyond Starlight defaults

## Risks

- SKILL.md files with invalid YAML frontmatter break the prebuild; add graceful
  error messages with skill name
- `model-profiles.md` phase mapping must be kept in sync with skill frontmatter;
  prebuild should warn on skills not found in the mapping
- Large number of skill pages (72) may slow sidebar rendering; Starlight
  handles this natively with collapsible groups
