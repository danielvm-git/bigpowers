---
bug_id: BUG-2026-11-06-mcp-json-project-server-blocked
status: fixed
severity: medium
scope: "mcp / pi"
title: "Tracked .mcp.json declares a project server pi blocks on every start (#210)"
issue: https://github.com/danielvm-git/bigpowers/issues/210
files_changed: ".mcp.json, bin/setup.js, scripts/validate-mcp-package.sh, docs/references/bigpowers-mcp.md"
approach: "Generate .mcp.json at install time for OMP only; document the approval path; keep package smoke test"
risk_level: medium
commit_message: "fix(mcp): stop shipping a blocked project server in clones (#210)"
fix_evidence: "PR #227 — documented approval + adapter key ownership"
---

# BUG-2026-11-06-mcp-json-project-server-blocked: Tracked .mcp.json declares a project server pi blocks on every start (#210)

## Problem

.mcp.json is tracked and declares bigpowers-mcp with a ${OMP_PLUGIN_ROOT:-.} fallback that only makes sense for OMP plugin installs. The adapter treats project servers as untrusted by default (project-server-trust.ts:44) and approval is keyed per project root, so every clone and worktree adds a permanent 'Project servers blocked' warning that cannot be cleared once.

## Acceptance criteria

- The behaviour described above no longer reproduces on a fresh install.
- A regression test fails before the fix and passes after it.

## Verify

- `npm run compliance && bash scripts/run-verification-gates.sh`
- Issue-specific commands are listed on https://github.com/danielvm-git/bigpowers/issues/210.
