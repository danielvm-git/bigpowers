# SPIKE: Spec Migration — GSD, spec-kit, and BMAD → bigpowers

**Date:** 2026-05-19
**Status:** Done
**Question:** What are the documentation styles of GSD, spec-kit, and BMAD? What can bigpowers learn from each? How should a migration skill transform their artifacts?

---

## 1. Method Profiles

### 1.1 GSD (Get Shit Done)

**Philosophy:** Orchestration-first. Workflows are state machines; agents are thin specialists.

**Artifact home:** `.planning/` at project root

| Artifact | Shape | Purpose |
|---|---|---|
| `.planning/ROADMAP.md` | Milestone list → phase list → success criteria | Project-level roadmap with observable goals per phase |
| `.planning/STATE.md` | Current position, performance metrics | Compact session-resumption artifact (< 100 lines) |
| `.planning/REQUIREMENTS.md` | Numbered REQ-XX with traceability table | Scoped requirements with explicit in/out-of-scope |
| `.planning/METHODOLOGY.md` | Named analytical lenses with trigger conditions | Reusable interpretive frameworks; project-scoped |
| `.planning/HANDOFF.json` + `.continue-here.md` | Machine-readable pause state + human-readable brief | Structured session resumption across context resets |
| `.planning/phases/XX-name/XX-CONTEXT.md` | 6 sections: domain, decisions, canonical_refs, code_context, specifics, deferred | Phase-scoped decision capture before planning |
| `.planning/phases/XX-name/XX-YY-PLAN.md` | Frontmatter + objective + typed tasks + success criteria + output spec | Executable plan; every task has `verify: <command>` |
| `.planning/phases/XX-name/XX-YY-SUMMARY.md` | Frontmatter (dependency graph) + narrative + deviations + self-check | Per-plan execution outcome; feeds subsequent plans |
| `.planning/phases/XX-name/XX-DISCUSSION-LOG.md` | Audit trail of gray-area resolutions | Human-readable history; not read by automated workflows |
| `.planning/spikes/SPIKE-NNN/README.md` | YAML frontmatter (verdict, related) + methodology + findings | Research spike; feeds planner |

**Fingerprints (detection):**
- `.planning/` directory exists
- `.planning/ROADMAP.md` present
- `.planning/REQUIREMENTS.md` contains `REQ-` prefixed IDs
- `.planning/STATE.md` present with `phase:` field

**Unique strengths:**
- METHODOLOGY.md: standing analytical lenses that agents inherit across sessions
- HANDOFF.json: structured resume format (machine + human versions)
- REQUIREMENTS traceability: REQ-XX → phase plan → verification
- Phase CONTEXT.md 6-section format forces explicit decision capture before code

---

### 1.2 spec-kit (GitHub)

**Philosophy:** Spec-first. The specification is a living, executable artifact. Code is its expression.

**Artifact home:** Project root (spec.md, plan.md, tasks.md) + `.specify/` (workflow state)

| Artifact | Shape | Purpose |
|---|---|---|
| `spec.md` | User journeys (UJ-N), success criteria, problem scope | Intent contract: what and why, not how |
| `plan.md` | Technology decisions, architecture constraints, implementation approach | Technical contract: stack, patterns, constraints |
| `tasks.md` | Atomic task list; each verifiable in isolation | Work breakdown; each task drives a focused agent pass |
| `.specify/workflow-catalogs.yml` | Catalog config | Which workflow sources are active |
| `.specify/workflows/runs/<id>/state.json` | Step progress, inputs, log | Resume state for interrupted workflows |

**Workflow definition format (YAML):**
```yaml
schema_version: "1.0"
workflow:
  id: "speckit"
  steps:
    - id: specify
      command: speckit.specify
    - id: review-spec
      type: gate           # human approval before proceeding
    - id: plan
      command: speckit.plan
    - id: review-plan
      type: gate
    - id: tasks
      command: speckit.tasks
    - id: implement
      command: speckit.implement
```

**Fingerprints (detection):**
- `.specify/` directory exists
- `spec.md` + `plan.md` at project root (without BMAD markers)
- `.github/skills/speckit-*/SKILL.md` pattern (if Claude integration active)
- `GEMINI.md` with Spec Kit section header

**Unique strengths:**
- Gate steps: mandatory human approval between each phase (approve or abort)
- Resume from exact step: `.specify/workflows/runs/<id>/` preserves full state
- Tasks as atomic verifiable chunks → same philosophy as bigpowers `verify:` mandate
- Cross-agent design: single workflow YAML runs on Copilot, Claude, Gemini without changes

---

### 1.3 BMAD (BMad Method)

**Philosophy:** Role-based, multi-agent, spec-first. Each phase is facilitated by a named agent persona (PM, Architect, Dev, QA). `project-context.md` is the project "constitution."

**Artifact home:** `_bmad-output/` (generated) + `docs/` (human-maintained) + `_bmad/` (config)

