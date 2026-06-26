# Proposed Commit Message

## Type and Scope
`feat(migrate-spec)` — Minor version bump

## Title
```
feat(migrate-spec): make handoff block mandatory in Step 4 output
```

## Body
```
The handoff block (last_step_completed, open_decisions, required_reading,
next_skill) is now a mandatory part of state.yaml generation, not optional.

During real migrations, the handoff block proved immediately useful — the next
agent reads it first to understand context, decisions, and required reading.
Promoting it from optional to mandatory ensures every migration output includes
this metadata.

Changes:
- SKILL.md Step 4: updated to mandate handoff block with YAML format example
- REFERENCE.md: added complete state.yaml YAML template with handoff structure
- Learnings table: marked handoff as adopted (from GSD learning set)
```

## Release Impact
- **Bump Type:** `minor` (X.Y.z)
- **Rationale:** New mandatory output structure in migrate-spec skill

## Notes
- Documentation-only change (no code changes)
- All verify commands pass
- Audit gate: PASS (10/10 items)
