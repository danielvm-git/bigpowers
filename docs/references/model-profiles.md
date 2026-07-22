# Model Profiles: Assignments & Token Budgets

**Purpose:** Define which Claude model should handle each skill, based on task complexity and token efficiency.

---

## Model Taxonomy

| Model | Cost | Speed | Quality | Token Budget | Use When |
|-------|------|-------|---------|--------------|----------|
| **Haiku** | $0.80/MTok | Fast | 4.0/5.0 | 100K | Light tasks: parsing, filtering, simple decisions |
| **Sonnet** | $3.00/MTok | Medium | 4.5/5.0 | 200K | Medium tasks: analysis, design, most implementations |
| **Opus** | $15.00/MTok | Slow | 5.0/5.0 | 250K | Complex tasks: strategy, code review, novel problems |

---

## Skill-to-Model Assignments

### Discovery Phase
| Skill | Model | Budget | Rationale |
|-------|-------|--------|-----------|
| `survey-context` | **Haiku** | 100K | Just reading code, extracting facts |
| `grill-me` | **Sonnet** | 200K | Asking clarifying questions, requires creativity |
| `model-domain` | **Sonnet** | 200K | Understanding domain; medium complexity |

### Elaboration Phase
| Skill | Model | Budget | Rationale |
|-------|-------|--------|-----------|
| `elaborate-spec` | **Opus** | 250K | Design decisions; needs strategic thinking |
| `grill-me` | **Sonnet** | 200K | Assumptions validation |
| `spike-prototype` | **Sonnet** | 200K | Quick prototyping; proof of concept |

### Planning Phase
| Skill | Model | Budget | Rationale |
|-------|-------|--------|-----------|
| `plan-work` | **Opus** | 250K | Complex planning; needs to anticipate issues |
| `trace-requirement` | **Haiku** | 100K | Tracing through code; deterministic |
| `assess-impact` | **Sonnet** | 200K | Blast radius analysis; moderate complexity |

### Build Phase
| Skill | Model | Budget | Rationale |
|-------|-------|--------|-----------|
| `develop-tdd` | **Sonnet** | 200K | Implementation; TDD-driven |
| `execute-plan` | **Haiku** | 100K | Step-by-step execution of plan |
| `plan-refactor` | **Sonnet** | 200K | Code restructuring; careful |
| `diagnose-root` | **Sonnet** | 200K | Problem-solving; needs analysis |

### Verification Phase
| Skill | Model | Budget | Rationale |
|-------|-------|--------|-----------|
| `verify-work` | **Haiku** | 100K | UAT checklist; step-by-step |
| `run-evals` | **Sonnet** | 200K | Eval design and pass@k |
| `validate-fix` | **Haiku** | 100K | Running tests; boolean result |

### Review Phase
| Skill | Model | Budget | Rationale |
|-------|-------|--------|-----------|
| `audit-code` | **Haiku** | 100K | Checklist validation; rule-based |
| `request-review` | **Opus** | 250K | Holistic code review |
| `respond-review` | **Sonnet** | 200K | Categorize and apply feedback |
| `trace-requirement` | **Haiku** | 100K | Deterministic trace |

### Bug Phase
| Skill | Model | Budget | Rationale |
|-------|-------|--------|-----------|
| `investigate-bug` | **Sonnet** | 200K | RCA |
| `diagnose-root` | **Sonnet** | 200K | 4-phase root cause |
| `validate-fix` | **Haiku** | 100K | Re-run suite |

### Sustain & Utility (v3.0.0)
| Skill | Model | Rationale |
|-------|-------|-----------|
| `stocktake-skills` | Sonnet | Catalog audit |
| `evolve-skill` | Opus | Benchmark-gated evolution |
| `search-skills` | Haiku | Lexical index lookup |
| `compose-workflow` | Sonnet | Workflow recipes |
| `simulate-agents` | Sonnet | Mock user + auditor |
| `research-first` | Sonnet | Prior art search |
| `scope-work` / `slice-tasks` | Sonnet | Planning artefacts |
| `grill-with-docs` | Opus | Doc-grounded grill |
| `setup-environment` / `reset-baseline` | Haiku | Mechanical prep |

Full list: every SKILL.md declares `model:` — verify with `grep -rl '^model:' */SKILL.md | wc -l` (expect 80).

### Release Phase
| Skill | Model | Budget | Rationale |
|-------|-------|--------|-----------|
| `orchestrate-project` | **Sonnet** | 200K | Coordination; needs judgment |
| `release-branch` | **Haiku** | 100K | Tag, push, notes; mechanical |

