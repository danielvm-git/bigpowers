<!-- wayfinder:grilling -->
# T23 — workflows-yaml

**Type:** Grilling (HITL) · **Status:** CLOSED · **Claim:** driver
**Blocks:** nothing — **the map's last fog item** · **Blocked by:** T1 (doctrine, closed)

## Question

Does `specs/workflows/<name>.yaml` (`compose-workflow`) need a template, and does it collide
with anything?

## Resolution

**No collision, straightforward close.** No TGDP candidate exists. No public-facing companion
warranted — pure internal orchestration recipe, same class as `tasks.yaml`/`TEST_PLAN`. Checked
8 real live files (`plan.yaml`, `ship.yaml`, `tdd.yaml`, `security.yaml`, `e2e.yaml`,
`check-stack.yaml`, `build-fix.yaml`, `code-review.yaml`): fields match `compose-workflow`'s
documented contract exactly (`name`/`command`/`description`/`skills[]`/`verify`), zero drift.
The skill itself confirms this YAML format already superseded a legacy
`specs/WORKFLOW-<name>.md` markdown predecessor — nothing to reconcile, already settled before
this round started.

**Artifact:** [`templates/workflow-recipe.md`](../templates/workflow-recipe.md).

---

## Map status

This closes the last item in the original "Not yet specified" fog. Every category — cockpit
YAML, product intent, delivery, architecture, quality, analysis, authoring, and config — now has
a verdict. 23 tickets closed, 25 artifacts shipped.