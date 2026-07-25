---
name: dispatch-agents
model: sonnet
effort: standard
description: Dispatch multiple subagents in parallel on independent tasks. No waiting between them — all run concurrently. Use when tasks are truly decoupled and speed matters. Distinct from delegate-task (concurrent here, no inter-task review gate).
---

# story: e09s04
# story: e45s38
<!-- story: e45s11 -->


# story: e45s30

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

## Subagent depth tiers (e45s30)

Map `effort:` frontmatter and story `risk:` to prompt depth — do not send `minimal_decisive` agents a `full_maturity` brief.

| Tier | When | Brief shape | Token budget |
|------|------|-------------|----------------|
| `full_maturity` | `effort: heavy`, `risk: P0`, security-sensitive diffs | Full `task_brief` + CONVENTIONS excerpts + threat model if present | Full envelope |
| `standard` | `effort: standard`, `risk: P1`–`P2` | Standard `task_brief` fields below | Default |
| `minimal_decisive` | `effort: light`, `risk: P3`, read-only exploration | `goal` + `verify` + `in_scope` only | ≤15 lines |

Record `depth: <tier>` in the Agent tool description when dispatching.

### 2. Write typed task briefs (Orca message protocol)

Before writing briefs, read `specs/state.yaml` if it exists — each agent gets only the decisions relevant to its task, nothing else.

Every inter-agent message uses a **typed envelope** — no freeform prose between waves:

| `type` | When | Required fields |
|--------|------|-----------------|
| `task_brief` | Dispatch | `task_id`, `goal`, `in_scope`, `out_of_bounds`, `verify`, `prior_decisions` |
| `checkpoint` | Mid-wave progress | `task_id`, `status` (`running`\|`blocked`), `comment` (one line) |
| `result` | Agent return | `task_id`, `exit` (`pass`\|`fail`), `summary`, `verify_output` |
| `circuit_open` | 3 consecutive failures | `task_id`, `failures` (3), `escalate_to` (`user`) |

Example `task_brief` (each agent starts cold — brief size directly controls token cost and hallucination risk):

```yaml
type: task_brief
task_id: agent-1
goal: [one sentence — what success looks like]
in_scope: [explicit file or module list]
out_of_bounds: [what NOT to touch]
verify: [runnable command]
prior_decisions: [relevant entries from specs/state.yaml — omit if none]
```

Emit **`checkpoint`** comments when an agent is slow or blocked — one line, no stack traces. Parent reads checkpoints before spawning follow-ups.

Do not include the full conversation, full file contents, or decisions unrelated to this agent's task.

### 3. Circuit breaker + iterative retrieval (max 3 cycles)

Track **consecutive failures per `task_id`**. On the **3rd consecutive `result.exit: fail`** for the same task, emit `type: circuit_open` and **stop dispatching** that task — escalate to user with the three failure summaries. Reset counter on any `pass`.

After each wave completes:
1. **Dispatch** — run parallel agents with typed `task_brief` envelopes.
2. **Evaluate** — read `result` messages; list gaps vs goal; honor open circuits.
3. **Refine** — tighten briefs or spawn follow-up agents (max **3 cycles** total).

Stop when gaps empty, circuit opens, or cycle 3 reached — escalate to user. If agents go silent without returning, invoke `diagnose-stall` before spawning another wave.

### 4. Dispatch in parallel

Spawn all agents in a single message using multiple Agent tool calls. Each agent gets its own complete brief.

```
Agent 1: brief for task A
Agent 2: brief for task B
Agent 3: brief for task C
```

### 5. Collect and review results

When all agents return: review each result, run verify commands, check diffs for scope violations.

### 6. Integrate

Merge accepted results. Resolve conflicts manually; note in summary.

Report: which tasks succeeded, which need revision, overall verify status.

## Verify
→ verify: `test -f skills/dispatch-agents/SKILL.md && test -f scripts/lib/completeness-critic.sh`

