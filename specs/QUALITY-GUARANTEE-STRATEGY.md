# Quality Guarantee Strategy: How to Prove Each Improvement Is Actually an Improvement

> Generated: 2026-07-02
> Question: How can we guarantee the skillset is better after each improvement? Can we test performance, quality, token expenditure as we go? Is there a benchmark or custom strategy — maybe a set of stories we always execute and measure?

---

## Table of Contents

1. [What Already Exists](#1-what-already-exists)
2. [The Gap](#2-the-gap)
3. [The Strategy: Three Gates](#3-the-strategy-three-gates)
4. [Gate 1: Golden Story Suite](#4-gate-1-golden-story-suite)
5. [Gate 2: Compliance Regression (existing, needs wiring)](#5-gate-2-compliance-regression)
6. [Gate 3: Token & Latency Budget](#6-gate-3-token--latency-budget)
7. [The "Always Execute" Stories](#7-the-always-execute-stories)
8. [Metrics Dashboard](#8-metrics-dashboard)
9. [Workflow: How to Run It Per Epic](#9-workflow-how-to-run-it-per-epic)
10. [Implementation Plan](#10-implementation-plan)

---

## 1. What Already Exists

bigpowers has four pieces of quality infrastructure, but they're not connected:

| Asset | Location | What it does | Status |
|-------|----------|-------------|--------|
| Benchmark schema | specs/benchmarks/SCHEMA.md | Defines pass@k YAML format with code/rubric graders | Complete |
| Benchmark definitions | specs/benchmarks/{develop-tdd,survey-context,verify-work}.yaml | 3 skills have scenario definitions | 3 of 72 skills (4%) |
| run-benchmark skill | skills/run-benchmark/ | Executes benchmark YAMLs, writes pass@k reports | Working |
| evolve-skill skill | skills/evolve-skill/ | Baseline → change → re-benchmark → ADR loop | Working |
| Gherkin compliance | specs/verifications/features/*.feature | 6 .feature files checking CONVENTIONS.md adherence | Working, 94% threshold |
| npm run compliance | scripts/audit-compliance.sh | Runs Gherkin audit with binary/gemini judge | Working |
| bp-timing.sh | scripts/bp-timing.sh | Records skill invocation start/end timestamps to state.yaml | Exists, not wired to benchmarks |
| BCP/hr tracking | specs/metrics/cycle-times.yaml | Per-story BCP, cycle minutes, velocity | Working |

## 2. The Gap

The infrastructure exists but has five gaps that prevent it from guaranteeing improvement:

**Gap 1: Coverage.** Only 3 of 72 skills have benchmark definitions. The other 69 have no measurable quality gate. When you change sync-skills.sh or CONVENTIONS.md, there's no benchmark that catches a regression in, say, plan-work or audit-code.

**Gap 2: No golden stories.** There's no canonical set of end-to-end stories that get re-run after every change. The existing benchmarks test individual skills in isolation (rubric-graded), not skill chains. A change to survey-context might break the survey-context → plan-work → kickoff-branch chain even if survey-context's own benchmark passes.

**Gap 3: No token measurement.** bp-timing.sh records wall-clock time but not token expenditure. GSD Core uses `effort:` frontmatter to signal token budget; bigpowers has nothing. When you deepen a skill (add more behavior behind the interface), you might increase token cost per invocation. Without measurement, you can't tell if the leverage is worth the cost.

**Gap 4: No CI gate.** `npm run compliance` runs in CI and enforces 94%. But `run-benchmark` does not. A skill can regress on its benchmark and still merge. The evolve-skill loop requires manual re-benchmarking — it's not enforced.

**Gap 5: Rubric graders are subjective.** Most existing benchmark scenarios use `type: rubric` (LLM-judged yes/no questions). These are non-deterministic, expensive, and hard to run in CI. Code graders (exit 0/1) are deterministic and cheap but only work for machine-verifiable outputs.

## 3. The Strategy: Three Gates

Every improvement (epic, story, or skill edit) must pass three gates before merging:

```
Change → Gate 1: Golden Story Suite (end-to-end behavioral)
       → Gate 2: Compliance Regression (Gherkin, existing)
       → Gate 3: Token & Latency Budget (cost check)
       → Merge if all three pass or improve
```

- **Gate 1** answers: "Did the skill chain still produce the right output?"
- **Gate 2** answers: "Did the change break any CONVENTIONS.md rule?"
- **Gate 3** answers: "Did the change make the agent slower or more expensive?"

If any gate regresses, the change is blocked or must justify the tradeoff in an ADR.

## 4. Gate 1: Golden Story Suite

### Concept

A fixed set of 5-8 end-to-end stories that exercise the full skill chain. Each story is a self-contained scenario with:
- A starting state (fixture repo or specs/ state)
- A user prompt
- A set of expected artifacts (files created, state.yaml keys set, verify commands passing)
- A code grader (deterministic, not rubric)

These stories never change. They are the regression baseline. After any improvement, you run the full suite. If any story fails that passed before, you have a regression.

### Why end-to-end, not per-skill

Per-skill benchmarks (the existing specs/benchmarks/*.yaml) catch skill-level regressions. But the real failure mode is chain-level: survey-context loads state → plan-work writes tasks → kickoff-branch creates worktree → develop-tdd implements. A change to state.yaml's schema might pass survey-context's own benchmark but break the handoff to plan-work. Golden stories catch this.

### Why code graders, not rubric

Rubric graders require an LLM judge per run — expensive, non-deterministic, CI-unfriendly. Code graders (bash exit 0/1) are free, deterministic, and run in seconds. The golden stories should assert on observable artifacts (files exist, grep matches, YAML keys present, verify commands pass), not on subjective quality.

### What a golden story looks like

```yaml
# specs/benchmarks/golden/g-01-add-validation-rule.yaml
id: g-01
name: "Add a validation rule to an existing function (full cycle)"
chain: survey-context → plan-work → kickoff-branch → develop-tdd → verify-work → audit-code
setup:
  fixture_repo: "specs/benchmarks/fixtures/minimal-api"
  branch: "feat/add-email-validation"
  state_yaml:
    active_flow: build_epic
    epic_cycle:
      current_epic: e99
      current_story: e99s01
prompt: |
  "Add email format validation to the createUser function in src/users.js.
  Reject emails without @. Write a test for the validation."
expected_artifacts:
  - path: "specs/epics/e99/e99s01-tasks.yaml"
    assert: "exists"
  - path: "src/users.js"
    assert: "grep -q 'email.*@' src/users.js"
  - path: "src/users.test.js"
    assert: "grep -q 'createUser.*invalid.*email' src/users.test.js"
  - path: "specs/state.yaml"
    assert: "grep -q 'next_skill: release-branch' specs/state.yaml"
grader:
  type: code
  command: |
    test -f specs/epics/e99/e99s01-tasks.yaml &&
    grep -q 'email.*@' src/users.js &&
    grep -q 'createUser.*invalid.*email' src/users.test.js &&
    grep -q 'next_skill: release-branch' specs/state.yaml
weight: 1.0
```

### How it runs

```bash
# Run the full golden suite
bash scripts/run-golden-suite.sh

# Output:
# g-01: PASS (12.3s)
# g-02: PASS (8.1s)
# g-03: FAIL — expected artifact missing: src/users.test.js
# g-04: PASS (15.7s)
# g-05: PASS (9.2s)
# ---
# Suite: 4/5 passed (80%), 1 regression
```

The script:
1. For each golden story YAML in specs/benchmarks/golden/
2. Copies the fixture repo to a temp directory
3. Seeds state.yaml from the story's setup
4. Runs the skill chain (or a mock agent that follows the chain)
5. Runs the grader command
6. Records pass/fail + wall-clock time
7. Compares against the last baseline run

## 5. Gate 2: Compliance Regression

This already exists and works. The only change needed: **wire it into the golden suite runner** so it runs automatically, not just via `npm run compliance`.

Currently:
- `npm run compliance` checks Gherkin features against the repo
- 94% threshold = hard stop
- But it's a separate command that developers must remember to run

Change: `scripts/run-golden-suite.sh` calls `npm run compliance` as its first step. If compliance < 94%, the suite fails before any golden stories run. This makes the compliance gate mandatory for every improvement, not just CI.

## 6. Gate 3: Token & Latency Budget

### What to measure

For each golden story run, record:
- **Wall-clock time** (already possible via bp-timing.sh)
- **Token expenditure** (input + output tokens per skill invocation)
- **Skill invocation count** (how many skills were loaded)
- **Context window pressure** (approximate tokens consumed at peak)

### How to measure tokens

Two approaches:

**Approach A: API-level (accurate, requires instrumentation)**
If the agent runs through an API that returns token usage (Claude API, OpenAI API), wrap each skill invocation in a token-counting shim. Record input_tokens + output_tokens per skill. This is the GSD approach — they track context headroom via lifecycle hooks.

**Approach B: Heuristic (approximate, no instrumentation)**
Estimate token cost from:
- SKILL.md file size (1 token ≈ 4 chars) — the cost of loading the skill
- state.yaml size — the cost of loading context
- Number of tool calls — each tool call has overhead

This is less accurate but works without API access. Formula:
```
estimated_tokens = sum(SKILL.md sizes loaded) + state.yaml_size + (tool_calls * 500)
```

### Budget enforcement

For each golden story, record a token baseline. After a change:
- If tokens increased by > 20% → WARNING (review the tradeoff)
- If tokens increased by > 50% → BLOCKED (the deepening isn't worth the cost)
- If tokens decreased → BONUS (the change improved efficiency)

### Where to store

Extend the golden suite report:
```yaml
# specs/benchmarks/reports/GOLDEN-<YYYY-MM-DD>.yaml
date: "2026-07-02"
stories:
  - id: g-01
    result: PASS
    wall_clock_seconds: 12.3
    estimated_tokens: 8200
    skills_invoked: 6
  - id: g-02
    result: PASS
    wall_clock_seconds: 8.1
    estimated_tokens: 5100
    skills_invoked: 4
summary:
  pass_rate: 0.80
  total_tokens: 28400
  total_seconds: 45.3
  regression: ["g-03"]
  token_delta_vs_baseline: "+12%"
```

## 7. The "Always Execute" Stories

These are the 5 golden stories that run after every improvement. Each exercises a different skill chain and a different aspect of the methodology.

### Story G-01: Add a validation rule (Build cycle)
**Chain**: survey-context → plan-work → kickoff-branch → develop-tdd → verify-work → audit-code
**Tests**: The core build-epic cycle. Verifies that a small feature addition flows through the full pipeline and produces the expected artifacts (task file, implementation, test, state.yaml handoff).
**Fixtures**: A minimal Node.js API with one function (createUser) and one test file.

### Story G-02: Investigate and fix a bug (Bug cycle)
**Chain**: investigate-bug → diagnose-root → develop-tdd → validate-fix → release-branch
**Tests**: The bug fix pipeline. Verifies that a bug report flows through investigation, root cause analysis, TDD fix, and validation. Checks that BUG-*.md is created with 4 RCA phases.
**Fixtures**: A minimal repo with a known bug (off-by-one error in a loop).

### Story G-03: Plan a release (Plan cycle)
**Chain**: scope-work → slice-tasks → plan-work → plan-release
**Tests**: The planning spine. Verifies that a product scope is decomposed into epics, sliced into stories, and sequenced into a release plan with BCP baselines.
**Fixtures**: A SCOPE_LATEST.yaml with 3 features. Asserts release-plan.yaml has epics with BCP values.

### Story G-04: Sync and validate skills (Build pipeline)
**Chain**: sync-skills.sh → generate-skill-index.sh → validate-skill-yaml.py → check-skill-size.sh → audit-catalog.sh
**Tests**: The sync pipeline itself. Verifies that the build pipeline produces correct artifacts for all targets (Cursor, Gemini, pi) and that no skills are orphaned or missing.
**Fixtures**: The bigpowers repo itself. No fixture needed — this is a self-test.
**Asserts**: 72 .mdc files in .cursor/rules/, 72 dirs in .gemini/skills/, 72 dirs in .pi/skills/, skills-lock.json has 72 entries, SKILL-INDEX.md TOTAL says 72.

### Story G-05: Search and route (Discovery cycle)
**Chain**: search-skills → survey-context → using-bigpowers
**Tests**: The discovery/bootstrap path. Verifies that an agent can find the right skill from natural-language intent, load context, and determine the next skill.
**Fixtures**: A repo with state.yaml set to mid-build. Asserts the agent identifies the correct next_skill.

### Why these 5

- G-01 covers the most common workflow (feature addition) and the most skills (6)
- G-02 covers the bug pipeline (different chain, different state.yaml keys)
- G-03 covers planning (the YAML cockpit, BCP, WSJF)
- G-04 covers the build pipeline itself (the thing that makes all the artifacts)
- G-05 covers navigation (the entry point for new users)

Together they exercise ~25 of the 72 skills and all 6 phases. If all 5 pass, the core methodology is intact.

## 8. Metrics Dashboard

A single report after each run:

```
═══════════════════════════════════════════════════
 GOLDEN SUITE REPORT — 2026-07-02
═══════════════════════════════════════════════════

 Compliance: 96% (threshold 94%)         ✅ PASS

 Golden Stories:
   G-01 Add validation rule       PASS  12.3s   8.2k tok  6 skills
   G-02 Investigate and fix bug   PASS   8.1s   5.1k tok  4 skills
   G-03 Plan a release            PASS  15.7s   9.4k tok  4 skills
   G-04 Sync and validate         PASS   3.2s      0 tok  0 skills (scripts only)
   G-05 Search and route          PASS   9.2s   4.8k tok  3 skills

 Summary:
   Pass rate:    5/5 (100%)
   Total time:   48.5s
   Total tokens: 27.5k
   Regressions:  none

 vs Baseline (2026-07-01):
   Pass rate:    same (5/5)
   Token delta:  -3% (improved)
   Time delta:   +2s (within noise)

 Verdict: ✅ SHIP — all gates pass, tokens improved
═══════════════════════════════════════════════════
```

## 9. Workflow: How to Run It Per Epic

For each epic in the delivery plan:

**Before starting the epic:**
```bash
bash scripts/run-golden-suite.sh --baseline
# Pins current results as baseline in specs/benchmarks/reports/BASELINE-GOLDEN.yaml
```

**After each story in the epic:**
```bash
bash scripts/run-golden-suite.sh
# Runs all 5 stories + compliance, compares against baseline
# If any story regresses: revert the change, fix, re-run
# If all pass: continue to next story
```

**Before merging the epic:**
```bash
bash scripts/run-golden-suite.sh --final
# Full run with token measurement
# Writes GOLDEN-<date>.yaml report
# If token delta > +20%: write ADR justifying the tradeoff
# If token delta > +50%: blocked, must optimize before merge
```

This means: every story in the delivery plan is verified against the golden suite before it ships. No improvement merges unless it passes all three gates.

## 10. Implementation Plan

| Story | BCP | Description | Gate |
|-------|-----|-------------|------|
| q01s01 | 3 | Create specs/benchmarks/fixtures/minimal-api/ (fixture repo with createUser + test) | Setup |
| q01s02 | 3 | Create 5 golden story YAMLs in specs/benchmarks/golden/ (g-01 through g-05) | Setup |
| q01s03 | 5 | Create scripts/run-golden-suite.sh — iterates golden stories, runs grader, writes report, compares baseline | Gate 1 |
| q01s04 | 2 | Wire `npm run compliance` as first step of run-golden-suite.sh (Gate 2 integration) | Gate 2 |
| q01s05 | 3 | Add token estimation to run-golden-suite.sh — sum SKILL.md sizes + state.yaml size + tool call count | Gate 3 |
| q01s06 | 2 | Create specs/benchmarks/reports/BASELINE-GOLDEN.yaml (pin current state as baseline) | Baseline |
| q01s07 | 2 | Add "Run golden suite" to CLAUDE.md and CONVENTIONS.md as mandatory pre-merge step | Process |
| q01s08 | 2 | Extend evolve-skill SKILL.md to call run-golden-suite.sh instead of per-skill run-benchmark | Integration |

**Total**: 8 stories, 22 BCP

This becomes Epic 7 in the delivery plan, shipped first (or in parallel with Epic 1), because it's the quality guarantee that makes all other epics safe to ship.

---

### What this guarantees

After implementing this strategy:

1. **No silent regressions** — every change runs 5 end-to-end stories + compliance
2. **Token cost is visible** — every change reports token delta vs baseline
3. **Compliance is mandatory** — the 94% gate runs automatically, not manually
4. **The golden stories never change** — they are the fixed regression baseline
5. **evolve-skill uses the golden suite** — not just per-skill benchmarks
6. **Every epic in the delivery plan is verified** — before merge, not after

The answer to "how do we guarantee improvement?" is: **run the golden suite before and after every change. If pass_rate stays 100% and tokens don't increase by more than 20%, the change is an improvement. If either regresses, it's not.**

---

*End of strategy*
