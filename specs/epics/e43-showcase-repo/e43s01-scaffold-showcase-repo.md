STORY KEY: E42-S01
TITLE:     Scaffold the showcase app in a separate public repo via seed-conventions
TYPE:      Story
PARENT:    e43
STATUS:    Draft
AUTHOR:    dvm           DATE: 2026-07-03
MATURITY:  3
SIZE:      M

### 1. Business narrative
The methodology's real product is the specs/ trail — but a prospect can only
see one by adopting first. A small REAL app (a utility with genuine logic,
e.g. a CLI or API client — explicitly not a todo list) in a separate public
repo (danielvm-git/bigpowers-showcase), with its full spec cockpit committed
from day one, lets people read a worked example before installing anything.
This story creates that repo and runs the discover/plan phases in it. Slotted
v2.8x so the trail demonstrates the CURRENT methodology (post-e40 honest
metrics), not the deprecated hand-arithmetic pipeline.

### 2. Value statement
As a prospective adopter, I want a public repo scaffolded with seed-conventions
and a committed specs/ cockpit, so that I can read a real bigpowers spec trail
before installing anything.

### 3. Actors and permissions
- Maintainer (dvm) — creates the public repo, runs seed-conventions and the
  discover/plan skills inside it, commits and pushes.
- Prospective adopter (external, read-only) — browses the public repo on GitHub.

### 4. Trigger and preconditions
Trigger: manual — maintainer starts the e43 build in the v2.8x train.
Preconditions: v2.8x reached (e40 metrics pipeline live so the trail is
current-methodology); gh CLI authenticated as danielvm-git; app concept chosen
(utility with genuine logic, not a todo list).

### 5. Main flow and business logic
1. Choose the showcase app: a small utility with genuine logic (CLI or API
   client), explicitly not a todo list.
2. Create the public repo danielvm-git/bigpowers-showcase with gh.
3. In the new repo, run seed-conventions to generate CLAUDE.md, CONVENTIONS.md,
   and the evolved specs/ directory structure.
4. Run scope-work to produce specs/product/SCOPE_LATEST.yaml, then plan-release
   to produce specs/release-plan.yaml; state.yaml records the session.
5. Commit the full cockpit (state.yaml, release-plan.yaml, product/) from
   day one — the spec trail is the product.
Interruption point: after repo creation — scaffolding can resume in a later
session; state.yaml in the showcase repo carries the context.

### 6. Alternative flows and exceptions
6a. Repo name already taken or gh create fails — pick an alternative name,
    update the epic note; verify commands reference the final name.
6b. Chosen app turns out to be trivial (todo-list-shaped) — reject and rechoose;
    the "genuine logic" constraint is a hard requirement of the epic source.
6c. seed-conventions output drifts from current bigpowers structure — fix the
    showcase repo by hand and file the gap against seed-conventions in THIS repo.

### 7. Interface elements
Context: new (a fresh public GitHub repository).
Static elements: CLAUDE.md, CONVENTIONS.md, specs/ directory tree.
Dynamic elements: state.yaml session block, release-plan.yaml epic list.

### 8. Domain model
Entities created (in the showcase repo): CLAUDE.md, CONVENTIONS.md,
specs/state.yaml, specs/release-plan.yaml, specs/product/SCOPE_LATEST.yaml,
specs/ subdirectories (product/, tech-architecture/, verifications/,
epics/archive/). Nothing is created in THIS repo by this story.

### 9. Integrations and boundaries
- GitHub (external, direction: out) — gh repo create / push; read-back via
  gh repo view for verification.
- bigpowers skills (perennial, direction: in) — seed-conventions, scope-work,
  plan-release executed against the showcase repo.
- ADR-0002 local-first boundary — verify commands in THIS repo are limited to
  local artifacts plus read-only gh queries; the showcase repo is verified by
  its own gates.

### 10. Background processes
Not applicable — all steps are interactive maintainer sessions.

### 11. Notifications
Not applicable — public visibility of the repo is the only signal.

### 12. Audit and logging
The showcase repo's git history IS the audit trail — cockpit committed from
day one, Conventional Commits throughout.

### 13. Solution variabilities
- App choice (decision) — any small utility with genuine logic qualifies;
  recorded in the showcase repo's SCOPE_LATEST.yaml.
- Repo name (config) — danielvm-git/bigpowers-showcase is the default; verify
  commands must track any rename (6a).

### 14. Quality attributes *NFR*
- The committed cockpit must reflect the current (post-e40) spec schema —
  no deprecated fields, no hand-computed metrics.
- Repo must be readable as a standalone worked example (no references that
  require the bigpowers repo to resolve).

### 15. Security and compliance *NFR*
- Public repo: no secrets, no tokens, no private data in any commit.
- gh operations use the maintainer's existing auth; nothing stored in specs.

### 16. UX and accessibility *NFR*
Not applicable — deliverable is a browsable GitHub repo, standard GitHub UX.

### 17. Acceptance criteria
Scenario: Cockpit committed from day one (happy path)
  Given a new public GitHub repo for a small real app (utility with genuine
        logic — e.g. a CLI or API client — explicitly not a todo list)
  When  seed-conventions and the discover/plan phases run
  Then  the repo contains CLAUDE.md, CONVENTIONS.md, and a full specs/
        cockpit (state.yaml, release-plan.yaml, product/) committed from
        day one

### 18. Out of scope
- Building any feature of the app (e43s02).
- Bug-fix trail (e43s03).
- Linking from README/docs site or e37 fixture registration (e43s04).
- Any edits to files in THIS repo.

### 19. Open questions
- Which specific utility app? Decided at build time under the "genuine logic,
  not a todo list" constraint; recorded in the showcase repo's scope doc.

### 20. References
- specs/epics/e43-showcase-repo/epic.yaml (source change request 2026-07-03).
- specs/adr/ ADR-0002 (local-first specs — verify boundary).
- skills/seed-conventions/SKILL.md, skills/scope-work/SKILL.md,
  skills/plan-release/SKILL.md (skills exercised).
