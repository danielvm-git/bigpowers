---
name: improve-codebase-architecture
description: Find deepening opportunities in a codebase, informed by the domain language in CONTEXT.md and the decisions in docs/adr/. Use when the user wants to improve architecture, find refactoring opportunities, consolidate tightly-coupled modules, or make a codebase more testable and AI-navigable.
---

# Improve Codebase Architecture

Surface architectural friction and propose deepening opportunities — refactors that consolidate shallow modules into deeper ones with smaller interfaces. The aim is testability and AI-navigability.

A **deep module** (Ousterhout, "A Philosophy of Software Design") has a small interface hiding a large implementation. Deep modules are easier to test at the boundary and easier for both humans and AI to navigate.

This skill is _informed_ by the project's domain model — `CONTEXT.md` and any `docs/adr/`. The domain language gives names to good module boundaries; ADRs record decisions the skill should not re-litigate.

See [CONTEXT-FORMAT.md](../domain-model/CONTEXT-FORMAT.md) and [ADR-FORMAT.md](../domain-model/ADR-FORMAT.md) for the file formats.

## Process

### 1. Explore

Read existing documentation first:

- `CONTEXT.md` (or `CONTEXT-MAP.md` + each `CONTEXT.md` in a multi-context repo)
- Relevant ADRs in `docs/adr/` (and any context-scoped `docs/adr/` directories)

If any of these files don't exist, proceed silently — don't flag their absence or suggest creating them upfront.

Then use the Agent tool with `subagent_type=Explore` to walk the codebase. Don't follow rigid heuristics — explore organically and note where you experience friction:

- Where does understanding one concept require bouncing between many small files?
- Where are modules so shallow that the interface is nearly as complex as the implementation?
- Where have pure functions been extracted just for testability, but the real bugs hide in how they're called?
- Where do tightly-coupled modules create integration risk in the seams between them?
- Which parts of the codebase are untested, or hard to test?

The friction you encounter IS the signal.

### 2. Present candidates

Present a numbered list of deepening opportunities. For each candidate:

- **Cluster**: which modules/concepts are involved
- **Why they're coupled**: shared types, call patterns, co-ownership of a concept
- **Dependency category**: see [DEEPENING.md](DEEPENING.md)
- **Test impact**: what existing tests would be replaced by boundary tests

**Use CONTEXT.md vocabulary when describing candidates.** If `CONTEXT.md` defines "Order," talk about "the Order intake module" rather than "the FooBarHandler."

**ADR conflicts**: if a candidate contradicts an existing ADR, only surface it when the friction you noticed is real enough to warrant revisiting the ADR. Mark it clearly (e.g. _"contradicts ADR-0007 — but worth reopening because…"_). Don't list every theoretical refactor an ADR forbids.

Do NOT propose interfaces yet. Ask the user: "Which of these would you like to explore?"

### 3. Grilling loop

Once the user picks a candidate, drop into a grilling conversation. Walk the design tree with them — constraints, dependencies, the shape of the deepened module, what gets hidden, what tests survive.

Side effects happen inline as decisions crystallize:

- **Naming a deepened module after a concept not in `CONTEXT.md`?** Add the term to `CONTEXT.md` — same discipline as `/domain-model` (see [CONTEXT-FORMAT.md](../domain-model/CONTEXT-FORMAT.md)). Create the file lazily if it doesn't exist.
- **Sharpening a fuzzy term during the conversation?** Update `CONTEXT.md` right there.
- **User rejects the candidate with a load-bearing reason?** Offer an ADR, framed as: _"Want me to record this as an ADR so future architecture reviews don't re-suggest it?"_ Only offer when the reason would actually be needed by a future explorer to avoid re-suggesting the same thing — skip ephemeral reasons ("not worth it right now") and self-evident ones. See [ADR-FORMAT.md](../domain-model/ADR-FORMAT.md).
- **Want to explore alternative interfaces for the deepened module?** See [INTERFACE-DESIGN.md](INTERFACE-DESIGN.md).
