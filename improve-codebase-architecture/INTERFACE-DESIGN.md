# Interface Design

When the user wants to explore alternative interfaces for a chosen deepening candidate, use this parallel sub-agent pattern. Based on "Design It Twice" (Ousterhout) — your first idea is unlikely to be the best.

## Process

### 1. Frame the problem space

Before spawning sub-agents, write a user-facing explanation of the problem space for the chosen candidate:

- The constraints any new interface would need to satisfy
- The dependencies it would need to rely on (see [DEEPENING.md](DEEPENING.md))
- A rough illustrative code sketch to ground the constraints — this is not a proposal, just a way to make the constraints concrete

Show this to the user, then immediately proceed to Step 2. The user reads and thinks while the sub-agents work in parallel.

### 2. Spawn sub-agents

Spawn 3+ sub-agents in parallel using the Agent tool. Each must produce a **radically different** interface for the deepened module.

Prompt each sub-agent with a separate technical brief (file paths, coupling details, dependency category from [DEEPENING.md](DEEPENING.md), what's being hidden). The brief is independent of the user-facing problem-space explanation in Step 1. Give each agent a different design constraint:

- Agent 1: "Minimize the interface — aim for 1-3 entry points max"
- Agent 2: "Maximize flexibility — support many use cases and extension"
- Agent 3: "Optimize for the most common caller — make the default case trivial"
- Agent 4 (if applicable): "Design around the ports & adapters pattern for cross-boundary dependencies"

Include CONTEXT.md vocabulary in the brief so each sub-agent names things consistently with the project's domain language.

Each sub-agent outputs:

1. Interface signature (types, methods, params)
2. Usage example showing how callers use it
3. What complexity it hides internally
4. Dependency strategy (see [DEEPENING.md](DEEPENING.md))
5. Trade-offs

### 3. Present and compare

Present designs sequentially so the user can absorb each one, then compare them in prose.

After comparing, give your own recommendation: which design you think is strongest and why. If elements from different designs would combine well, propose a hybrid. Be opinionated — the user wants a strong read, not a menu.
