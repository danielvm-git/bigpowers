---
name: session-state
description: "Track implementation decisions and progress in specs/STATE.md to prevent context rot. Use at the start of a session to load context, and whenever a significant decision is made or a milestone is reached."
---


# Session State

Track the current state of implementation, including decisions made, pending tasks, and open questions, to ensure continuity across session boundaries and prevent "context rot."

## Goal

Maintain a single source of truth for the *current* state of the work in `specs/STATE.md`. This file acts as the project's short-term memory, complementing the long-term memory of `specs/CONTEXT.md` and the task-specific instructions in `specs/PLAN.md`.
## Workflow

### 1. Initialize (Session Start)

If `specs/STATE.md` does not exist, or if starting a new major phase:

- [ ] Read `specs/PLAN.md` and `specs/SCOPE.md`.
- [ ] Get git metadata: `git branch --show-current` and `git rev-parse HEAD`.
- [ ] Create `specs/STATE.md` with the current milestone, git metadata, pending tasks, and any active decisions.

### 2. Load (Context Refresh)

When starting a new session or after a significant context flush:

- [ ] Read `specs/STATE.md` to understand where the previous agent left off.
- [ ] Verify the current state matches the actual codebase (run `git branch` and `git diff`).
- [ ] Surface any discrepancies between recorded git hash and current hash.

### 3. Update (Decision Point/Milestone)

Whenever a significant decision is made or a milestone is reached:

- [ ] Update git metadata if the branch or hash has changed.
- [ ] Update the `Active Decisions` section with the rationale for the choice.
- [ ] Mark completed tasks as done.
- [ ] Add new pending tasks discovered during implementation.
- [ ] Record any "Open Questions" that need user clarification.

## File Format: specs/STATE.md

```markdown
# Session State: [Feature Name]

## Current Milestone
[What is being worked on right now]

## Git Metadata
- **Branch**: [branch-name]
- **Hash**: [commit-hash]

## Pending Tasks
...
```
- [ ] Task 2

## Active Decisions
- **Decision Name**: [Rationale and impact]

## Open Questions
- [Question for the user]
```

## Anti-Patterns

- **Duplicate Plan**: Don't just copy `specs/PLAN.md`. The plan is the *intended* path; the state is the *actual* progress and the deviations from that path.
- **Stale State**: Forgetting to update `specs/STATE.md` after a major refactor or decision.
- **Verbose History**: Keep it focused on the *current* state. Use git history for the past.
