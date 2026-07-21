<!-- wayfinder:grilling -->
# T6 — doc-information-architecture

**Type:** Grilling (HITL) · **Status:** CLOSED · **Claim:** driver
**Blocks:** T1 (doctrine), T4 (survivor set) · **Blocked by:** informed by T3 (inventory)

## Question

What is bigpowers' documentation **information architecture** — how many source trees, which audiences,
and which GitHub feature (Pages / Wiki) serves each — given the solo-dev goal of "fewer places to look"?
Specifically: does "put everything in `docs/`" include the machine cockpit (state.yaml, tasks.yaml,
execution-status), or only the human-facing prose?

## Decision output

A documentation container map: source trees × audiences × GitHub feature (Pages/Wiki/none), with a rule
for which tree a new document lands in. This fixes the "specs/ vs docs/" axis that T1's doctrine depends on.

## Decided so far (grilling in progress)

The fork is answered: **publish the cockpit, don't hide it.** All repos are public; the dev wants to read
project state without opening VS Code.

- **`specs/` stays** the machine source of truth (OKF artifacts, gate-parsed) — NOT merged into `docs/`.
- **`docs/` = human prose authoring** home (absorbs scattered root explainers / references).
- **NEW generated target — the "project portal":** a bigpowers-shipped generator renders a consumer
  project's `specs/` (specs, requirements, bug list, epic done-status, metrics) into a browsable published
  site + wiki, **auto-rebuilt in CI on every change**. This is a consumer-project capability, not just an
  internal doc reorg — it reframes T1 (each doc needs an OKF *source* template + a *render* view) and adds
  portal-generator build tickets to the fog.
- Existing partial pieces to reconcile: bigpowers' own Astro site (`website/`, self-docs only),
  the `visual-dashboard` skill + `dashboard/` (local web, port 7742), `receipts.astro` (reads receipts.json).

## Decided so far (round 2)

**One OKF template format, two render paths — not two templates.** Evidence: `website/src/content.config.ts`
uses generic `docsLoader()` + `docsSchema()` (globs markdown + frontmatter, no per-kind transform needed).
`docs/okf-spine.md` envelope (okf_kind/version/generated_by/generated_at/supersedes/commit_range) is
directly compatible — the one gap is Starlight's required `title` field, closed by adding `title:` to
the envelope template (sourced from the doc's own header line), not a runtime transform.

- **Narrative OKF** (story, epic spec, ADR, bug, glossary — countable-story-format prose body) →
  renders **1:1 as a Starlight page**, zero transform. The authoring template IS the render.
- **Data OKF** (cockpit-state, story-metrics, bcp-count, execution-status, cycle-times — structured
  YAML, no prose body — confirmed via live sample `specs/metrics/e38s09.okf.md`) → not a page; feeds a
  **small fixed set of generic dashboard views** (epic board, BCP burndown, bug registry, compliance/
  receipts) that query the content collection by `okf_kind`. Few views, not one per doc type.
- **Q2 resolved as a consequence: Pages only**, single surface. No separate Wiki sync — wiki-named
  dirs (`codebase-wiki/`, `skills-wiki/`) become ordinary narrative-OKF content in the same collection.
- **Deprecation entailed:** `visual-dashboard` skill + local `dashboard/` (port 7742) are replaced by
  the generic dashboard views in the one published site. Feed into T4 (survivor-set) as a "drop" candidate.

## Resolution (final, round 3)

**Adopt `big-docs` verbatim as the target information architecture** — it is not a design exercise
input, it IS the answer: its own README states it's "the gabarito... the canonical reference
implementation of the 3-wave project structure that bigpowers should emit." Confirmed against its
real `DESIGN.md` and folder tree:

- **Wave 1 — GitHub-native** (repo root + `.github/`): README, LICENSE, CONTRIBUTING, CODE_OF_CONDUCT,
  SECURITY, SUPPORT, GOVERNANCE, CITATION.cff, CODEOWNERS, issue/PR templates, CI. Gated independently
  (`validate-wave-1.sh`). Rendered **by GitHub's own UI** (repo homepage, Community tab, Security tab,
  issue/PR forms) — confirmed this is a genuinely separate rendering surface, not a gap: bigpowers'
  own Pages deploy is `build_type: "workflow"` (Actions-driven Astro, not classic folder-serve), so
  Wave 1 files COULD be ingested into the site, but currently aren't (confirmed empty grep on
  `content.config.ts`/`astro.config.mjs`) — a real, separately-tracked gap, not a platform wall.
  **Decision:** 4 files (`CONTRIBUTING`, `CODE_OF_CONDUCT`, `SUPPORT`, `GOVERNANCE`) get mirrored onto
  the site as real pages (build-time embed, root stays the one source); `SECURITY.md`/`LICENSE`/`README`
  stay GitHub-native-only (SECURITY ties to GitHub's own vuln-reporting UI; README is the repo homepage,
  not a docs-site page — the site has its own landing page instead).
