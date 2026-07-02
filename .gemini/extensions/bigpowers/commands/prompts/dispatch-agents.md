
# Dispatch Agents
> **HARD GATE** — **HARD GATE** — Agent work must be parallelizable and have explicit synchronization points. Do NOT dispatch work that has hidden dependencies between agents.


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

Before writing briefs, read `specs/state.yaml` if it exists — each agent gets only the decisions relevant to its task, nothing else.

For each task, use this minimal template (each agent starts cold — brief size directly controls token cost and hallucination risk):

```
Goal: [one sentence — what success looks like]
In scope: [explicit file or module list]
Out of bounds: [what NOT to touch]
Verify: [runnable command]
Prior decisions: [relevant entries from specs/state.yaml — omit section if none apply]
```

Do not include the full conversation, full file contents, or decisions unrelated to this agent's task.

### 3. Iterative retrieval (max 3 cycles)

After each wave completes:
1. **Dispatch** — run parallel agents with briefs.
2. **Evaluate** — read outputs; list gaps vs goal.
3. **Refine** — tighten briefs or spawn follow-up agents (max **3 cycles** total).

Stop when gaps empty or cycle 3 reached — escalate to user.

### 4. Dispatch in parallel

Spawn all agents in a single message using multiple Agent tool calls. Each agent gets its own complete brief.

```
Agent 1: brief for task A
Agent 2: brief for task B
Agent 3: brief for task C
```

### 5. Collect and review results

When all agents return:
- Review each result independently
- Run all verify commands
- Check diffs for scope violations or CONVENTIONS.md breaches

### 6. Integrate

Merge accepted results. If any agent's result conflicts with another, resolve manually and note the conflict.

Report a summary: which tasks succeeded, which need revision, and overall verify status.
