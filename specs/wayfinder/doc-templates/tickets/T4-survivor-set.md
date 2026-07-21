<!-- wayfinder:grilling -->
# T4 — survivor-set

**Type:** Grilling (HITL) · **Status:** CLOSED · **Claim:** driver
**Blocks:** which fog graduates into per-doc tickets · **Blocked by:** informed by T3 (inventory), T6 (Wave assignment + invariants)

## Question

After the bigspec-aligned reclassification (skill = procedure, tools → kernel, `_LATEST` abolished,
OKF universal envelope), which documents **survive** and get a template, which **merge**, and which
are **dropped**? No point templating a doc slated to disappear.

## Decision output

A keep / merge / drop verdict per document type from the T3 inventory. Only "keep" (and the survivor
of each "merge") graduate from the fog into per-document template tickets.

## Resolution

**User rulings on the 4 judgment calls:**
1. **Bigpowers-about-itself DROPS from the consumer-app template set** — confirmed. `skills-wiki/`, `SKILL-SEARCH-INDEX`, `skills/*/SKILL.md` catalog stay bigpowers-internal only.
2. **`receipts.json`-equivalent tentatively KEEPs** (generalized compliance/gate-results page), **`rule-matrix.json`/`skill-graph.json` DROP** — confirmed, but **exact shape deferred to that document's own per-document ticket** ("the one by one phase"), not finalized here.
3. **SCOPE CORRECTION (supersedes T6/earlier session framing):** `acps-workflow` is **NOT a template target**. It is **reference/inspiration only** — the same role as `big-docs`/bigspec: consult it when a problem may already be solved there, never emit templates for it. The map's Destination is updated below to reflect this. The `acps-workflow` vs `acps-workflow-main` divergence is **not our problem to fix** under this reframing — no cleanup ticket spun.
4. **`specs/verifications/reports/**`, `falsification/**`, `security/epics/**` shape → PARKED, TBD.** Not researched further now; stays unenumerated fog, picked up if/when a per-document ticket needs it.

### Final survivor verdicts (by T3 grouping)

| Group | Verdict |
|---|---|
| Wave 1 (GitHub-native, all 9 files) | **KEEP as-is** — GitHub's own standard, no bigpowers template beyond adopting the file set (T6 already covers mirror-vs-link-out) |
| Wave 2 — 12 TGDP packs + AGENTS.md/CLAUDE.md/CONVENTIONS.md | **KEEP all** |
| Cockpit YAML (state, release-plan, execution-status, planning-status, cycle-times) | **KEEP** — data-OKF |
| Product intent (SCOPE, VISION, GLOSSARY, snapshots) | **KEEP**, drop `_LATEST` suffix; GLOSSARY absorbs the retired UBIQUITOUS_LANGUAGE file |
| Delivery (epic.yaml, story .md, tasks.yaml) | **KEEP** — story is the narrative-OKF flagship (already countable-story-format) |
| Architecture (tech-stack, TEST_PLAN, *_PLAN, ADR) | **KEEP**, drop `_LATEST`; ADR is T5's exemplar |
| Quality (BUG, registry, audit reports, .feature, security REVIEW, UAT checklists, waivers) | **KEEP**, drop `_LATEST` where present |
| Analysis (IMPACT, REFACTOR, TRACEABILITY, SPIKE) | **KEEP**, drop `_LATEST` |
| `adr-wiki/`, `epics-wiki/`, `codebase-wiki/` | **DROP as folders** — content merges into the single Wave-3 source (T6 Invariant #4) |
| `skills-wiki/`, `SKILL-SEARCH-INDEX`, `skills/*/SKILL.md` catalog | **DROP** — bigpowers-internal only (ruling #1) |
| `visual-dashboard` skill + local `dashboard/` app | **DROP** — superseded by generated site dashboards (T6) |
| `receipts.json` | **KEEP (tentative)**, generalized; shape TBD at its own ticket (ruling #2) |
| `rule-matrix.json`, `skill-graph.json` | **DROP** — bigpowers-internal (ruling #2) |
| `specs/workflows/*.yaml` (compose-workflow recipes) | **KEEP** — data-OKF, low priority |
| Surface B (website — all generated `.mdx`/`.astro`/sidebar) | **DROP as a template category** — build output of Wave 2/3, not separately authored |
| Surface C (`acps-workflow` — commands, prompts, memory, config) | **OUT — reference/inspiration only, not templated** (ruling #3, scope correction) |
| `verifications/reports/**`, `falsification/**`, `security/epics/**` | **PARKED — TBD** (ruling #4) |

Survivor set (KEEP + MERGE rows above) is what graduates into per-document template tickets next.
