---
# ─────────────────────────────────────────────────────────────────────
# OKF bundle — per-story delivery & efficiency metrics
# Format: OKF (markdown + YAML frontmatter). One file per story.
# Aggregation legend:  Σ additive (sum→total) · ⌀ median/p95 (never sum)
#                      % rate (ratio over window) · • static (identity)
# ─────────────────────────────────────────────────────────────────────
okf_kind: story-metrics
okf_version: "0.1"

# Identity & provenance ─ • static
id: e31s07
epic: e31
bcps: 1                         # Σ  scope estimate (Budgeted Change Points)
commit_range: "8823212..d1abc82"
source: measured                # measured | estimated | backfilled
generated_at: 2026-07-03T14:02:00Z
generator: scripts/record-cycle-time.sh

# DORA — the four keys (market standard; software-delivery latency/rates)
# Per story = raw event; the DORA metric itself is the cross-story aggregate.
dora:
  lead_time_for_changes_min: 5000   # ⌀  first commit → deploy/merge; aggregate by median
  deployment_frequency: 1           # %  deploys attributed to this story; Σ→rate/period
  change_failure: false             # %  did this change cause a failure? Σ→change-failure-rate
  time_to_restore_min: null         # ⌀  if failed: detect → restore; aggregate by median

# Agent code-generation telemetry (GSD-2 style; measures generation efficiency)
# Natively ADDITIVE — Σ over stories = project total.
agent:
  cost_usd: 0.047                   # Σ
  tokens: { input: 42150, output: 8300, cache_read: 60120, cache_write: 4100, total: 114670 }  # Σ
  cache_hit_rate_pct: 62            # %  cache_read / (cache_read + input)
  compression_savings_pct: 38       # %
  tool_calls: 14                    # Σ
  api_requests: 9                   # Σ
  agent_duration_ms: 45231          # Σ  real dispatch runtime (excludes human UAT wait)
  model: claude-sonnet-5
  tier: standard                    # light | standard | heavy  (dynamic routing)
  model_downgraded: false
  skills: [plan-work, develop-tdd, audit-code]

# Effort (git-derived fallback where no session telemetry; idle-stripped, ADDITIVE)
effort:
  effort_hours: 1.33                # Σ  gaps < idle_threshold; overnight/UAT gaps dropped
  idle_threshold_min: 120           # •  recorded so the number is interpretable

# Quality gate
quality:
  audit_score_pct: 96               # ⌀  ≥ 94 hard gate
  coverage_pct: 91                  # ⌀
  tests_passed: true                # •
  verify_status: pass               # pass | waived
  rework_count: 0                   # Σ  reopens → feeds change_failure

# Flow (worktree telemetry)
flow:
  merge_duration_ms: 3200           # ⌀  p50/p95 across stories
  merge_conflicts: 0                # Σ
  worktree_orphaned: false          # •
---

# Story metrics — e31s07

One OKF bundle per story. Machine-read for the dashboard/benchmark; human-read
here. Every field above carries an aggregation tag so a roll-up never sums a
metric that isn't additive.

## How each block rolls up to a benchmark

- **DORA (the four keys).** The industry standard for *software delivery*.
  Report `lead_time_for_changes` and `time_to_restore` as **medians** and
  `deployment_frequency` / `change_failure_rate` as **rates** over a window —
  never per-story headlines. Caveat for an AI pipeline: DORA measures delivery
  latency, not generation cost, so treat it as the "is it shippable at a healthy
  cadence" axis, not the efficiency axis.

- **Agent code-gen telemetry.** The efficiency axis. Cost, tokens, tool calls
  and dispatch duration are **additive** — `Σ` over stories is the true project
  total, and `getProjectTotals()`-style sums are exact. This is what varies with
  model/tier routing and what a cost benchmark should track.

- **Effort.** Additive, idle-stripped estimate from `git log` (120-min session
  threshold). Use only where session telemetry is unavailable (Cursor/Gemini);
  where the harness exposes usage (pi, Claude Code), prefer `agent.*`.

- **Quality & flow.** Gate scores aggregate by median; `rework_count` and
  `merge_conflicts` are additive and feed the DORA change-failure signal.

## Benchmark axes (future)

| Axis | Primary metric | Aggregation |
|---|---|---|
| Delivery health | dora.lead_time_for_changes_min | median |
| Delivery reliability | dora.change_failure (rate), time_to_restore | rate / median |
| Generation cost | agent.cost_usd, agent.tokens.total | sum |
| Routing efficiency | agent.tier mix, cache_hit_rate_pct, model_downgraded | ratio |
| Quality | quality.audit_score_pct, rework_count | median / sum |

## Provenance gate (do not gate on values)

A row is valid iff (a) `generator` ran and (b) `commit_range` resolves to real
commits. Never gate on a specific `lead_time` or `effort_hours` value — these
are estimates/latencies, not pass/fail numbers. Gate on provenance and freshness.
