STORY KEY: E37-S14
TITLE:     seed-conventions — optional Codex wiring step (AGENTS.md + .codex/config.toml)
TYPE:      Story
PARENT:    e37
STATUS:    Draft
AUTHOR:    dvm           DATE: 2026-07-06
MATURITY:  3
SIZE:      S

### 1. Business narrative
Codex CLI users (GitHub issue #52) need project-local onboarding without a
slash-skill catalog. e47 scoped Codex as instruction-file-only; this story
extends seed-conventions' optional local-tool wiring step to emit `.codex/config.toml`
and a Codex-flavoured `AGENTS.md` header when the user opts in.

### 2. Value statement
As a developer seeding a greenfield project for Codex CLI, I want an opt-in
seed step that wires `.codex/config.toml` and AGENTS.md, so Codex loads
bigpowers conventions without manual copy-paste.

### 3. Actors and permissions
- Developer (user) — opts in during seed-conventions interview.
- seed-conventions skill (agent) — writes project files from REFERENCE templates.

### 4. Trigger and preconditions
Trigger: seed-conventions interview reaches optional local-tool wiring step.
Precondition: bigpowers repo has REFERENCE templates; user project has no
existing `.codex/config.toml` or user confirms overwrite.

### 5. Main flow and business logic
1. Offer Codex alongside Cursor + OpenCode in the local-tool wiring question.
2. If opted in: ensure root `AGENTS.md` uses Codex header (`# [Project] — Codex CLI`).
3. Create `.codex/config.toml` from REFERENCE template pointing at root AGENTS.md.
4. If opted out: no `.codex/` directory created; standard seed unchanged.
5. Run sync-skills.sh after SKILL.md / REFERENCE.md edits.

### 6. Alternative flows and exceptions
6a. User already has `.codex/config.toml` — ask before overwrite; merge instructions
    array if user prefers merge over replace.
6b. Duplicate interview step 8 in SKILL.md — collapse to single step 8 listing
    Cursor, OpenCode, and Codex (cleanup included in this story).

### 7. Interface elements
- seed-conventions SKILL.md — interview question text.
- seed-conventions REFERENCE.md — Codex CLI § with config.toml template.
- Generated artifacts: `AGENTS.md`, `.codex/config.toml` (project root).

### 8. Domain model
Entities: AGENTS.md (always-on instructions), `.codex/config.toml` (Codex project
config). No skill symlinks — Codex does not expose a per-skill catalog.

### 9. Integrations and boundaries
- OpenAI Codex CLI (external) — reads global `~/.codex/` then project `.codex/`.
  Discovery ref: https://developers.openai.com/codex/guides/agents-md
- Does NOT modify scripts/install.sh (e37s02) or verify-install.sh (e37s04).

### 10. Background processes
Not applicable.

### 11. Notifications
Not applicable.

### 12. Audit and logging
Git commit in consumer project records seeded files.

### 13. Solution variabilities
- config.toml shape (config) — must match current Codex docs at implement time;
  verify with doc fetch during develop-tdd.

### 14. Quality attributes *NFR*
- Opt-in only — default seed output unchanged when user declines.
- Template must be valid TOML (parseable).

### 15. Security and compliance *NFR*
- Templates must not embed secrets or API keys.
- `.codex/config.toml` references local paths only.

### 16. UX and accessibility *NFR*
Interview question must state Codex is instruction-file-only (not slash skills).

### 17. Acceptance criteria
Scenario: Codex wiring opted in
  Given a greenfield project being seeded
  When  the user opts into Codex local wiring
  Then  `.codex/config.toml` exists and is valid TOML
  And   `AGENTS.md` includes a Codex CLI header
  And   REFERENCE.md documents the Codex template

Scenario: Codex wiring declined
  Given a greenfield project being seeded
  When  the user declines local tool wiring
  Then  no `.codex/` directory is created

### 18. Out of scope
- Global `~/.codex/` install (e37s02).
- using-bigpowers docs (e37s03).
- verify-install harness (e37s04).

### 19. Open questions
- Exact config.toml keys — resolve against OpenAI Codex docs at implementation
  (config.toml companion to AGENTS.md per agent-config reference).

### 20. References
- specs/epics/e37-codex-reach/epic.yaml
- docs/references/agent-config-files-and-okf.md §Codex CLI
- skills/seed-conventions/SKILL.md, REFERENCE.md
- GitHub issue #52
