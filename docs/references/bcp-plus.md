# BCP Plus — Reference

> The next-generation methodology for sizing functional and non-functional complexity in AI-augmented software engineering. Building on the May 2026 open-source release of Business Complexity Points (BCP).

---

## What Is BCP Plus?

**BCP Plus** is a 13-dimension complexity-rating framework created by Daniel Vieira Magalhães (Head of Operations, CI&T) and released as a methodology whitepaper in May 2026. It extends the original 10-dimension **Business Complexity Points (BCP)** framework — open-sourced by CI&T and Itaú Unibanco — with three explicit non-functional dimensions and an enterprise-grade evaluation protocol engineered for organisations operating hybrid human–AI engineering teams at scale.

The original BCP is a tech-agnostic, universal complexity-sizing methodology designed so "different people arrive at the same result." BCP Plus adds non-functional rigor and AI-assisted counting with measured stability targets.

---

## The 13 Dimensions

### Functional Dimensions (1–10)

| # | Dimension | What It Counts |
|:--|:----------|:---------------|
| 1 | **Boundaries** (External Integrations) | Cross-system communication paths. One element per distinct medium (REST, gRPC, message queue, file transfer). |
| 2 | **Interface Elements** | User-visible screens, forms, widgets. Bucketed: `ceil(static/5) × 3 + ceil(dynamic/5) × 5`. |
| 3 | **Business Rules** | Conditional logic, validations, transformations. **Residual dimension** — receives only what no specific dimension claims. |
| 4 | **Solution Variabilities** | Alternative solution paths (e.g., payment-method selection). One element per distinct variability axis, not per branch. |
| 5 | **Roles / Permissions** | Authorization rules. Identity rule: one element per distinct role-permission combination. |
| 6 | **Domain Entities — Existing** | Existing domain objects the story reads, validates, or persists. |
| 7 | **Domain Entities — New** | New domain objects created by the story. **Mutually exclusive** with dim 6 per entity; higher floor (M) already prices in usage cost. |
| 8 | **Notifications** | Outbound messages (email, push, SMS, webhook). One element per distinct notification event. |
| 9 | **Audits** | Audit-trail requirements. One element per audited entity. |
| 10 | **Background Processes** | Async jobs, scheduled tasks, batch processing. |

### Non-Functional Dimensions (11–13)

| # | Dimension | What It Counts |
|:--|:----------|:---------------|
| 11 | **Quality Attributes** | Performance, scalability, reliability, availability requirements. |
| 12 | **Security & Compliance** | Encryption, data protection, regulatory requirements (LGPD, GDPR, PCI). |
| 13 | **UX & Accessibility** | WCAG compliance, screen-reader support, keyboard navigation, responsive design. |

Each NFR dimension includes a **bottom-rung NFR Gate**: standard-expectation items (e.g., "use HTTPS") score N/A with 0 points and a one-line rationale. The Router always routes every distinct NFR requirement — gating is a sizing judgment, never a routing one.

### NFR Gate Pattern

**Purpose:** Prevent inflating complexity scores with standard-expected non-functional requirements.

**Rule:** An NFR item that is baseline-expected for any professional software project scores 0 points. Only above-standard NFR requirements contribute to dimensions 11–13.

**Examples:**

| NFR Item | Gate Decision | Rationale |
|:---------|:--------------|:----------|
| "Use HTTPS for all endpoints" | 0 points (N/A) | Standard expectation for any web application |
| "Log errors to structured JSON" | 0 points (N/A) | Standard expectation for any production service |
| "WCAG 2.1 AA compliance" | Counted | Above-standard accessibility requirement |
| "SOC 2 Type II audit trail" | Counted | Above-standard compliance requirement |
| "p99 latency < 50ms under 10K RPS" | Counted | Above-standard performance SLO |
| "Hash passwords with bcrypt" | 0 points (N/A) | Standard security expectation |

**Pattern:** For every gated item, record: `[NFR Gate] <item> → 0 pts — standard expectation: <rationale>` in the breakdown. This provides auditability: reviewers can challenge a gate decision without re-running the counter.

### SNAP Compatibility

The whitepaper's Exhibit 5 maps all 14 SNAP (Software Non-functional Assessment Process) subcategories onto combinations of BCP Plus dimensions. Element identity stays BCP-dimension-based; SNAP reconciliation happens through the mapping table. NFR size criteria use SNAP-style countable inputs.

---

## How BCP Counting Works

### Original Pipeline (v1 — bcp-agent)

