---
bug_id: BUG-2026-11-06-install-multi-channel-collisions
status: open
severity: high
scope: "distribution / pi"
title: "Five install channels produce 80 skill-name collisions (#208)"
issue: https://github.com/danielvm-git/bigpowers/issues/208
files_changed: "scripts/install.sh, bin/setup.js, scripts/sync-skills.sh, distribution target manifest"
approach: "Single target manifest; refuse a second channel for the same host; add --verify duplicate-root report"
risk_level: medium
commit_message: "fix(dist): one install channel per host and a --verify report (#208)"
---

# BUG-2026-11-06-install-multi-channel-collisions: Five install channels produce 80 skill-name collisions (#208)

## Problem

pi scans ~/.pi/agent/skills, ~/.agents/skills, <cwd>/.pi/skills and <cwd>/.agents/skills, plus package pi.skills. Measured on the author machine: 91 distinct names across roots, 80 present in 2+ roots with different real paths, producing 80 collision blocks per start; the rank the host applies is not the copy the maintainer edits.

## Acceptance criteria

- The behaviour described above no longer reproduces on a fresh install.
- A regression test fails before the fix and passes after it.

## Verify

- `npm run compliance && bash scripts/run-verification-gates.sh`
- Issue-specific commands are listed on https://github.com/danielvm-git/bigpowers/issues/208.
