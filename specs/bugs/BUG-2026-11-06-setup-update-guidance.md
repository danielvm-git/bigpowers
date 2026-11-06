---
bug_id: BUG-2026-11-06-setup-update-guidance
status: open
severity: low
scope: "docs"
title: "No guidance for pi update --extensions in setup output (#212)"
issue: https://github.com/danielvm-git/bigpowers/issues/212
files_changed: "bin/setup.js, docs/references/agent-tooling.md, README.md"
approach: "Add the package-update step to post-install output and docs"
risk_level: medium
commit_message: "docs(setup): mention pi update --extensions after install (#212)"
---

# BUG-2026-11-06-setup-update-guidance: No guidance for pi update --extensions in setup output (#212)

## Problem

A pending pi-web-access update renders as 'Package Updates Available', which users attribute to bigpowers. Nothing in setup output or docs mentions pi update --extensions (pi docs/cli.md:276).

## Acceptance criteria

- The behaviour described above no longer reproduces on a fresh install.
- A regression test fails before the fix and passes after it.

## Verify

- `npm run compliance && bash scripts/run-verification-gates.sh`
- Issue-specific commands are listed on https://github.com/danielvm-git/bigpowers/issues/212.
