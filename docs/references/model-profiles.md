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

Full list: every SKILL.md declares `model:` — verify with `grep -rl '^model:' */SKILL.md | wc -l` (expect 77).

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
| `/Users/danielvm/Developer/bigpowers/skills/align-grid` | **Sonnet** |
| `/Users/danielvm/Developer/bigpowers/skills/assess-impact` | **Sonnet** |
| `/Users/danielvm/Developer/bigpowers/skills/audit-code` | **Haiku** |
| `/Users/danielvm/Developer/bigpowers/skills/audit-plan` | **Sonnet** |
| `/Users/danielvm/Developer/bigpowers/skills/build-epic` | **Sonnet** |
| `/Users/danielvm/Developer/bigpowers/skills/change-request` | **Sonnet** |
| `/Users/danielvm/Developer/bigpowers/skills/commit-message` | **Haiku** |
| `/Users/danielvm/Developer/bigpowers/skills/compose-workflow` | **Sonnet** |
| `/Users/danielvm/Developer/bigpowers/skills/context7-mcp` | **Haiku** |
| `/Users/danielvm/Developer/bigpowers/skills/craft-skill` | **Sonnet** |
| `/Users/danielvm/Developer/bigpowers/skills/deepen-architecture` | **Sonnet** |
| `/Users/danielvm/Developer/bigpowers/skills/define-language` | **Sonnet** |
| `/Users/danielvm/Developer/bigpowers/skills/define-success` | **Sonnet** |
| `/Users/danielvm/Developer/bigpowers/skills/delegate-task` | **Sonnet** |
| `/Users/danielvm/Developer/bigpowers/skills/deploy` | **Sonnet** |
| `/Users/danielvm/Developer/bigpowers/skills/design-interface` | **Opus** |
| `/Users/danielvm/Developer/bigpowers/skills/develop-tdd` | **Sonnet** |
| `/Users/danielvm/Developer/bigpowers/skills/diagnose-root` | **Sonnet** |
| `/Users/danielvm/Developer/bigpowers/skills/diagnose-stall` | **Haiku** |
| `/Users/danielvm/Developer/bigpowers/skills/dispatch-agents` | **Sonnet** |
| `/Users/danielvm/Developer/bigpowers/skills/edit-document` | **Sonnet** |
| `/Users/danielvm/Developer/bigpowers/skills/elaborate-spec` | **Opus** |
| `/Users/danielvm/Developer/bigpowers/skills/enforce-first` | **Haiku** |
| `/Users/danielvm/Developer/bigpowers/skills/evolve-skill` | **Opus** |
| `/Users/danielvm/Developer/bigpowers/skills/execute-plan` | **Haiku** |
| `/Users/danielvm/Developer/bigpowers/skills/extract-design` | **Sonnet** |
| `/Users/danielvm/Developer/bigpowers/skills/fix-bug` | **Sonnet** |
| `/Users/danielvm/Developer/bigpowers/skills/gate-trace` | **Haiku** |
| `/Users/danielvm/Developer/bigpowers/skills/grill-me` | **Sonnet** |
| `/Users/danielvm/Developer/bigpowers/skills/grill-with-docs` | **Opus** |
| `/Users/danielvm/Developer/bigpowers/skills/guard-git` | **Haiku** |
| `/Users/danielvm/Developer/bigpowers/skills/hook-commits` | **Haiku** |
| `/Users/danielvm/Developer/bigpowers/skills/inspect-quality` | **Sonnet** |
| `/Users/danielvm/Developer/bigpowers/skills/investigate-bug` | **Sonnet** |
| `/Users/danielvm/Developer/bigpowers/skills/kickoff-branch` | **Haiku** |
| `/Users/danielvm/Developer/bigpowers/skills/maintain-wiki` | **Haiku** |
| `/Users/danielvm/Developer/bigpowers/skills/map-codebase` | **Sonnet** |
| `/Users/danielvm/Developer/bigpowers/skills/migrate-spec` | **Sonnet** |
| `/Users/danielvm/Developer/bigpowers/skills/model-domain` | **Sonnet** |
| `/Users/danielvm/Developer/bigpowers/skills/orchestrate-project` | **Sonnet** |
| `/Users/danielvm/Developer/bigpowers/skills/organize-workspace` | **Haiku** |
| `/Users/danielvm/Developer/bigpowers/skills/plan-refactor` | **Sonnet** |
| `/Users/danielvm/Developer/bigpowers/skills/plan-release` | **Sonnet** |
| `/Users/danielvm/Developer/bigpowers/skills/plan-tests` | **Opus** |
| `/Users/danielvm/Developer/bigpowers/skills/plan-work` | **Opus** |
| `/Users/danielvm/Developer/bigpowers/skills/publish-package` | **Sonnet** |
| `/Users/danielvm/Developer/bigpowers/skills/quick-fix` | **Sonnet** |
| `/Users/danielvm/Developer/bigpowers/skills/release-branch` | **Haiku** |
| `/Users/danielvm/Developer/bigpowers/skills/request-review` | **Opus** |
| `/Users/danielvm/Developer/bigpowers/skills/research-first` | **Sonnet** |
| `/Users/danielvm/Developer/bigpowers/skills/reset-baseline` | **Haiku** |
| `/Users/danielvm/Developer/bigpowers/skills/respond-review` | **Sonnet** |
| `/Users/danielvm/Developer/bigpowers/skills/run-benchmark` | **Haiku** |
| `/Users/danielvm/Developer/bigpowers/skills/run-evals` | **Sonnet** |
| `/Users/danielvm/Developer/bigpowers/skills/run-planning` | **Sonnet** |
| `/Users/danielvm/Developer/bigpowers/skills/scope-work` | **Sonnet** |
| `/Users/danielvm/Developer/bigpowers/skills/search-skills` | **Haiku** |
| `/Users/danielvm/Developer/bigpowers/skills/security-review` | **Sonnet** |
| `/Users/danielvm/Developer/bigpowers/skills/seed-conventions` | **Sonnet** |
| `/Users/danielvm/Developer/bigpowers/skills/session-state` | **Haiku** |
| `/Users/danielvm/Developer/bigpowers/skills/setup-environment` | **Haiku** |
| `/Users/danielvm/Developer/bigpowers/skills/simulate-agents` | **Sonnet** |
| `/Users/danielvm/Developer/bigpowers/skills/slice-tasks` | **Sonnet** |
| `/Users/danielvm/Developer/bigpowers/skills/smoke-test` | **Sonnet** |
| `/Users/danielvm/Developer/bigpowers/skills/spike-prototype` | **Sonnet** |
| `/Users/danielvm/Developer/bigpowers/skills/stocktake-skills` | **Sonnet** |
| `/Users/danielvm/Developer/bigpowers/skills/survey-context` | **Haiku** |
| `/Users/danielvm/Developer/bigpowers/skills/terse-mode` | **Haiku** |
| `/Users/danielvm/Developer/bigpowers/skills/trace-requirement` | **Haiku** |
| `/Users/danielvm/Developer/bigpowers/skills/using-bigpowers` | **Sonnet** |
| `/Users/danielvm/Developer/bigpowers/skills/validate-contracts` | **Sonnet** |
| `/Users/danielvm/Developer/bigpowers/skills/validate-fix` | **Haiku** |
| `/Users/danielvm/Developer/bigpowers/skills/verify-work` | **Haiku** |
| `/Users/danielvm/Developer/bigpowers/skills/visual-dashboard` | **Sonnet** |
| `/Users/danielvm/Developer/bigpowers/skills/wire-ci` | **Sonnet** |
| `/Users/danielvm/Developer/bigpowers/skills/wire-observability` | **Sonnet** |
| `/Users/danielvm/Developer/bigpowers/skills/write-document` | **Sonnet** |

Total: **77** skills — verify with `find . skills -maxdepth 2 -name SKILL.md 2>/dev/null | grep -v '.git\|.cursor\|.gemini\|.pi' | sort -u | wc -l`
<!-- AUTO-GENERATED-CATALOG: end -->