---

## Cost Analysis: Typical 5-Phase Project

### Baseline (All Opus)
```
discover: grill-me (Opus)     = 250K tokens × $15/MTok = $3.75
elaborate: elaborate-spec     = 250K tokens × $15/MTok = $3.75
plan: plan-work               = 250K tokens × $15/MTok = $3.75
build: develop-tdd            = 300K tokens × $15/MTok = $4.50
verify: request-review        = 250K tokens × $15/MTok = $3.75
────────────────────────────────────────────────────────
TOTAL: $19.50 (expensive, slow)
```

### Smart Routing (This Table)
```
discover: survey-context (Haiku)  = 100K tokens × $0.80/MTok = $0.08
discover: grill-me (Sonnet)       = 200K tokens × $3.00/MTok = $0.60
elaborate: elaborate-spec (Opus)  = 250K tokens × $15.00/MTok = $3.75
plan: plan-work (Opus)            = 250K tokens × $15.00/MTok = $3.75
plan: assess-impact (Sonnet)      = 200K tokens × $3.00/MTok = $0.60
build: develop-tdd (Sonnet)       = 200K tokens × $3.00/MTok = $0.60
verify: validate-fix (Haiku)      = 100K tokens × $0.80/MTok = $0.08
verify: request-review (Opus)     = 250K tokens × $15.00/MTok = $3.75
────────────────────────────────────────────────────────
TOTAL: $14.21 (27% cheaper, faster, same quality)
```

---

## Complexity-Based Escalation

Start with cheaper model; escalate if task is harder:

### Rule 1: Complexity Surprises Escalate

```
Task assigned to Haiku:
  "Just read the codebase and summarize"
  
Haiku starts, then:
  ← "This has 500 interdependent modules"
  → "Escalate to Sonnet for better pattern recognition"
```

### Rule 2: Quality Failures Escalate

```
Task assigned to Sonnet:
  "Design the API"
  
Review by human:
  "Your design misses the concurrency constraints"
  → "Escalate to Opus to reconsider with full context"
```

### Rule 3: Subjective Judgment Escalates

```
Task assigned to Haiku:
  "Is this code safe?"
  
Agent hits security question:
  "This uses encryption; safety is subjective"
  → "Escalate to Opus for security review"
```

---

## Token Budget Enforcement

Each skill must declare its budget in the frontmatter:

```yaml
---
name: plan-work
model: opus
token_budget: 250000  # 250K max input + output
estimated_usage:
  typical: 180000
  complex: 230000
  worst_case: 250000
---
```

**Enforcement Rules:**
- If actual usage exceeds 90% of budget → agent pauses, asks for approval to continue
- If actual usage exceeds 100% → agent stops, requests chunking (break into sub-tasks)
- If repeated overruns → escalate to next model up

---

## Model Selection Decision Tree

```
Start: Task assigned

  Q1: Is the task deterministic (same input → same output)?
  YES → Use Haiku (fast, cheap)
  NO → Q2

  Q2: Does the task require subjective judgment?
  YES → Use Opus (best quality for judgment)
  NO → Q3

  Q3: Does the task require strategic thinking or novel problem-solving?
  YES → Use Opus
  NO → Use Sonnet (balanced cost/quality)

  Q4: Check token budget
  If budget < 100K → Haiku is sufficient
  If budget 100-200K → Sonnet is right
  If budget > 200K → Opus is needed
```

---

## Context Isolation Benefits per Model

### Haiku + Context Isolation
- Fresh 100K window per skill
- No session context bloat
- Cost: $0.08 per skill × 10 skills = $0.80 total for discovery phase

### Sonnet + Context Isolation
- Fresh 200K window per skill
- Medium complexity handled well
- Cost: $0.60 per skill × 5 skills = $3.00 typical

### Opus + Context Isolation
- Fresh 250K window for hard problems
- No need to re-brief on prior work (files are fresh input)
- Cost: $3.75 per strategic skill × 2 skills = $7.50 typical

**Total typical 6-phase project:** $14.21 (vs. $19.50 without routing = 27% savings)

---

## See Also

- orchestration.md — Which model for each phase?
- verification-patterns.md — How models verify outputs
- verify: `bash scripts/generate-reference-tables.sh` (regenerates this file from live frontmatter)


## Full Skill Catalog (auto-generated)

