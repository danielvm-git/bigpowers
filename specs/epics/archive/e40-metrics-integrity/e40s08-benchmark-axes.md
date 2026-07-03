STORY KEY: E40-S08
TITLE:     Benchmark axes scaffold in specs/benchmarks using OKF bundles (delivery, reliability, cost, routing, quality)
TYPE:      Story
PARENT:    e40
STATUS:    Draft
AUTHOR:    dvm           DATE: 2026-07-03
MATURITY:  3
SIZE:      S

### 1. Business narrative
The OKF story-metrics bundles (e40s03) contain structured data across five
axes: delivery (DORA lead time, deploy frequency), reliability (change failure,
time to restore), generation cost (agent cost, tokens), routing efficiency
(model tier, cache hit rate), and quality (audit score, rework count). The
existing specs/benchmarks/ schema (e23 run-benchmark) tracks skill quality
but has no delivery or cost axes. Wiring the OKF benchmark-axes table into
the benchmarks schema enables cross-run efficiency/delivery comparison — the
missing dimension that makes the benchmark actionable for cost-and-speed
trade-offs.

### 2. Value statement
As a maintainer evaluating a model routing change, I want to see cost and
delivery benchmarks alongside quality benchmarks, so I can make
data-informed trade-offs instead of guessing.

### 3. Actors and permissions
- run-benchmark skill (system) — reads benchmark axes for cross-run comparison.
- CI runner (system) — collects benchmark data over time.

### 4. Trigger and preconditions
Trigger: run-benchmark execution (e23).
Precondition: OKF story-metrics bundles exist in specs/metrics/.
Precondition: specs/benchmarks/ directory exists.

### 5. Main flow and business logic
1. Read the benchmark-axes table from specs/templates/story-metrics.okf.md:
   - Delivery health: dora.lead_time_for_changes_min (median)
   - Delivery reliability: dora.change_failure (rate), time_to_restore (median)
   - Generation cost: agent.cost_usd, agent.tokens.total (sum)
   - Routing efficiency: agent.tier mix, cache_hit_rate_pct, model_downgraded (ratio)
   - Quality: quality.audit_score_pct (median), rework_count (sum)
2. Scaffold these axes in specs/benchmarks/ as benchmark definitions.
3. Wire run-benchmark to collect cross-run data from OKF bundles.
4. Output: benchmark report with delivery/cost/quality axes alongside skill quality.

### 6-16. Not applicable (standard benchmark scaffold pattern)

### 17. Acceptance criteria
Scenario: Benchmark axes scaffolded
  GIVEN specs/benchmarks/ directory exists
  WHEN the OKF benchmark axes are scaffolded
  THEN test -d specs/benchmarks exits 0
  AND grep -rq 'generation cost|lead_time|cost_usd' specs/benchmarks exits 0
  AND run-benchmark can collect cross-run data from OKF bundles

### 18. Out of scope
- Running benchmarks (this is the scaffold — data collection and comparison runs later).
- Building a benchmark dashboard (deferred to visual-dashboard).

### 19. Open questions
- Should benchmark axes be defined as YAML configs or OKF bundles themselves?
  YAML configs for now — the benchmark framework already uses YAML (g-*.yaml).
  OKF-ification of benchmarks is a future evolution.

### 20. References
- specs/templates/story-metrics.okf.md (benchmark axes table).
- specs/benchmarks/ (target directory).
- skills/run-benchmark/SKILL.md (e23, consumer of benchmark axes).
