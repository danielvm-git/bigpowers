---
bug_id: BUG-2026-09-13-docs-browse-skills-base-path
status: fixed
severity: medium
scope: website / docs
title: "Browse skills hero button 404s — generated links missing /bigpowers base (#127)"
issue: https://github.com/danielvm-git/bigpowers/issues/127
files_changed: "website/scripts/prebuild.mjs, website/src/content/docs/index.mdx, website/src/content/docs/skills/index.mdx, website/public/llms.txt, scripts/validate-docs-base-path.sh"
approach: "Prefix generated site links with SITE_BASE; fix pageUrl double-base; add docs base-path gate"
risk_level: low
commit_message: "fix(docs): prefix generated site links with base path (#127)"
---

# BUG-2026-09-13: Browse skills hero button 404s (#127)

## Problem

- **Actual:** On [GitHub Pages](https://danielvm-git.github.io/bigpowers/), the **Browse skills**
  hero button links to `https://danielvm-git.github.io/skills/` → 404.
- **Expected:** Link resolves to `https://danielvm-git.github.io/bigpowers/skills/` (200).
- **Reproduce:** `cd website && npm run build`; inspect `dist/index.html` hero `href`, or click
  the button on the deployed site.

**Security impact: NONE** — broken internal navigation only.

## Root Cause Analysis

Astro serves the docs site with `base: '/bigpowers'` (`website/astro.config.mjs`), but
`website/scripts/prebuild.mjs` emitted root-absolute paths (`/skills/`, `/guides/`, `/images/`)
without the base prefix. On GitHub Pages those resolve to the domain root, not the project
subpath.

Additionally, `pageUrl()` appended `SITE_BASE` to `SITE_URL` even though `SITE_URL` already
includes `/bigpowers`, producing `/bigpowers/bigpowers/...` in `llms.txt`.

**Prior art:** Community fix in PR #126 (same root cause analysis).

## TDD Fix Plan

1. **RED:** `scripts/validate-docs-base-path.sh` fails when hero link omits `SITE_BASE`.
   **GREEN:** Prefix generated links in `prebuild.mjs`; fix `pageUrl()`.
   **verify:** `bash scripts/validate-docs-base-path.sh`

2. **RED:** Built `dist/index.html` lacks `/bigpowers/skills/` hero href.
   **GREEN:** Regenerate content via `npm run generate`.
   **verify:** `cd website && npm run build && grep -q 'href="/bigpowers/skills/"' dist/index.html`

## Acceptance Criteria

- [x] Hero **Browse skills** link includes `/bigpowers` base prefix.
- [x] Generated body/guide/skill links include base prefix.
- [x] `llms.txt` has no `/bigpowers/bigpowers/` double prefix.
- [x] Docs base-path gate passes.
- [x] `website` build succeeds.
