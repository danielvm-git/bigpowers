<!-- wayfinder:grilling -->
# T1 — template-doctrine

**Type:** Grilling (HITL) · **Status:** CLOSED · **Claim:** driver
**Blocks:** T5 + all per-document fog · **Informed by:** T2 (landscape), T3 (inventory), **T6 (doc-information-architecture)**

## Question

Which single doctrine governs the template for *every* bigpowers document? Candidates to grill,
one question at a time:

- **(a) bigspec B8 — one body template per `okf_kind`.** Universal OKF envelope (frontmatter:
  `okf_kind`, `okf_version`, provenance) + one body template per kind; `validate-okf` gates
  structure & provenance, never a value. Machine-first.
- **(b) Diátaxis / Good Docs doc-type split.** Classify by reader intent — tutorial / how-to /
  reference / explanation — each with its own template. Prose-first.
- **(c) Hybrid.** OKF envelope as the universal wrapper for machine artifacts (YAML specs, reports),
  Diátaxis for human prose (README, guides, wiki). One axis for docs-as-data, another for docs-as-prose.

## Decision output (what "resolved" looks like)

A one-paragraph doctrine statement + a rule that, given any bigpowers document, says which template
family owns it and why. This becomes the header of every per-document template ticket that graduates.

## Resolution

**Closed by synthesis of T6 — no fresh grilling needed; the doctrine fell out of the information-
architecture decision.** Answer is a refined **(c) hybrid**, concretely instantiated as `big-docs`'
3-wave model rather than left abstract:

> **The doctrine is one template format per Wave, with a render split inside Wave 3.**
> - Wave 1 (GitHub-native) — no bigpowers template; these are GitHub's own standard files.
> - Wave 2 (GoodDocs, `docs/`) — one TGDP pack template per doc type (12 packs), human prose,
>   Diátaxis-descended but flatter (siblings, not nested under 4 parents — resolves the original
>   "Diátaxis is too small" objection).
> - Wave 3 (Specs, `specs/`) — one OKF envelope format for every artifact. Within it: **narrative
>   kinds** (ADR, story, bug, audit report) use a markdown-prose-body template that IS the site
>   render, zero transform — not two templates, one template used directly. **Data kinds** (metrics,
>   cockpit state, cycle-times) use a structured-YAML-body template with no page render at all — they
>   feed generic dashboard views instead.

**The sorting test from the original grilling question (Q1) is answered:** it's neither pure "who
reads it" nor pure "specs/ vs docs/ location" — it's **which Wave the document's generating skill
belongs to**, which was always well-defined (every T3 inventory row already has an owning skill).
The three examples that seemed ambiguous in Q1 resolve cleanly:
1. `tech-stack.md` → Wave 2 (`docs/concept` or `docs/reference`) — human-consumed prose, not gated.
2. Wiki pages → **retired as a concept** — T6 Invariant #4 forbids parallel `*-wiki/` folders; former
   wiki content is just Wave 3 narrative-OKF now, one source, no separate mirror.
3. ADR → Wave 3 (`specs/architecture/decisions/`), narrative-OKF, rendered 1:1 — no second face; the
   "public mirror" is literally the same file rendered by the site build, not a duplicate.

**Decision output delivered:** every per-document template ticket that graduates from the fog inherits
this header: which Wave it belongs to, and (if Wave 3) narrative or data shape.
