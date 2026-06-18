# Workflow Artifacts & Metrics Reference

**Source of Truth:** `docs/WORKFLOW-SOP-v2.md` (pinned)  
**Purpose:** Artifact inventory, metrics targets, and dashboard monitoring details for the bigpowers SDLC.

---

## Artifact Inventory

All files live under `specs/` except where noted.

| Artifact | Created by | Updated by | Purpose |
|----------|-----------|------------|---------|
| `CLAUDE.md` | `seed-conventions` | Developer | Project instructions for Claude Code |
| `CONVENTIONS.md` | `seed-conventions` | Developer | Git, code style, skill rules |
| `.claude/settings.json` | `seed-conventions` | — | Claude Code agent config |
| `.gemini/extensions/bigpowers/` | `seed-conventions` via sync | `sync-skills.sh` | Gemini CLI skill artifacts |
| `.cursor/rules/` | `seed-conventions` via sync | `sync-skills.sh` | Cursor agent skill artifacts |
| `specs/state.yaml` | `orchestrate-project` | Every skill | Session state, active epic/story/step, metrics |
| `specs/release-plan.yaml` | `orchestrate-project` Ph 3 | `change-request` | BCP baseline, WSJF-ordered stories |
| `specs/product/SCOPE_LATEST.yaml` | `scope-work` | `change-request` | Project boundaries |
| `specs/product/VISION_LATEST.yaml` | `elaborate-spec` | Developer | Product vision |
| `specs/tech-architecture/TECH_STACK_LATEST.md` | `orchestrate-project` | Developer | Architecture decisions |
| `specs/epics/<eNN>-<name>.yaml` | `plan-work` | `plan-work` (per story) | BCP tasks + verify commands |
| `specs/execution-status.yaml` | `release-branch` | `release-branch` | Story/epic done status |
| `specs/metrics/cycle-times.yaml` | `release-branch` (first story) | `release-branch` (each story) | Per-story BCP/hr, cycle time |
| `specs/metrics/README.md` | `release-branch` (first story) | — | Metrics schema documentation |
| `specs/EVALS-<feature>.md` | `run-evals` | `run-evals` | Capability measurement results |
| `specs/bugs/BUG-*.md` | `investigate-bug` | `validate-fix` | Bug record and resolution |
| `CHANGELOG.md` | `semantic-release` | `semantic-release` | Auto-generated from Conventional Commits |

---

## Metrics

| Metric | Target | How to Measure | Written by |
|--------|--------|----------------|-----------|
| BCP/hr per story | ≥ 2.0 | `bcps / (cycle_minutes / 60)` | `release-branch` → `cycle-times.yaml` |
| Avg cycle time per story | ≤ 90 min | Mean of `cycle_minutes` across stories | `specs/metrics/cycle-times.yaml` |
| Code quality | ≥ 94% | `npm run compliance` output | `audit-code` |
| Test suite | 0 failures | `npm test` | `verify-work` (cold-start) |
| Semver progression | `feat:` → minor bump | `commit-message` analysis | `semantic-release` |
| Stories landed per epic | All planned BCPs | `specs/execution-status.yaml` | `release-branch` |

**Monitoring:** Run `npm run dashboard` (TUI) or `npm run dashboard:web` (browser on port 7742) to watch all metrics live as stories land.

---

## Dashboard Monitoring

| Command | Mode | What it shows |
|---------|------|---------------|
| `npm run dashboard` | TUI (terminal) | 6-panel blessed screen: pipeline · epic queue · action log · file system · state.yaml · cycle-time ledger |
| `npm run dashboard:web` | Browser (port 7742) | Same panels, served as live HTML via SSE |
| `Ctrl-R` (TUI) | — | Force refresh all panels |
| `F` (TUI) | — | Toggle file system panel |
| `L` (TUI) | — | Toggle cycle-time ledger |

The dashboard is **read-only**. It updates automatically via `chokidar` file watchers — no polling, no manual refresh needed.

---

## Semver Convention

| Stage | Version | How reached |
|-------|---------|-------------|
| Pre-delivery | `0.0.0-β` | Initial state after `orchestrate-project` |
| Per story feat | `0.N.0` | Each `feat:` commit via `commit-message` |
| Per story fix | `0.N.P` | Each `fix:` commit via `commit-message` |
| MVP release | `1.0.0` | Developer declares MVP; `npm run release` tags it |
| Post-MVP feat | `1.N.0` | Each `feat:` commit after MVP |
| Breaking change | `N.0.0` | `feat!:` or `BREAKING CHANGE:` footer |

The `1.0.0` tag is never automated — it is a deliberate human decision.
