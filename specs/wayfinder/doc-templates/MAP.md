<!-- wayfinder:map -->
# wayfinder — philosophy-tied templates for every bigpowers document

> Local-markdown tracker (find-way fallback mode; no GitHub issues per CONVENTIONS.md §42).
> Refer to tickets by **name**, never bare id. Plan, don't do — each ticket resolves a decision.
> **Never resolve more than one ticket per session** (except `research`).

## Destination

One canonical, philosophy-tied template for every document the **bigpowers solo core** generates
(consumer projects built with it, plus bigpowers' own repo) — **all living under one `docs/` root**
(specs/ dissolved, see T6 amendment). Every document belongs to exactly one subtree of that root, so
every generated doc is countable / OKF-valid / constitution-aligned **by construction**. **One template
format per document — not two.** Narrative content renders directly as the site page, zero transform;
data content (`docs/project/status/`) feeds a small, fixed set of generic dashboard views. No separate
wiki platform — Pages only, with the llm-wiki file-layout pattern (`index.md`+`log.md`) living inside
`docs/`. `acps-workflow` is **reference material, not a template target** (T4 ruling #3).

## Notes

- **North-star:** `big-docs`' 3-wave *content* model is adopted, but its literal sibling `docs/`+`specs/`
  layout is **amended** (T6 amendment, this session) — Wave 3 is now a subtree of `docs/`
  (`docs/project/`), not a sibling folder. `big-docs`' own DESIGN.md needs the matching update (tracked,
  not yet done).
- **Governing formats:** countable-story-format, BCP / BCP-Plus, OKF envelope, TGDP pack templates.
- **Skills to consult:** `write-document`, `edit-document`, `craft-skill`, `define-language`, `grill-me`,
  `maintain-wiki` (kept — the INGEST/LINT mechanism, not the `*-wiki/` folders).
- **Reference/inspiration sources** (consult, never template-target): `bigspec`, `acps-workflow`,
  `big-kickass-readme`, Good Docs / Diátaxis (TGDP packs vendored faithfully in `big-docs`).
- **Standing rule:** template only documents in T4's survivor set (KEEP/MERGE) — never a DROP row.
- **Working mode (user-set, this round):** go through templates **one by one**, starting with genuine
  *collisions* (>1 candidate template), in priority order Core pack > Community pack > Miscellaneous
  pack, tie-broken by driver judgment when no better reason exists.

## Open tickets (frontier — local-tracker index; a native tracker would query these)

| Ticket | Type | Status | Blocked by |
|--------|------|--------|-----------|
| [T2 — template-landscape](tickets/T2-template-landscape.md) | research (AFK) | ✅ closed | — |
| [T3 — doc-inventory](tickets/T3-doc-inventory.md) | research (AFK) | ✅ closed | — |
| [T6 — doc-information-architecture](tickets/T6-doc-information-architecture.md) | grilling (HITL) | ✅ closed (+ amended) | — |
| [T1 — template-doctrine](tickets/T1-template-doctrine.md) | grilling (HITL) | ✅ closed | — |
| [T4 — survivor-set](tickets/T4-survivor-set.md) | grilling (HITL) | ✅ closed | — |
| T7 — folder-collision-list | research+grilling | ✅ closed | T6 (closed) |
| [T8 — readme-template](tickets/T8-readme-template.md) | grilling (HITL) | ✅ closed | — |
| [T5 — exemplar-adr](tickets/T5-exemplar-adr.md) | prototype (HITL) | ✅ closed | — |
| [T9 — changelog-vs-release-notes](tickets/T9-changelog-vs-release-notes.md) | grilling (HITL) | ✅ closed | — |
| [T10 — glossary-collision](tickets/T10-glossary-collision.md) | grilling (HITL) | ✅ closed | — |
| [T11 — troubleshooting-vs-bug-rca](tickets/T11-troubleshooting-vs-bug-rca.md) | grilling (HITL) | ✅ closed | — |
| [T12 — story-template](tickets/T12-story-template.md) | grilling (HITL) | ✅ closed | — |
| [T13 — tech-stack-collision](tickets/T13-tech-stack-collision.md) | grilling (HITL) | ✅ closed | — |
| [T14 — security-review](tickets/T14-security-review.md) | grilling (HITL) | ✅ closed | — |
| [T15 — test-plan](tickets/T15-test-plan.md) | grilling (HITL) | ✅ closed | — |
| [T16 — cockpit-yaml](tickets/T16-cockpit-yaml.md) | grilling (HITL) | ✅ closed | — |
| [T17 — scope-and-vision](tickets/T17-scope-and-vision.md) | grilling (HITL) | ✅ closed | — |
| [T18 — agents-and-conventions](tickets/T18-agents-and-conventions.md) | grilling (HITL) | ✅ closed | — |
| [T19 — tasks-yaml](tickets/T19-tasks-yaml.md) | grilling (HITL) | ✅ closed | — |
| [T20 — impact-refactor-traceability](tickets/T20-impact-refactor-traceability.md) | grilling (HITL) | ✅ closed | — |
| [T21 — parked-tbd](tickets/T21-parked-tbd.md) | grilling (HITL) | ✅ closed | — |
| [T22 — design-and-spike](tickets/T22-design-and-spike.md) | grilling (HITL) | ✅ closed | — |
| [T23 — workflows-yaml](tickets/T23-workflows-yaml.md) | grilling (HITL) | ✅ closed | — |
| [T24 — epic-template](tickets/T24-epic-template.md) | grilling (HITL) | ✅ closed | — |

**Map status: CLEAR.** No open or frontier tickets remain. 24 tickets closed, 26 artifacts shipped
under `templates/`. Every category in the original "Not yet specified" fog list has a verdict —
including at document granularity now that T24 closes `epic.yaml`, the one document that
previously had a category-level verdict (KEEP, T4:34) but no per-document ticket or template.

## Decisions so far

<!-- one line per closed ticket: gist + link. Empty at charting. -->

- [T2 — template-landscape](tickets/T2-template-landscape.md) — hybrid doctrine recommended: OKF envelope for machine/YAML specs + Diátaxis/TGDP for prose; `big-docs` already converges on this split. (Informs T1; not a final decision.)
- [T3 — doc-inventory](tickets/T3-doc-inventory.md) — ~64 doc types across solo core / website / acps; OKF adoption already begun (`.okf.md` in 5 dirs); acps counting prompts already countable. (Informs T1, T4.)
- [T6 — doc-information-architecture](tickets/T6-doc-information-architecture.md) — **adopt `big-docs` verbatim** as the target IA: Wave 1 GitHub-native (root+`.github/`, mostly GitHub's own UI, 4 files mirrored onto the site), Wave 2 GoodDocs `docs/` (12 flat TGDP packs, richer than 4-quadrant Diátaxis), Wave 3 Specs `specs/` (OKF envelope, narrative renders 1:1 as pages / data feeds ~4 generic dashboards, `visual-dashboard` skill dropped). No parallel `*-wiki/` mirrors (hard invariant, not just preference). Diagram: `bigpowers-doc-architecture.dataflow.json`.
- [T1 — template-doctrine](tickets/T1-template-doctrine.md) — closed by synthesis of T6: doctrine = one template format per Wave; Wave 3 splits narrative (page render) vs data (dashboard aggregate). Sorting test = which Wave the generating skill belongs to.
- [T4 — survivor-set](tickets/T4-survivor-set.md) — full keep/merge/drop verdict across all ~64 T3 rows (see ticket for the table). Key drops: `adr-wiki`/`epics-wiki` mirror folders, `visual-dashboard` skill, `rule-matrix.json`/`skill-graph.json`, bigpowers-internal skill catalog. **`acps-workflow` reclassified from template-target to reference-only.** `receipts.json` shape and eval/audit report shape parked TBD.
- **T6 AMENDMENT** — `specs/` dissolves into `docs/` (as `docs/project/`); management info IS documentation, so one root, not two. Runtime state (`state.yaml`, `execution-status.yaml`) → `docs/project/status/`. Wiki refined, not reversed: llm-wiki is a file layout (`index.md`+`log.md`), not GitHub's Wiki feature — lives inside `docs/`, rendered by Pages. `skills-wiki`/`conventions-wiki` were wrongly bundled into T4's DROP verdict — the `maintain-wiki` INGEST/LINT mechanism is genuine Karpathy-pattern synthesis, not a mirror, and is **kept** (generalized per-app, not bigpowers' own skill catalog). `codebase-wiki` resolved by T4's final table: DROP as a standalone folder, same
  no-parallel-wiki-mirrors reasoning as `adr-wiki`/`epics-wiki` (T6 Invariant #4) — content
  merges as supplementary sections on each story's own page. (Correction, this audit pass: an
  earlier draft of this line claimed the folder was "broken — index references 77 pages, 0
  exist on disk"; independently re-verified false — every cited page exists, 0 broken, both
  before and after this session's regeneration. The DROP verdict itself is unaffected, since
  T4's table grounds it in the mirror invariant, not brokenness — only this line's stated
  evidence was wrong.) `log.md` resurrected from archived `obsidian-wiki`.
- T7 — folder-collision-list — of the user's 26 candidate GoodDocs folders: 6 are sub-templates already nested inside a parent (api-reference/api-getting-started/sdk-overview → inside `reference/`; installation-guide → inside `how-to/`; quickstart → inside `tutorial/`; terminology-system → inside `glossary/`), 8 are Wave-1 root files (bug-report, code-of-conduct+3 records, contributing-guide, our-team, contact-support) — not `docs/` content at all. Remaining 12 = exactly what `big-docs` vendored (verified: 26 − 6 − 8 = 12). **Only 4 genuine collisions**, in priority order: (1) README — resolved, T8; (2) changelog vs release-notes — both vendored, `CHANGELOG.md` is semantic-release-owned; (3) glossary — TGDP pack vs `GLOSSARY_LATEST.yaml` vs retired UBIQUITOUS_LANGUAGE; (4) troubleshooting vs bug RCA — mild, likely both survive with a stated boundary. Clean, no session needed: concept, how-to, tutorial, reference, style-guide, user-personas, images.
- [T8 — readme-template](tickets/T8-readme-template.md) — composed 12-section README from 4 sources (GitHub-native, TGDP `readme/` pack, `big-kickass-readme`, bigpowers' own prior README). Kept the "how to read this README" nav table (bigpowers original) and TGDP's link-don't-restate discipline; dropped separate build-status/code-style sections and the TOC section. New "Learn more" link block replaces the old deep-dive content (philosophy/hierarchy/MCP/pi-support/maintenance move to `docs/`). Artifact: `templates/readme.md`.
- [T9 — changelog-vs-release-notes](tickets/T9-changelog-vs-release-notes.md) — not a real duplication: `changelog/` is mechanical/commit-linked (semantic-release already fulfills it, `CHANGELOG.md` unchanged, no new template), `release-notes/` is curated prose with sections a commit scraper can't produce (Known issues, config-change actions). Confirmed live: `gh release view` today just auto-pastes the changelog, zero curation exists. Decision: release-notes template **on the shelf** — optional, no CI gate, becomes the GitHub Release body only when it exists for that version. Artifact: `templates/release-notes.md`.
- [T10 — glossary-collision](tickets/T10-glossary-collision.md) — **corrects T4's UBIQUITOUS_LANGUAGE→GLOSSARY merge ruling** (was a filename guess). One glossary template survives, not two: `define-language`'s richer shape (relationships, aliases-to-avoid, worked dialogue) wins over TGDP's flat table. `GLOSSARY_LATEST.yaml` (BCP/WSJF/OKF) isn't a second kind — it's bigpowers' own domain glossary for its own domain (software methodology); the same template glossaries a consumer app's actual business terms instead. **No bigpowers-jargon glossary ever ships to a consumer app** — same exclusion class as the skill catalog (T4 ruling #1), not an exception to it. Artifact: `templates/glossary.md`.
- [T11 — troubleshooting-vs-bug-rca](tickets/T11-troubleshooting-vs-bug-rca.md) — same shape as T9: `BUG-*.md` is the internal engineering record (RCA, TDD plan, tests — unchanged, no new template), `troubleshooting/` is an optional curated translation layer for the subset of bugs that surface as a real user-facing symptom. On the shelf, no gate, doesn't restate the RCA. **T7's full collision list is now closed** (README, changelog/release-notes, glossary, troubleshooting/bug-RCA). Artifact: `templates/troubleshooting.md`.
- [T5 — exemplar-adr](tickets/T5-exemplar-adr.md) — composed from 3 real sources: OKF frontmatter (bigspec, required by T1's doctrine), Nygard Status/Context/Decision/Consequences + `NNNN-<slug>.md` numbering (`big-docs`), **Conway's Law note** (`big-docs`, kept — fits the solo-dev-with-enterprise-behaviour framing), **Amended field** (bigpowers' own live ADRs — lets status evolve in place without forcing supersession). **This is now the reference envelope + section discipline every other narrative-OKF template inherits.**
- [T12 — story-template](tickets/T12-story-template.md) — the 20-section `countable-story-format.md` doesn't change (bigspec's own architecture.md already diagnosed this reconciliation: "OKF wraps it, the counter is just the validator for `okf_kind: story`"). **Resolved conflict:** constitution B9's "no gestalt SIZE field" vs. the format's mandatory `SIZE: XS-XL` header — ruled that SIZE stays as a pre-count Fibonacci estimate, never the computed BCP total (user ruling, baked into the artifact as a guardrail comment). Artifact is a thin wrapper (frontmatter + header, following T5's pattern) — does **not** duplicate the 20 sections; `countable-story-format.md` stays their single source.
- [T13 — tech-stack-collision](tickets/T13-tech-stack-collision.md) — **corrects T1's own Q1 answer** (half right; hadn't read the real `map-codebase` output yet). Third instance of the T9/T11 mechanical-record-vs-curated-layer pattern: `tech-stack.md` unchanged (already fully specified in `map-codebase`, explicitly the agent's "Long-Term Memory," terse and machine-refreshed — neither TGDP `concept/` nor `reference/` fits its register). New curated `architecture-concept.md` (TGDP `concept/`-shaped, links out to `tech-stack.md` rather than duplicating it) explains WHY, for humans. **Cadence differs from T9/T11: default, like README** — not on-the-shelf (user ruling).
- [T14 — security-review](tickets/T14-security-review.md) — no TGDP collision; a responsible-disclosure boundary instead. `REVIEW.md` unchanged, **never auto-published** — the one deliberate exception to "everything dissolves into `docs/`, all visible." New Security Advisory draft template, gated strictly on severity HIGH/CRITICAL + status fixed (user ruling, build-now not on-the-shelf). Fields verified against GitHub's real REST API schema via context7, not assumed. **Novel category:** doesn't render on the Astro site at all — a staging draft submitted to GitHub's own native Security Advisory feature, which hosts and publishes it separately.
- [T15 — test-plan](tickets/T15-test-plan.md) — no collision (checked: no TGDP candidate, no bigspec conflict, no public-facing companion warranted). Straightforward T5-pattern application: OKF envelope wraps the existing, already-gate-dependent body verbatim (Risk Matrix & Scenarios, Test Level Strategy, honest "Known verification gaps" section, Manual UAT, Hard gates). Per-epic like ADR is per-decision. **SC-ID format preserved untouched** — `gate-trace` depends on it.
- [T16 — cockpit-yaml](tickets/T16-cockpit-yaml.md) — **first data-OKF round**, not a fill-in template: per B8, tool-owned data kinds are never hand-templated, so each artifact is a field-contract schema instead. All 4 live files (state, release-plan, execution-status — 2776 lines, cycle-times — 483 lines) confirmed to have zero OKF envelope today. **Data-integrity finding:** `cycle-times.yaml` has a documented fabrication incident (e40 remediation) — Metrics dashboard must visually separate `measured` from `backfilled`, never blend (user-confirmed hard rule). **Disposition:** state.yaml internal-only (session noise, not project info — one exception for a derived `active_epic` indicator); release-plan→Roadmap; execution-status→Epic Status Board (confirmed sole source of truth, citing the real `BUG-001` epic-status-drift incident); cycle-times→Metrics.
- [T17 — scope-and-vision](tickets/T17-scope-and-vision.md) — narrative-OKF despite YAML format (multi-paragraph `summary`, human-interview authoring via `scope-work`) — not data-OKF like T16. No TGDP collision (`concept/` is didactic, wrong purpose). **Real overlap resolved:** both files had their own `out_of_scope` — now explicit: `vision.md` = permanent/identity-level, `scope.md` = tactical/per-round with individual reasons, revisitable. `_LATEST` dropped from both per standing doctrine.
- [T18 — agents-and-conventions](tickets/T18-agents-and-conventions.md) — **not a full merge into one constitution.md** — `big-docs` had already built the surgical answer: a real, thin (79-line) `AGENTS.md` template found in its archived snapshot. AGENTS.md canonical, CLAUDE.md/GEMINI.md are symlinks (zero divergence by construction). Confirmed the ~250-line RTK/sqz/bts tables never belonged inline — extracted to `docs/reference/agent-tooling.md` (TGDP `reference/` shape, conditional not mandatory). **Real overlap cut:** a duplicate "Pre-Merge Checklist" existed in both CLAUDE.md and CONVENTIONS.md — same restatement pattern as S6/wiki/glossary — collapsed to one `Preflight` row. CONVENTIONS.md itself unchanged, same treatment as tech-stack.md/TEST_PLAN.
- [T19 — tasks-yaml](tickets/T19-tasks-yaml.md) — no collision (no TGDP candidate, no public-facing companion warranted). **Compliance check came back clean:** grepped every live `*-tasks.yaml` for per-task BCP annotations — none found; `bcps:` correctly lives at story level only, already following B9's prohibition rather than violating it (unlike T12's SIZE tension, nothing to arbitrate here). `verify:`-required hard gate preserved as an explicit guardrail comment.
- [T20 — impact-refactor-traceability](tickets/T20-impact-refactor-traceability.md) — no collision between the three (different lifecycle moments: pre-change gate, interview-driven delivery plan, post-hoc audit). **Naming confirmed against real files:** IMPACT is per-target (9 live instances, `IMPACT_LATEST.md` vestigial and retired); REFACTOR and TRACEABILITY are single evolving docs, `_LATEST` dropped. **Live drift found and fixed:** `TRACEABILITY.md` (stale, manual, epics e01-e29 only, never CI-referenced) and `TRACEABILITY_LATEST.md` (tool-generated, full-scope, the real one) existed simultaneously — the stale one is retired, not reconciled. Template grounded in the tool's real output, which is richer than its own skill doc describes.
- [T21 — parked-tbd](tickets/T21-parked-tbd.md) — resolved all 3 deferred items. `planning-status.yaml` inherits T16's `state.yaml` ruling (internal only). `receipts.json` gets a new T16-style schema with the same measured/absent honesty rule as `cycle-times.md`. Audit-run logs and `THREAT_MODEL.md` stay internal (same class as `REVIEW.md`, T14) — raw evidence never publishes, only the aggregate does. **Closed a dangling thread:** `.feature` files were referenced since the start of the map but never ticketed — resolved as bigpowers-internal-only (T4 ruling #1 class), no consumer-app template.
- [T22 — design-and-spike](tickets/T22-design-and-spike.md) — `DESIGN.md` **defers to an external spec** (Google's own published `design.md` format, validated by `npx @google/design.md lint`) rather than getting an invented 8-section template — same reasoning as T14 deferring to GitHub's real API. Checked and confirmed it does **not** need T13's mechanical/curated split (its prose is already reader-facing, unlike tech-stack.md's terse register — a precedent correctly NOT over-applied). `SPIKE-*.md` is per-target, deliberately flexible — checked 5 real spikes, one (`SPIKE-frameworks.md`) took a much broader comparison-matrix form the exploration warranted, so the template doesn't force rigidity.
- [T24 — epic-template](tickets/T24-epic-template.md) — closes the one fog-list gap a later audit found: `epic.yaml` was KEEP in T4's survivor table (T4:34) but, unlike its siblings `story` (T12) and `tasks.yaml` (T19), had neither a per-document ticket nor a template. **Same pattern as T19, not T12:** pure YAML, no markdown body, collaboratively-authored-during-planning — narrative-OKF by authorship, not body shape, same reasoning T19 gave `tasks.yaml`. Field contract transcribed from a real live `epic.yaml`, not invented. **Guardrail baked in:** every listed story MUST have both a matching `spec:` `.md` and `tasks:` `.yaml` before the epic starts — the same audit found this exact gap in e53's own `epic.yaml` (CRITICAL per `scripts/lib/plan-consistency-check.sh`) and that the validator meant to catch it was silently exiting 0 on this host (bash-3.2 portability bug, fixed same round). Confirmed `bcp:` (singular, per-story) is the real repo-wide convention (236 occurrences across every other epic), not an inconsistency with `tasks.yaml`'s `bcps:` to correct.

## Not yet specified

<!-- per-document template tickets; graduate one at a time now that T1 (doctrine) and T4 (survivor set) are both closed. Only KEEP/MERGE rows from T4 appear below — DROP rows (wiki mirrors, visual-dashboard, rule-matrix.json, skill-graph.json, SKILL-SEARCH-INDEX, skills-wiki, Surface B, acps) are excluded. -->

- **Cockpit YAML (data-OKF):** *fully resolved* — state/release-plan/execution-status/cycle-times (T16), planning-status (T21, inherits T16's state.yaml ruling), receipts (T21, new schema, measured/absent honesty rule)
- **Product intent (narrative):** *fully resolved* — SCOPE + VISION (T17, tactical vs. permanent out_of_scope) · GLOSSARY (T10, absorbs UBIQUITOUS_LANGUAGE)
- **Delivery (narrative):** *fully resolved* — epic.yaml *(resolved T24)* · story *(resolved T12)* · tasks.yaml *(resolved T19 — checked clean, no per-task BCP violations found)*
- **Architecture (narrative):** ADR *(resolved T5)* · TEST_PLAN *(resolved T15)* — tech-stack resolved as T13 (split: `tech-stack.md` mechanical/unchanged + new curated `architecture-concept.md`, default cadence)
- **Quality (narrative):** *fully resolved* — BUG + registry (T11) · security REVIEW (T14) · `.feature` (T21, bigpowers-internal-only per T4 ruling #1, no template) · audit reports (T21, stay internal, feed receipts.md's aggregate)
- **Analysis (narrative):** *fully resolved* — IMPACT · REFACTOR · TRACEABILITY (T20) · DESIGN (T22, defers to external Google `design.md` spec, not hand-authored) · SPIKE (T22, per-target, deliberately flexible)
- **Authoring:** README *(resolved T8)* · CLAUDE.md/CONVENTIONS.md *(resolved T18)* · SKILL.md (bigpowers-internal per T4 ruling #1, no consumer-app template — same exclusion class T21 reaffirmed for `.feature`)
- **Config (narrative):** `specs/workflows/*.yaml` — *resolved T23*, no collision, format already settled pre-round

## Out of scope

- Any `bigspec` kernel changes — this effort templates bigpowers-line **docs**; it does not build the kernel.
- `acps-workflow` as a template target (T4 ruling #3) — it is a reference/inspiration source only.
- Surface B (`website/` generated `.mdx`/`.astro`) as a separate template category (T4) — it is build
  output of the Wave 2/3 templates, not separately authored.
- Bigpowers-internal-only artifacts for the consumer-app template set (T4 ruling #1): `skills-wiki/`,
  `SKILL-SEARCH-INDEX`, the `skills/*/SKILL.md` catalog, `rule-matrix.json`, `skill-graph.json`.
