# Release Plan: bigpowers

Current audit score: **~94% (~84/89)** — post-v2.0.0.

> **Note on Versioning:** This plan uses "Target Milestones" for planning. Actual version numbers are determined automatically by `semantic-release` at merge time based on commit types (Conventional Commits).

Ordered by WSJF: (Business Value + Time Criticality + Risk Reduction) / Job Size.

---

## Release Sequence

| Milestone | Status | WSJF | Focus | Objective |
|:----------|:-------|:-----|:------|:----------|
| v1.11.0–v1.18.0 | ✅ | — | Foundation | Benchmarks → harness → conventions → guardrails → execution loop |
| v2.0.0 | ✅ | — | Framework | Reference library (11 docs) + `orchestrate-project` meta-skill |
| **v2.1.0** | ⏳ | **8.0** | Repo Health | Documentation refactoring: specs/ restructure, SKILL-INDEX accuracy, ADRs |
| **v2.1.1** | 📋 | **8.0** | Integration | OpenCode integration: automated `opencode.json` and `AGENTS.md` generation |
| **v2.2.0** | 📋 | **4.2** | Security | slopcheck supply-chain gates in `plan-work` + `audit-code` |
| **v2.3.0** | 📋 | **3.5** | Ergonomics | `handoff` skill + `terse-mode` hardening |
| **v2.4.0** | 📋 | **3.3** | Isolation | Context isolation (fresh 200K/skill) + model routing |
| **v2.5.0** | 📋 | **3.0** | Taxonomy | Provenance links, `type:` / `context:` metadata in plans |
| **v2.6.0** | 📋 | **2.8** | Complexity | Law of Demeter, Module Depth score, concurrency safety |
| **v2.7.0** | 📋 | **1.5** | Execution | Wave-based parallel task execution |
| **v3.0.0** | 📋 | < 1.0 | AI Tier | Semantic Search, Skill Composition, Multi-Agent Simulation |

---

## Pending Releases — Detail

### v2.1.0: Repo Health (WSJF 8.0) ⏳ ← next

Highest WSJF: repo misrepresents itself right now (ghost skills, wrong artifact names, duplicate
audit tables). Zero risk (renames only), high payoff — unblocks everything downstream.

**Success Criteria:**
- [ ] `specs/CONTEXT.md` exists with Vision, Technology, Architecture, Glossary sections.
- [ ] `specs/SCOPE.md` is the canonical scope artifact (renamed from PROJECT.md).
- [ ] `specs/adr/` contains all 6 hard-decision ADRs.
- [ ] `SKILL-INDEX.md` counts match reality: all 44 skills present, ghosts marked 📋.
- [ ] All root-level count references say "44+" (CLAUDE.md, GEMINI.md, README.md).
- [ ] `RELEASE-PLAN.md` has no completed-release detail blocks; all future items consolidated here.
- [ ] `CONVENTIONS.md` documents the two naming exceptions (terse-mode, visual-dashboard).

→ verify: `wc -l specs/CONTEXT.md specs/SCOPE.md specs/adr/*.md | awk '$1 > 300 {print "OVERSIZED:", $2}'`

---

### v2.1.1: OpenCode Integration (WSJF 8.0) 📋

Automates integration for the OpenCode agent platform. Currently manual and error-prone.

**Success Criteria:**
- [ ] `sync-skills.sh` generates a root-level `opencode.json` for the bigpowers repo.
- [ ] `scripts/install.sh` automatically creates `opencode.json` in the target project if it doesn't exist.
- [ ] `seed-conventions` skill generates both `AGENTS.md` and `opencode.json` templates.
- [ ] `AGENTS.md` follows the bigpowers template from `docs/AGENTS.md`.

→ verify: `grep -r "opencode.json" scripts/sync-skills.sh scripts/install.sh seed-conventions/SKILL.md | wc -l | awk '{if($1>=3) print "OK"; else print "MISSING"}'`

### Story [2.1.1]: OpenCode Integration — Implementation Steps

**Context**: Automates the generation of `opencode.json` and `AGENTS.md` to ensure `bigpowers` rules are correctly loaded by the OpenCode agent platform.

## Steps

1. Update `scripts/sync-skills.sh` to generate a default `opencode.json` at the repo root → verify: `bash scripts/sync-skills.sh && grep "instructions" opencode.json`

2. Update `scripts/install.sh` to create `opencode.json` in the user's project if it doesn't exist, and update `print_opencode_instructions` → verify: `grep -A 5 "install_opencode" scripts/install.sh`

3. Update `seed-conventions/SKILL.md` to include `AGENTS.md` and `opencode.json` templates in its output → verify: `grep -E "AGENTS.md|opencode.json" seed-conventions/SKILL.md | wc -l | awk '{if($1>=2) print "OK"; else print "MISSING"}'`

4. Run `sync-skills.sh` to propagate changes to `.cursor/rules` and `.gemini/extensions` → verify: `bash scripts/sync-skills.sh && grep "AGENTS.md" .cursor/rules/seed-conventions.mdc`

## Out of scope

- Direct integration with OpenCode API or remote rule fetching.

## Risks

- `opencode.json` schema might change (mitigated by following the current documentation found in the OpenCode source).

---

### v2.2.0: Supply-Chain Security (WSJF 4.2) 📋

Closes documented drift: `docs/references/security-threats.md` describes slopcheck but no skill
implements it. Risk Reduction score is 9/10 — one supply-chain incident is a reputation kill.

