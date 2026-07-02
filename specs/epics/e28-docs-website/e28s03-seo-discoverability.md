# Story e28s03: SEO + AI discoverability layer

**type:** feat
**context:** infra
**bcps:** 2

## Context

The docs site must be discoverable by search engines (Google, Bing) and AI
agents (Claude, ChatGPT, Gemini). Starlight ships with built-in SEO support;
this story configures it and adds AI-specific discoverability artifacts.

Required outputs in the built site:
- `sitemap-index.xml` / `sitemap-0.xml` — standard sitemap
- Canonical URLs on every page pointing to the GitHub Pages domain
- Per-page `<meta>` and Open Graph descriptions sourced from SKILL.md frontmatter
- `llms.txt` — a single-page summary of the site's content for LLM context windows

## Steps

1. Install and configure `@astrojs/sitemap` integration in `astro.config.mjs`.
   Set `site` to `https://danielvm-git.github.io/bigpowers` (the GitHub Pages URL).
   This also sets canonical URLs automatically.
   → verify: `grep -q '@astrojs/sitemap' website/astro.config.mjs && grep -q "site:" website/astro.config.mjs`

2. Configure Starlight's built-in SEO: enable `head` in `astro.config.mjs` to
   inject per-page `<meta name="description">` and Open Graph tags from the
   `description` frontmatter field (already set by the prebuild in e28s02).
   → verify: `grep -q 'head:' website/astro.config.mjs`

3. Add `llms.txt` generation to the prebuild script: read all generated pages'
   titles and URLs from the Starlight sidebar config or content collection,
   produce a `website/public/llms.txt` (or generate during prebuild to
   `website/src/content/docs/llms.txt` for Starlight to pick up).
   Format follows the llms.txt convention: `# bigpowers\n\n## Skills\n- [name](url): description\n...`.
   → verify: `test -f website/src/content/docs/llms.txt || test -f website/public/llms.txt`

4. Add `robots.txt` (Starlight generates this from the `site` config; verify
   it's present and not disallowing anything).
   → verify: `cd website && npm run build && test -f dist/robots.txt`

5. Configure favicon: copy or symlink a bigpowers icon to `website/public/favicon.svg`
   or `website/public/favicon.ico`. Use a text-based SVG favicon if no graphic
   icon exists (e.g., "bp" monogram).
   → verify: `test -f website/public/favicon.svg || test -f website/public/favicon.ico`

6. Full build verification: confirm sitemap, canonical URLs, Open Graph tags,
   and llms.txt are present in the build output.
   → verify: `test -f website/dist/sitemap-index.xml && test -f website/dist/llms.txt && grep -q 'og:title' website/dist/index.html`

## Verification Script

1. Run `npm run site:build` — zero errors
2. Check `website/dist/sitemap-index.xml` — contains URLs for all pages
3. Check `website/dist/llms.txt` — contains skills listing with descriptions
4. Check `website/dist/index.html` — contains `<meta property="og:title">`
5. Run `npm run site:preview` — visit a skill page, view source, confirm
   `<meta name="description">` is populated from the skill's frontmatter

## Out of scope

- Google Analytics / Plausible / tracking scripts
- Structured data / JSON-LD (nice-to-have, not essential for launch)
- Social card images (og:image) beyond a default
- Pagefind search configuration (Starlight default is adequate)

## Risks

- `@astrojs/sitemap` may require `site` to be set before build; if GitHub Pages
  custom domain is used later, update the `site` URL
- `llms.txt` is an emerging convention (2024+); format may drift — pin to the
  spec at `https://llmstxt.org/`
