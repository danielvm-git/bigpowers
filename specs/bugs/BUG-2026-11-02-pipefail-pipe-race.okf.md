---
okf_kind: concept
okf_version: "0.1"
type: Bug
id: "BUG-2026-11-02-pipefail-pipe-race"
title: "Pipelines with an early-exit reader (grep -q, head) fail at random under set -o pipefail"
category: bug
tier: extended
severity: medium
status: fixed
generator: scripts/sync-bugs-registry.sh
references:
    - specs/bugs/BUG-2026-11-02-pipefail-pipe-race.md
---

# Pipelines with an early-exit reader (grep -q, head) fail at random under set -o pipefail

**Bug:** BUG-2026-11-02-pipefail-pipe-race | **Severity:** medium | **Status:** fixed | **Scope:** scripts / gates
**Tier:** extended

See `specs/bugs/BUG-2026-11-02-pipefail-pipe-race.md` for full investigation and fix details.
