# HARD GATES Reference — Canonical Patterns by Phase

**Status:** Documenting existing coverage (all 61 skills complete as of 2026-06-11)
**Total HARD GATE callouts:** 69 across all skills
**Skills with zero callouts:** 0

---

## Format

All HARD GATEs use the blockquote markdown:

```
> **HARD GATE** — [constraint description]
```

Placement: top of SKILL.md, after the title and description, before the workflow steps. Multiple HARD GATEs per skill are stacked (no blank line between them).

---

## Phase Patterns

### Discover Phase
**Focus:** Scope clarity, prior art validation, stakeholder alignment.

| Skill | HARD GATE |
|-------|-----------|
| `survey-context` | Do not proceed without reading specs/ + CONVENTIONS.md |
| `map-codebase` | Do not skip gray areas (error handling, API shapes); incomplete survey = incomplete plan |
| `research-first` | Look-before-build; prior art search must complete before any design begins |
| `elaborate-spec` | Do NOT proceed until problem space is clear. Success criteria, actors, scope must be explicit. Multiple interpretations → list and ask user before guessing. |

### Elaborate Phase
**Focus:** Domain understanding, interface completeness, architectural trade-offs.

| Skill | HARD GATE |
|-------|-----------|
| `define-language` | Do not invent terms; extract only from conversation and codebase |
| `deepen-architecture` | Every deepening must be justified by domain language in specs/CONTEXT.md |
| `design-interface` | Must produce ≥2 radically different designs; single-option output is a FAIL |
| `grill-me` | Every hard decision must be stress-tested. "Seems right" is not a decision. |
| `grill-with-docs` | Every challenge must cite a real documentation URL. No hallucinated APIs. |
| `model-domain` | Domain model must reflect the ubiquitous language; no orphaned concepts |

### Plan Phase
**Focus:** Scope boundaries, impact assessment, verifiability, success criteria.

| Skill | HARD GATE |
|-------|-----------|
| `assess-impact` | Run before plan-work on any change touching an existing module with >1 caller |
| `plan-refactor` | Document current behavior + extract one invariant before any change |
| `scope-work` | Scope must be explicitly bounded; no "and everything else" clauses |
| `change-request` | specs/release-plan.yaml must exist before running either mode |
| `slice-tasks` | Every slice must be independently grabbable and verifiable |
| `define-success` | (Archived — absorbed into plan-work) |
| `plan-work` | Do NOT proceed until success criteria are clear. Multiple interpretations → list, ask. Every abstraction needs a "Reason for Depth." Every external package needs slopcheck: [OK]/[SUS]/[SLOP]. |
| `plan-release` | SCOPE_LATEST.yaml must exist. Do not run unless elaborate-spec output is clear. |

### Build Phase
**Focus:** Test discipline, agent coordination, task execution.

| Skill | HARD GATE |
|-------|-----------|
| `develop-tdd` | Red phase must fail before green phase begins |
| `enforce-first` | All enforcement checks (lint, typecheck, tests, coverage) must pass before shipping |
| `delegate-task` | Subagent MUST work on exactly one task; no scope creep |
| `dispatch-agents` | Each subagent task must be truly independent; overlapping state = data races |
| `execute-plan` | Do NOT proceed on main/master. Active epic must have runnable `verify` on each task. |
| `build-epic` | Set state.yaml active_flow + active_epic before starting. No code on main/master. |
| `run-planning` | Planning outputs must go to specs/; no ad-hoc plan fragments in conversation |
| `kickoff-branch` | Direct work on main/master is PROHIBITED. Clean test baseline required before creating worktree. |

### Verify Phase
**Focus:** UAT evidence, runnable verification, gap closure.

| Skill | HARD GATE |
|-------|-----------|
| `verify-work` | All verify commands must pass before marking story done. UAT evidence must be persisted. |
| `run-evals` | Eval baseline must be defined before feature code; regression evals must re-run after changes. |

### Bug Phase
**Focus:** Root cause confirmation, fix validation, regression prevention.

