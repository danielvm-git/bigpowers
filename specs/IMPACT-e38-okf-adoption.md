# OKF Adoption — Impact Assessment

**Date:** 2026-07-03  
**Target:** Adopting Google's Open Knowledge Format (OKF v0.1) as a generated knowledge representation layer across bigpowers  
**Source:** Market survey of OKF spec + 3 sample bundles (GA4, Stack Overflow, Crypto Bitcoin) + Knowledge Catalog product analysis  
**Trigger:** "Should we leverage OKF in other areas of the project?"

---

## Research Findings (Primary Evidence)

### What OKF Is

A vendor-neutral, agent- and human-friendly format: a directory of markdown files with YAML frontmatter. Three conformance requirements: parseable frontmatter, non-empty `type` field, reserved filenames. That's it. Designed to be produced by agents, consumed by agents, and exchanged between systems.

### What the Bundles Teach Us

Analysis of the 3 Google-produced OKF sample bundles (60+ concepts total) revealed:

| Finding | Evidence | Implication for bigpowers |
|---|---|---|
| **Spec vs. Reality: links are relative** | SPEC.md recommends `/`-prefixed absolute links; the reference agent forbids them for GitHub rendering. All bundles use relative paths. | Use relative paths. Ignore spec recommendation. |
| **`log.md` is specified but unused** | SPEC.md §7 defines log format; zero bundles have one. Chronology is aspirational. | Defer `log.md`. `execution-status.yaml` already serves chronology. |
| **Compliance bar is trivially low** | 3 requirements: frontmatter, `type`, reserved names. bigpowers already meets 2/3 (frontmatter exists in YAML files). | Adoption is additive, not a rewrite. Existing files stay as authority. |
| **What makes OKF USEFUL is conventions ABOVE the spec** | Grain statements, SQL patterns, schema types, enum linkages, join docs, citations, prose context, domain tags — NONE required by spec | bigpowers needs its own convention layer: which `type` values, which sections, which link semantics |
| **Cross-link density is sparse** | Even the richest bundle (Stack Overflow, 50 concepts) has only 1.81 links per concept | Graph emerges gradually. Don't expect full mesh on day 1. |
| **Bundles are agent-generated, not hand-authored** | Reference agent reads BigQuery metadata → crawls web → writes OKF. Same pattern as a `maintain-wiki` skill. | This IS the bigpowers pattern: agent reads code/specs → writes OKF concepts |
| **`viz.html` provides graph visualization** | Single self-contained HTML: Cytoscape.js graph + marked.js renderer + embedded JSON. Backlinks computed at runtime. | Natural companion to `visual-dashboard` skill |

---

## Dependents — What Gets Touched

### Directly Affected Files

| File/Module | How OKF touches it | Callers affected |
|---|---|---|
| `scripts/sync-skills.sh` | New OKF output target (generate `specs/skills-wiki/` from 72 SKILL.md files) | CI (`sync-skills.yml`), every skill creation/modification (`craft-skill`, `evolve-skill`) |
| `SKILL-INDEX.md` | Augmented by OKF `index.md` at `specs/skills-wiki/index.md` | `search-skills`, `using-bigpowers`, `stocktake-skills`, `run-benchmark` |
| `specs/` directory | New `codebase-wiki/`, `skills-wiki/`, `conventions-wiki/`, `agent-guide/`, `epics-wiki/`, `adr-wiki/` subdirectories | Every skill that reads `specs/` (see below) |
| `CONVENTIONS.md` | Decomposed into `specs/conventions-wiki/` concepts (derived, not replacement) | `survey-context`, `audit-code`, `request-review`, `delegate-task`, `dispatch-agents`, `seed-conventions`, `craft-skill` — essentially ALL skills |
| `CLAUDE.md` | Augmented by `specs/agent-guide/` for progressive disclosure (derived, not replacement) | Every agent session start |
| `scripts/validate-specs-yaml.sh` | New `scripts/validate-okf.sh` for OKF conformance checks | CI pipeline |

### Stories Affected

