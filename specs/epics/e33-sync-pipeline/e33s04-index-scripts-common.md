STORY KEY: E33-S04
TITLE:     Refactor regenerate-lockfile.sh, generate-skill-index.sh, build-skill-index.sh to source skill-common.sh
TYPE:      Story
PARENT:    e33
STATUS:    Draft
AUTHOR:    dvm           DATE: 2026-07-03
MATURITY:  3
SIZE:      M

### 1. Business narrative
The three catalog scripts invoked at the tail of sync-skills.sh —
regenerate-lockfile.sh (writes skills-lock.json), generate-skill-index.sh
(writes SKILL-INDEX.md), and build-skill-index.sh (writes the lexical index
for search-skills) — each carry their own skill iteration and frontmatter
parsing, variants of the same logic now centralised in skill-common.sh
(e33s01). Divergent parsers are how the lockfile, the index, and the
artifacts drift apart — exactly the class of bug the golden self-test (G-04)
exists to catch. This story completes the epic: after it, every consumer of
SKILL.md metadata in the pipeline reads through one parser.

### 2. Value statement
As a maintainer, I want the lockfile and index generators to consume the
shared parse functions, so that skills-lock.json, SKILL-INDEX.md, and the
rendered artifacts can never disagree about what a skill's frontmatter says.

### 3. Actors and permissions
- Maintainer (internal) — runs sync-skills.sh, which chains these scripts.
- CI runner (system) — executes them in the sync-skills workflow.

### 4. Trigger and preconditions
Trigger: `bash scripts/sync-skills.sh` (which invokes all three), or direct
invocation of any of the three scripts.
Precondition: e33s01 complete (library exists); e33s02 already routes their
REPO_ROOT boilerplate through the library.

### 5. Main flow and business logic
1. regenerate-lockfile.sh sources skill-common.sh and replaces its own skill
   enumeration/frontmatter extraction with iterate_skills + parse_frontmatter.
2. generate-skill-index.sh does the same for its index-row generation.
3. build-skill-index.sh does the same for the lexical index it builds from
   SKILL.md frontmatter.
4. Outputs (skills-lock.json, SKILL-INDEX.md, lexical index) remain
   semantically identical: same skill set, same counts, same fields.
5. Full sync run proves the chain: skill count in skills-lock.json equals the
   catalog size (72 at planning time; never hardcoded in docs).

### 6. Alternative flows and exceptions
6a. Skill without parseable frontmatter — skipped consistently by all three
    scripts (single parser guarantees consistency).
6b. Library missing or unsourceable — script fails fast with non-zero exit,
    surfaced by sync-skills.sh's existing FAIL handling.
6c. Output count disagrees with pre-refactor baseline — treated as a
    regression; golden self-test (lockfile vs index assertion) exits 1.

### 7. Interface elements
Not applicable — CLI scripts with unchanged invocation and outputs.

### 8. Domain model
Entities read: SKILL.md files via the shared parser.
Entities written: skills-lock.json, SKILL-INDEX.md, lexical skill index —
same files and schemas as today.

### 9. Integrations and boundaries
- scripts/lib/skill-common.sh (e33s01, direction: in) — single parser.
- scripts/sync-skills.sh (e33s03, direction: in) — invokes all three at the
  end of every sync run.
- golden-g04-selftest.sh (perennial, direction: out) — asserts lockfile/index
  consistency these scripts produce.
- Downstream e39 (depends_on e33): e39's OKF `index.md` is a derived view
  with SKILL-INDEX.md remaining the authority (IMPACT-e38 §Phase 2); keeping
  all index generators on the shared parser is what lets the future
  render_okf_bundle() target derive from the same IR without a sixth parser.

### 10. Background processes
Not applicable — invoked synchronously by sync-skills.sh or a human.

### 11. Notifications
Not applicable — exit codes and stdout, unchanged.

### 12. Audit and logging
Not applicable — outputs are versioned in git; no separate audit trail.

### 13. Solution variabilities
- build-skill-index.sh currently runs best-effort (`|| true` in sync) — that
  tolerance is preserved; only its parsing internals change.

### 14. Quality attributes *NFR*
- Semantic parity: same skill set and counts in all three outputs before and
  after the refactor.
- Deterministic: same inputs → identical lockfile/index content.
- No material wall-clock regression on the full catalog.

### 15. Security and compliance *NFR*
- Read skills/, write only the three existing generated files; no network,
  no secrets.

### 16. UX and accessibility *NFR*
Not applicable — CLI scripts consumed by the pipeline and maintainers.

### 17. Acceptance criteria
Scenario: Full sync keeps catalog consistent (happy path)
  Given the three scripts are refactored onto skill-common.sh
  When  `bash scripts/sync-skills.sh` is run
  Then  it exits 0
  And   `jq '.skills | length' skills-lock.json` equals the catalog skill count (72 at planning time)
  And   `bash scripts/golden-g04-selftest.sh` exits 0

Scenario: All three scripts source the library
  Given the refactor is complete
  When  the three scripts are grepped for the library source line
  Then  regenerate-lockfile.sh, generate-skill-index.sh, and
        build-skill-index.sh each source scripts/lib/skill-common.sh

Scenario: Direct invocation still works
  Given a clean checkout after sync
  When  `bash scripts/regenerate-lockfile.sh` is run standalone
  Then  it exits 0
  And   skills-lock.json is regenerated with the same skill count

Scenario: Unparseable skill skipped consistently (6a)
  Given a skill directory whose SKILL.md frontmatter cannot be parsed
  When  the full sync runs
  Then  that skill is absent from skills-lock.json, SKILL-INDEX.md, and the
        lexical index alike

### 18. Out of scope
- Changing the schema of skills-lock.json, SKILL-INDEX.md, or the lexical
  index.
- Adding new render targets or index views (e39 territory).
- Refactoring scripts outside the three named here.

### 19. Open questions
Not applicable — the three targets and the parity requirement are fixed by
the epic verify command.

### 20. References
- specs/DEEPEN-ARCHITECTURE-REVIEW.md §5.1 (epic source).
- scripts/regenerate-lockfile.sh, scripts/generate-skill-index.sh,
  scripts/build-skill-index.sh (scripts under refactor).
- specs/epics/e33-sync-pipeline/e33s01-skill-common-library.md (shared parser).
- specs/IMPACT-e38-okf-adoption.md §Phase 2 (SKILL-INDEX.md as authority for
  the derived OKF index in e39).
