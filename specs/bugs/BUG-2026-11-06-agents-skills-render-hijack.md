---
bug_id: BUG-2026-11-06-agents-skills-render-hijack
status: open
severity: medium
scope: "distribution / pi"
title: "Antigravity render target .agents/skills is auto-discovered by pi (#209)"
issue: https://github.com/danielvm-git/bigpowers/issues/209
files_changed: "scripts/lib/install-targets-b.sh, bin/setup.js, .gitignore, scripts/sync-skills.sh"
approach: "Render Antigravity skills outside host discovery roots; assert no render target is a discovery root"
risk_level: medium
commit_message: "fix(dist): move the Antigravity render target out of pi discovery (#209)"
---

# BUG-2026-11-06-agents-skills-render-hijack: Antigravity render target .agents/skills is auto-discovered by pi (#209)

## Problem

install-targets-b.sh:90 renders to $REPO_ROOT/.agents/skills, which pi treats as a project Agent Skills root (package-manager.ts:2644). It ranks project scope, so inside a checkout the generated copy outranks the maintained source and the package copy. Repo .gitignore does not help: pi reads ignore files inside the skill root only.

## Acceptance criteria

- The behaviour described above no longer reproduces on a fresh install.
- A regression test fails before the fix and passes after it.

## Verify

- `npm run compliance && bash scripts/run-verification-gates.sh`
- Issue-specific commands are listed on https://github.com/danielvm-git/bigpowers/issues/209.