| Story | Impact | Severity |
|---|---|---|
| **e38s01** — `trace-stories.sh` | Output format changes from custom JSON to OKF-conformant bundle. The script's logic stays the same; only the output target changes. | MEDIUM |
| **e38s04** — `check-blind-spots.sh` | Findings embed in OKF frontmatter (`coverage_status: untested`) instead of separate `blind-spots.json` | LOW |
| **e38s06** — `gate-trace` | Reads OKF frontmatter instead of custom JSON. Gate logic unchanged. | LOW |
| **e36** — Documentation Deduplication | OKF provides the "thin provenance pointer" format. Concept bodies cite sources; the authority lives in one place. e36's target aligns perfectly. | MEDIUM |
| **e34** — Context Engineering Layer | OKF bundles ARE context engineering: progressive disclosure via `index.md`, compression via concept isolation, selection via tags, write-once query-many | MEDIUM |
| **e28** — Docs Website | OKF bundles are Astro/MkDocs-friendly (markdown + frontmatter). Could render `specs/codebase-wiki/` as a browsable site. | LOW |
| **e33** — Sync Pipeline Refactor | New render target function in sync-skills.sh: `render_okf_bundle()`. Aligns with e33's goal of "adding target = adding a function." | LOW |
| NEW — `maintain-wiki` skill | New skill that implements OKF ingest/lint/query operations. Agent-maintained, language-agnostic. | NEW |

### Skills That Reference the Affected Files

Skills reading `specs/state.yaml`: `survey-context`, `session-state`, `build-epic`, `release-branch`, `fix-bug`, `plan-work`, `dispatch-agents`, `delegate-task`, `visual-dashboard` (9 skills)  
Skills reading `specs/release-plan.yaml`: `plan-release`, `change-request`, `survey-context`, `research-first`, `slice-tasks`, `scope-work`, `plan-work`, `visual-dashboard`, `run-benchmark` (9 skills)  
Skills reading `CONVENTIONS.md`: ALL 72 skills (via CLAUDE.md bootstrap)  
Skills reading `SKILL-INDEX.md`: `search-skills`, `using-bigpowers`, `stocktake-skills`, `run-benchmark`, `publish-package` (5 skills)

**Total blast radius: ~72 skills indirectly, ~15 skills directly referenced by affected files**

---

## Risk Classification

### Risk: MEDIUM

**Rationale:** OKF adoption is additive (generated bundles alongside existing files — no existing artifact is replaced). The blast radius is wide (touches sync pipeline and specs/) but shallow (existing file formats stay authoritative; OKF is a generated derivative). The compliance bar is trivially low (3 requirements). The `type` taxonomy is bigpowers-specific and carries no upstream dependency risk. However, `sync-skills.sh` changes affect CI, and CI failure blocks releases.

| Risk factor | Score | Notes |
|---|---|---|
| Caller count | HIGH (>10 direct dependents) | sync-skills.sh, CI, 15 skills, visual-dashboard |
| Test coverage | LOW | Documentation project — "tests" are verify commands. No automated test suite for sync-skills.sh behavior. |
| Shared interface | MEDIUM | specs/ structure is a de facto interface. Adding subdirectories is backwards-compatible but new. |
| Breaking change | LOW | No existing file is changed. New files are generated, not replacing old ones. |

### Risk Mitigations

1. **Add OKF output as optional** — `sync-skills.sh --okf` flag. CI runs it only when explicitly enabled.
2. **Validate before adding to CI** — `scripts/validate-okf.sh` runs locally first. Only add to CI after 3 successful manual runs.
3. **Pilot on codebase-wiki first** — e38 traceability is the pilot. If OKF works for traceability, expand to skills/conventions/epics.
4. **Keep existing formats** — TRACEABILITY_LATEST.md, SKILL-INDEX.md, CONVENTIONS.md remain the authority. OKF is a derived view.

---

## Philosophy Alignment Check

bigpowers principles vs. OKF adoption:

| Principle | OKF Alignment | Verdict |
|---|---|---|
| **Minimum code** | OKF adds scripts (sync output), not code. Zero runtime dependencies. | ✔ Aligned |
| **Spec-driven** | OKF IS a spec (v0.1). Conformance is verifiable via `validate-okf.sh`. | ✔ Aligned |
| **Language agnostic** | OKF works for any language — agent reads code, writes markdown. Matches bigpowers' "build any software in any LLM in any harness." | ✔ Aligned |
| **SRP** | Each concept has one job (describe one skill, one story, one convention). | ✔ Aligned |
| **Boy Scout Rule** | OKF leaves existing files cleaner — decomposes CONVENTIONS.md, augments SKILL-INDEX.md without replacing them. | ✔ Aligned |
| **Progressive disclosure** | `index.md` matches bigpowers' own pattern (SKILL-INDEX.md IS an index.md). | ✔ Aligned |
| **Vendor neutrality** | OKF is Google-published but Apache 2.0 licensed, vendor-neutral, no SDK lock-in. | ✔ Aligned |
| **Version-controllable** | OKF bundles are git repos of markdown. Diffs are readable. | ✔ Aligned |

---

