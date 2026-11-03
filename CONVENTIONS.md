# story: e05s01 e46s04
# story: e06s02
# story: e07s01
# story: e30s02
# story: e30s03
# story: e38s08
# story: e45s10
# story: e51s01
# story: e45s25
# story: e45s36
# story: e27s01
# story: e29s03
# story: e54s03
# story: e55s03
# story: e84s01

# Conventions

[`constitution.md`](constitution.md) synthesizes this project's doctrine (this file, CLAUDE.md, docs/PRINCIPLES.md, docs/references/*.md) into B0-B10 + Capstone blocks. This file remains fully authoritative.

## Conventional Commits & Semantic Versioning

All changes MUST follow [Conventional Commits 1.0.0](https://www.conventionalcommits.org/en/v1.0.0/) and [Semantic Versioning 2.0.0](https://semver.org/).
- Format: `<type>(<scope>): <description>` (space after colon mandatory).
- Types: `feat` (minor), `fix`/`perf` (patch), `docs`/`chore`/`style`/`refactor`/`test` (no bump). `BREAKING CHANGE:` or `!` triggers major.

## GitHub & Git Operations

- No direct work on `main` or `master`. Every task MUST start with a feature branch or worktree via `kickoff-branch`.
- **Integrate:** Use `gh pr create` + `gh pr merge --squash` via `release-branch`. Solo profile: `bash scripts/land-branch.sh <branch> "<msg>"` after release gates.
- Never push directly to `main`/`master` except via `land-branch.sh` (`GIT_BIGPOWERS_LAND=1`). Use `gh` over git/curl/fetch.
- **Git Attribution:** NEVER include `Co-authored-by`, `Co-Authored-By`, or any AI attribution footer in git commits. All commits must appear solely authored by the human user.
- **Pre-Merge Verification Gates:** Run `bash scripts/run-verification-gates.sh` (compliance → G-04 self-test) before any merge.

## Agent Workflow Mandates

**AGENTS MUST NEVER BYPASS THE BIGPOWERS WORKFLOW.**
- **No Direct Coding:** Never write code directly for directives like "build feature X". Route feature work through bigpowers skills (`survey-context`, `plan-work`, `develop-tdd`, `verify-work`).
- **Verification Mandate:** Every story must include runnable `verify:` commands. Verify every change with tests. Provide step-by-step UAT to user.
- **Traceability Mandate:** Every story MUST have ≥1 `story: eNNsNN` tag in implementing code or tests (`bash scripts/trace-stories.sh --strict`).
- **Scenario ID Format (e46s04+):** Critical-path scenarios use format `SC-eNNsYY-P{0|1|2|3}-NN` in `eNN-TEST_PLAN_LATEST.md` and tests.
- **Stream Continuity:** Output continuously in chunks of ~200 lines. Never pause or go silent.

## Always Green & Discovered Defects

- **Always Green (Shift Left):** Preflight (`npm run compliance && bash scripts/run-verification-gates.sh`) and CI (`gh pr checks`) must be green before forward work.
- **Discovered Defects (fix-or-log):** Any reproducible gate failure requires `quick-fix` or `fix-bug` (separate commit). Banned dismissive phrases: "pre-existing", "unrelated to this session", "not introduced by my changes", "out of scope".

## Risk Tiers (Effective Rule Matrix)

Human-readable source of truth for verification depth. Compile: `bash scripts/compile-rule-matrix.sh` (→ `specs/rule-matrix.json`).

### P0 — Critical (never violate)
- **[always-green]**: Preflight and CI must be green before forward work. (`verify-work`, `kickoff-branch`, `develop-tdd`)
- **[no-direct-coding]**: Route feature work through bigpowers skills — no ad-hoc implementation without a plan in `specs/`. (`plan-work`, `orchestrate-project`)
- **[traceability]**: Every story has ≥1 `story: eNNsNN` tag in implementing code or tests. (`trace-stories.sh --strict`)
- **[no-generated-edits]**: Never edit `.cursor/rules/`, `.gemini/`, or `website/src/content/docs/` directly. (`sync-skills.sh`)

### P1 — High (fix before merge)
- **[conventional-commits]**: All commits follow Conventional Commits; semantic-release owns version bumps. (`commit-message`, `release-branch`)
- **[verify-per-story]**: Every story/task has runnable `verify:` commands; `verify-work` confirms before done. (`plan-work`, `verify-work`)
- **[test-on-change]**: New functions and bug fixes include tests; regressions get regression tests. (`develop-tdd`, `validate-fix`)
- **[branch-protection]**: No direct work on `main`/`master`; feature branches via `kickoff-branch`. (`guard-git`)

### P2 — Medium (address in same epic or next)
- **[plan-tests-waiver]**: P2/P3-dominant epics may set `test_plan: waived` in `state.yaml`. (`plan-tests`)
- **[file-size-cap]**: Source files under 300 lines unless listed in § File-Size Exceptions. (`audit-code`)
- **[handoff-signaling]**: Critical-path skills write `handoff.next_skill` to `state.yaml`. (`session-state`)
- **[delta-requirements]**: Behavior changes require `ADDED`/`MODIFIED`/`REMOVED`/`RENAMED` tags in requirement specs. (`plan-work`, `change-request`)

### P3 — Low (best effort)
- **[boy-scout]**: Leave touched files at least as clean as found. (`audit-code`)
- **[terse-when-heavy]**: Switch to `terse-mode` when context exceeds ~20 turns. (`terse-mode`)
- **[skill-naming]**: Verb-noun kebab-case under `skills/`; documented exceptions only. (`craft-skill`)

## specs/ — All Planning Output Goes Here

Every skill writes written output to `specs/` at root. See [specs/README.md](specs/README.md) for full schema.
- **YAML cockpit:** `specs/state.yaml` (session & handoff), `specs/release-plan.yaml` (WSJF index), `specs/execution-status.yaml` (story done/todo SoT), `specs/metrics/cycle-times.yaml` (velocity ledger).
- **BCP accounting mandate:** BCP = Business Complexity Points (story size baseline via 6-step method before build; see [docs/references/bcp.md](docs/references/bcp.md)). Timestamps: `metrics.story_start` and `metrics.story_end` mandatory.
- **Generated targets:** Never edit `.cursor/rules/`, `.gemini/extensions/bigpowers/`, `.pi/`, or `website/src/content/docs/` directly — run `bash scripts/sync-skills.sh`.

## Code Style & Clean Architecture

- **Size limits:** Functions: 4–20 lines (split if longer). Source files: under 300 lines (SRP; fits single context window).
- **Quality heuristics:** One responsibility per function/module (SRP). Stepdown Rule (G34). Demeter's Law.
- **Names:** specific and unique (<5 hits in repo). Avoid `data`, `handler`, `Manager`, `Service`. Names describe side-effects (N7).
- **Types:** explicit typing mandatory — no `any`, no untyped public APIs. No magic numbers/strings (G25).
- **Errors & remediation:** Throw typed exceptions with offending value, expected shape, and actionable remediation hint.
- **Boy Scout Rule:** Leave every file touched at least as clean as found. Remove dead code (G9/F4; no commented-out code C5).
- **Portability:** `grep -E portability`: never use `\d` or `\D` (PCRE-only; breaks on GNU grep in Linux CI). Use `[0-9]`.
- **Comments:** Write WHY, not WHAT. Never strip comments on refactor. Complex logic must include provenance links (issue, SHA, ADR).
## Tests (F.I.R.S.T)
- Fast, Independent, Repeatable, Self-Validating, Timely. Headless single-command runs.
- Boundary conditions (T5): test exact edges (empty, min, max, off-by-one).
- Public interfaces only (T8): test observable behavior, never private state.
- No ignored tests without explicit ambiguity note (T4).

## Detailed References

- Skill Naming & Exceptions: [docs/references/skill-naming.md](docs/references/skill-naming.md)
- Tombstone Aliases: [docs/references/tombstones.md](docs/references/tombstones.md)
- Catalog Freeze: [docs/references/catalog-freeze.md](docs/references/catalog-freeze.md)
- File-Size Exceptions: [docs/references/file-size-exceptions.md](docs/references/file-size-exceptions.md)
- Reference SSOT Sync: [docs/references/ssot-sync.md](docs/references/ssot-sync.md)
- Toolchain (bts, sqz, RTK): [docs/references/agent-tooling.md](docs/references/agent-tooling.md)
