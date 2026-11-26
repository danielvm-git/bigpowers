---
bug_id: BUG-2026-11-06-install-uninstall-noop
status: fixed
severity: high
scope: "install"
title: "install.sh --uninstall is a no-op from a checkout and never removes copy-mode channels (#219)"
issue: https://github.com/danielvm-git/bigpowers/issues/219
files_changed: "scripts/install.sh, scripts/lib/install-targets-*.sh, scripts/test-install-helpers.js"
approach: "Match by resolved realpath; record an install manifest; handle copy-mode entries; always print a summary"
risk_level: medium
commit_message: "fix(install): make --uninstall actually remove every managed entry (#219)"
fix_evidence: "PR #224 — install manifest + resolved-path uninstall"
---

# BUG-2026-11-06-install-uninstall-noop: install.sh --uninstall is a no-op from a checkout and never removes copy-mode channels (#219)

## Problem

unlink_if_managed only removes a link whose literal readlink text starts with $REPO_ROOT/. Entries installed from the npm package point at node_modules/bigpowers, so an uninstall run from a checkout removes 0 of 85 and exits 0. Chained hops (~/.agents/skills -> ~/.claude/skills -> node_modules) survive too, and copy-mode channels (Hermes, Cursor, Antigravity) are never considered. Measured: 635 entries plus a 62 MB copy tree had to be removed by hand.

## Acceptance criteria

- The behaviour described above no longer reproduces on a fresh install.
- A regression test fails before the fix and passes after it.

## Verify

- `npm run compliance && bash scripts/run-verification-gates.sh`
- Issue-specific commands are listed on https://github.com/danielvm-git/bigpowers/issues/219.
