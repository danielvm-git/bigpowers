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
