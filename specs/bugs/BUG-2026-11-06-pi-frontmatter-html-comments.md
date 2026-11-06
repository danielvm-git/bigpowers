---
bug_id: BUG-2026-11-06-pi-frontmatter-html-comments
status: open
severity: high
scope: "skills / pi"
title: "HTML comments inside SKILL.md frontmatter drop 10 skills in pi (#173)"
issue: https://github.com/danielvm-git/bigpowers/issues/173
files_changed: "skills/*/SKILL.md, .pi/skills, .cursor/rules, .gemini/extensions/bigpowers, website/src/content/docs, specs/skills-wiki"
approach: "Rewrite frontmatter story tags as YAML '#' comments; keep body tags in HTML form; regenerate all targets"
risk_level: medium
commit_message: "fix(skills): use YAML comments for story tags inside frontmatter (#173)"
---

# BUG-2026-11-06-pi-frontmatter-html-comments: HTML comments inside SKILL.md frontmatter drop 10 skills in pi (#173)

## Problem

pi 1.5.0 parses SKILL.md frontmatter with the `yaml` package (`uniqueKeys` default on). A line `<!-- story: e45s18 -->` is a mapping entry, not a comment: key `<!-- story`, value `e45s18 -->`. Two markers repeat the key and the whole frontmatter throws `Map keys must be unique`, so pi discards the skill. 39 of 80 sources carry the form; the 10 with 2+ markers are dropped: audit-code, craft-skill, deepen-architecture, develop-tdd, gate-trace, plan-work, request-review, run-benchmark, stocktake-skills, validate-fix. Introduced by 120a0d99 (PR #158), a regression of #108/BUG-2026-08-06. Fixed shape verified against pi's own parser: `# story: eNNsNN` inside the fence parses to the expected keys.

## Acceptance criteria

- The behaviour described above no longer reproduces on a fresh install.
- A regression test fails before the fix and passes after it.

## Verify

- `npm run compliance && bash scripts/run-verification-gates.sh`
- Issue-specific commands are listed on https://github.com/danielvm-git/bigpowers/issues/173.