**Success Criteria:**
- [ ] `plan-work` runs slopcheck for every external package and tags with `[OK]`, `[SUS]`, or `[SLOP]`.
- [ ] `audit-code` includes a supply-chain checklist item (slopcheck verified?).
- [ ] `[SUS]` and `[SLOP]` packages trigger a HARD GATE requiring human confirmation.
- [ ] `docs/references/security-threats.md` reflects actual implementation (no drift).

→ verify: `grep -r "slopcheck" plan-work/SKILL.md audit-code/SKILL.md | wc -l | awk '{if($1>=2) print "OK"; else print "MISSING"}'`

---

### v2.3.0: Developer Ergonomics (WSJF 3.5) 📋

High Business Value relative to job size. `handoff` is the single most-requested missing skill.

**Success Criteria:**
- [ ] `handoff` skill compacts current session (open decisions, last step, required reading) into a single cold-start document.
- [ ] `terse-mode` updated with Pocock `caveman` rules (drop articles, filler, pleasantries; target 30% token reduction).
- [ ] `organize-workspace` includes an automated `.gitignore` suggester.

→ verify: `[ -f handoff/SKILL.md ] && echo "OK" || echo "MISSING: handoff skill"`

---

### v2.4.0: Context Isolation + Model Routing (WSJF 3.3) 📋

Implements ADR-0004 and ADR-0006. Largest quality lever (+40% quality, -20% tokens per
DECISION-JUSTIFICATION research). Requires `orchestrate-project` as coordinator.

**Success Criteria:**
- [ ] `execute-plan` spawns every skill with a fresh, isolated context window.
- [ ] Each skill's `SKILL.md` declares a `model:` tier (haiku / sonnet / opus).
- [ ] Orchestrator reads `model:` and routes accordingly.
- [ ] `STATE.md` is the sole mechanism for passing decisions between skill spawns.

→ verify: `grep -r "model:" */SKILL.md | wc -l | awk '{if($1>10) print "OK"; else print "PARTIAL"}'`

---

### v2.5.0: Taxonomy & Provenance (WSJF 3.0) 📋

**Success Criteria:**
- [ ] All plan templates include `type:` (feat/fix/refactor) and `context:` (domain/infra) metadata.
- [ ] `plan-work` mandates linking every step to an ADR or commit SHA.
- [ ] `audit-code` verifies presence of metadata in all new artifacts.

→ verify: `grep -r "type:\|context:" specs/PLAN*.md 2>/dev/null | wc -l`

---

### v2.6.0: Architectural Complexity (WSJF 2.8) 📋

**Success Criteria:**
- [ ] `audit-code` and `CONVENTIONS.md` include a Law of Demeter checklist.
- [ ] `deepen-architecture` produces a numeric Module Depth score (Ousterhout compliance).
- [ ] `model-domain` includes a concurrency safety audit (shared mutable state detection).

→ verify: `grep -c "Demeter" audit-code/SKILL.md CONVENTIONS.md | awk -F: '$2>0' | wc -l | awk '{if($1==2) print "OK"; else print "MISSING"}'`

---

### v2.7.0: Wave-Based Parallel Execution (WSJF 1.5) 📋

Depends on v2.4.0 (context isolation must be in place for safe parallel spawns).

**Success Criteria:**
- [ ] `execute-plan` automatically groups independent tasks into parallel execution waves.
- [ ] Dependency parsing reads `depends-on:` declarations from PLAN.md task entries.
- [ ] Atomic `STATE.md` writes prevent race conditions between wave executors.

→ verify: `grep -c "wave\|parallel" execute-plan/SKILL.md | awk '{if($1>0) print "OK"; else print "MISSING"}'`

---

### v3.0.0: AI Capability Tier (WSJF < 1.0) 📋

Major version: significant new capability class. Candidates pending WSJF scoring before commitment:

- **Semantic Skill Search** — vector embeddings to find the right skill from natural language intent.
- **Skill Composition** — meta-skill to chain multiple skills into a custom workflow.
- **Multi-Agent Simulation** — "Mock User" + "Auditor" agents against a new feature before human review.
- **Auto-Skill Generator** — `craft-skill` upgrade: draft `SKILL.md` from a library README or API docs.
- **Methodology Lenses** — `specs/METHODOLOGY.md` encoding project-specific reasoning modes (STRIDE, Cost-of-Delay).

---

## Audit Score Tracking

| Version | Score | Notes |
|---------|-------|-------|
| v1.12.0 | ~75% (67/89) | First measured score |
| v1.12.1 | ~84% (~75/89) | +9 from CONVENTIONS.md heuristics |
| v1.14.0 | ~87% (~77/89) | +3 from karpathy.feature behavioral mandates |
| v1.15.0 | ~91% (~81/89) | +4 from superpowers.feature gates |
| v1.16.0 | ~93% (~83/89) | +3 from cleancode.feature T4/T5/T8 |
| v1.17.0 | ~94% (~84/89) | +1 from guardrails discipline |
| v2.0.0 | ~94% (~84/89) | +0 (reference library; enforcement deferred to v2.2+) |
| **Current** | **~94%** | **Next lift: v2.2.0 security gates** |

---

## bigpowers-benchmark

Tracked in a separate repo: `/Users/danielvm/Developer/bigpowers-benchmark/`

See `bigpowers-benchmark/specs/RELEASE-PLAN.md` for the full v1.0.0 implementation plan
(14 steps, 5 SANDBOX tasks, automated scoring pipeline).
