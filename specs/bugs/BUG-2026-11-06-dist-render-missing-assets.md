---
bug_id: BUG-2026-11-06-dist-render-missing-assets
status: fixed
severity: high
scope: "distribution"
title: "Rendered .pi/skills and .agents/skills ship 0 of 92 bundled assets (#218)"
issue: https://github.com/danielvm-git/bigpowers/issues/218
files_changed: "scripts/lib/sync-render.sh, scripts/lib/sync-post.sh, .pi/skills, .agents/skills, tests/"
approach: "Mirror sibling files and nested dirs into rendered skill dirs; assert payload parity and link resolution"
risk_level: medium
commit_message: "fix(dist): copy bundled skill assets into rendered targets (#218)"
fix_evidence: "PR #223 — .pi/skills ships 92 assets; render-assets gate"
---

# BUG-2026-11-06-dist-render-missing-assets: Rendered .pi/skills and .agents/skills ship 0 of 92 bundled assets (#218)

## Problem

render_pi_skill writes only SKILL.md, so the pi package channel ships 38 skills whose instructions reference sibling files (deepen-architecture/LANGUAGE.md, audit-code/HEURISTICS.md, extract-design/scripts/extract.js, align-grid/scripts/*) that are absent. Symlink installs ship them, so the same skill behaves differently per channel. 92 sibling files exist in skills/, 0 in the rendered trees.

## Acceptance criteria

- The behaviour described above no longer reproduces on a fresh install.
- A regression test fails before the fix and passes after it.

## Verify

- `npm run compliance && bash scripts/run-verification-gates.sh`
- Issue-specific commands are listed on https://github.com/danielvm-git/bigpowers/issues/218.
