---
okf_kind: concept
okf_version: "0.1"
type: Bug
id: "BUG-2026-11-03-atomic-yaml-writes"
title: "Spec state YAML/JSON is written in place, so a concurrent reader or an interrupted run sees a truncated file (yaml ScannerError)"
category: bug
tier: extended
severity: high
status: fixed
generator: scripts/sync-bugs-registry.sh
references:
    - specs/bugs/BUG-2026-11-03-atomic-yaml-writes.md
---

# Spec state YAML/JSON is written in place, so a concurrent reader or an interrupted run sees a truncated file (yaml ScannerError)

**Bug:** BUG-2026-11-03-atomic-yaml-writes | **Severity:** high | **Status:** fixed | **Scope:** scripts / specs state
**Tier:** extended

See `specs/bugs/BUG-2026-11-03-atomic-yaml-writes.md` for full investigation and fix details.
