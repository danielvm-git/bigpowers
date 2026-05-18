
# Visual Dashboard

Browser-based visual companion for bigpowers. Visualizes architecture, plans, and status.

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
