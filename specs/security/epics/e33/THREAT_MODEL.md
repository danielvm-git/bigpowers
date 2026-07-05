# Threat Model — e33: Docs Website

**Date:** 2026-07-05
**Risk Level:** LOW
**Risk Score:** 2/10

## Surface Area

| Asset | Exposure | Sensitivity |
|-------|----------|-------------|
| website/dist/ | Public via GitHub Pages | Public docs only |
| website/scripts/prebuild.mjs | Build-time only (CI) | Source code |
| .github/workflows/docs-site.yml | GitHub Actions | CI config |
| SKILL-INDEX.md (read by prebuild) | Repo-accessible | Public docs source |

## Vulnerability Categories

| Category | Finding | Risk |
|----------|---------|------|
| **Supply chain** | `npm ci` pulls Starlight/Astro deps from npm | LOW — pinned versions in package-lock.json |
| **Injection** | prebuild.mjs reads repo .md files and writes MDX; frontmatter is escaped | LOW — `escapeYaml()` wraps in JSON.stringify |
| **Secrets exposure** | No secrets in generated site content | NONE — public docs only |
| **CI compromise** | GitHub Actions with `pages: write` + OIDC token | LOW — restricted to `main` branch; path-filtered trigger |
| **Dependency freshness** | Actions use v4 (checkout, setup-node, upload-pages-artifact, deploy-pages) | LOW — per project convention |
| **Data integrity** | Prebuild reads repo sources; if sources are corrupted, site shows bad data | LOW — source of truth is the git repo |

## Mitigation Guidance

1. **Do NOT** add any private keys, tokens, or secrets to website/ content or prebuild output
2. **Do NOT** allow user-submitted content into the prebuild pipeline
3. **Pin** Astro/Starlight versions in website/package.json (already done)
4. **Keep** prebuild deterministic — no external API calls during build
5. **Review** any new prebuild data sources for sensitive content before wiring

## Verdict

CLEAR. The docs website is a read-only public artifact with zero user input and no secrets. The primary risk is stale/drifting content, not security compromise.
