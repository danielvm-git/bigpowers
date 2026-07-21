<!-- wayfinder:grilling -->
# T19 — tasks-yaml

**Type:** Grilling (HITL) · **Status:** CLOSED · **Claim:** driver
**Blocks:** the last delivery-slot document in the survivor set · **Blocked by:** T1 (doctrine,
closed), T5 (exemplar-adr, closed — pattern applied here)

## Question

Does `eNNsYY-tasks.yaml` need a template, and does it violate constitution B9's per-task BCP
prohibition the way `story.md`'s SIZE field almost did (T12)?

## Resolution

**No collision, and a real compliance check came back clean.** No TGDP candidate exists (no
"tasks" folder in the original 26). Checked every live `*-tasks.yaml` under `specs/epics/` for
per-task BCP annotations — **none found.** `bcps:` correctly appears once, at the story level
(top of file), never per-task. Constitution B9 ("BCP lives at the story level only; task-level
`[BCP N]` is prohibited") is already followed in practice, not violated — unlike T12's SIZE
tension, there was nothing to arbitrate here.

No public-facing companion warranted — pure internal execution tracking (task descriptions,
`verify:` commands), no reader value, same reasoning as T15's test-plan.

**Preserved as a hard, load-bearing gate:** every task MUST have a runnable `verify:` command —
"no verify: = not a task" (CONVENTIONS.md, `plan-release`). Baked into the artifact as an
explicit guardrail comment, matching T12's SIZE/BCP distinction and T15's SC-ID preservation.

**Artifact:** [`templates/tasks.md`](../templates/tasks.md) — OKF envelope wrapping the existing
structure verbatim, per T5's established pattern.