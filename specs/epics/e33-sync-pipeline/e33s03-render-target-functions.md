STORY KEY: E33-S03
TITLE:     Refactor sync-skills.sh to use render-target functions (one per target)
TYPE:      Story
PARENT:    e33
STATUS:    Draft
AUTHOR:    dvm           DATE: 2026-07-03
MATURITY:  3
SIZE:      M

### 1. Business narrative
sync-skills.sh (272 lines) generates five artifact kinds per skill inside one
monolithic loop: .cursor/rules/<name>.mdc, Gemini SKILL.md, Gemini TOML
command + prompt file, .pi SKILL.md, and .pi prompt template — plus an
optional opencode copy loop. Each target is an inline heredoc-style block
that re-quotes the same parsed frontmatter its own way: the copy-paste-variant
pattern the epic exists to kill. Adding a new IDE target today means cloning
and mutating a block inside the loop; after this story it means writing one
`render_<target>()` function. This is the architectural core of e33 — the
parse→IR→render split — and the extension point e39's `render_okf_bundle()`
plugs into.

### 2. Value statement
As a maintainer, I want sync-skills.sh split into a parse phase (via
skill-common.sh) and one render function per output target, so that adding or
fixing a target touches exactly one function and never the shared loop.

### 3. Actors and permissions
- Maintainer (internal) — runs sync-skills.sh after any SKILL.md change.
- CI runner (system) — executes sync in the sync-skills.yml workflow.

### 4. Trigger and preconditions
Trigger: `bash scripts/sync-skills.sh` (optionally with --opencode=<path>).
Precondition: e33s01 complete — parse_frontmatter and iterate_skills exist in
scripts/lib/skill-common.sh.

### 5. Main flow and business logic
1. sync-skills.sh sources scripts/lib/skill-common.sh.
2. Parse phase: for each skill from iterate_skills, parse_frontmatter yields
   an intermediate representation (IR): name, model, description, assembled
   body (SKILL.md body + extra *.md files, disable-model-invocation stripped).
3. Render phase: the loop dispatches the IR to one function per target —
   render_cursor, render_gemini_skill, render_gemini_command, render_pi_skill,
   render_pi_prompt (names indicative; one function per current target).
4. Each render function owns its target's directory setup, escaping/quoting,
   and file write; the loop owns nothing target-specific.
5. Post-loop steps (gemini manifest, .pi/package.json, opencode.json, opencode
   sync, lockfile/index regeneration, orphan pruning, README badge) are
   preserved unchanged in behaviour.
6. Output artifacts are byte-identical (or semantically identical where noted)
   to the pre-refactor pipeline; the golden self-test passes.

### 6. Alternative flows and exceptions
6a. Skill with no name in frontmatter — skipped, as today.
6b. A render function fails mid-run — script exits non-zero under
    `set -euo pipefail`, matching current failure behaviour.
6c. --opencode target absent or path invalid — opencode sync skipped, as today.
6d. Downstream regeneration (regenerate-lockfile.sh, generate-skill-index.sh)
    fails — sync reports FAIL and exits 1, as today.

### 7. Interface elements
Context: existing CLI script, interface unchanged.
Static elements: same invocation (`bash scripts/sync-skills.sh [--opencode=…]`),
same summary output lines, same exit codes.
Dynamic elements: per-target artifact counts in the summary.

### 8. Domain model
Entities read: SKILL.md files (frontmatter + body), extra skill *.md files,
package.json (version/description).
Entities written: .cursor/rules/*.mdc, .gemini/extensions/bigpowers/** ,
.pi/** , opencode.json, skills-lock.json and SKILL-INDEX.md (via downstream
scripts) — same set as today.

### 9. Integrations and boundaries
- scripts/lib/skill-common.sh (e33s01, direction: in) — supplies parse phase.
- regenerate-lockfile.sh, generate-skill-index.sh, build-skill-index.sh
  (perennial, direction: out) — invoked post-render, unchanged here (e33s04
  refactors their internals).
- Downstream e39 (knowledge graph / OKF adoption, depends_on e33): per
  specs/IMPACT-e38-okf-adoption.md §Phase 2, e39 adds `render_okf_bundle()`
  generating specs/skills-wiki/ as a new render target. This story's
  function-per-target dispatch is the contract that makes that a LOW-risk,
  one-function addition — the render function signature (IR in, files out)
  must be stable and documented for e39.

### 10. Background processes
Not applicable — synchronous CLI script invoked by human or CI.

### 11. Notifications
Not applicable — stdout summary and exit code, as today.

### 12. Audit and logging
Not applicable — no persistent audit trail; git history covers artifacts.

### 13. Solution variabilities
- IR shape (globals vs associative array vs positional args) — implementer's
  choice, but every render function must consume the same shape.
- Render function registry (explicit call list vs array of function names) —
  array preferred so adding a target is a one-line registration plus one
  function.

### 14. Quality attributes *NFR*
- Wall-clock: no material regression vs current sync (full run remains within
  the same order of magnitude on 72 skills).
- Deterministic: same SKILL.md inputs → identical artifacts, every run.
- Extensibility: adding a render target requires one new function and one
  registration line, zero edits to the shared loop.

### 15. Security and compliance *NFR*
- Same filesystem footprint as today: writes only under repo-local generated
  dirs; no network, no secrets, no eval of skill content.

### 16. UX and accessibility *NFR*
Not applicable — CLI script consumed by maintainers and CI.

### 17. Acceptance criteria
Scenario: Full sync produces all target artifacts (happy path)
  Given the refactored sync-skills.sh
  When  `bash scripts/sync-skills.sh` is run
  Then  it exits 0
  And   .cursor/rules/audit-code.mdc exists
  And   .gemini/extensions/bigpowers/skills/audit-code/SKILL.md exists
  And   .pi/skills/audit-code/SKILL.md exists

Scenario: One function per render target
  Given the refactored script
  When  its structure is inspected
  Then  each of the five current per-skill targets is produced by its own
        render function
  And   the per-skill loop contains no target-specific write logic

Scenario: Output parity with pre-refactor pipeline
  Given artifacts generated by the pre-refactor script are recorded
  When  the refactored script runs on the same SKILL.md inputs
  Then  the generated artifact set is identical in paths and content
  And   `bash scripts/golden-g04-selftest.sh` exits 0

Scenario: Skill without a name is skipped (6a)
  Given a skill directory whose SKILL.md frontmatter lacks a name
  When  sync runs
  Then  that directory produces no artifacts
  And   the run still exits 0

Scenario: Downstream regeneration failure propagates (6d)
  Given regenerate-lockfile.sh exits non-zero
  When  sync runs
  Then  sync reports the lockfile FAIL message
  And   exits 1

### 18. Out of scope
- Adding any new render target (e39 adds render_okf_bundle later).
- Refactoring regenerate-lockfile.sh / index scripts internals (e33s04).
- Changing artifact formats, paths, or the CLI interface.

### 19. Open questions
- Whether the opencode `--opencode` copy loop becomes a render function or
  stays a post-loop step (it copies raw SKILL.md, not the IR) — decide during
  implementation; either preserves behaviour.

### 20. References
- specs/DEEPEN-ARCHITECTURE-REVIEW.md §5.1 (epic source).
- scripts/sync-skills.sh (current 272-line monolith under refactor).
- specs/IMPACT-e38-okf-adoption.md §Phase 2 and dependency table (e39's
  render_okf_bundle rides on this architecture).
- specs/epics/e33-sync-pipeline/e33s01-skill-common-library.md (parse phase).
