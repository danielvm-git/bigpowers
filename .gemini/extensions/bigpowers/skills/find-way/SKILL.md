---
name: find-way
model: sonnet
description: "Plan a large effort as a shared map of decision tickets on an issue tracker, resolving them one at a time until the way is clear. Use when an idea is too big for one session, needs structured exploration before implementation, or requires mapping decisions before building."
disable-model-invocation: true
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

---

# Find-Way Reference

## Ticket Anatomy

Each ticket holds one question, sized to one 100K token agent session:

```markdown
## Question

<the decision or investigation this ticket resolves>
```

**Labels:** `wayfinder:research`, `wayfinder:prototype`, `wayfinder:grilling`, or `wayfinder:task`

**Claim:** Assign to yourself before any work — claim blocks concurrent sessions.

**Blocking:** Use tracker's native dependency relationship so the frontier renders visually.

**Resolution:** Post answer as a comment, close the issue, append to map's Decisions-so-far.

## Resolution Protocol

1. **Load the map** — read low-res view, not every ticket body
2. **Choose & claim** — assign ticket to yourself (or take first frontier ticket if not named)
3. **Resolve** — zoom into related/closed tickets as needed; invoke skills the Notes block names
4. **Record** — post resolution comment with the answer, close the issue
5. **Update map** — append to Decisions-so-far with one-line gist + link
6. **Graduate fog** — create new tickets from newly-specifiable fog; clear from Not-yet-specified
7. **Rule out of scope** if resolution reveals something past the destination

## Ticket Types in Detail

### Research (AFK)
Surfacing facts from docs, APIs, or knowledge bases that a decision waits on.
- Resolved by a `/research` subagent
- Use when knowledge outside the working directory is required
- **Label:** `wayfinder:research`

### Prototype (HITL)
Raise fidelity by building cheap, rough, concrete artifact to react to — outline, stub, UI/logic code.
- Use the `/prototype` skill
- Links the prototype as an asset
- Use when "how should it look" or "how should it behave" is key
- **Label:** `wayfinder:prototype`

### Grilling (HITL)
Conversation via `/grilling` and `/domain-modeling` skills, one question at a time.
- The default case for clarifying decisions
- **Label:** `wayfinder:grilling`

### Task (HITL or AFK)
Manual work unblocking a decision — signing up for service, provisioning access, moving data.
- This is the **only** type that does rather than decides
- Earns its place by unblocking a decision, not by delivering the destination
- Agent drives AFK tasks alone; HITL tasks get precise checklist
- **Label:** `wayfinder:task`

## Fog-to-Ticket Graduation

When resolving a ticket clears fog, graduate the newly-specifiable bits into fresh tickets:

1. **Identify the fog** in Not-yet-specified that the resolution illuminates
2. **Create new tickets** with crisp question statements
3. **Wire blocking edges** if the new tickets depend on each other or existing ones
4. **Clear from fog** — remove the graduated patch from Not-yet-specified so it lives only as its ticket

## Out-of-Scope Close Protocol

If a ticket turns out to sit past the destination:

1. **Close the ticket** — mark it resolved or won't-fix
2. **Add one line to Out of scope** — gist + why it's out of scope, linking the closed ticket
3. **Never append to Decisions so far** — scope boundaries aren't steps on the route

## Map State Transitions

| State | Meaning | Action |
|-------|---------|--------|
| **Open, unblocked, unclaimed** | Frontier — ready to take | Claim and resolve |
| **Open, blocked** | Waiting on something | Wait for blockers to close |
| **Open, claimed** | Concurrent session working | Skip for now |
| **Closed** | Decided — lives in Decisions so far | Reference, don't re-open |

## Concurrency

Users may run unblocked tickets in parallel, so expect the tracker to be edited concurrently. Always:

- Refresh the map before picking a ticket
- Claim immediately before starting work
- Never assume state hasn't changed since last read
