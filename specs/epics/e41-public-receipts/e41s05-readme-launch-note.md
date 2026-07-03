STORY KEY: E41-S05
TITLE:     README + launch note point to the live receipts page
TYPE:      Story
PARENT:    e41
STATUS:    Draft
AUTHOR:    dvm           DATE: 2026-07-03
MATURITY:  3
SIZE:      S

### 1. Business narrative
The receipts page is the headline deliverable of the v2.7x/v3.0 Semantic Bridge
release — it proves bigpowers' discipline with live evidence. But if the page is
live and nobody knows to look at it, the differentiator is invisible. The README
is the first thing a prospective user sees; a link to the live receipts page
with one-line framing ("this methodology publishes its own evidence") converts
claims into verifiable proof at the first touchpoint. A launch-note paragraph
in docs/RELEASE.md provides context for the v3.0 release.

### 2. Value statement
As a prospective bigpowers user, I want to see evidence of the methodology's
discipline before I invest time, so I can make an informed adoption decision.

### 3. Actors and permissions
- Documentation maintainer (internal) — edits README.md and docs/RELEASE.md.

### 4. Trigger and preconditions
Trigger: manual edit of README.md and docs/RELEASE.md.
Precondition: receipts page is live on the e28 docs site (e41s02 complete).
Precondition: canonical README structure is documented (memory: readme-must-stay-complete).

### 5. Main flow and business logic
1. Identify appropriate location in README for receipts link (near top, visible).
2. Add one-line framing: "This methodology publishes its own evidence — see the live receipts page."
3. Link to the live /receipts URL on the docs site.
4. Draft a launch-note paragraph in docs/RELEASE.md contextualizing the receipts page.
5. Preserve canonical README structure — add, don't restructure.

### 6. Alternative flows and exceptions
6a. Receipts page not yet live — add link as HTML comment, activate post-deploy.
6b. README restructuring proposed — defer to separate discussion, keep this story additive only.

### 7. Interface elements
Context: existing (README.md, docs/RELEASE.md).
Static elements: receipts link text, framing line, launch note paragraph.
Dynamic elements: live receipts URL (config — depends on docs site deployment).

### 8. Domain model
Entities modified: README.md (link added), docs/RELEASE.md (launch note added).
Entities referenced: e28 docs site /receipts URL.

### 9. Integrations and boundaries
- e41s02 receipts page (direction: in) — must be live before link is meaningful.
- README.md (direction: in/out) — add link, preserve structure.
- docs/RELEASE.md (direction: in/out) — add launch note.

### 10. Background processes
Not applicable — manual documentation edit.

### 11. Notifications
Not applicable — no automated alert.

### 12. Audit and logging
Not applicable — git diff serves as the change record.

### 13. Solution variabilities
- Link placement (config) — top of README, after description, before installation.
- Framing text (config) — exact wording may evolve with messaging.

### 14. Quality attributes *NFR*
- Link validity: must point to a live, resolving URL.
- Structure preservation: README section count unchanged (additive edit only).

### 15. Security and compliance *NFR*
- External link to own docs site — no third-party dependency.
- No tracking, no analytics in the link.

### 16. UX and accessibility *NFR*
- Link text is descriptive ("live receipts page") — not "click here".
- Framing line is a complete sentence, screen-reader friendly.

### 17. Acceptance criteria
Scenario: Link added to README (happy path)
  GIVEN the receipts page is live on the docs site
  WHEN the README is edited
  THEN a link to /receipts exists with one-line framing
  AND grep -qi 'receipts' README.md exits 0
  AND the canonical README structure is preserved (sections unchanged)

Scenario: Launch note drafted
  GIVEN the v3.0 release is approaching
  WHEN docs/RELEASE.md is updated
  THEN a paragraph describes the receipts page as a launch centerpiece
  AND the note contextualizes the evidence methodology

Scenario: Receipts not yet live (6a)
  GIVEN the receipts page is not yet deployed
  WHEN the README is edited
  THEN the link is added as an HTML comment <!-- activate post-deploy -->
  OR the edit is deferred until the page is live

### 18. Out of scope
- Restructuring the README (additive edit only — memory: readme-must-stay-complete).
- Creating a dedicated marketing page for receipts.
- Adding receipts links to other documentation pages.

### 19. Open questions
- Should the receipts link mention specific numbers (e.g., "96% compliance") or
  stay generic? Generic is safer — numbers change, framing shouldn't.
- How to handle if the receipts page URL changes post-launch? Update the link as
  part of the deployment that changes the URL.

### 20. References
- README.md (target file).
- docs/RELEASE.md (launch note target).
- specs/epics/e41-public-receipts/epic.yaml (parent epic).
- specs/epics/e28-docs-website/epic.yaml (docs site — hosts receipts page).
