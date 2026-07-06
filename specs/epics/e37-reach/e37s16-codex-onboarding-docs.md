STORY KEY: E37-S16
TITLE:     using-bigpowers — Codex CLI onboarding section
TYPE:      Story
PARENT:    e37
STATUS:    Draft
AUTHOR:    dvm           DATE: 2026-07-06
MATURITY:  3
SIZE:      S

### 1. Business narrative
Install and seed paths exist after e37s01–s02; users still need a single
onboarding doc explaining how Codex differs from Cursor slash skills and what
to run first. using-bigpowers is the canonical entry skill.

### 2. Value statement
As a new Codex user, I want using-bigpowers to explain global vs project Codex
setup, so I know to run setup then seed-conventions without expecting /skills.

### 3. Actors and permissions
- Developer — reads using-bigpowers via Codex loading AGENTS.md.
- Agent — follows onboarding flow when user asks "where do I start?".

### 4. Trigger and preconditions
Trigger: user invokes using-bigpowers or reads bundled ~/.codex/AGENTS.md starter.
Precondition: e37s01 and e37s02 merged or docs reference planned paths accurately.

### 5. Main flow and business logic
1. Add "Codex CLI" subsection under Install / Local tools in using-bigpowers/SKILL.md.
2. Document: global `bash scripts/install.sh` → ~/.codex/AGENTS.md; project
   seed via seed-conventions optional step → .codex/config.toml.
3. Explicit contrast: Codex uses AGENTS.md always-on instructions, not bigpowers
   slash-skill catalog (e47 decision).
4. Cross-link docs/references/agent-config-files-and-okf.md §Codex.
5. Run sync-skills.sh.

### 6. Alternative flows
User on Codex only (no Cursor) — section must stand alone without Cursor prerequisites.

### 7. Interface elements
- skills/using-bigpowers/SKILL.md — new Codex section.
- Generated .cursor/rules/using-bigpowers.mdc, .gemini, .pi artifacts.

### 8–16. Domain / NFR
Single source of truth for Codex onboarding copy; keep section under ~40 lines.

### 17. Acceptance criteria
Scenario: Codex onboarding documented
  Given using-bigpowers SKILL.md
  When  a reader searches for Codex
  Then  they find install + seed steps and the no-slash-skills note

### 18. Out of scope
- Website docs (e33 done separately if needed).
- Codex MCP or plugin install.

### 19. Open questions
None.

### 20. References
- skills/using-bigpowers/SKILL.md
- docs/references/agent-config-files-and-okf.md
- specs/epics/e37-codex-reach/epic.yaml
