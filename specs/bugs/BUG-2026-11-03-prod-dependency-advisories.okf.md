---
okf_kind: concept
okf_version: "0.1"
type: Bug
id: "BUG-2026-11-03-prod-dependency-advisories"
title: "The production dependency tree carried 10 advisories including a critical (proxy-addr IP spoofing) and two high direct dependencies (js-yaml, zod), with no gate watching it"
category: bug
tier: extended
severity: high
status: fixed
generator: scripts/sync-bugs-registry.sh
references:
    - specs/bugs/BUG-2026-11-03-prod-dependency-advisories.md
---

# The production dependency tree carried 10 advisories including a critical (proxy-addr IP spoofing) and two high direct dependencies (js-yaml, zod), with no gate watching it

**Bug:** BUG-2026-11-03-prod-dependency-advisories | **Severity:** high | **Status:** fixed | **Scope:** dependencies / shipped runtime
**Tier:** extended

See `specs/bugs/BUG-2026-11-03-prod-dependency-advisories.md` for full investigation and fix details.
