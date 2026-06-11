# Plan: bigpowers factory dashboard

**Created:** 2026-06-10  
**Status:** ready  
**Target version:** 1.0.0 (standalone tool, versioned independently)  
**Scope baseline:** 18 BCPs across 3 epics  
**Entry skill:** `orchestrate-project` → `build-epic` × each story below  
**Delivery:** `dashboard/` directory at bigpowers project root, launchable via `npm run dashboard`

---

## Context

The factory simulator widget (2026-06-10 session) demonstrated the ideal mental model for monitoring a live bigpowers project: pipeline stations, epic queue with BCP tracking, live state.yaml inspection, file system evolution, and a cycle-time ledger. This plan builds a real version of that simulator that reads from the actual project files.

Two delivery modes are in scope:

- **TUI** (default) — runs in the terminal alongside Claude Code, no browser required. Uses Node.js + blessed or ink. Ideal for solo developer workflow.
- **Web** (optional, same data layer) — serves a local HTML page (port 7742) with the same panels. The widget from the simulation session is the visual reference.

The data layer is shared. The rendering layer is swapped.

---

## Success criteria

- `npm run dashboard` launches the TUI in the current terminal within 2 seconds.
- The TUI refreshes automatically when `specs/state.yaml`, `specs/execution-status.yaml`, or `specs/metrics/cycle-times.yaml` changes on disk.
- The 8-step pipeline highlights the active station from `state.yaml epic_cycle.current_step`.
- The epic queue reads `specs/epics/*.yaml` and shows BCP counts per story.
- The cycle-time ledger reads `specs/metrics/cycle-times.yaml` and shows BCP/hr, cycle minutes, start/end per story.
- The file system panel lists `specs/` contents with last-modified timestamps.
- `npm run dashboard -- --web` starts a local server at port 7742 serving the web view.
- All panels degrade gracefully when files do not yet exist (shows "—" not errors).

---

## Release plan

| epic | title | BCPs | target |
|------|-------|------|--------|
| e01 | Data layer — file watchers + parsers | 6 | v0.2.0 |
| e02 | TUI rendering (blessed) | 7 | v0.4.0 |
| e03 | Web mode + packaging | 5 | v1.0.0 |

---

## Architecture

```
dashboard/
├── package.json          # scripts: start (TUI), web (serve), build
├── src/
│   ├── data/
│   │   ├── reader.js     # parse state.yaml, execution-status, cycle-times
│   │   ├── watcher.js    # chokidar file watcher → event emitter
│   │   └── metrics.js    # compute BCP/hr, avg cycle, totals
│   ├── tui/
│   │   ├── index.js      # blessed screen setup + layout
│   │   ├── pipeline.js   # 8-station pipeline panel
│   │   ├── epic-queue.js # epic/story/BCP tree panel
│   │   ├── action.js     # current skill + log panel
│   │   ├── filesystem.js # specs/ directory tree panel
│   │   ├── state-yaml.js # state.yaml key-value inspector panel
│   │   └── ledger.js     # cycle-time table panel
│   └── web/
│       ├── server.js     # express static + SSE endpoint
│       └── client.html   # self-contained HTML (the factory widget, live data)
└── bin/
    └── dashboard.js      # CLI entry point (--web flag)
```

Data flow:
```
specs/*.yaml  →  watcher.js  →  reader.js  →  metrics.js
                                                    ↓
                                          tui/index.js  OR  web/server.js (SSE)
                                                    ↓
                                          terminal panels  OR  browser widget
```

---

## Epic e01 — Data layer (6 BCPs)

### e01s01 · YAML reader + schema types (2 BCPs)

Parse all four bigpowers data files into typed JS objects. Must handle missing files gracefully.

Tasks:
- [BCP 1] Write `src/data/reader.js`:
  - `readStateYaml(projectRoot)` → `{ activeFlow, activeEpic, activeStory, epicCycle, gateStatus, gitBranch, metrics }`
  - `readExecutionStatus(projectRoot)` → `{ epics: Map<id, 'pending'|'active'|'done'> }`
  - `readEpicShards(projectRoot)` → `Array<{ id, title, stories: Array<{ id, title, bcps }> }>`
  - `readCycleTimes(projectRoot)` → `Array<{ id, bcps, start, end, cycleMin, bcpPerHour }>`
  - All functions return `null` when the file does not exist (no throws).
  - verify: `node -e "const r=require('./src/data/reader'); console.log(r.readStateYaml('.'))"` prints object or null
