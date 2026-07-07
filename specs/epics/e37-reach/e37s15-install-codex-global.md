STORY KEY: E37-S15
TITLE:     install.sh — global ~/.codex/ AGENTS.md starter symlink
TYPE:      Story
PARENT:    e37
STATUS:    Draft
AUTHOR:    dvm           DATE: 2026-07-06
MATURITY:  3
SIZE:      S

### 1. Business narrative
Project seed covers per-repo Codex wiring; global install must give Codex users
a zero-config entry point before they run seed-conventions. This story adds
managed symlinks under `~/.codex/` mirroring the pi/Claude install pattern but
for Codex's always-on AGENTS.md model.

### 2. Value statement
As a Codex CLI user who ran `bigpowers setup`, I want a global AGENTS.md starter
linked into `~/.codex/`, so Codex loads bigpowers onboarding before I seed a
project.

### 3. Actors and permissions
- Developer — runs scripts/install.sh or bigpowers setup.
- install.sh — writes managed symlinks only under ~/.codex/.

### 4. Trigger and preconditions
Trigger: install.sh invoked without --uninstall.
Precondition: bundled starter template exists in bigpowers repo
(`docs/templates/codex/AGENTS.md`).

### 5. Main flow and business logic
1. Add `docs/templates/codex/AGENTS.md` starter (points to using-bigpowers,
   seed-conventions, issue #52 / e37 epic).
2. Implement install_codex() — mkdir ~/.codex, symlink AGENTS.md to starter.
3. Implement uninstall_codex() — unlink_if_managed for ~/.codex/AGENTS.md only.
4. Wire into main install/uninstall dispatch; print "Codex CLI → ~/.codex/" in output.
5. --dry-run must show Codex section without writing files.

### 6. Alternative flows and exceptions
6a. User has own ~/.codex/AGENTS.md — unlink_if_managed only removes symlinks
    pointing into REPO_ROOT; user files preserved.
6b. Codex not installed — install still succeeds; AGENTS.md ready when Codex runs.

### 7. Interface elements
- scripts/install.sh — install_codex, uninstall_codex, dispatch.
- docs/templates/codex/AGENTS.md — bundled starter content.

### 8. Domain model
~/.codex/AGENTS.md symlink → REPO_ROOT/docs/templates/codex/AGENTS.md.

### 9. Integrations and boundaries
- Codex CLI global config path ~/.codex/ (external).
- Does not write .codex/config.toml globally (project-scoped per OpenAI docs).

### 10–16. (N/A or standard)
Security: no secrets in starter template. NFR: dry-run safe; uninstall idempotent.

### 17. Acceptance criteria
Scenario: Global Codex install
  Given bigpowers source or global package
  When  install.sh runs (non-dry-run)
  Then  ~/.codex/AGENTS.md is a symlink to the bundled starter
  And   uninstall removes only managed symlinks

Scenario: Dry-run visibility
  When  install.sh --dry-run runs
  Then  output includes a Codex CLI section

### 18. Out of scope
- Project .codex/config.toml (e37s01).
- Codex skill catalog / slash commands.

### 19. Open questions
None — pattern mirrors install_pi with single AGENTS.md target.

### 20. References
- scripts/install.sh (install_claude, install_pi patterns)
- specs/epics/e37-reach/epic.yaml (e37s15)
- GitHub issue #52
