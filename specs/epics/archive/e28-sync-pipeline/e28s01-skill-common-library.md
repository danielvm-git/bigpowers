STORY KEY: E33-S01
TITLE:     Create scripts/lib/skill-common.sh with shared functions (resolve_repo_root, parse_frontmatter, iterate_skills)
TYPE:      Story
PARENT:    e28
STATUS:    Draft
AUTHOR:    dvm           DATE: 2026-07-03
MATURITY:  3
SIZE:      M

### 1. Business narrative
Thirteen scripts under scripts/ independently re-derive REPO_ROOT via the same
`$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)` incantation, and several of
them (sync-skills.sh, regenerate-lockfile.sh, generate-skill-index.sh,
build-skill-index.sh) each carry their own awk/sed frontmatter extraction and
their own `for skill_dir in "$SKILLS_ROOT"/*/` iteration loop. Every copy is a
divergence point: a frontmatter parsing fix applied to one script silently
misses the others. A single shared library eliminates the copy-paste-variant
pattern at its root and is the foundation the rest of e28 (and e39's future
render target) builds on.

### 2. Value statement
As a maintainer, I want one shared bash library that owns repo-root
resolution, SKILL.md frontmatter parsing, and skill-directory iteration, so
that every script consumes identical, tested logic instead of drifting copies.

### 3. Actors and permissions
- Maintainer (internal) — sources the library from scripts and interactively.
- Scripts under scripts/ (system) — source the library at startup.

### 4. Trigger and preconditions
Trigger: any script does `source scripts/lib/skill-common.sh`.
Precondition: repository checked out with skills/ directory and SKILL.md
sources present.

### 5. Main flow and business logic
1. Create scripts/lib/skill-common.sh, safe to source under `set -euo pipefail`.
2. Implement `resolve_repo_root` — returns the repo root regardless of the
   caller's depth (scripts/ or scripts/lib/), replacing the per-script
   BASH_SOURCE incantation; also resolves SKILLS_ROOT (skills/ subdirectory
   when it exists, repo root fallback, matching current sync-skills.sh logic).
3. Implement `parse_frontmatter <SKILL.md>` — extracts name, model, and the
   possibly-multiline description from YAML frontmatter (current awk logic in
   sync-skills.sh), exposing them to the caller (e.g. via variables or stdout).
4. Implement `iterate_skills` — enumerates skill directories under
   SKILLS_ROOT that contain a SKILL.md, in stable sorted order.
5. Guard against double-sourcing (idempotent include).

### 6. Alternative flows and exceptions
6a. parse_frontmatter called on a file with no frontmatter — returns non-zero,
    caller can skip the file (current scripts `continue` on empty name).
6b. parse_frontmatter called on a missing path — returns non-zero with a
    message on stderr.
6c. skills/ directory absent — resolve_repo_root falls back to repo root as
    SKILLS_ROOT, matching current sync-skills.sh behaviour.

### 7. Interface elements
Context: new (bash library, no UI).
Static elements: function names resolve_repo_root, parse_frontmatter,
iterate_skills; exit codes 0/non-zero.
Dynamic elements: parsed name/model/description values per SKILL.md.

### 8. Domain model
Entities read: SKILL.md files (YAML frontmatter: name, model, description),
skills/ directory layout. No entities written — the library is read-only.

### 9. Integrations and boundaries
- scripts/sync-skills.sh and 12 sibling scripts (perennial, direction: out) —
  will source this library in e28s02–e28s04.
- Downstream e39 (knowledge graph / OKF adoption, depends_on e28): the future
  `render_okf_bundle()` target described in specs/IMPACT-e38-okf-adoption.md
  §Phase 2 will consume parse_frontmatter and iterate_skills from this
  library, so their signatures are a stability boundary.

### 10. Background processes
Not applicable — library is sourced synchronously by calling scripts.

### 11. Notifications
Not applicable — exit codes and stderr are the only signalling mechanism.

### 12. Audit and logging
Not applicable — deterministic pure functions, no persistent state.

### 13. Solution variabilities
- Output convention of parse_frontmatter (globals vs stdout key=value) —
  implementer's choice, but must be consistent for all e28 consumers.

### 14. Quality attributes *NFR*
- Sourcing the library adds < 50ms overhead per script invocation.
- Deterministic: same SKILL.md input → same parsed output, every run.
- Portable across BSD/GNU userlands (macOS + Linux CI), like sync-skills.sh.

### 15. Security and compliance *NFR*
- Read-only filesystem access; no network, no secrets, no eval of file content.

### 16. UX and accessibility *NFR*
Not applicable — bash library consumed by scripts, no human-facing surface.

### 17. Acceptance criteria
Scenario: Library sources cleanly and parses a real skill (happy path)
  Given the repository is checked out with skills/audit-code/SKILL.md present
  When  `source scripts/lib/skill-common.sh && parse_frontmatter skills/audit-code/SKILL.md` is run
  Then  the command exits 0
  And   the parsed name equals "audit-code"

Scenario: Iterating skills matches the current pipeline count
  Given the library is sourced
  When  iterate_skills is invoked
  Then  it emits one entry per directory under skills/ containing a SKILL.md
  And   the entry count matches the skill count reported by sync-skills.sh

Scenario: Frontmatter missing (6a)
  Given a markdown file without YAML frontmatter
  When  parse_frontmatter is called on it
  Then  it returns a non-zero status
  And   the calling script can skip the file without aborting

Scenario: Safe under strict mode
  Given a script running with `set -euo pipefail`
  When  it sources scripts/lib/skill-common.sh twice
  Then  no error is raised and functions remain defined

### 18. Out of scope
- Refactoring any existing script to use the library (e28s02–e28s04).
- Render-target functions for sync-skills.sh (e28s03).
- OKF bundle generation (e39).

### 19. Open questions
Not applicable — function set is fixed by the epic story title and the
existing duplicated logic it replaces.

### 20. References
- specs/DEEPEN-ARCHITECTURE-REVIEW.md §5.1 (epic source).
- scripts/sync-skills.sh (current frontmatter/iteration logic to extract).
- specs/IMPACT-e38-okf-adoption.md §Phase 2 (future render_okf_bundle consumer).