- [BCP 2] Write `src/data/metrics.js`:
  - `computeEpicMetrics(cycleTimes)` → per-epic avg cycle, total BCPs, avg BCP/hr
  - `computeProjectMetrics(cycleTimes)` → project-level totals and averages
  - `computeCurrentVelocity(cycleTimes, windowStories=3)` → rolling avg of last N stories
  - verify: `node -e "const m=require('./src/data/metrics'); console.log(m.computeProjectMetrics([{bcps:3,cycleMin:90},{bcps:2,cycleMin:70}]))"` returns `{ totalBcps: 5, totalMin: 160, avgBphPerHour: 1.9 }`

### e01s02 · File watcher with debounce (2 BCPs)

Tasks:
- [BCP 3] Write `src/data/watcher.js`:
  - Uses `chokidar` to watch `specs/state.yaml`, `specs/execution-status.yaml`, `specs/metrics/cycle-times.yaml`, `specs/epics/`
  - Emits `'change'` event with `{ file, data }` payload where data is the parsed object
  - Debounces rapid writes (300ms) to avoid partial-write flicker
  - verify: `node -e "const w=require('./src/data/watcher'); w.watch('.').on('change', d => console.log(d.file))"` then `touch specs/state.yaml` → prints path within 400ms
- [BCP 4] Write integration test: modify `specs/state.yaml` programmatically, assert watcher fires within 500ms with updated parsed data.
  - verify: `node test/watcher.test.js` exits 0

### e01s03 · Pipeline step mapper (2 BCPs)

Map `epic_cycle.current_step` string values from state.yaml to pipeline station indices (0–7).

Tasks:
- [BCP 5] Write `src/data/pipeline-map.js`:
  ```js
  const STEPS = ['survey-context','plan-work','kickoff-branch','develop-tdd',
                 'verify-work','audit-code','commit-message','release-branch'];
  function stepIndex(currentStep) { return STEPS.indexOf(currentStep); }
  function stepLabel(index) { return STEPS[index] || '—'; }
  ```
  - verify: `node -e "const p=require('./src/data/pipeline-map'); console.log(p.stepIndex('develop-tdd'))"` prints 3
- [BCP 6] Write `src/data/gate-status.js`: map `gate_status` string → color token (`ready→green`, `blocked→red`, `in_progress→yellow`, `—→dim`).
  - verify: `node -e "const g=require('./src/data/gate-status'); console.log(g.gateColor('ready'))"` prints `green`

---

## Epic e02 — TUI rendering (7 BCPs)

**Library:** `blessed` (Node.js terminal UI). Fallback option: `ink` (React for terminals).

### e02s01 · Screen layout + pipeline panel (2 BCPs)

Tasks:
- [BCP 7] Write `src/tui/index.js`:
  - Create blessed screen (256-color, full-width, smart-CSR)
  - Define 6-zone grid layout matching the factory widget:
    ```
    ┌─ metrics bar ────────────────────────────────────┐
    ├─ pipeline (8 stations) ──────────────────────────┤
    ├─ epic queue ──┬─ action + log ──┬─ file system ──┤
    ├─ state.yaml ─────────────────────────────────────┤
    └─ cycle-time ledger ──────────────────────────────┘
    ```
  - Wire watcher events → re-render all panels
  - verify: `npm run dashboard` opens a full-terminal blessed screen without errors; `q` exits cleanly
- [BCP 8] Write `src/tui/pipeline.js`:
  - Render 8 station boxes in a horizontal row
  - Active station: reverse-video highlight + blinking cursor
  - Done stations: green foreground
  - Pending stations: dim
  - verify: set `state.yaml epic_cycle.current_step: develop-tdd` → station 4 highlights within 400ms of file save

### e02s02 · Epic queue + metrics bar (2 BCPs)

Tasks:
- [BCP 9] Write `src/tui/epic-queue.js`:
  - Tree view: epic label → story items indented, each showing `[BCP N]` count
  - Status dots: `●` green = done, `◉` blue+blink = active, `○` dim = pending
  - Footer: release baseline totals (total BCPs, target version)
  - verify: place a test `specs/epics/e01-test.yaml` with 2 stories → both appear in panel
- [BCP 10] Write `src/tui/metrics-bar.js`:
  - Top bar with 6 metric cells: epics done, stories done, BCPs delivered, avg cycle, BCP/hr (color-coded ≥2.0=green), semver
  - All values read from metrics.js computed output
  - verify: mock cycle-times with 2 stories → BCP/hr cell shows correct value

### e02s03 · State.yaml inspector + cycle-time ledger (3 BCPs)

