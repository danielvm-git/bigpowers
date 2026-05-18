
# Delegate Task

Delegate a single complex task to a subagent with a two-stage review gate before accepting the result. Use when oversight of a single task matters more than speed.

**Distinct from `dispatch-agents`:** This skill runs one subagent sequentially with a mandatory review. `dispatch-agents` runs multiple subagents in parallel without inter-task review gates.

## Process

### 1. Define the task

Before spawning the agent, write a complete, self-contained task brief:
- What needs to be done (specific, measurable outcome)
- What files/modules are relevant
- What constraints apply (CONVENTIONS.md, existing patterns, test requirements)
- What the verify step is (`verify: <runnable command>`)
- What NOT to do (scope boundaries)

### 2. Spawn the subagent

Use the Agent tool to spawn the subagent with the complete brief. Include:
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

Report the decision and rationale to the user.
