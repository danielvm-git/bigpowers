---
name: dispatch-agents
description: "Dispatch multiple subagents in parallel on independent tasks. No waiting between them — all run concurrently. Use when tasks are truly decoupled and speed matters. Distinct from delegate-task (concurrent here, no inter-task review gate)."
---


# Dispatch Agents

Run multiple subagents in parallel on independent tasks. Use when tasks are genuinely decoupled — no agent needs the output of another to start.

**Distinct from `delegate-task`:** This skill maximizes throughput via concurrency. There is no sequential review gate between tasks. Use `delegate-task` instead when a single task needs careful two-stage oversight before proceeding.

## When to use

- Tasks that can run simultaneously without shared state
- Large plans that can be broken into parallel workstreams
- Exploration: gather information from multiple parts of the codebase at once

## When NOT to use

- Task B depends on Task A's output
- You need to review Task A before Task B can start safely
- The tasks share a file and concurrent edits would conflict

## Process

### 1. Confirm independence

Before dispatching, verify each task pair is truly independent:
- No shared files being written
- No shared state (DB migrations, config files)
- No ordering dependency between outcomes

If any two tasks conflict, sequence them with `delegate-task` or `execute-plan` instead.

### 2. Write task briefs

For each task, write a complete self-contained brief (each agent starts cold):
- What needs to be done
- Which files/modules are in scope
- CONVENTIONS.md constraints
- The verify command
- What NOT to touch

### 3. Dispatch in parallel

Spawn all agents in a single message using multiple Agent tool calls. Each agent gets its own complete brief.

```
Agent 1: brief for task A
Agent 2: brief for task B
Agent 3: brief for task C
```

### 4. Collect and review results

When all agents return:
- Review each result independently
- Run all verify commands
- Check diffs for scope violations or CONVENTIONS.md breaches

### 5. Integrate

Merge accepted results. If any agent's result conflicts with another, resolve manually and note the conflict.

Report a summary: which tasks succeeded, which need revision, and overall verify status.
