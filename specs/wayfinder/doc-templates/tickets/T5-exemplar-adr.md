<!-- wayfinder:prototype -->
# T5 — exemplar-adr

**Type:** Prototype (HITL) · **Status:** CLOSED · **Claim:** driver
**Blocks:** per-document fog (the reference all others copy) · **Blocked by:** T1 (closed)

## Question

Under the doctrine chosen in T1, draft the **ADR template** as the reference exemplar — the concrete
artifact every other per-document template copies its envelope, provenance, and section discipline from.
ADR chosen because it is small, stable, and already exists in both `specs/adr/` and `bigspec/specs/adr/`.

## Decision output

A drafted `templates/adr.md` (or per-doctrine equivalent) to react to, linked as an asset — not merged
into the repo's live ADRs. Proves the doctrine survives contact with a real document.

## Resolution

**Three real shapes reconciled, nothing dropped without reason:**

| Element | Source | Kept because |
|---|---|---|
| OKF frontmatter (`okf_kind: adr`, provenance) | bigspec's live ADR-0007 | **Required by T1's closed doctrine** — narrative-OKF envelope + prose body = the render, directly |
| Status/Date/Deciders header, Context/Decision/Consequences, `NNNN-<slug>.md` numbering | `big-docs`' `0000-template.md` (Nygard format) | Universal ADR shape; already matches bigpowers' own numbering (0001–0007 confirmed live) |
| **Conway's Law note** | `big-docs`' template | Distinctive, not present in bigspec or bigpowers' live ADRs — genuinely useful, fits the "solo-dev with enterprise behaviour" framing from this project's original brief |
| **Amended field** | bigpowers' own live ADRs (e.g. ADR-0006's `Amended: 2026-07-03`) | Lets a decision's status evolve in place without forcing a full supersession churn for a minor clarification — absent from both other sources |

**Doctrine survives contact with a real document:** the OKF frontmatter is the machine-gated envelope
(`validate-okf` checks structure/provenance, never a value, per T1); the body's compact header line
is for a human scanning the rendered page — light redundancy with frontmatter, intentional, since
frontmatter isn't always visible to a reader depending on the site theme.

**Artifact:** [`templates/adr.md`](../templates/adr.md) — this is now the reference every other
narrative-OKF template (story, bug, tech-stack, security REVIEW) copies its envelope and section
discipline from, per this ticket's own charge.
