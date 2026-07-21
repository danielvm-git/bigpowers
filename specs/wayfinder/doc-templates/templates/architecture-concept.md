<!-- wayfinder resolution artifact — T13 (tech-stack collision), closed -->
<!-- DEFAULT, like README — not on-the-shelf like release-notes/troubleshooting. Every project
     gets one, written deliberately at setup and kept current, not left for a rare occasion. -->
<!-- This is the CURATED companion to tech-stack.md, not a replacement for it. tech-stack.md
     (produced by map-codebase, unchanged, no new template — it's already fully specified in
     that skill) stays the machine-refreshed factual snapshot — current dependency versions,
     the terse Stack/Architecture/Conventions/Signals inventory, agent-consumed "long-term
     memory." This page explains WHY, for a human reader; it does not restate WHAT — link to
     tech-stack.md for current factual detail rather than duplicating it, so this page never
     goes stale when a dependency bumps. -->
<!-- Composed from: big-docs/docs/concept/template_concept.md (TGDP), adapted from a generic
     "explain a concept" shape to "explain this project's own architecture." -->

# Architecture — {Project Name}

{One paragraph: what this project is built with and why, at a glance. This is the page a
contributor reads before touching code.}

## Why these choices

{The reasoning TGDP's Background section anticipates, made central here since "why" is the
whole point of this page. What forces shaped the stack and structure — not a changelog of
decisions, a synthesis of the ones that matter to a newcomer.}

## How it's organized

{The high-level pattern in prose — translate tech-stack.md's terse "Architecture" bullets into
an explanation a newcomer can follow: entry points, data flow, where logic lives vs. where I/O
lives.}

## Key decisions

{The alternatives that were considered and why the current choice won — mirrors TGDP's optional
Comparison section. Link to the specific ADR for each decision's full record rather than
re-arguing it here.}

- **{Decision area}** — {one-line rationale}. See [`{ADR NNNN}`](../architecture/decisions/{NNNN-slug}.md).

## Current stack

{Do not restate versions/dependencies here — they drift. Point to the machine-refreshed source.}

For the current, factual stack inventory (dependencies, conventions observed, active signals),
see [`tech-stack.md`](../architecture/tech-stack.md) — refreshed automatically, not hand-maintained.

## Related resources

- [Architecture decisions](../architecture/decisions/) — the full ADR history
- [`tech-stack.md`](../architecture/tech-stack.md) — current factual snapshot