- **Wave 2 — GoodDocs** (`docs/`): flat sibling TGDP pack folders — `concept, how-to, reference,
  tutorial, glossary, changelog, release-notes, style-guide, troubleshooting, user-personas, readme,
  images` — richer than 4-quadrant Diátaxis, confirmed as the actual `big-docs/docs/` tree. Also owns
  `AGENTS.md`/`CLAUDE.md`/`CONVENTIONS.md` (§3.11: agent-config files are Wave 2, not Wave 1;
  `CLAUDE.md`/`GEMINI.md` are symlinks to `AGENTS.md`, single source, never divergent copies). Renders
  1:1 onto the site, zero transform.
- **Wave 3 — Specs** (`specs/`): `architecture/{contracts,decisions,threat-models}`, `archive/spikes`,
  `audit/reports`, `bugs`, `epics/{archive,eNN-<slug> capsules}`, `metrics/stories`, `product/snapshots`.
  Only `state.yaml`, `release-plan.yaml`, `execution-status.yaml`, `README.md` loose at root (Invariant
  #1). Stories live inside their epic capsule, never loose (#2). **No `_LATEST` suffix** — git + capsule
  is the current file (#3, independently matches bigspec B8). **No parallel `*-wiki/` mirror folders —
  forbidden by design** (#4, hardens the earlier "single OKF source, no mirror" call from a preference
  into a named structural rule). Generated outputs live inside their owning capsule, never at root (#5).
  **No `.feature/`/`standards/` folder in a project's `specs/`** (#7) — bigpowers-tooling concerns never
  leak into a consumer app's specs.
- **Render split within Wave 3** (this session's own finding, still holds): narrative-OKF (ADR, story,
  bug, audit report — markdown prose body) renders 1:1 as a Starlight page, zero transform — the
  authoring template IS the render, closing the "two templates" question the user correctly rejected.
  Data-OKF (metrics, execution-status, cycle-times — structured YAML, no prose) is not a page; it feeds
  a small fixed set of generic dashboard views (Epic Status Board, Bug Registry, Metrics) queried by
  `okf_kind` — **replacing the `visual-dashboard` skill and local `dashboard/` app entirely** (flagged
  for T4's drop list).

**Diagram (the resolution artifact):** `/private/tmp/claude-501/-Users-danielvm-Developer-bigpowers/26f84c14-325c-4223-841c-bcb35a25af33/scratchpad/bigpowers-doc-architecture.dataflow.json`
rendered to `bigpowers-doc-architecture.html`, published as a Claude Artifact — 3 waves → build (Direct
Render / Aggregator) → 2 site destinations + GitHub UI, all layout checks passing (`orthogonal_arrows`,
`legend_clearance`, `finite_svg`, `single_svg` all green). User-confirmed as matching intent.

**Scope confirmed with user (this round):** website content and `acps-workflow` templates are IN scope;
only bigspec kernel changes are OUT.
*(Superseded by T4 ruling #3: `acps-workflow` is reference-only, not a template target.)*

---

## AMENDMENT (supersedes the `specs/` decision above)

**REVERSAL — user-confirmed.** The resolution above kept `specs/` as a separate top-level tree. That is
now overturned. The confirmed architecture is **one documentation root**:

1. **`docs/` is the single documentation root. `specs/` DISSOLVES into it.**
   Reasoning chain the user confirmed: management information (scope, roadmap, risk, status, metrics)
   *is* project documentation (PMBOK project documents) → all documentation lives in `docs/` → therefore
   no separate `specs/` folder is needed. The ex-`specs/` content becomes `docs/project/`.
2. **Runtime state → `docs/project/status/`** (`state.yaml`, `execution-status.yaml`). The alternative
   considered and rejected was a hidden root `.bigpowers/`; user chose to keep it inside the docs root.
3. **Payoff that makes this coherent:** one set of markdown files serves two consumers — agents read the
   raw repo files, humans read the same files rendered on Pages. No sync step, no mirror (consistent
   with the no-parallel-mirror invariant).
4. **Known migration cost (accepted, not a blocker):** every bigpowers script parses `specs/…` paths.
   Dissolution is a real path migration, sequenced in the epic plan, not a rename.

**Consequence for `big-docs`:** the gabarito's 3-wave model has `docs/` and `specs/` as *siblings*.
Under this amendment Wave 3 becomes a **subtree of Wave 2's folder** (`docs/project/`), not a sibling.
`big-docs`' DESIGN.md and layout invariants need amending to match — tracked as follow-up, since
`big-docs` is the declared "answer key" and must not silently diverge.

**Consequence for wiki (refines, does not reverse, the Pages-only call):** Karpathy's llm-wiki is a
*file layout*, not a platform — `index.md` catalog + interlinked pages + `log.md` append-only journal.
It lives entirely inside `docs/` and renders via Pages; **GitHub's Wiki feature is not used at all**
(separate `repo.wiki.git`, no PR review, separate history → guaranteed drift, and it would be a parallel
mirror). The `maintain-wiki` INGEST/LINT mechanism is genuinely the Karpathy bookkeeping loop and is
**kept**, even though the `*-wiki/` folders themselves are dropped. `log.md` is resurrected from the
archived `obsidian-wiki` attempt as a real artifact.

**Confirmed constraints (this round):** bigpowers generates the full Wave 1 root file set when the repo
has no Template Repository associated; bigpowers is GitHub-native (Actions); Pages renders the site
from the `.md` files.
