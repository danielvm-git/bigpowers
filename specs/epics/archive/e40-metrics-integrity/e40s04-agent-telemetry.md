STORY KEY: E40-S04
TITLE:     Agent code-gen telemetry capture where harness exposes usage (pi, Claude Code): cost, tokens, cache_hit, tier, tool_calls
TYPE:      Story
PARENT:    e40
STATUS:    Draft
AUTHOR:    dvm           DATE: 2026-07-03
MATURITY:  3
SIZE:      M

### 1. Business narrative
Git-derived effort is a fallback — it approximates coding time from commit
spacing but cannot measure agent cost, token consumption, cache efficiency,
or model routing decisions. Where the harness exposes usage (pi, Claude Code),
capturing session telemetry (cost, tokens, cache_hit, tier, tool_calls) provides
a naturally additive measurement: Σ over stories = exact project total, no idle
heuristic needed. The GSD-2/gsd-pi model (metrics.ts snapshotUnitMetrics) shows
the pattern. Where no session usage is available (Cursor, Gemini), fall back to
git effort.

### 2. Value statement
As a cost-conscious maintainer, I want to know how much agent time and money
each story consumed, so I can benchmark model routing decisions and track
cost trends.

### 3. Actors and permissions
- record-cycle-time.sh (system) — captures telemetry where available.
- Agent harness (external) — exposes usage data.

### 4. Trigger and preconditions
Trigger: record-cycle-time.sh append invocation.
Precondition: session usage data available (pi: metrics, Claude Code: usage events).
Fallback: git effort where no session data.

### 5. Main flow and business logic
1. record-cycle-time.sh checks for session usage data.
2. If available: capture cost_usd, tokens (input, output, cache_read, cache_write, total), cache_hit_rate_pct, tool_calls, api_requests, agent_duration_ms, model, tier.
3. If unavailable: fall back to git-derived effort.
4. All telemetry fields are Σ additive — sum exactly to project total.
5. Human UAT wait falls between dispatches → never counted.

### 6. Alternative flows and exceptions
6a. Partial session data — capture what's available, mark rest as "estimated."
6b. Multiple models used in one story — capture model_downgraded flag, note routing path.

### 7-16. Not applicable (standard telemetry capture pattern)

### 17. Acceptance criteria
Scenario: Telemetry captured where available
  GIVEN a pi or Claude Code session for a story
  WHEN record-cycle-time.sh append runs
  THEN the OKF bundle includes agent.cost_usd, tokens, cache_hit, tier
  AND grep -rq 'cost_usd|tokens.total|cache_hit_rate|agent_duration_ms' specs/templates/story-metrics.okf.md scripts/ 2>/dev/null exits 0

### 18. Out of scope
- Capturing telemetry from unsupported harnesses (Cursor, Gemini — they fall back to git effort).
- Real-time telemetry streaming (this is per-story snapshot at merge time).

### 19. Open questions
- How to detect which harness was used for a story? From agent-dispatch metadata
  or story tags — deferred to implementation.

### 20. References
- GSD-2/gsd-pi metrics.ts snapshotUnitMetrics (pattern reference).
- specs/templates/story-metrics.okf.md (bundle template).
- scripts/record-cycle-time.sh (e40s01).