```
User Story (MD)
    │
    ▼
Step 3: Break Elements     →  Integrations, UI sections, Business Rules
Step 4: External Integrations Complexity
Step 5: UI Elements Complexity
Step 6: Business Rules Complexity
    │
    ▼
Total BCP = Step4 + Step5 + Step6
```

This is the open-source `bcp-agent` available on GitHub. It counts 3 dimensions using GPT-4o-mini via LangChain. The counter reached 19% aggregate CV (coefficient of variation) on a 43-story production baseline.

### BCP Plus Pipeline (v2 — big-counter)

```
User Story (MD)
    │
    ▼
Step 0: Story Type Classification    [Functional | Non-Functional]
Step 1: Story Maturity                [supplementary]
Step 2: Story INVEST Maturity         [supplementary]
    │
    ▼
Step 3: Break Elements                [CRITICAL — structured sections]
    │
    ▼
Step 3.5: Element Router             [NEW — canonical element extraction]
    │  Produces zero or more Complexity Elements, each tagged with
    │  exactly one owning Dimension. Single pass, no separate dedup.
    ▼
Per-Dimension Sizers                  [NEW — pure, LLM-free scoring]
    │  Each Sizer receives only its routed Elements.
    │  Sizers NEVER read raw story text, merge, split, or drop elements.
    │
    ├── dim 1: Boundaries
    ├── dim 2: Interface Elements
    ├── dim 3: Business Rules (residual)
    ├── dim 4: Solution Variabilities
    ├── dim 5: Roles / Permissions
    ├── dim 6: Domain Entities — Existing
    ├── dim 7: Domain Entities — New
    ├── dim 8: Notifications
    ├── dim 9: Audits
    ├── dim 10: Background Processes
    ├── dim 11: Quality Attributes
    ├── dim 12: Security & Compliance
    └── dim 13: UX & Accessibility
    │
    ▼
Total BCP = sum of 13 dimension subtotals
```

The Router solves the key problem of the v1 pipeline: element counting and dimension assignment were conflated in a single LLM prompt, producing noisy results. By separating routing (one LLM call) from sizing (pure decision tables), BCP Plus achieves a target aggregate CV of ~10% (down from 19%).

---

## Architecture Design Principles

### Core Invariants (from ADRs)

1. **Exclusive ownership** — every Complexity Element has exactly one Dimension. Enforced structurally (single enum field set in one pass), not by prompt etiquette.
2. **No re-extraction** — Sizers receive only their routed Elements; no Sizer reads raw story text.
3. **Sum integrity** — `total_bcp` equals Σ of dimension subtotals. Validation failure retries once, then returns an error naming the failed dimension.
4. **Coverage over silence** — unclassifiable elements go to an explicit `unclassified` bucket (score 0), never silently dropped.
5. **Count preservation** — a Sizer sizes exactly the Elements routed to it. Output count = input count.
6. **Criteria-defined sizes** — every Size label (XS–XXXL, Fibonacci-weighted) is defined by enumerable, countable criteria (a decision table), never adjectives.

### Key Concepts

**Aspect Splitting**: The Router may split one sentence into multiple elements when it carries distinct aspects. Example: *"Only admins can approve refunds over $1,000"* → an authorization element (Roles/Permissions) + a threshold-condition element (Business Rules).

**Specificity Precedence**: The Router routes each aspect to the *most specific* Dimension that claims it. Business Rules is the residual — it receives conditional logic only when no specific Dimension owns it.

**Dimension Module**: The code shape of one dimension: prompt file + expected response shape + decision-table scoring, all as pure functions. No LLM I/O inside the module — the calculator renders, calls, and hands the parsed response back, enabling offline replay of recorded responses for threshold tuning.

**Calibration ID**: The complete score-affecting configuration: ruler version + prompt set + decision-table thresholds + pinned model snapshot + sampling params. BCP numbers are comparable iff their calibration_id matches. Any score-affecting change bumps the ID.

**Confidence Verdict**: Every result carries a verdict: `reliable` (maturity > 3), `moderate` (maturity = 3), `low` (maturity < 3). Any element in the `unclassified` bucket caps the verdict at `moderate`. Stability targets (aggregate CV ≈ 10–15%) apply to `reliable` stories only.

---

## Empirical Evidence

The methodology was validated on a **43-story production baseline** from Itaú Unibanco delivery squads. Key findings:

| Metric | BCP (10-dim) | BCP Plus Target |
|:-------|:-------------|:----------------|
| Aggregate CV | 19% | ~10% |
| Primary CV driver | Variabilities dimension (47.1% intrinsic) | Decision-table per-dimension sizing |
| Tail coverage | Concentrated in medium band (5–29 BCP) | Needs small (≤4) and large (≥30) coverage |
| Automation | GPT-4o-mini locked | Model-migration path planned |