| Artifact | Shape | Purpose |
|---|---|---|
| `product-brief.md` | Vision, core value, target users, key capabilities | Strategic intent (optional; feeds prd.md) |
| `prfaq-{project}.md` | Amazon-style press release + customer FAQ + internal FAQ | Working-backwards stress test |
| `prd.md` | Vision, Glossary, FR-XX + UJ-XX per feature, NFRs | Full product requirements doc; FR IDs are stable references |
| `addendum.md` | Change signals and their reconciliation with current PRD | PRD change log |
| `decision-log.md` | Timestamped decisions with rationale and alternatives | Traceability for PRD decisions |
| `ux-spec.md` | User experience design (steps 1-14 of UX workflow) | UX contract; referenced by architecture |
| `architecture.md` | ADRs, system design, data models, API contracts, sequence diagrams | Technical decisions; feeds story implementation |
| `epic-{slug}.md` | Epic with nested stories (story-{slug}.md files) | Work breakdown at epic and story level |
| `story-{slug}.md` | Story with acceptance criteria, tasks, implementation notes | Story-level implementation contract |
| `sprint-status.yaml` | Story status per sprint | Progress tracker |
| `project-context.md` | Tech stack, coding conventions, team preferences | "Constitution" read by all implementation agents |
| `_bmad/bmm/config.yaml` | Language, output location, artifact scanning paths | Project-level BMAD configuration |

**Fingerprints (detection):**
- `_bmad/` directory exists
- `_bmad-output/` directory exists
- `prd.md` with `FR-` prefixed requirements or `UJ-` user journeys
- `architecture.md` with ADR sections
- `project-context.md` with BMAD-style constitution format
- `epic-*.md` or `story-*.md` file naming pattern

**Unique strengths:**
- `prd.md` FR-XX + UJ-XX: explicit traceability from user journey to functional requirement
- `decision-log.md`: timestamped decision history per PRD (not just ADRs — every choice logged)
- `project-context.md`: explicit "constitution" pattern → all agents read it before acting
- PRD lifecycle (create / update / validate): three distinct intents handled by same skill
- Adversarial review: dedicated critique pass before implementation begins

---

## 2. Mapping: Source Artifacts → bigpowers Target

### 2.1 GSD → bigpowers

| GSD Artifact | bigpowers Target | Transform Notes |
|---|---|---|
| `.planning/ROADMAP.md` | `specs/RELEASE-PLAN.md` | Flatten phases to releases; add WSJF column; preserve success criteria |
| `.planning/STATE.md` | `specs/STATE.md` | Keep as-is; simplify to bigpowers format (milestone, branch, hash) |
| `.planning/REQUIREMENTS.md` | `specs/SCOPE.md` | REQ-XX IDs → SCOPE items; Validated/Active/Out-of-Scope sections map directly |
| `.planning/phases/XX/XX-CONTEXT.md` | `specs/CONTEXT.md` + `specs/adr/` | Domain section → CONTEXT.md; decisions → individual ADR files |
| `.planning/phases/XX/XX-YY-PLAN.md` | `specs/PLAN-vX.Y.Z.md` | Task format preserved; `verify:` commands kept |
| `.planning/phases/XX/XX-YY-SUMMARY.md` | (archive note in STATE.md) | Execution record; not a live bigpowers artifact |
| `.planning/METHODOLOGY.md` | `specs/SPIKE-methodology.md` | Standing lenses; bigpowers has no equivalent; spike captures intent |
| `.planning/HANDOFF.json` | `specs/STATE.md` (resume section) | Add "Session Resume" block to STATE.md |
| `.planning/spikes/SPIKE-NNN/` | `specs/SPIKE-{name}.md` | Flatten to single SPIKE file per spike |

### 2.2 spec-kit → bigpowers

| spec-kit Artifact | bigpowers Target | Transform Notes |
|---|---|---|
| `spec.md` | `specs/SCOPE.md` + `specs/CONTEXT.md` | User journeys → success criteria in SCOPE; domain terms → CONTEXT.md glossary |
| `plan.md` | `specs/CONTEXT.md` (architecture) + `specs/PLAN.md` | Tech decisions → CONTEXT.md; task sequence → PLAN.md |
| `tasks.md` | `specs/TASKS.md` | Atomic tasks map directly to bigpowers TASKS format |
| `.specify/` state | (discard) | Workflow engine state; not meaningful in bigpowers skill model |

### 2.3 BMAD → bigpowers

| BMAD Artifact | bigpowers Target | Transform Notes |
|---|---|---|
| `product-brief.md` / `prfaq-*.md` | `specs/CONTEXT.md` (Vision section) | Extract vision + core value + user summary |
| `prd.md` (FR-XX, UJ-XX) | `specs/SCOPE.md` | FR-XX → scope items; UJ-XX → success criteria section; Glossary → CONTEXT.md |
| `addendum.md` + `decision-log.md` | `specs/adr/` | Each logged decision becomes an ADR |
| `architecture.md` | `specs/CONTEXT.md` (Architecture section) + `specs/adr/` | Architecture ADRs → adr/; system overview → CONTEXT.md |
| `ux-spec.md` | `specs/CONTEXT.md` (UX section reference) | Note reference to ux-spec.md; do not duplicate |
| `epic-*.md` | `specs/RELEASE-PLAN.md` (epic-as-release) | Each epic becomes a planned release entry |
| `story-*.md` | `specs/TASKS.md` | Each story → TASKS entry with acceptance criteria |
| `project-context.md` | `CLAUDE.md` | Constitution → project-level CLAUDE.md content |
| `sprint-status.yaml` | `specs/STATE.md` | Map current story status to STATE.md milestone block |
| `_bmad/bmm/config.yaml` | (informational) | Extract language preference only |

