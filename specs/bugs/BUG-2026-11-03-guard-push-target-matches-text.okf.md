---
okf_kind: concept
okf_version: "0.1"
type: Bug
id: "BUG-2026-11-03-guard-push-target-matches-text"
title: "Protected-branch push check matches the word 'main' anywhere in the command, so an unrelated echo or comment blocks a legitimate feature push"
category: bug
tier: extended
severity: medium
status: fixed
generator: scripts/sync-bugs-registry.sh
references:
    - specs/bugs/BUG-2026-11-03-guard-push-target-matches-text.md
---

# Protected-branch push check matches the word 'main' anywhere in the command, so an unrelated echo or comment blocks a legitimate feature push

**Bug:** BUG-2026-11-03-guard-push-target-matches-text | **Severity:** medium | **Status:** fixed | **Scope:** hooks / guard-git
**Tier:** extended

See `specs/bugs/BUG-2026-11-03-guard-push-target-matches-text.md` for full investigation and fix details.
