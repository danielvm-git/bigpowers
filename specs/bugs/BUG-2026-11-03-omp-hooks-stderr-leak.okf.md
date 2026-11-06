---
okf_kind: concept
okf_version: "0.1"
type: Bug
id: "BUG-2026-11-03-omp-hooks-stderr-leak"
title: "tool_call hook leaks git's fatal: not a git repository onto the TUI when a bash command cds outside the session repo"
category: bug
tier: extended
severity: medium
status: fixed
generator: scripts/sync-bugs-registry.sh
references:
    - specs/bugs/BUG-2026-11-03-omp-hooks-stderr-leak.md
---

# tool_call hook leaks git's fatal: not a git repository onto the TUI when a bash command cds outside the session repo

**Bug:** BUG-2026-11-03-omp-hooks-stderr-leak | **Severity:** medium | **Status:** fixed | **Scope:** extensions / omp-hooks
**Tier:** extended

See `specs/bugs/BUG-2026-11-03-omp-hooks-stderr-leak.md` for full investigation and fix details.
