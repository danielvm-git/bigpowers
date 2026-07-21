<!-- wayfinder:research -->
# T3 — doc-inventory

**Type:** Research (AFK) · **Status:** CLOSED · **Claim:** research-subagent
**Blocks:** informs T1 (doctrine), T4 (survivor set) · **Blocked by:** —

## Question

The authoritative list of every document the bigpowers line generates today — solo core, generated
`website/` source, and the `acps-workflow` line — each with: owning skill/command, path/glob,
format (YAML | MD), and whether it is countable / OKF-tagged today.

## Decision output

An inventory table (doc type → owner → path → format → countable?/OKF?) that T1 and T4 consume.

## Resolution

~64 generated doc types across three surfaces. **Key structural finding: OKF adoption has already
begun** — `.okf.md` files exist in `adr-wiki/`, `epics-wiki/`, `metrics/`, `migrations/`, `templates/`
(so `templates/story-metrics.okf.md` is a live precedent for the hybrid doctrine), while
`codebase-wiki/` + `conventions-wiki/` are still plain `.md`. acps's FP/SNAP/BCP **prompt** docs are
already "countable." So the migration is partly self-started, not greenfield.

**Surface A — solo core (~47):**
- Cockpit YAML: state, release-plan, execution-status, planning-status, metrics/cycle-times — *none OKF*
- Product intent: SCOPE, VISION, GLOSSARY, snapshots — *none OKF*
- Delivery: epic.yaml (BCP baseline), story .md (**countable-story — the one fully-countable type**), tasks.yaml
- Architecture: tech-stack, TEST_PLAN, *_PLAN, ADR (+ `adr-wiki/*.okf.md` mirror)
- Quality: BUG (+ `bugs/*.okf.md` mirror), registry.yaml, verifications/{AUDIT-*, *-verify.yaml, reports/**, features/*.feature, UAT checklists, waivers.yaml}, security/REVIEW
- Analysis: IMPACT, REFACTOR, TRACEABILITY (+matrix.json), SKILL-SEARCH-INDEX, SPIKE
- Authoring: SKILL.md, CLAUDE.md, CONVENTIONS.md, README
- Wiki/graph/meta: codebase-wiki (181 files), skills-wiki, `epics-wiki/*.okf.md`, conventions-wiki, rule-matrix.json, skill-graph.json, receipts.json, workflows/*.yaml

**Surface B — generated website (7):** skill reference `.mdx`, guides, ADR mirror, skill-index, receipts.astro, sidebar (generated) — all downstream of A sources.

**Surface C — acps enterprise (~10):** slash-command docs (`commands/*.md`), **FP/SNAP/BCP + maturity prompt templates** (`prompts/*.txt` — already countable), memory docs (methodology/states/**bcp-rubric**), config template.

**Ambiguities flagged for T4 (not resolved here):**
- `UBIQUITOUS_LANGUAGE_LATEST.md` referenced but not found — likely superseded by `product/GLOSSARY_LATEST.yaml` (confirm).
- `verifications/reports/**`, `falsification/**`, `security/epics/**` contents not enumerated — eval-report format unconfirmed.
- `acps-workflow` vs `acps-workflow-main` are near-duplicate trees that have diverged — reconcile which is canonical.
