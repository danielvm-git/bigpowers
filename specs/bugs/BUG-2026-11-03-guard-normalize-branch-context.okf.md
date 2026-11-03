---
okf_kind: concept
okf_version: "0.1"
type: Bug
id: "BUG-2026-11-03-guard-normalize-branch-context"
title: "The parity gate pinned the TS side to a feature branch and left the shell side on the real HEAD, so it passed on every PR and went red the moment the merge landed on main"
category: bug
tier: extended
severity: high
status: fixed
generator: scripts/sync-bugs-registry.sh
references:
    - specs/bugs/BUG-2026-11-03-guard-normalize-branch-context.md
---

# The parity gate pinned the TS side to a feature branch and left the shell side on the real HEAD, so it passed on every PR and went red the moment the merge landed on main

**Bug:** BUG-2026-11-03-guard-normalize-branch-context | **Severity:** high | **Status:** fixed | **Scope:** hooks / guard-git / verification
**Tier:** extended

See `specs/bugs/BUG-2026-11-03-guard-normalize-branch-context.md` for full investigation and fix details.
