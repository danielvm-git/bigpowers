# story: e38s08
# story: e51s05
# story: e45s22
# story: e45s23
# story: e55s03
# story: e84s01

# bigpowers — Agent Instructions

Read CONVENTIONS.md before any GitHub or git operation.
[`constitution.md`](constitution.md) synthesizes this project's doctrine (this file, CONVENTIONS.md, docs/PRINCIPLES.md, docs/references/*.md). This file remains fully authoritative.

<!-- BEGIN bigpowers:context-routing -->
## Context Routing

Load subdirectory context by file glob — do not read the full doc tree up front.

| Glob / trigger | Load first | Fallback |
|----------------|------------|----------|
| `skills/**` | Active skill `SKILL.md` + sibling `REFERENCE.md` | `SKILL-INDEX.md` |
| `specs/epics/**` | Capsule `epic.yaml` + active story `-tasks.yaml` | `specs/release-plan.yaml` |
| `specs/product/**` | `SCOPE_LATEST.yaml`, `VISION_LATEST.yaml` | `specs/README.md` |
| `specs/tech-architecture/**` | `tech-stack.md` + epic `eNN-TEST_PLAN_LATEST.md` | `CONVENTIONS.md` |
| `scripts/**` | `CONVENTIONS.md` § Generated targets | Commands table below |
| `website/**` | `website/README.md` | Never edit generated docs in `website/src/content/docs/` |
| `docs/**` | Matching doc under `docs/` | `docs/references/` |
| Default / session start | This file → `CONVENTIONS.md` → `specs/state.yaml` | `survey-context` |
<!-- END bigpowers:context-routing -->

<!-- BEGIN bigpowers:learned-preferences -->
## Learned User Preferences

- Prefer `rtk`-prefixed shell commands for git, test, and build output (token savings).
- Run Preflight before forward work; never dismiss red gates as pre-existing.
- Edit `skills/*/SKILL.md` sources only — never `.cursor/rules/` or `.gemini/` artifacts.

## Workspace Facts

- Stack: Markdown / Bash documentation project; skills sync via `bash scripts/sync-skills.sh`.
- Planning SoT: `specs/state.yaml`, `specs/release-plan.yaml`, `specs/execution-status.yaml`.
- Story traceability: `# story: eNNsNN` tags in implementing files; `bash scripts/trace-stories.sh --strict` in CI.
- Rule matrix: `bash scripts/compile-rule-matrix.sh` → `specs/rule-matrix.json` (P0–P3 tiers from CONVENTIONS.md).
<!-- END bigpowers:learned-preferences -->

## Project

bigpowers — agent skills for spec-driven, test-first software development by solo developers (catalog in `SKILL-INDEX.md`).
Stack: Markdown / Bash (documentation-based; skills integrate with Claude Code, Cursor, Gemini CLI)

## Commands

| Action | Command |
|--------|---------|
| Install | `npm install -g bigpowers && bigpowers setup` |
| Run / Lint | `bash scripts/sync-skills.sh` |
| Test | `npm run compliance` |
| Build | `bash scripts/install.sh` (from source) |
| Validate specs YAML | `bash scripts/validate-specs-yaml.sh` |
| Compliance | `npm run compliance` |
| Verification Gates | `bash scripts/run-verification-gates.sh` |
| Traceability | `bash scripts/trace-stories.sh --strict` |
| Preflight | `npm run compliance && bash scripts/run-verification-gates.sh && bash scripts/sync-skills.sh && bash scripts/trace-stories.sh --strict` |
| CI | `gh pr checks` |

Pre-merge: `npm run compliance && bash scripts/run-verification-gates.sh`. If BCP Plus sized, see `docs/references/bcp-plus.md`.

## Architecture & Conventions

- Collection of verb-noun skills under `skills/`, each with a single `SKILL.md` source of truth.
- Runtime specs in `specs/state.yaml`, `specs/release-plan.yaml`, and `specs/execution-status.yaml`; intent in `specs/product/`; epics in `specs/epics/`.
- Generated targets: `.cursor/rules/`, `.gemini/extensions/bigpowers/`, `.pi/skills/`, and `website/src/content/docs/`. Run `bash scripts/sync-skills.sh` after any changes.
- **Never** edit generated targets directly. Never create a skill without a `SKILL.md` file. Never push without running `sync-skills.sh`.

## Token Management & Toolchain

- Context discipline: Write (short functions 4-20 lines), Select (`bts map`, `survey-context`), Compress (`sqz compress`, `rtk`), Isolate (`kickoff-branch`, `dispatch-agents`). See `docs/references/context-engineering.md`.
- Auto-Terse: Switch to `terse-mode` when session exceeds ~20 turns or context is heavy.
- Context compaction: Summarize state every 10 turns into a short, high-density note.
- Stream stability: Continuous output in chunks of ~200 lines without pausing.
- Mechanical backstop (e45s03): `scripts/hooks/token-mgmt-pre-tool-use.sh` blocks oversized tool calls.
- **Toolchain (bts, sqz, rtk):** Syntax tables, compression rules, MCP tools, and commands live in [docs/references/agent-tooling.md](docs/references/agent-tooling.md).
  - Search: `bts find --print <pattern>` | Map: `bts map` | Docs: `bts docs <lib>`
  - Compression: pipe through `sqz compress` (MCP: `sqz_read_file`, `sqz_grep`, `sqz_list_dir`)
  - RTK: prefix commands with `rtk` (e.g. `rtk git status`, `rtk cargo test`, `rtk gh pr view`)

## Session Start

Before any task, run this sequence — not optional:
1. Read `CLAUDE.md` (or `AGENTS.md`)
2. Read `CONVENTIONS.md`
3. Read `specs/state.yaml` if it exists — current session and active epic
4. Read `specs/release-plan.yaml` if it exists — active release context

## Agent Rules

- **Workflow Mandate:** You MUST use the bigpowers skills (e.g., `plan-work`, `develop-tdd`, `craft-skill`) to perform tasks. DO NOT write code directly in response to a user prompt like "build this feature".
- **Always Green / fix-or-log:** Preflight and CI must be green before forward work. Any reproducible gate failure during unrelated work requires `quick-fix` or `fix-bug` (CONVENTIONS § Discovered Defects). Never dismiss failures as pre-existing or out of scope.
- Read specs/ and CONVENTIONS.md before writing code. Write minimum code that solves the stated problem. Run tests after every change. All written output in specs/.
