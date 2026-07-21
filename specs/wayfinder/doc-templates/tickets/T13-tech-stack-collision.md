<!-- wayfinder:grilling -->
# T13 — tech-stack-collision

**Type:** Grilling (HITL) · **Status:** CLOSED · **Claim:** driver
**Blocks:** the architecture/reference slot in `docs/` · **Blocked by:** T1 (doctrine, closed)
**Corrects:** T1's original Q1 answer ("tech-stack.md → Wave 2, human-consumed prose") — half
right, made before the real `map-codebase` output was read. It anticipated a concept-shaped
Wave-2 document belongs here, but not that the mechanical document and the curated one are two
separate documents, not one relocating.

## Question

TGDP's `concept/`+`reference/` packs vs. bigpowers' `tech-stack.md` (produced by `map-codebase`).
Which template, and where does it live?

## Resolution

**Third instance of the T9/T11 pattern (mechanical internal record vs. optional/curated human
layer) — but with a different default than the first two.** Verified against `map-codebase`'s
real output: `tech-stack.md` is explicitly the project's **"Long-Term Memory"** — machine-refreshed
(re-run the skill after significant changes), terse bullet inventory (Stack/Architecture/
Conventions/Signals), consumed primarily by `survey-context` (agent bootstrap), not stable
published prose. Neither TGDP pack actually fits its register: `concept/` is didactic
("what is X and why it matters, from scratch") — wrong shape for a factual snapshot; `reference/`
is closer in physical shape (tables/lists) but built for stable lookup material, not something
refreshed on every architecture change.

**Split, not relocation:**
- **`tech-stack.md`** — unchanged, no new template (already fully specified inside `map-codebase`
  itself). Stays the machine-refreshed factual snapshot.
- **New curated architecture page** — TGDP `concept/`-shaped, adapted from generic "explain a
  concept" to "explain this project's own architecture and why." Links to `tech-stack.md` for
  current factual detail rather than duplicating it (avoids staleness when dependencies bump).

**Cadence ruling (user-confirmed, differs from T9/T11):** unlike release-notes and troubleshooting,
this is **default, not on-the-shelf** — every project gets one, written deliberately, same
treatment as README. Most readers landing on a project's docs want "how is this built and why"
by default; it isn't an edge case.

**Artifact:** [`templates/architecture-concept.md`](../templates/architecture-concept.md).