# Story e28s04: GitHub Pages deploy workflow

**type:** feat
**context:** infra
**bcps:** 2

## Context

Deploy the Starlight site to GitHub Pages via the official `actions/deploy-pages`
action. The workflow triggers on pushes to `main` that touch content paths
(`skills/*/SKILL.md`, `docs/`, `specs/adr/`, `website/`, `README.md`). It must not
interfere with the existing `publish.yml` sync-skills drift gate or the
semantic-release publishing pipeline.

GitHub Pages source: "GitHub Actions" (not branch-based — no `gh-pages` branch).

## Steps

1. Enable GitHub Pages in repo settings: Source = "GitHub Actions".
   This must be done manually in the GitHub UI (Settings → Pages → Source).
   Document in the verify as a manual step that the automated check can't cover.
   → verify: manual — check Settings → Pages → Source = "GitHub Actions"

2. Create `.github/workflows/docs-site.yml`:
   - Name: "Deploy Docs Site to GitHub Pages"
   - Trigger: `push` to `main` with `paths` filter matching content sources:
     `'skills/*/SKILL.md'`, `'docs/**'`, `'specs/adr/**'`, `'website/**'`, `'README.md'`,
     `'.github/workflows/docs-site.yml'`
   - Permissions: `contents: read`, `pages: write`, `id-token: write`
   - Concurrency: `group: pages`, `cancel-in-progress: false`
   - Jobs: `build` (runs-on: ubuntu-latest) → checkout → setup node → `cd website && npm ci && npm run build` → upload artifact → `deploy` (needs: build) → `actions/deploy-pages`
   → verify: `python3 -c "import yaml; yaml.safe_load(open('.github/workflows/docs-site.yml'))"`

3. Configure `website/astro.config.mjs` with `base: '/bigpowers'` so asset
   paths resolve correctly under the GitHub Pages project-site URL
   (`https://danielvm-git.github.io/bigpowers/`).
   → verify: `grep -q "base:" website/astro.config.mjs`

4. Verify the workflow does NOT trigger on changes unrelated to content
   (e.g., changes to `scripts/`, `specs/state.yaml`, `.cursor/`).
   → verify: manual — push a non-content change and confirm docs-site workflow does not run

5. Test deploy: push a content change (e.g., update a SKILL.md heading),
   confirm the workflow runs and deploys to `https://danielvm-git.github.io/bigpowers/`.
   → verify: manual — check Actions tab for successful deploy run and visit the URL

## Verification Script

1. Check `.github/workflows/docs-site.yml` exists and parses as valid YAML
2. Push a change to any SKILL.md — confirm the workflow triggers automatically
3. Check the Actions tab — confirm `build` and `deploy` jobs both succeed
4. Visit `https://danielvm-git.github.io/bigpowers/` — confirm the site loads
5. Push a change to `scripts/sync-skills.sh` — confirm docs-site workflow does NOT trigger

## Out of scope

- Custom domain (CNAME) configuration
- Staging/preview deployments for branches
- Cache invalidation / CDN configuration
- Status badge in README

## Risks

- The `paths` filter must be carefully maintained; if new content sources are
  added (e.g., a new docs/ subdirectory), the filter must be updated
- GitHub Pages has a build/deploy time limit of ~10 minutes; the Astro build
  with 72+ skill pages should be well under this
- The `base` path must be consistent between the site config and the Pages URL;
  if a custom domain is configured later, remove the `base` setting
