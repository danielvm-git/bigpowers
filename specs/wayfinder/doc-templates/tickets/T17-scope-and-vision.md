<!-- wayfinder:grilling -->
# T17 — scope-and-vision

**Type:** Grilling (HITL) · **Status:** CLOSED · **Claim:** driver
**Blocks:** the product-intent slot in the survivor set · **Blocked by:** T1 (doctrine, closed)

## Question

`SCOPE_LATEST.yaml` and `VISION_LATEST.yaml` — narrative or data-OKF? Any TGDP collision? Any
overlap between them?

## Resolution

**Narrative-OKF (T5's pattern), not data-OKF (T16's pattern) — YAML-serialized, but genuinely
narrative content.** Verified against real files and `scope-work`'s skill contract: `SCOPE_LATEST.
yaml` has a multi-paragraph `summary`, a `core_value` sentence, and reasoned `in_scope`/
`out_of_scope` lists. `scope-work` explicitly runs a human interview ("what is the goal, who are
the users, what's in/out") — collaborative authoring, not machine-derived like `execution-status.
yaml`. Format is YAML; content shape is narrative. **No TGDP collision** — `concept/` is didactic
(explain something to someone who doesn't understand it), these are planning/boundary artifacts;
different purpose, not a real overlap.

**Real overlap found and resolved:** both files carry their own `out_of_scope` list. Distinguished
explicitly rather than left implicit: **`vision.md`'s is permanent** ("never, as a matter of
product identity"); **`scope.md`'s is tactical, per-round**, each entry with an individual reason
(deferred/not-valuable/too-risky/depends-on-external) and revisitable in a future round. Confirmed
against the live files — VISION's entries ("Domain-specific scaffold skills," "SaaS tracker
integrations") read as identity-level; SCOPE's `fr-NN` items map to specific epics, clearly
tactical.

**Mechanical fix applied:** `_LATEST` suffix dropped from both, per T1/T6 doctrine (git + the
file's location is "current" — already applied consistently to ADR, TEST_PLAN).

**Artifacts:** [`templates/vision.md`](../templates/vision.md),
[`templates/scope.md`](../templates/scope.md).