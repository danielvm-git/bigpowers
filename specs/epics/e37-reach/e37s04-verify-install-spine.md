STORY KEY: E37-S04
TITLE:     verify-install.sh — AGENTS.md spine and OSS P1 assertions
TYPE:      Story
PARENT:    e37
STATUS:    Draft
AUTHOR:    dvm           DATE: 2026-07-06
MATURITY:  3
SIZE:      S

### 1. Business narrative
e47 added verify-install harness for pi/OpenCode; AGENTS.md spine must be regression-
tested the same way so CI and local `bash scripts/verify-install.sh` catch
drift in install output and seed templates.

### 2. Value statement
As a maintainer, I want verify-install to assert Codex install dry-run and
seed-conventions Codex templates, so e37 cannot ship broken wiring silently.

### 3. Actors and permissions
- CI workflow (verify-install job) — runs harness on every PR touching install/seed.
- Developer — runs script locally before release.

### 4. Trigger and preconditions
Precondition: e37s01–s03 implemented (templates and install_codex exist).

### 5. Main flow and business logic
1. Extend verify-install.sh dry-run checks: output contains Codex CLI section.
2. Assert docs/templates/codex/AGENTS.md exists and passes secret grep (no keys).
3. Assert seed-conventions REFERENCE contains parseable config.toml block (tomllib).
4. Optional scratch-dir test: copy REFERENCE template to temp .codex/config.toml,
   validate TOML parse (mirrors e47 REFERENCE JSON pattern).
5. Full harness exit 0 in CI.

### 6. Alternative flows
Offline CI — dry-run only, no real ~/.codex writes (same as existing harness).

### 7. Interface elements
- scripts/verify-install.sh — new assert functions / grep blocks.

### 8–16. NFR
Fast (<5s added); no network; no writes outside TMPDIR.

### 17. Acceptance criteria
Scenario: Harness passes with Codex support
  When  bash scripts/verify-install.sh runs
  Then  exit code is 0
  And   AGENTS.md spine and OSS P1 checks execute

### 18. Out of scope
- Live Codex CLI binary invocation.
- E2E Codex session test.

### 19. Open questions
None.

### 20. References
- scripts/verify-install.sh (e47s04 patterns)
- specs/epics/e37-codex-reach/epic.yaml