<!-- AUTO-GENERATED-CATALOG: begin — do not edit manually; run scripts/generate-reference-tables.sh -->
| Skill | Model |
|-------|-------|
| `skills/align-grid` | **Sonnet** |
| `skills/assess-impact` | **Sonnet** |
| `skills/audit-code` | **Haiku** |
| `skills/audit-plan` | **Sonnet** |
| `skills/build-epic` | **Sonnet** |
| `skills/change-request` | **Sonnet** |
| `skills/commit-message` | **Haiku** |
| `skills/compose-workflow` | **Sonnet** |
| `skills/context7-mcp` | **Haiku** |
| `skills/craft-skill` | **Sonnet** |
| `skills/deepen-architecture` | **Sonnet** |
| `skills/define-language` | **Sonnet** |
| `skills/define-success` | **Sonnet** |
| `skills/delegate-task` | **Sonnet** |
| `skills/deploy` | **Sonnet** |
| `skills/design-interface` | **Opus** |
| `skills/develop-tdd` | **Sonnet** |
| `skills/diagnose-root` | **Sonnet** |
| `skills/diagnose-stall` | **Haiku** |
| `skills/dispatch-agents` | **Sonnet** |
| `skills/edit-document` | **Sonnet** |
| `skills/elaborate-spec` | **Opus** |
| `skills/enforce-first` | **Haiku** |
| `skills/evolve-skill` | **Opus** |
| `skills/execute-plan` | **Haiku** |
| `skills/extract-design` | **Sonnet** |
| `skills/find-way` | **Sonnet** |
| `skills/fix-bug` | **Sonnet** |
| `skills/gate-trace` | **Haiku** |
| `skills/generate-allure-report` | **Sonnet** |
| `skills/grill-me` | **Sonnet** |
| `skills/grill-with-docs` | **Opus** |
| `skills/guard-git` | **Haiku** |
| `skills/harden-vps` | **Haiku** |
| `skills/hook-commits` | **Haiku** |
| `skills/inspect-quality` | **Sonnet** |
| `skills/investigate-bug` | **Sonnet** |
| `skills/kickoff-branch` | **Haiku** |
| `skills/maintain-wiki` | **Haiku** |
| `skills/map-codebase` | **Sonnet** |
| `skills/migrate-spec` | **Sonnet** |
| `skills/model-domain` | **Sonnet** |
| `skills/orchestrate-project` | **Sonnet** |
| `skills/organize-workspace` | **Haiku** |
| `skills/plan-refactor` | **Sonnet** |
| `skills/plan-release` | **Sonnet** |
| `skills/plan-tests` | **Opus** |
| `skills/plan-work` | **Opus** |
| `skills/publish-package` | **Sonnet** |
| `skills/quick-fix` | **Sonnet** |
| `skills/release-branch` | **Haiku** |
| `skills/request-review` | **Opus** |
| `skills/research-first` | **Sonnet** |
| `skills/reset-baseline` | **Haiku** |
| `skills/respond-review` | **Sonnet** |
| `skills/run-benchmark` | **Haiku** |
| `skills/run-evals` | **Sonnet** |
| `skills/run-planning` | **Sonnet** |
| `skills/scope-work` | **Sonnet** |
| `skills/search-skills` | **Haiku** |
| `skills/security-review` | **Sonnet** |
| `skills/seed-conventions` | **Sonnet** |
| `skills/session-state` | **Haiku** |
| `skills/setup-environment` | **Haiku** |
| `skills/simulate-agents` | **Sonnet** |
| `skills/slice-tasks` | **Sonnet** |
| `skills/smoke-test` | **Sonnet** |
| `skills/spike-prototype` | **Sonnet** |
| `skills/stocktake-skills` | **Sonnet** |
| `skills/survey-context` | **Haiku** |
| `skills/terse-mode` | **Haiku** |
| `skills/trace-requirement` | **Haiku** |
| `skills/using-bigpowers` | **Sonnet** |
| `skills/validate-contracts` | **Sonnet** |
| `skills/validate-fix` | **Haiku** |
| `skills/verify-work` | **Haiku** |
| `skills/visual-dashboard` | **Sonnet** |
| `skills/wire-ci` | **Sonnet** |
| `skills/wire-observability` | **Sonnet** |
| `skills/write-document` | **Sonnet** |

Total: **80** skills — verify with `find . skills -maxdepth 2 -name SKILL.md 2>/dev/null | grep -v '.git\|.cursor\|.gemini\|.pi' | sort -u | wc -l`
<!-- AUTO-GENERATED-CATALOG: end -->
