<!-- wayfinder:grilling -->
# T24 — epic-template

**Type:** Grilling (HITL) · **Status:** CLOSED · **Claim:** driver
**Blocks:** nothing (fog list closure only) · **Blocked by:** T4 (survivor-set, closed — lists
`epic.yaml` as KEEP), T5 (exemplar-adr, closed — this thin-wrapper pattern), T19 (tasks-yaml,
closed — the closest sibling: also pure-YAML, also Delivery-group)

## Question

A Fable audit of this session's own work (2026-07-21) found that `epic.yaml` was the **one**
document in the "Not yet specified" fog list's Delivery category with neither a per-document
ticket nor a template — its siblings `story` (T12) and `tasks.yaml` (T19) both got both, and
`epic.yaml` itself is explicitly KEEP in T4's survivor table (T4:34: "Delivery (epic.yaml,
story .md, tasks.yaml) | **KEEP** — story is the narrative-OKF flagship"). MAP.md's own claim
that "every category in the original fog list has a verdict" (MAP.md:63-64) was true at
category granularity but not document granularity. Does `epic.yaml` get a template, and if so,
what shape?

## Resolution

**Same pattern as tasks.yaml (T19), not story.md (T12).** `epic.yaml` is structurally closer to
`tasks.yaml`/`specs/workflows/*.yaml` than to `story.md`: pure YAML, no markdown prose body,
authored collaboratively during planning (via `plan-work`/`plan-release`) rather than
machine-derived from a script the way `execution-status.yaml` is. Classified narrative-OKF for
the same reason T19 gave `tasks.yaml`: authorship (human/agent-collaborative), not body shape —
its `source:`/`note:`/`ac:` fields are prose, not data records a script emits after the fact.

**Thin wrapper, grounded in the real live shape** — not invented. The field contract (`id`,
`title`, `wsjf`, `bcps`, `capsule_dir`, `mode`, `status`, `depends_on`, `source`, `note`,
`stories[]` with `id`/`bcp`/`status`/`title`/`spec`/`tasks`/`ac`) is transcribed from
`specs/epics/e53-establish-migration-baseline/epic.yaml`'s actual fields — the same
audit-then-template discipline every other ticket in this session followed (T16's cockpit
schemas, T19's own tasks.yaml grep, T23's workflow-recipe field check).

**Guardrail baked in, not left implicit** — the same audit that found this gap also found the
CRITICAL-severity consequence of not stating it: e53's own `epic.yaml` shipped referencing 4
`spec:` files that didn't exist, and the validator meant to catch that
(`scripts/lib/plan-consistency-check.sh`) was silently exiting 0 on this host due to an
unrelated bash-3.2 portability bug. The new template's closing comment states the spec+tasks
pairing requirement explicitly and cites the real gate, so a future epic author sees the rule at
the point of authoring, not after a validator failure (or, as happened here, a validator that
should have failed but didn't).

**`bcp:` (singular, per-story) confirmed as the real convention, not a defect to correct.** A
sub-agent flagged `epic.yaml`'s per-story `bcp:` as inconsistent with `tasks.yaml`'s
story-level `bcps:` (plural) during this same audit. Checked before baking anything into the
template: `bcp:` singular at per-story level appears 236 times across every other live and
archived `epic.yaml` in the repo — it is the established convention, not an e53-specific
outlier. The template preserves it as-is and notes this explicitly, so a future reader doesn't
"fix" it again.

**Artifact:** [`templates/epic.md`](../templates/epic.md).