## Recommended Action

### ADOPT — with phased rollout

**Phase 1: Pilot (e38 traceability only)**
- e38s01 generates OKF output to `specs/codebase-wiki/` alongside existing `TRACEABILITY_LATEST.md`
- `validate-okf.sh` checks conformance locally (not in CI yet)
- `gate-trace` reads OKF frontmatter
- **Risk:** Isolated to one epic. No CI dependency.

**Phase 2: Skills Wiki (sync-skills.sh output target)**
- `sync-skills.sh --okf` generates `specs/skills-wiki/` from 72 SKILL.md files
- `SKILL-INDEX.md` remains the authority; OKF `index.md` is a derived view
- CI runs `sync-skills.sh --okf` and `validate-okf.sh` as a non-blocking check
- **Risk:** CI now depends on OKF generation. Failure is non-blocking in Phase 2.

**Phase 3: Conventions + Agent Guide (decomposition)**
- `scripts/decompose-conventions.sh` generates `specs/conventions-wiki/` from CONVENTIONS.md
- `scripts/generate-agent-guide.sh` generates `specs/agent-guide/` from CLAUDE.md
- Skills optionally read from wiki concepts instead of full files
- **Risk:** Derived files must not drift from source. Lint pass detects drift.

**Phase 4: Full integration**
- `build-epic` Step 8 generates OKF concepts for completed stories
- `maintain-wiki` skill becomes a standard part of the methodology
- CI blocks on OKF conformance violations
- `visual-dashboard` renders OKF bundles
- **Risk:** Methodology change requires all skills to be aware of wiki maintenance step.

### What NOT to adopt

| Element | Reason |
|---|---|
| `okf_version` declaration | v0.1 is draft; wait for v1.0 |
| Absolute `/`-prefixed links | GitHub rendering breaks; relative works |
| `log.md` for chronology | `execution-status.yaml` already serves this |
| BigQuery-specific patterns | bigpowers is not a data catalog |
| `resource` as BigQuery URI | Use git-relative paths instead |

### bigpowers-Specific OKF Extensions

Custom `type` values needed (beyond OKF spec's examples):

| Type | Used for | Example concept |
|---|---|---|
| `Skill` | Each of the 72 skills | `skills/build-epic.md` |
| `Story` | Each epic story | `stories/e38s01.md` |
| `Epic` | Each epic capsule | `epics/e38-traceability-gate.md` |
| `ADR` | Each architecture decision | `adr/0001-verb-noun-naming.md` |
| `Convention` | Each rule in CONVENTIONS.md | `conventions/commit-conventions.md` |
| `Release` | Each release plan | `epics/release-v2.45.0.md` |
| `Module` | Code modules (for user projects) | `modules/auth-middleware.md` |
| `Reference` | External references, library docs | `references/tea-traceability.md` |
| `Dependency` | Skill → skill dependency edges | `dependencies/handoff-chain.md` |

Custom frontmatter fields (beyond OKF spec's recommended):

| Field | Type | Used for |
|---|---|---|
| `implementation_status` | `done` / `active` / `backlog` | Story/epic status |
| `bcps` | integer | Business complexity points |
| `wsjf` | float | Weighted shortest job first |
| `verify_passed` | boolean | Did verify-work pass? |
| `coverage_status` | `full` / `partial` / `none` | Test coverage level |
| `handoff_next` | string | Next skill in handoff chain |
| `depends_on` | list of strings | Skill dependencies (concept IDs) |
| `gates` | list of strings | HARD GATE prerequisites (concept IDs) |
| `model` | string | Recommended model (sonnet/haiku) |
| `effort` | `heavy` / `light` | Token cost estimate |

---

## Conclusion

OKF adoption is **aligned with bigpowers' philosophy** (minimum code, spec-driven, language-agnostic, vendor-neutral, version-controllable) and **matches its architectural bets** (specs/ as context management, sync pipeline as artifact generator, skill catalog as discoverable knowledge).

The research shows that the format is stable enough for adoption (Google is using it in production Knowledge Catalog) but the spec is still evolving (link format tension not resolved). The pragmatic approach is: **adopt the pattern, not the spec rigidly — use relative links, defer `log.md`, define bigpowers-specific `type` taxonomy, and treat OKF as a generated derivative layer, not a replacement for existing files.**

The biggest strategic value: OKF gives bigpowers a **universal, vendor-neutral knowledge representation** that works for any language, any LLM, any harness — exactly the agnosticism the project aims for. The format IS the integration layer between methodology (Layer 1), discipline (Layer 2), and technical context (Layer 3).