The **Variabilities dimension** (dim 4) had the highest intrinsic CV at 47.1% — this is addressed in the big-counter project via ADR-0006's per-dimension decision tables.

---

## Adoption Roadmap

| Stage | When | What |
|:------|:-----|:-----|
| **Stage 1** | Months 1–3 | Pilot open-source BCP counter on 2 squads. Paired-baseline dataset of ≥40 stories. H/BCP dashboard at squad level. |
| **Stage 2** | Months 4–6 | Layer NFR dimensions onto pilot squads. Train estimators on NFR sizing tables. Add NFR Ratio to portfolio reporting. |
| **Stage 3** | Months 7–9 | Migrate from GPT-4o-mini to successor LLM. Replay 43-story protocol; target aggregate CV ≈ 10%. Address Boundaries and Solution Variabilities via per-dimension prompt rewrite. |
| **Stage 4** | Months 10–12 | Roll out across remaining squads. Maturity-score gating in refinement workflow. Embed BCP Plus into vendor contracts and managed-service SLAs. |

---

## Relationship to bigpowers

bigpowers uses BCP as its **complexity-sizing unit** in the build-epic cycle:

- Every story in an epic capsule carries a `[BCP N]` annotation
- Story BCP totals feed into `specs/metrics/cycle-times.yaml`
- The pre-merge checklist uses BCP as a scope guard
- BCP/hr is computed from git-derived effort (e40 Metrics Integrity)

BCP Plus extends this with non-functional complexity — relevant to bigpowers skills that touch NFR concerns:
- `wire-observability` (structured logging, health checks → Quality Attributes)
- `security-review` (data-flow analysis, injection detection → Security & Compliance)
- `wire-ci` (CI pipeline → Quality Attributes)
- `deploy` + `smoke-test` (deployment reliability → Quality Attributes)
- `validate-contracts` (API/data shape checks → integration complexity)
- `design-interface` (UI/UX complexity → Interface Elements, UX & Accessibility)

The `big-counter` project (separate repo) implements BCP Plus as a Python package with:
- **Element Router** (ADR-0001): single-pass canonical extraction with dimension tagging
- **Dimension Modules** (ADR-0007): pure-function sizers with decision tables
- **Stability Harness**: CV measurement, replay corpus for offline threshold tuning
- **MCP Server**: FastMCP tool for agent integration
- **3-provider support**: OpenAI, Anthropic, CI&T Flow (internal proxy)

---

## Risks & Limitations

- **Construct validity**: The 13 dimensions are not perfectly orthogonal — Interface Elements and UX & Accessibility overlap conceptually.
- **External validity**: The baseline is concentrated at one organisation (Itaú) and one delivery model (CI&T). Replication elsewhere is needed.
- **Tail coverage**: The 43-story baseline is concentrated in the medium band (5–29 BCP). Stability on small (≤4) and very large (≥30) items is not measured.
- **Automation bias**: LLM suggestions may anchor human estimators, narrowing apparent variance without improving accuracy.
- **Model risk**: The published counter is locked to GPT-4o-mini. OpenAI deprecation propagates directly to the open-source community release.
- **NFR scope**: Current NFR sizing assumes baseline security/compliance requirements contribute to complexity. Future iterations may move these from scoring dimensions to mandatory "Definition of Done."

---

## Sources

- **BCP Plus Whitepaper**: Daniel Vieira Magalhães, CI&T Insight Series, May 2026
- **Original BCP**: CI&T and Itaú Unibanco, open-sourced May 2026 under CC BY-NC-ND 4.0
- **big-counter implementation**: `/Users/danielvm/Developer/big-counter` — Python, FastAPI, LangChain, FastMCP
- **bigpowers integration**: `specs/release-plan.yaml`, `docs/references/bcp.md`, e40 Metrics Integrity
- **SNAP**: IFPUG SNAP Assessment Practices Manual, Release 2.4 (2013)
- **Function Points**: IFPUG Function Point Counting Practices Manual, Release 4.3.1 (2010)
- **Agile estimation**: Cohn, M. (2005). *Agile Estimating and Planning*
- **Effort estimation survey**: Usman, Mendes, Weidt, & Britto (2014), PROMISE; Tawosi, Moussa, & Sarro (2023), IEEE TSE

---

*verify: `python3 -c "import PyPDF2; r = PyPDF2.PdfReader('/Users/danielvm/Documents/BCP-Plus-Whitepaper.pdf'); assert len(r.pages) == 20, f'Expected 20 pages, got {len(r.pages)}'"` — confirms the source document is intact.*
