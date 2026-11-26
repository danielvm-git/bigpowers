---
bug_id: BUG-2026-11-06-mcp-directtools-wrong-file
status: fixed
severity: medium
scope: "mcp / docs"
title: "directTools in pi's mcp.json is ignored by pi-mcp-adapter (#211)"
issue: https://github.com/danielvm-git/bigpowers/issues/211
files_changed: "docs/references/bigpowers-mcp.md, README.md, bin/setup.js"
approach: "Document mcp-adapter.json as the owner of adapter keys; write adapter keys there only"
risk_level: medium
commit_message: "docs(mcp): document mcp-adapter.json ownership of adapter keys (#211)"
fix_evidence: "PR #227 — documented mcp-adapter.json ownership"
---

# BUG-2026-11-06-mcp-directtools-wrong-file: directTools in pi's mcp.json is ignored by pi-mcp-adapter (#211)

## Problem

pi-mcp-adapter reads ~/.pi/agent/mcp.json for servers but strips keys pi's schema does not define (config.ts:1345-1382), reporting 'Ignored settings'. directTools belongs in ~/.pi/agent/mcp-adapter.json. bigpowers documents neither file.

## Acceptance criteria

- The behaviour described above no longer reproduces on a fresh install.
- A regression test fails before the fix and passes after it.

## Verify

- `npm run compliance && bash scripts/run-verification-gates.sh`
- Issue-specific commands are listed on https://github.com/danielvm-git/bigpowers/issues/211.
