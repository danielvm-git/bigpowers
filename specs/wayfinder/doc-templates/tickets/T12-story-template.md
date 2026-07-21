<!-- wayfinder:grilling -->
# T12 — story-template

**Type:** Grilling (HITL) · **Status:** CLOSED · **Claim:** driver
**Blocks:** the flagship narrative-OKF document (highest-traffic template in the catalog)
**Blocked by:** T1 (doctrine, closed), T5 (exemplar-adr, closed — provides the frontmatter+body
header pattern this ticket follows)

## Question

`docs/countable-story-format.md` is a single, already-mandatory 20-section format (user co-authored
the underlying BCP methodology). Unlike README/changelog/glossary/troubleshooting, there's no
competing candidate to compose from. The work is reconciling it with T1's OKF envelope doctrine —
does the 20-section body change, and does anything conflict with bigspec's constitution (also
mandatory, per this session's north-star)?

## Resolution

**The 20 sections do not change.** Confirmed via bigspec's own `architecture.md`, which diagnosed
this exact reconciliation before this session started: "the doc layer runs three overlapping
conventions... the countable-story 20-section contract, `_LATEST`, and OKF frontmatter... the best
idea (OKF) governs a fraction of the surface." Its fix, already decided: **"the countable-story
'counter' is just the validator for `okf_kind: story`"** — OKF wraps the format, it doesn't replace
it. Constitution B4 independently confirms: "the spec MUST use the structured countable-story
format" (verbatim mandate, unweakened).

**One real conflict found and resolved (user ruling):** constitution B9 says stories carry "no
gestalt `SIZE` field," which reads as a direct contradiction of the format's mandatory
`SIZE: XS-XL` header at maturity 4+. **Ruling: SIZE stays — it is a pre-count Fibonacci T-shirt
estimate for sprint-commit gating, never the computed BCP total.** B9's rule targets a hand-stamped
BCP number anchoring the independent Element Router count; SIZE is a coarser, earlier, different
instrument. This distinction is baked into the artifact as an explicit guardrail comment so it
can't be misused the way B9 was guarding against.

**Scoping decision (consistent with the no-parallel-mirror discipline from T6 onward):** the
template artifact does **not** reproduce the 20 sections' prose, maturity rubric, or hard rules —
`docs/countable-story-format.md` remains the single source for that content. The artifact is a thin
wrapper showing only the OKF-envelope + header reconciliation, following T5's ADR pattern
(frontmatter for machine gating, body header line for human scanning, deliberate light redundancy
between them).

**Artifact:** [`templates/story.md`](../templates/story.md).