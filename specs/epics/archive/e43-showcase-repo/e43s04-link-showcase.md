STORY KEY: E42-S04
TITLE:     Link the showcase from README + docs site; register as e37 golden-story fixture candidate
TYPE:      Story
PARENT:    e43
STATUS:    Draft
AUTHOR:    dvm           DATE: 2026-07-03
MATURITY:  3
SIZE:      S

### 1. Business narrative
The showcase repo (built in e43s01-s03) demonstrates bigpowers in action — but
only if people can find it. A "see it working" link from the README and the
e28 docs site converts the showcase from an internal artifact into a public
demonstration. Registering the showcase as an e37 golden-story fixture candidate
also feeds the golden suite: the showcase repo's spec trail can serve as test
material for agent-driven golden stories, closing the loop between demonstration
and quality assurance.

### 2. Value statement
As a prospective bigpowers user, I want a one-click path to see the methodology
working on a real app, so I can evaluate it without installing anything.

### 3. Actors and permissions
- Documentation maintainer (internal) — edits README.md, docs site, and e37 epic.yaml.

### 4. Trigger and preconditions
Trigger: manual edit after showcase repo is complete.
Precondition: showcase repo is public and populated (e43s01-s03 complete).
Precondition: e28 docs site is live (for docs site link).

### 5. Main flow and business logic
1. Add showcase link to README.md with one-line framing ("see it working").
2. Preserve canonical README structure (memory: readme-must-stay-complete).
3. Add showcase link to the e28 docs site (alongside receipts page).
4. Register showcase repo as fixture candidate in e37 epic.yaml.
5. Note that the showcase is verified by its own gates, per local-first specs (ADR-0002).

### 6. Alternative flows and exceptions
6a. Showcase repo not yet public — add link as HTML comment, activate post-launch.
6b. Docs site not yet live — add README link only, defer docs site link.

### 7. Interface elements
Context: existing (README.md, e28 docs site, e37 epic.yaml).
Static elements: showcase link, one-line framing text, fixture registration note.
Dynamic elements: showcase repo URL (config).

### 8. Domain model
Entities modified: README.md (link added), e28 docs site (link added), e37 epic.yaml (fixture note).
Entities referenced: danielvm-git/bigpowers-showcase (target repo).

### 9. Integrations and boundaries
- e43s01-s03 showcase repo (direction: in) — must exist before linking.
- README.md (direction: in/out) — add link, preserve structure.
- e28 docs site (direction: in/out) — add link alongside receipts.
- e37 golden stories (direction: out) — fixture candidate registration.
- ADR-0002 (direction: in) — local-first specs rule.

### 10. Background processes
Not applicable — manual documentation edit.

### 11. Notifications
Not applicable — no automated alert.

### 12. Audit and logging
Not applicable — git diff serves as the change record.

### 13. Solution variabilities
- Link placement (config) — README: near top, after description. Docs site: alongside receipts.
- Fixture registration format (config) — e37 epic.yaml note field.

### 14. Quality attributes *NFR*
- Link validity: must point to a live, public repo.
- Structure preservation: README sections unchanged (additive edit only).

### 15. Security and compliance *NFR*
- Link to own public repo — no third-party dependency.
- No tracking, no analytics in the link.

### 16. UX and accessibility *NFR*
- Link text is descriptive ("see it working — bigpowers showcase repo").
- Framing line is a complete sentence.

### 17. Acceptance criteria
Scenario: Showcase linked from README (happy path)
  GIVEN the showcase repo is public and populated
  WHEN the README is edited
  THEN a "see it working" link points to the showcase with one-line framing
  AND grep -qi 'showcase' README.md exits 0
  AND the canonical README structure is preserved

Scenario: Showcase registered as fixture candidate
  GIVEN the showcase repo is complete
  WHEN e37 epic.yaml is updated
  THEN grep -qi 'showcase' specs/epics/e42-golden-stories/epic.yaml exits 0
  AND the fixture note describes the showcase as candidate material

Scenario: Showcase not yet public (6a)
  GIVEN the showcase repo is not yet public
  WHEN the README edit is attempted
  THEN the link is added as an HTML comment or deferred

### 18. Out of scope
- Creating a dedicated showcase page on the docs site (link only).
- Verifying the showcase repo's quality (it is verified by its own gates).
- Adding the showcase to any CI pipeline in bigpowers.

### 19. Open questions
- Should the fixture registration specify which golden stories the showcase
  supports, or leave it as a general "candidate" note? General note is
  sufficient — specific story matching happens in e37 golden story YAMLs.

### 20. References
- README.md (target file).
- specs/epics/e42-golden-stories/epic.yaml (fixture registration target).
- specs/epics/e43-showcase-repo/epic.yaml (parent epic).
- specs/adr/ADR-0002.md (local-first specs — showcase verified by its own gates).
