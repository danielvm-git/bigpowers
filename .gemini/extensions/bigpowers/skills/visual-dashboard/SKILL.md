---
name: visual-dashboard
description: "Start a browser-based dashboard that visualizes architecture, implementation plans, and project status. Use when showing complex diagrams, progress roadmaps, or UI mockups would be clearer than text. Persists artifacts in .bigpowers/dashboard/. Also maintains specs/STATE.md and specs/RELEASE-PLAN.md in the correct format for the opencode progress panel."
---


# Visual Dashboard

Browser-based visual companion for bigpowers. Visualizes architecture, plans, and status.

## Opencode Progress Panel

Projects using bigpowers in opencode get a **live progress panel** (right sidebar) that reads `specs/STATE.md` and `specs/RELEASE-PLAN.md` directly. Toggle it with the document icon (⬚) in the opencode session header.

### Spec file format requirements

**`specs/STATE.md`** — the parser extracts:
- Project name from `# Session State: <name>`
- Milestone from `## Current Milestone` → first `**bold**` = name, `(parens)` = status
- Pending items from `## Pending` → `- [ ]` / `- [x]` lines

```markdown
# Session State: my-project

## Current Milestone

**v1.0.0 — Feature Name** (in progress)

## Pending

- [ ] Remaining task
- [x] Completed task
```

**`specs/RELEASE-PLAN.md`** — the parser extracts:
- Workstreams from `### WSN — Title · WSJF N.N` headings
- Steps from `- [ ]` / `- [x]` lines inside each workstream block

```markdown
## Workstreams (WSJF order)

### WS1 — Feature Area · WSJF 4.5

- [x] Step already done
- [ ] Step pending

→ verify: `<command>`
```

**Parser rules:**
- Only `[ ]` and `[x]`/`[X]` are recognised as step markers.
- `→ verify:` lines are ignored.
- Steps outside a `### WSN —` block are not picked up.
- Missing `## Current Milestone` → panel shows "No specs found".

After completing a step, update the checkbox in-place; the panel auto-refreshes every 30 s or on manual ↺.


## When to Use

Use when the user would understand the project state better by seeing it than reading it.

- **Architecture maps** — visualizing module dependencies and "code rot."
- **Implementation progress** — seeing the vertical slices of a `PLAN.md` as a visual roadmap.
- **UI brainstorming** — wireframes and layout options.
- **Complexity audits** — visualizing "God classes" vs "Clean modules."

## How It Works

The server watches for updates to your artifacts and serves a dashboard to the browser. You write visual representations (HTML fragments) to the dashboard's `screen_dir`, and the user interacts with them.

## Starting a Session

```bash
# Start server with project persistence
visual-dashboard/scripts/start-server.sh --project-dir $(pwd)
```

Save the `url`, `screen_dir`, and `state_dir` from the response. Tell the user to open the dashboard.

## Dashboard Loops

### 1. The Architecture View
When using `deepen-architecture`, push a Mermaid diagram of the target modules to the dashboard.
Filename: `architecture.html`

### 2. The Plan View
When using `plan-work`, push a step-by-step progress map.
Filename: `plan.html`

### 3. User Interaction
Read `state_dir/events` to see which components or options the user clicked in the dashboard. Use this to refine your next design pass.

## Cleaning Up

```bash
visual-dashboard/scripts/stop-server.sh $SESSION_DIR
```