| Skill | HARD GATE |
|-------|-----------|
| `investigate-bug` | Do not propose a fix until root cause is isolated and reproduced |
| `diagnose-root` | Do not propose a fix until phase 4 confirms one root cause with evidence |
| `validate-fix` | Fix must pass: failing test → full suite → typecheck → lint → regression check |
| `fix-bug` | Set state.yaml active_flow: fix_bug |

### Review Phase
**Focus:** Code quality, check compliance, independent review.

| Skill | HARD GATE |
|-------|-----------|
| `audit-code` | Audit must check: bugs (correctness), security, performance, and clarity. Do NOT skip security review. |
| `request-review` | Reviewer agent must have clean context (no shared state with coding agent) |
| `respond-review` | Every reviewer finding must be categorized (apply/discuss/reject) with rationale |
| `trace-requirement` | Every story ID in release-plan must map to at least one test or code location |

### Integrate Phase
**Focus:** Commit discipline, merge gates.

| Skill | HARD GATE |
|-------|-----------|
| `commit-message` | Commits must follow Conventional Commits. Message must explain "why," not "what." |
| `release-branch` | Do NOT merge if tests fail or coverage gates are not met |

### Sustain Phase
**Focus:** Quality metrics, workspace hygiene, skill evolution.

| Skill | HARD GATE |
|-------|-----------|
| `inspect-quality` | QA session must produce structured bug entries; no verbal-only reports |
| `organize-workspace` | Workspace structure must reflect domain structure; disorganization is a domain misalignment signal |
| `stocktake-skills` | Full audit required before major release; no skill shipped with known compliance gaps |
| `evolve-skill` | No skill change ships without benchmark score ≥ pre-change baseline |

### Utility Phase
**Focus:** Mode switches, environment setup, documentation, session integrity.

| Skill | HARD GATE |
|-------|-----------|
| `terse-mode` | Use ONLY when context window is critically long; not a development strategy |
| `craft-skill` | Must use verb-noun naming; must run sync-skills.sh after creation |
| `edit-document` | Do not delete substantive content; structural edits only |
| `session-state` | Session state must be synchronized with git; conflicts = halt and clarify |
| `migrate-spec` | Migration must preserve all existing spec content; no data loss |
| `visual-dashboard` | Dashboard data must derive from filesystem state, not cached memory |
| `write-document` | Every document must be Bold, Minimal, Actionable, Durable |
| `setup-environment` | Environment must be validated (deps installed, tools configured) before development |
| `reset-baseline` | Reset must restore a KNOWN state; not a convenient undo |
| `search-skills` | Search must use lexical index; no hallucinated skill suggestions |
| `compose-workflow` | Workflows are orchestration, not automation. Single-skill tasks stay single-skill. |
| `simulate-agents` | Simulation agents must have clean context (no shared state) |

### Bootstrap / Orchestrate
**Focus:** Lifecycle entry, meta-skill mandates.

| Skill | HARD GATE |
|-------|-----------|
| `using-bigpowers` | Do not skip lifecycle intro; bigpowers has a specific phase order |
| `orchestrate-project` | Use only for complex multi-phase work; single tasks use dedicated skills |

### Spike
**Focus:** Learning, not production code.

| Skill | HARD GATE |
|-------|-----------|
| `spike-prototype` | Spike output is learning notes, NOT production code. Delete or file under specs/SPIKE-*.md |

---

## Verification

```bash
# Confirm 100% coverage
grep -c '> \*\*HARD GATE\*\*' */SKILL.md | awk -F: '{s+=$2} END {print s " total HARD GATEs across all skills"}'

# Find any skills with zero HARD GATEs
for d in */; do
  name="${d%/}"
  [ -f "$d/SKILL.md" ] && ! grep -q '> \*\*HARD GATE\*\*' "$d/SKILL.md" && echo "MISSING: $name"
done
# Expected: no output (zero missing)
```

*Reference generated 2026-06-11. All 61 skills confirmed compliant.*
