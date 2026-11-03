---
okf_kind: concept
okf_version: "0.1"
type: Bug
id: "BUG-2026-11-03-adapter-stdin-hang"
title: "Adapters read stdin when sourced, so Preflight hangs and context wiring can skip targets"
category: bug
tier: extended
severity: high
status: fixed
generator: scripts/sync-bugs-registry.sh
references:
    - specs/bugs/BUG-2026-11-03-adapter-stdin-hang.md
---

# Adapters read stdin when sourced, so Preflight hangs and context wiring can skip targets

**Bug:** BUG-2026-11-03-adapter-stdin-hang | **Severity:** high | **Status:** fixed | **Scope:** adapters / verification gates
**Tier:** extended

See `specs/bugs/BUG-2026-11-03-adapter-stdin-hang.md` for full investigation and fix details.
