# Process Document: bigpowers — Solo Developer SDLC

**Owner:** Solo Developer | **Last Updated:** 2026-06-13 | **Version:** 2.1.2 | **Review Cadence:** Per major release

> **Note:** Version-specific sections tagged `(v2.0.0 ...)` describe features introduced in v2.0.0 that remain current unless noted.

---

## Purpose

Provide a deterministic, auditable, enterprise-ready software delivery lifecycle for solo developers. Eliminates the "what comes next?" problem through a conductor hierarchy, mandatory next-skill signaling, BCP scope accounting, and automated cycle-time metrics. Every story that ships writes its own evidence trail.

---

## Scope

**In scope:** New features, bug fixes (`fix-bug`), refactors with a spec, projects of any size.

**Out of scope:** Emergency hotfixes (use `release-branch --hotfix`), pure research spikes (`spike-prototype`), multi-team orchestration (`dispatch-agents`), one-off document edits.

---

## RACI Matrix

| Step | Responsible | Accountable |
|------|-------------|-------------|
| Machine setup (`seed-conventions`) | Developer | Developer |
| Project scoping (`orchestrate-project` Ph 1–3) | Agent + Developer | Developer |
| Story planning (`plan-work`) | Agent | Developer |
| Branch + baseline (`kickoff-branch`) | Agent | Developer |
| TDD implementation (`develop-tdd`) | Agent | Developer |
| UAT sign-off (`verify-work`) | **Developer** | Developer |
| Code audit (`audit-code`) | Agent | Developer |
| Commit + land (`commit-message` + `release-branch`) | Agent | Developer |
| Metrics logging (`cycle-times.yaml`) | Agent (automated) | Developer |
| MVP release (`semantic-release`) | Agent | Developer |

> UAT (`verify-work`) is the only step where the Developer is exclusively Responsible. The agent cannot confirm behavioral correctness on behalf of the user.

---

## Process Flow

```
ONE TIME (new machine or fresh clone)
────────────────────────────────────
seed-conventions
  └─ Creates: CLAUDE.md, CONVENTIONS.md, .claude/, .gemini/, .cursor/rules/
  └─ Syncs:   skills via scripts/sync-skills.sh
  └─ Gate: READY → next: orchestrate-project

ONCE PER PROJECT
────────────────
orchestrate-project --mode [standard | fast-track | ad-hoc]
  ├─ Phase 1  DISCOVER   survey-context, research-first, elaborate-spec
  ├─ Phase 2  ELABORATE  model-domain, grill-me, define-language, deepen-architecture, design-interface
  ├─ Phase 3  PLAN       scope-work, slice-tasks, plan-work → release-plan.yaml (BCP baseline)
  ├─ Phase 4  BUILD      → build-epic × N stories (see below)
  ├─ Phase 5  VERIFY     run-evals, verify-work (project-level UAT)
  └─ Phase 6  RELEASE    commit-message, release-branch, semantic-release → v1.0.0 MVP

ONCE PER STORY (inside Phase 4 — called by build-epic)
───────────────────────────────────────────────────────
Step 1  survey-context    ← stamps story_start timestamp
Step 2  plan-work         ← writes [BCP N] tasks + verify: commands
Step 3  kickoff-branch    ← creates worktree + feature branch
Step 4  develop-tdd       ← RED → GREEN → REFACTOR (vertical slices)
Step 5  verify-work       ← UAT gate (developer confirms behavioral correctness)
Step 6  audit-code        ← quality gate ≥ 94%
Step 7  commit-message    ← Conventional Commits + semver bump
Step 8  release-branch    ← land to main; stamps story_end + writes cycle-times.yaml
```

See [`docs/references/workflow-steps.md`](references/workflow-steps.md) for full per-step operational detail.

---

## Exceptions and Edge Cases

| Scenario | What to Do |
|----------|-----------|
| Bug found mid-story | Pause story (`state.yaml` preserves position). Run `/fix-bug` → `investigate-bug` → `develop-tdd` → `validate-fix`. Resume at `handoff.next_skill`. |
| Gate fails (quality < 94%) | Do NOT advance. Fix issues, re-run `audit-code`. Never lower threshold. |
| UAT step fails | Return to `develop-tdd` for that BCP. Do not mark story done. |
| Session interrupted mid-story | Run `/survey-context` — reads `state.yaml epic_cycle` and resumes at `handoff.next_skill`. |
| Task is ambiguous (no verify command) | Do not write the task. Run `define-success` first. |
| Story blocked by external dependency | Document in `state.yaml handoff.open_decisions`. Pause; work next WSJF story. |
| New requirement arrives mid-build | Run `change-request` to insert into `release-plan.yaml`. Finish current story first. |
| sync-skills.sh fails on `.gemini/` | Sandbox-only issue. Run on host machine where `.gemini/` is writable. |
| Need to parallel-ship two stories | Use `dispatch-agents` inside `develop-tdd`. Never split the 8-step cycle across simultaneous stories on same worktree. |

---

## Gate Reference

All gates must pass before advancing. Gates cannot be downgraded or skipped in Standard mode.

| Gate type | When | Passes when | Blocks on |
|-----------|------|-------------|-----------|
| **Confirm** | plan→build, safety-critical actions | Developer explicitly confirms | No response or "no" |
| **Quality** | `audit-code` | `npm run compliance` ≥ 94% | Score < 94% |
| **Safety** | `release-branch` land to main | Developer confirms "yes" | No confirmation |
| **Transition** | Phase advancement | Required artifact files exist | Missing state.yaml, SCOPE_LATEST.yaml, etc. |
| **Hard Gate** | Inline in skills (plan-work, kickoff-branch) | Specific precondition met | Precondition not met — skill stops |

---

## next_skill Signaling Reference

Each critical-path skill writes `state.yaml handoff.next_skill` on exit. Run `/survey-context` at any time to read the current recommended next skill.

```
survey-context    → plan-work
plan-work         → kickoff-branch
kickoff-branch    → develop-tdd
develop-tdd       → verify-work
verify-work       → audit-code
audit-code        → commit-message
commit-message    → release-branch
release-branch    → survey-context (next story) | semantic-release (all done)
```

---

## Related Documents

- [`CONVENTIONS.md`](../CONVENTIONS.md) — Git rules, code style, Conventional Commits format
- [`docs/PRINCIPLES.md`](PRINCIPLES.md) — Seven philosophical layers (Uncle Bob → BMAD synthesis)
- [`docs/references/workflow-steps.md`](references/workflow-steps.md) — Per-step operational detail (Phases 0–8)
- [`docs/references/workflow-artifacts.md`](references/workflow-artifacts.md) — Artifact inventory, metrics, dashboard, semver
- [`specs/SKILL-SEARCH-INDEX_LATEST.md`](../specs/SKILL-SEARCH-INDEX_LATEST.md) — Auto-generated skill catalog
- [`orchestrate-project/REFERENCE.md`](../orchestrate-project/REFERENCE.md) — Full phase specs + gate truth table
- [`build-epic/SKILL.md`](../build-epic/SKILL.md) — 8-step story cycle reference
- [`specs/metrics/README.md`](../specs/metrics/README.md) — cycle-times.yaml schema reference
