---
bug_id: BUG-2026-11-06-setup-pi-localpath
status: fixed
severity: medium
scope: "install / pi"
title: "setup.js uses .pi/agent/skills for pi's project-local path (#220)"
issue: https://github.com/danielvm-git/bigpowers/issues/220
files_changed: "bin/setup.js, scripts/test-install-helpers.js"
approach: "Correct localPath to .pi/skills; add a per-target verify probe and a path table test"
risk_level: medium
commit_message: "fix(setup): install pi skills to the project path pi scans (#220)"
fix_evidence: "PR #224 — pi project-local path .pi/skills"
---

# BUG-2026-11-06-setup-pi-localpath: setup.js uses .pi/agent/skills for pi's project-local path (#220)

## Problem

bin/setup.js:68 declares localPath '.pi/agent/skills'. pi resolves project resources from <cwd>/.pi/skills (package-manager.ts:2599); ~/.pi/agent/skills is the user-global dir. The concatenated path is scanned by no pi version, so project-local pi installs silently do nothing.

## Acceptance criteria

- The behaviour described above no longer reproduces on a fresh install.
- A regression test fails before the fix and passes after it.

## Verify

- `npm run compliance && bash scripts/run-verification-gates.sh`
- Issue-specific commands are listed on https://github.com/danielvm-git/bigpowers/issues/220.
