STORY KEY: E41-S02
TITLE:     Render /receipts page on the e28 docs site from receipts.json
TYPE:      Story
PARENT:    e41
STATUS:    Draft
AUTHOR:    dvm           DATE: 2026-07-03
MATURITY:  3
SIZE:      M

### 1. Business narrative
The evidence machinery exists (or is funded), but it is invisible: ~86% of
the backlog's value is stuck at "user can't see it". bigpowers' only genuine
differentiator vs Superpowers/GSD/BMAD/spec-kit is that it PROVES its
discipline instead of claiming it. This story converts that proof into a
public /receipts page on the e28 docs site, rendered at build time from
specs/receipts.json (e41s01) — turning "user can't see it" into "user can
verify it".

### 2. Value statement
As a prospective user evaluating bigpowers, I want a live public page
showing each quality evidence source with its value, freshness, and the
command that produced it, so that I can verify the methodology's claims
instead of taking them on faith.

### 3. Actors and permissions
- Prospective user / evaluator (external, anonymous) — reads the public page.
- Maintainer (internal) — owns the page source in website/.
- Site build (system) — consumes specs/receipts.json at build time.

### 4. Trigger and preconditions
Trigger: production build of the website (locally or via the docs-site
workflow, wired in e41s03).
Preconditions: the e28 docs site exists (hard dependency); a receipts.json
is present at build time (produced by e41s01).

### 5. Main flow and business logic
1. The Astro build reads specs/receipts.json.
2. A receipts page is generated at receipts/index.html in website/dist.
3. The page shows one section per evidence source (compliance,
   golden_suite, metrics, traceability), each with its value, freshness
   timestamp (generated_at), and provenance command.
4. Sections whose source is `absent` render an explicit "not yet measured"
   state.
5. Backfilled metrics are visually quarantined per e40s07 — visibly
   distinguished from measured values, never blended in.
Interruption point: N/A (static build).

### 6. Alternative flows and exceptions
6a. Section tagged source: absent — render "not yet measured"; never a
    fabricated or placeholder number.
6b. Section tagged source: backfilled — render the value inside the e40s07
    visual quarantine treatment so it cannot be mistaken for a measured
    number.
6c. receipts.json missing at build time — build-level concern; the CI
    ordering guarantee (generator runs before the site build) is owned by
    e41s03.

### 7. Interface elements
Context: extend (new page on the existing e28 Astro site).
Static elements: page route /receipts, one section block per evidence
source, "not yet measured" state, backfilled-quarantine treatment.
Dynamic elements: per-section value, generated_at timestamp, provenance
command — all data-driven from receipts.json.

### 8. Domain model
Entity read: specs/receipts.json (receipt document from e41s01 — sections
with value, generated_at, source tag, producing command).
Entity written: website/dist/receipts/index.html (generated static page)
from source website/src/pages/receipts.astro.

### 9. Integrations and boundaries
- e28 docs site (hard dependency, direction: in) — the site must exist to
  host the page; this story extends website/ (Astro).
- e40 honest metrics (hard dependency, direction: in) — the metrics section
  displays only e40-format values with source tags; the backfilled
  quarantine treatment follows e40s07. Displaying pre-e40 numbers is
  exactly the dishonesty this page exists to reject.
- e41s01 build-receipts.sh (internal, direction: in) — sole data source;
  the page reads receipts.json, never the raw evidence artifacts.
- e38 traceability (soft dependency, direction: in) — the traceability
  section renders "not yet measured" until e38 lands.
- e37 golden suite (soft dependency, direction: in) — the golden-suite
  section renders "not yet measured" until e37s02–s04 land.

### 10. Background processes
Not applicable — static page generated at build time; no runtime process.

### 11. Notifications
Not applicable — the page itself is the communication artifact.

### 12. Audit and logging
Provenance is rendered on-page: every section shows the command that
produced its value and when. No additional logging.

### 13. Solution variabilities
- Section list (data-driven) — the page renders whatever sections
  receipts.json carries; adding a fifth evidence source requires no page
  logic change beyond styling.
- "Not yet measured" copy (content) — single explicit string, no per-section
  variants needed initially.

### 14. Quality attributes *NFR*
- Static output — no client-side data fetching; page is fully rendered at
  build time.
- Freshness is honest: timestamps come from receipts.json generated_at, not
  from the page build clock.

### 15. Security and compliance *NFR*
- Honesty guarantee (epic design rule): every evidence section degrades to
  an explicit "not yet measured" state when its source is absent — the page
  never fabricates, defaults, or placeholder-fills a number. Backfilled
  values are visually quarantined per e40s07 so they cannot pass as
  measured.
- Static public page — no user input, no secrets, no runtime attack surface.

### 16. UX and accessibility *NFR*
- The distinction between measured, backfilled, and "not yet measured" must
  be conveyed by text/markup, not colour alone (accessible quarantine
  treatment).
- Follows existing e28 site layout and navigation conventions.

### 17. Acceptance criteria
Scenario: Receipts page rendered from receipts.json (happy path)
  Given a production build of the website with a receipts.json present
  When  website/dist is inspected
  Then  receipts/index.html exists
  And   it shows one section per evidence source with its value, freshness
        timestamp, and provenance command

Scenario: Absent source renders "not yet measured" (6a)
  Given a receipts.json section whose source is absent
  When  the production build runs
  Then  that section renders an explicit "not yet measured" state
  And   never a fabricated or placeholder number

Scenario: Backfilled metrics visually quarantined (6b)
  Given a receipts.json metrics section tagged source: backfilled
  When  the production build runs
  Then  the rendered value is visually quarantined per e40s07
  And   cannot be mistaken for a measured number

### 18. Out of scope
- Generating receipts.json (e41s01).
- CI wiring so the page rebuilds on every main push (e41s03).
- Schema validation of receipts.json (e41s04).
- README/launch-note pointing at the page (e41s05).

### 19. Open questions
- Until e38 and e37s02–s04 land (soft dependencies), the traceability and
  golden-suite sections will ship in the "not yet measured" state — this is
  by design, not a blocker; confirm no launch messaging implies otherwise.

### 20. References
- specs/epics/e41-public-receipts/epic.yaml (source change request and
  graceful-degradation design rule).
- specs/epics/e40-metrics-integrity/ (e40s07 backfill quarantine treatment).
- website/ (e28 Astro docs site).
- e41s01-build-receipts.md (receipts.json producer and schema).
