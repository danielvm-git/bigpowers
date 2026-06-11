---
name: delegate-task
description: "Delegate one complex task to a single subagent, review its work in two stages before merging back. Sequential — one agent at a time, with oversight. Use when a task is complex and requires careful review before the result is accepted. Distinct from dispatch-agents (no parallelism here; reviewer sees full diff before proceeding)."
---


# Delegate Task
> **HARD GATE** — **HARD GATE** — Delegated work must have clear success criteria and verification commands. The delegate must be able to verify completion independently.


Delegate a single complex task to a subagent with a two-stage review gate before accepting the result. Use when oversight of a single task matters more than speed.

**Distinct from `dispatch-agents`:** This skill runs one subagent sequentially with a mandatory review. `dispatch-agents` runs multiple subagents in parallel without inter-task review gates.

## Process

### 1. Define the task

Before spawning the agent, read `specs/state.yaml` if it exists. Then write a minimal self-contained brief using this template (brief size directly controls token cost and hallucination risk — do not pad):

```
Goal: [one sentence — specific, measurable outcome]
In scope: [explicit file or module list]
Out of bounds: [what NOT to do]
Constraints: [relevant CONVENTIONS.md rules, existing patterns, test requirements]
Verify: [runnable command]
Prior decisions: [relevant entries from specs/state.yaml — omit section if none apply]
```

Do not include full file contents, full conversation history, or decisions unrelated to this task.

### 2. Spawn the subagent (iterative retrieval, max 3 cycles)

Use the Agent tool with a **fresh context** per spawn. Pass prior decisions only via `specs/state.yaml`.

**Cycle:** dispatch → evaluate output vs goal → refine brief → re-spawn if needed (max 3 cycles).

Include in each brief:
- All context the agent needs (it starts cold — no shared state)
- Reference to CONVENTIONS.md constraints
- The verify command it must run before reporting done

### 3. Stage 1 review — output inspection

When the subagent returns, review its report before looking at the diff:
- Did it run the verify command? Did it pass?
- Does it explain what it changed and why?
- Are there any concerns raised by the agent?

If the report raises red flags, ask the subagent for clarification or re-run with adjusted instructions.

### 4. Stage 2 review — diff inspection

Inspect the actual diff:
```bash
git diff main...HEAD
```

Check:
- [ ] Changes are scoped to what was asked — nothing extra
- [ ] No `any`, no `@ts-ignore`, no disabled lint rules
- [ ] Tests added for new behavior
- [ ] CONVENTIONS.md compliance (naming, structure, no gh issue creation)
- [ ] Boy Scout Rule: touched areas are cleaner than before

### 5. Decision

- **Accept**: merge the result into the main working branch
- **Revise**: send back to the subagent with specific feedback
- **Reject**: discard and re-approach differently

**After accepting**, append to `specs/state.yaml` under `## Active Decisions`:
```
**[task short name]**: [what approach the agent chose and why — one sentence]
```

Report the decision and rationale to the user.