Tasks:
- [BCP 11] Write `src/tui/state-yaml.js`:
  - Key-value grid showing 8 fields: active_flow, active_epic, active_story, epic_cycle.current_step, handoff.next_skill, gate_status, git.branch, metrics.story_start
  - Color-code values: branch=main→green, branch=feat/*→yellow, gate_status=ready→green, gate_status=blocked→red
  - verify: update `state.yaml git.branch: feat/test` → branch cell turns yellow within 400ms
- [BCP 12] Write `src/tui/ledger.js`:
  - Table: story | epic | BCPs | start | end | cycle | BCP/hr
  - Running totals row at bottom: avg cycle, total BCPs, avg BCP/hr
  - Empty state: "no completed stories yet"
  - verify: add one entry to `specs/metrics/cycle-times.yaml` → row appears in ledger
- [BCP 13] Write `src/tui/filesystem.js`:
  - Tree view of `specs/` directory, 2 levels deep
  - Files modified in last 60 seconds highlighted in yellow
  - File count badge: "specs/ — 12 files"
  - verify: `touch specs/state.yaml` → that file highlights yellow, clears after 60s

---

## Epic e03 — Web mode + packaging (5 BCPs)

### e03s01 · SSE server for live web data (2 BCPs)

The web client (client.html) is the factory simulator widget adapted to receive live data via Server-Sent Events instead of a static FRAMES array.

Tasks:
- [BCP 14] Write `src/web/server.js`:
  - Express app on port 7742 (configurable via `--port`)
  - `GET /` → serves `client.html`
  - `GET /api/state` → returns current full dashboard snapshot as JSON
  - `GET /events` → SSE endpoint; pushes a snapshot whenever watcher fires a `'change'` event
  - verify: `curl http://localhost:7742/api/state` returns JSON with all dashboard fields
- [BCP 15] Adapt `src/web/client.html` from the factory simulator widget:
  - Replace the static `FRAMES` array with a live data fetch on load + SSE listener
  - `const es = new EventSource('/events'); es.onmessage = e => render(JSON.parse(e.data));`
  - Remove play/pause/step controls (not needed for live view); keep speed selector for refresh debounce
  - verify: open `http://localhost:7742`, update `specs/state.yaml`, browser panel updates within 500ms without page reload

### e03s02 · CLI entry point + npm scripts (2 BCPs)

Tasks:
- [BCP 16] Write `bin/dashboard.js`:
  - `--web` flag → start web server and print `Dashboard: http://localhost:7742`
  - `--port N` → override default port
  - `--project <path>` → watch a different project root (default: cwd)
  - `--help` → usage
  - verify: `node bin/dashboard.js --help` prints usage without error
- [BCP 17] Update `bigpowers/package.json` scripts:
  ```json
  "dashboard": "node dashboard/bin/dashboard.js",
  "dashboard:web": "node dashboard/bin/dashboard.js --web"
  ```
  - verify: `npm run dashboard -- --help` works from bigpowers project root

### e03s03 · Dependency install + smoke test (1 BCP)

Tasks:
- [BCP 18] Write `dashboard/package.json` with pinned deps:
  ```json
  {
    "dependencies": {
      "blessed": "0.1.81",
      "chokidar": "3.6.0",
      "express": "4.19.0",
      "js-yaml": "4.1.0"
    }
  }
  ```
  Run `npm install` inside `dashboard/`. Write a smoke test that:
  - Imports reader, metrics, pipeline-map, gate-status with no errors
  - Reads a fixture `test/fixtures/state.yaml` and asserts parsed values
  - verify: `cd dashboard && npm test` exits 0

---

## UX decisions

**TUI key bindings:**
- `q` / `Ctrl-C` — quit
- `r` — force refresh (re-read all files)
- `f` — toggle file system panel (hide/show to save space on small terminals)
- `l` — toggle cycle-time ledger
- `?` — help overlay

**Web refresh strategy:**
- SSE pushes on every file change (debounced 300ms)
- If SSE disconnects, client polls `/api/state` every 5s as fallback
- No WebSocket dependency — SSE is sufficient for one-way push

**Terminal size handling:**
- Minimum: 120×30. If terminal is smaller, show a resize prompt.
- Responsive: epic queue panel collapses to icon-only at < 140 cols.

**Missing data handling:**
- Any file not found → panel shows "— not started yet —" in dim color
- Parser errors → panel shows "⚠ parse error: <filename>" in red
- Never crash the dashboard on a malformed YAML file

---

## Never

- Never read files outside the project root passed to `--project`.
- Never write to any file — dashboard is read-only.
- Never open a browser automatically — print the URL and let the user decide.
- Never bundle heavy dependencies (no webpack, no vite) — keep it a plain Node.js script.
- Never use `setInterval` for refresh — use file watchers only (no polling in TUI mode).
