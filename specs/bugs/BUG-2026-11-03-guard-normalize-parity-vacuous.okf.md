---
okf_kind: concept
okf_version: "0.1"
type: Bug
id: "BUG-2026-11-03-guard-normalize-parity-vacuous"
title: "The guard-git parity gate asserted 'allow' for a push to protected main and only compared the destructive-argv rule against the whole hook, so CI went red and the gate was vacuous for the protected-branch rules"
category: bug
tier: extended
severity: high
status: fixed
generator: scripts/sync-bugs-registry.sh
references:
    - specs/bugs/BUG-2026-11-03-guard-normalize-parity-vacuous.md
---

# The guard-git parity gate asserted 'allow' for a push to protected main and only compared the destructive-argv rule against the whole hook, so CI went red and the gate was vacuous for the protected-branch rules

**Bug:** BUG-2026-11-03-guard-normalize-parity-vacuous | **Severity:** high | **Status:** fixed | **Scope:** hooks / guard-git / verification
**Tier:** extended

See `specs/bugs/BUG-2026-11-03-guard-normalize-parity-vacuous.md` for full investigation and fix details.
