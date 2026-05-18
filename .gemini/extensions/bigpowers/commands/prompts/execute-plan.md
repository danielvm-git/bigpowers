
# Execute Plan

Execute the tasks in `specs/PLAN.md` one at a time, showing evidence after each step before proceeding.

## Process

### 1. Read the plan

Read `specs/PLAN.md` in full. Confirm with the user:
- How many steps are there?
- Any steps to skip or reorder?
- Should you stop after a specific step?

### 2. Execute step by step

For each step in the plan:

**a. Announce the step**
```
─── Step N of M ─────────────────────────
Task: [step description]
verify: [verify command]
```

**b. Execute the work**
Implement the step using the appropriate approach:
- Write/edit code directly for small focused changes
- Spawn a subagent via `delegate-task` for complex isolated work

**c. Run the verify command**
Every step in `specs/PLAN.md` must have a `verify: <cmd>`. Run it and show the output.

**d. Checkpoint**
Report the result and ask: "Step N complete. Proceed to step N+1?" (or proceed automatically if the user asked for fully autonomous execution)

If verify fails:
- Do NOT move to the next step
- Diagnose the failure
- Fix it and re-run verify
- Only proceed when green

### 3. Handle blockers

If a step cannot be completed as written:
- Report the blocker clearly
- Ask the user whether to skip, adapt, or stop
- Update `specs/PLAN.md` if the plan needs revision

### 4. Final report

After all steps complete:
```
✓ Plan complete: N/N steps executed
All verify commands passed.
Suggested next: audit-code → commit-message → release-branch
```
