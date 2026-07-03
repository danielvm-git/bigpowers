# bigpowers — Release History

> 98 releases in 41 days. 19 epics delivered. 3 generations of software engineering thought, synthesized into executable agent discipline.

---

## 📊 By the Numbers

| Metric | Value |
|:---|---:|
| First release | v1.0.0 — 2026-05-23 |
| Current version | v2.56.1 — 2026-07-03 |
| Total releases | 98 |
| Release cadence | 2.4/day (fully automated via semantic-release) |
| Epics delivered | 19 (~151 BCP, ~135 stories) |
| Active epics | 1 (e37 Golden Story Suite) |
| Backlog epics | 10 (~96 BCP queued across 4 release trains) |

---

## 🧭 Phase I: Foundation — The Stack Works

**May 23 – June 10, 2026** · v1.0.0 → v1.x series

The launch. 38 spec-driven lifecycle skills covering the full arc: discover → elaborate → plan → build (TDD) → verify → release. Not a collection of tips — a methodology.

- **Conventional Commits enforcement** from day one. Every commit is feat/fix/docs, every merge triggers semantic-release. No manual version bumps.
- **Agent workflow mandates** baked into CLAUDE.md: agents cannot write code directly. Every task flows through a skill.
- **Cursor + Gemini CLI + pi support** generated automatically from a single source of truth (`SKILL.md` files).
- **Karpathy behavioral mandates** (write/select/compress/isolate) enforced from the start — token discipline isn't an afterthought, it's architecture.
- **Clean Code heuristics**, Superpowers gates, testing mandates — each hardened with Gherkin `.feature` files and `npm run compliance` scoring.

~25 releases in this phase. Each one a structural hardening, not a feature toss.

---

## 🏗 Phase II: Evolution — The System Becomes Self-Aware

**June 11–22** · v2.0.0 → v2.28.0

The major architecture change. Flat file structure couldn't scale — every new epic meant another loose markdown file in the root.

- **v2.0.0** (June 11) — BREAKING. Capsule-directory architecture. Each epic gets its own directory with `epic.yaml`, numbered story specs, and a decoupled `-tasks.yaml`. ADR split (epic-local decisions stay with the epic, global decisions go to `specs/adr/`). Bug registry with structured naming (`BUG-NNN-slug.md`). Verification ledger. State lock file. **50/50 SDD adequacy score** against a 22-method comparison.
- **v2.10.0** (June 20) — CI verification and dry-run integrated into the skill system. Skills validate themselves.
- **v2.20.0** (June 21) — Quality gates shipped. Audit-code gate, F.I.R.S.T. test rubric enforcement, universal checkpoint pattern across all workflow skills.
- **v2.28.0** (June 22) — Machine-runnable skill catalog CI gate. Every SKILL.md's verify commands are now checked automatically on every push.

The system now builds itself. Skills create skills. Epics execute in 8 steps per story. The methodology is self-referential — bigpowers is built with bigpowers.

---

## ⚙️ Phase III: Maturity — CI/CD, Security, Operations

**June 22–29** · v2.29.0 → v2.43.x

Production-grade infrastructure. The methodology was correct; now the pipeline had to be unbreakable.

- **v2.29.0** (June 26) — Migrate-spec methodology complete. ID tracking, trace output, mandatory handoff, adversarial review. Absorbs learnings from migrating GSD, spec-kit, and BMAD projects.
- **v2.30.0** (June 26) — Security-review integrated into all 9 workflow skills. Every PR gets a data-flow analysis before merge.
- **v2.42.0** (June 29) — Standardized `_LATEST.md` naming. 7 skills updated. Predictable file names for CI pipelines.
- **v2.44.0** (July 2) — Repository restructuring. 72 skill sources moved under `skills/` directory. Root directory goes from ~96 entries to ~20. Clean landing page.

---

## 🔬 Phase IV: Deepening — The System Builds Itself Better

**July 2–3** · v2.45.0 → v2.56.1

The quality infrastructure phase. This is where bigpowers proved it could measure and improve itself.

### Quality Guarantee (e31) — v2.47.0 → v2.50.0

- **G-04 sync-pipeline self-test**: Every `sync-skills.sh` run validates its own output. Deterministic gate.
- **Compliance CI gate**: `npm run compliance` must pass ≥ 94% before any merge. Hard stop.
- **Golden suite runner**: Machine-runnable quality orchestration with baseline snapshots and size-change detection.
- **Pre-merge mandate**: No PR lands without compliance + sync + golden suite passing.
- **Evolve-skill regression gate**: Every skill change re-runs benchmarks to prove it's an improvement.

### Golden Stories (e37) — v2.46.0

- **Spike passed**: DeepSeek v4 running via gh-aw Claude engine confirmed viable. G-01 golden story now lives in CI — a real agent runs a real skill on every push and proves it works.

### Metrics Integrity (e40) — v2.51.0

- **Git-derived effort**: Hand-arithmetic cycle times replaced with commit-partition analysis. No self-reported wall-clock. Every number traceable to a git event.
- **OKF provenance gate**: Metrics bundles include aggregation tags and provenance pointers. Gate on the pipeline, not the value.

### Context Engineering (e34) — v2.51.0

- Four strategies named and tooled: **write** (token-efficient code), **select** (only relevant context), **compress** (reduce without losing structure), **isolate** (partitioned worktrees).
- `effort: heavy|light` frontmatter on every skill. Agents can budget context before loading.

### Traceability Gate (e38) — v2.52.0 → v2.56.0

- **Deterministic spec-to-code matrix**: `trace-stories.sh` maps every story ID to implementing code. Three-tier confidence: tagged (high), heuristic (medium), inferred (low).
- **Blind-spot detector**: Heuristic analysis catches stories with no code match.
- **CI/CD integration**: Matrix runs on every push. 9 stories shipped in a single day — the fastest-moving epic in project history.

---

## 🗺 Forward Plan

| Train | Epics | BCP | When | Focus |
|:---|---:|---:|:---|
| **v2.5x** Trust & Signal | e40, e34 | 28 | Current | Internal debt. Honest metrics, clean context vocabulary. |
| **v2.6x** Traceability Gate | e38, e33 | 26 | Next | Deterministic coverage in CI. Pipeline refactored for OKF rendering. |
| **v2.7x/v3.0** Semantic Bridge | e43, e39, e44, e28, e41, e42, e37 | 87 | After | **Headline release.** Docs website, public receipts page, MCP server, worked example repo. First release where a stranger can open a browser and understand why this exists. |
| **v2.8x** Docs Polish | e32, e36, e45, e46 | 48 | Later | Content quality. Reference docs, deduplication, OKF completion. |

---

## 🔍 What This Proves

- **98 releases in 41 days** with zero manual version bumps. Semantic-release from Conventional Commits.
- **19 epics delivered** through the same 8-step build cycle the methodology prescribes for users. bigpowers is its own first customer.
- **Quality is machine-enforced, not human-asserted.** Compliance scores, golden suites, sync-pipeline self-tests, traceability matrices — all deterministic. No "trust me."
- **Metrics are git-derived, not self-reported.** Every cycle time, effort number, and lead time traces to a commit. No hand arithmetic.
- **The stack is a chronological layer cake.** Clean Code (2008) → Deep Modules (2018) → Agent Orchestration (2023) → Spec-Driven Development (2024) → AI-Native Code Hygiene (2026). Each wave resolves tensions from the last. Nothing is random.

---

> *"Simplicity is the ultimate sophistication, but integrity is the ultimate requirement."*

---

*verify: `git tag --sort=-creatordate | wc -l` should match the total releases count above (98 as of 2026-07-03).*
