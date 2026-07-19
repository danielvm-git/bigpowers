---
name: find-way
description: Plan a large effort as a shared map of decision tickets on an issue tracker, resolving them one at a time until the way is clear. Use when an idea is too big for one session, needs structured exploration before implementation, or requires mapping decisions before building.
---

# Find Way

## Concept

A large effort arrives — too big for one session, wrapped in fog. **Find-way** charts the way as a **shared map** on the repo's issue tracker, then works **decision tickets** — questions whose resolution is a decision, not build slices — one at a time until the route is clear.

**Plan, don't do.** Each ticket resolves a decision. The map is done when the way is clear — nothing left to decide before someone executes.

**Refer by name.** Every map and ticket is an issue with a title. Always use the name, never bare ids or numbers.

## The Map

A single issue labelled `wayfinder:map` — the canonical artifact. Child issues are its tickets.

```markdown
## Destination
<what reaching the end looks like — one or two lines>

## Notes
<domain, skills to consult, standing preferences>

## Decisions so far
- [closed ticket title](link) — one-line gist

## Not yet specified
<in-scope fog you can't ticket yet>

## Out of scope
<work ruled beyond the destination>
```

## Ticket Types

| Type | Label | Mode | Purpose |
|------|-------|------|---------|
| Research | `wayfinder:research` | AFK | Surface facts from docs/APIs |
| Prototype | `wayfinder:prototype` | HITL | Cheap artifact to react to |
| Grilling | `wayfinder:grilling` | HITL | One-question-at-a-time dialogue |
| Task | `wayfinder:task` | Either | Manual work unblocking a decision |

**HITL** = human in the loop. **AFK** = agent alone.

## Two Modes

### Chart the Map

User invokes with a loose idea.

1. **Name the destination** — grill to pin down what this map finds its way to
2. **Map the frontier** — breadth-first: surface open decisions and first steps. If no fog emerges, the effort fits one session — skip the map
3. **Create the map** issue (label `wayfinder:map`)
4. **Create tickets** as child issues, then wire blocking edges in a second pass
5. **Fire research subagents** for each `research` ticket in parallel
6. Stop — charting resolves nothing

### Work Through the Map

User invokes with a map (URL/number). Ticket optional — without one, pick the next frontier ticket.

1. Load the map (low-res view)
2. **Choose & claim** — assign ticket before any work
3. **Resolve** — zoom into related/closed tickets as needed
4. **Record** — post resolution comment, close issue, append to Decisions-so-far
5. **Graduate fog** — create new tickets from newly-specifiable fog, clear from Not-yet-specified
6. **Rule out of scope** if resolution reveals something past the destination

**Never resolve more than one ticket per session** (except research).

## Fog of War

Beyond live tickets lies the **fog** — decisions you can tell are coming but can't pin down yet. The **Not yet specified** section holds this dim view.

**Fog or ticket?** Test: can you state the question precisely now?

- **Ticket** when the question is sharp (even if blocked)
- **Not yet specified** when you can't phrase it sharply yet

## Out of Scope

Work beyond the destination. Ruling something out is a scoping act, not a route step. Never graduates — returns only if destination is redrawn.

If an existing ticket sits past the destination, close it and note in Out of scope.

## Blocking & Frontier

- **Blocking**: tracker's native dependency relationship
- **Unblocked**: every blocker is closed
- **Frontier**: open, unblocked, unclaimed children — the edge of the known

## Detailed Reference

See [REFERENCE.md](REFERENCE.md) for ticket anatomy, resolution protocol, and examples.