---

## 3. Learnings to Adopt in bigpowers

### From GSD

1. **METHODOLOGY.md pattern** — A `specs/METHODOLOGY.md` that names standing analytical lenses (Bayesian updating, STRIDE threat modeling, cost-of-delay) would give bigpowers projects a way to encode project-specific reasoning modes. Agents can read this before planning. Low cost, high payoff for long-running projects.

2. **Structured session handoff** — `.continue-here.md` + `HANDOFF.json` solves the cold-start problem. bigpowers' STATE.md does half of this but lacks the "Required Reading" section and the machine-readable pause context. The `organize-workspace` skill could generate this.

3. **REQ-XX traceability** — SCOPE.md should offer an optional ID column (SCOPE-01, SCOPE-02...) so requirements can be traced from specification → plan → verification. The `elaborate-spec` skill already captures scope; adding IDs costs nothing.

### From spec-kit

4. **Gate steps between phases** — spec-kit's workflow YAML enforces explicit human approval before moving from specify → plan → tasks → implement. bigpowers' `elaborate-spec` skill has a HARD GATE for ambiguity but no inter-phase gate. Adding an explicit "Approve to proceed to planning?" checkpoint to `elaborate-spec`'s step 4 (Synthesize) would catch misaligned specs before `plan-work` starts.

5. **Resume state** — `.specify/workflows/runs/<id>/state.json` lets you resume from the exact step where a gate paused. bigpowers can approximate this with a "Last Step" section in STATE.md: if a session ends at a gate, record which skill and which step, so the next session resumes from there.

6. **spec.md user-journey focus** — spec-kit's `spec.md` is intentionally non-technical. It captures who uses the feature, what success looks like, and user journeys — leaving "how" entirely to `plan.md`. bigpowers' `elaborate-spec` conflates what/why with how. Separating these into a two-pass flow (journeys first, technical decisions second) would improve spec quality.

### From BMAD

7. **FR-XX + UJ-XX in SCOPE.md** — BMAD's `prd.md` template is exceptionally rigorous: each feature has a behavioral description, numbered functional requirements (FR-XX), and cross-referenced user journeys (UJ-XX). bigpowers' SCOPE.md is looser. The migrate-spec skill should surface this format as a recommended output for the target project's `specs/SCOPE.md`, even when the source was not BMAD.

8. **decision-log.md** — BMAD logs every PRD decision with timestamp, rationale, and alternatives considered. bigpowers has ADRs for hard architectural decisions but no equivalent for lightweight PRD decisions. A `specs/DECISION-LOG.md` (simpler than a full ADR) would capture "we chose X over Y because Z" at the requirements level.

9. **project-context.md as constitution** — BMAD's `project-context.md` is a dedicated file that all implementation agents read before acting. bigpowers achieves this through CLAUDE.md + CONVENTIONS.md, but these are bigpowers-framework documents, not project-specific. A project-specific `PROJECT-CONTEXT.md` (generated by `model-domain`) would give implementation agents a clear, project-specific charter without polluting CLAUDE.md.

---

## 4. Detection Algorithm

The `migrate-spec` skill should auto-detect the source framework before asking the user:

```
1. Check for `.planning/` directory
   AND `.planning/ROADMAP.md`
   → GSD

2. Check for `.specify/` directory
   OR (`spec.md` AND `plan.md` in project root, no BMAD markers)
   → spec-kit

3. Check for `_bmad/` directory
   OR `_bmad-output/` directory
   OR `prd.md` with `FR-` prefixed requirements
   OR `epic-*.md` / `story-*.md` naming pattern
   → BMAD

4. None of the above → ask user which framework
```

If multiple signals overlap (e.g., user has both `_bmad/` and `.planning/`), ask the user which is the primary source.

---

## 5. Key Decisions

- **Preserve source IDs** — REQ-XX, FR-XX, UJ-XX should be kept as cross-reference comments in bigpowers targets. Never silently renumber.
- **Don't merge** — produce separate bigpowers files, don't try to merge GSD CONTEXT.md + BMAD architecture.md into one CONTEXT.md. Create sections.
- **Prefer SCOPE.md over PLAN.md for requirements** — requirements from all sources land in SCOPE.md; execution plan lands in PLAN.md or RELEASE-PLAN.md.
- **ADRs are opt-in** — only create an ADR when the bigpowers rule applies: hard to reverse, surprising without context, result of a real trade-off.
- **STATE.md is always regenerated** — don't migrate the source STATE.md verbatim; generate a fresh bigpowers-format STATE.md from the information available.
