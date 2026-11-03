---
okf_kind: concept
okf_version: "0.1"
type: Bug
id: "BUG-2026-11-03-guard-git-flag-normalize"
title: "guard-git matches command substrings, so global flags and reordered options bypass the destructive-command deny list"
category: bug
tier: extended
severity: high
status: fixed
generator: scripts/sync-bugs-registry.sh
references:
    - specs/bugs/BUG-2026-11-03-guard-git-flag-normalize.md
---

# guard-git matches command substrings, so global flags and reordered options bypass the destructive-command deny list

**Bug:** BUG-2026-11-03-guard-git-flag-normalize | **Severity:** high | **Status:** fixed | **Scope:** hooks / guard-git
**Tier:** extended

See `specs/bugs/BUG-2026-11-03-guard-git-flag-normalize.md` for full investigation and fix details.
