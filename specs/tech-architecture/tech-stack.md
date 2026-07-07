# Project Context

## Stack
- **Node.js (>=14.0.0)**: Used for CLI wrapper entry point and web/TUI dashboard.
- **Bash (v3.2+ compatible)**: Used for the core orchestration scripts, installers, and sync pipelines.
- **Astro (v7.0.2)**: Powers the Starlight documentation site under `website/`.
- **Python (3.x)**: Used for YAML frontmatter schema validation and Gherkin traceability analysis (`pyyaml`).
- **Key Libraries**:
  - Production: No production npm dependencies for the core package.
  - Dashboard: `blessed` (0.1.81), `chokidar` (3.6.0), `express` (4.19.0), `js-yaml` (4.1.0).
  - Website: `@astrojs/starlight` (0.41.3), `@astrojs/sitemap` (3.7.3), `sharp` (0.34.5).
  - DevDependencies: `semantic-release` (24.2.0) and associated plugins for automated tag and changelog publishing.

## Architecture
- **Pattern Description**: Documentation-as-Code / Build-time Compilation. The project acts as a single-source-of-truth for AI agent skills (`SKILL.md` files) and compiles them into IDE-specific formats (Cursor rules, Gemini CLI extensions, Pi skills, OKF concepts).
- **Data Flow**:
  - **Input**: `verb-noun` directories in `skills/` containing a `SKILL.md` source file.
  - **Processing**: `scripts/sync-skills.sh` delegates to `scripts/lib/srp-engine.py`, which iterates over skills, parses frontmatter into a `SkillIR` JSON object, and spawns target-specific Bash adapters as subprocesses, piping the JSON payload to `stdin`.
  - **Output**: Auto-generated artifacts in `.cursor/rules/`, `.gemini/extensions/bigpowers/`, `.pi/`, and lockfiles/indices (`skills-lock.json`, `SKILL-INDEX.md`, `specs/skills-wiki/`).
- **Entry Points**:
  - **CLI Entry Point**: `bin/bigpowers.js` (detects setup state and installs/updates/checks version).
  - **Core Sync Orchestrator**: `scripts/sync-skills.sh` (compiles and generates rulesets/wiki concept nodes).
  - **User Installer**: `scripts/install.sh` (installs symlinks to user home directories for global agent use).
  - **Dashboard TUI/Web**: `dashboard/bin/dashboard.js` (TUI Blessed viewer and optional Express web UI).
  - **Docs Site**: `website/` (Starlight documentation site build/dev server).

## Conventions (Observed)
- **Error Handling**:
  - Bash scripts use `set -euo pipefail` for immediate failure on errors. Manual regression checks and validation runs exist at the end of key scripts (e.g., `sync-skills: FAIL — ...` checks).
  - Node/JS components use top-level `try/catch` wraps around commands and filesystem access, with clean stderr exits.
- **API Design**: CLI and Filesystem-first. There are no external public HTTP APIs in the core. The dashboard runs local read-only Express services.
- **Type System**: Untyped. Pure Bash, Vanilla CommonJS/ESM JavaScript, and script-level Python.
- **Workflow & Lifecycle**: Strict spec-driven development (SDD) pipeline governed by `CONVENTIONS.md`. Uses `specs/` as a centralized planning directory:
  - `state.yaml`: Active session, epic, story, current step, and handoff.
  - `release-plan.yaml`: Initiative version, BCP baselines, and epic release lists.
  - `execution-status.yaml`: Flat mapping of epic and story completion.
  - `metrics/cycle-times.yaml`: Ledger tracking cycle time, BCP counts, and velocity (BCP/hour).

## Reach Domain (e37)

Single authored context file per project. All tool-specific context filenames are symlinks or absent.

### Language

**Context Spine**:
The one authored project-context file at repo root (`AGENTS.md`). Holds Preflight, commands table, workflow mandates, and multi-agent preamble.
_Avoid_: CLAUDE.md as authoring surface, dual spine, "agent config"

**Context Derivative**:
A tool-specific filename that points at the Context Spine (`CLAUDE.md`, `CURSOR.md`) — symlink by default; `copy` when symlinks are unavailable (Windows without Developer Mode).
_Avoid_: parallel templates, independently authored CLAUDE.md

**Skill Source**:
A `SKILL.md` file under `skills/<verb-noun>/`. Orthogonal to the Context Spine; compiled by `sync-skills.sh`, not merged into AGENTS.md.
_Avoid_: skills-in-AGENTS.md, context-in-SKILL.md

**Integration Target**:
A named AI coding runtime (cursor, gemini, cline, aider, goose, …) with exactly one row in `scripts/targets.yaml`.
_Avoid_: adapter, renderer, platform (when meaning a target)

**Integration Registry**:
`scripts/targets.yaml` — single `targets[]` list where each row is one Integration Target with nullable `skill` and `context` fields.
_Avoid_: split registries, hardcoded TARGETS array, per-script target lists

**Skill Adapter** (field):
Nullable registry field pointing to an adapter script's `render_skill` hook. `null` when the target reads no skill artifacts.
_Avoid_: skill target, renderer function name in orchestrator

**Context Wiring** (field):
Nullable registry field declaring how a target consumes the Context Spine (`native`, `symlink`, `copy`, `config-bridge`). `null` only when the target is skill-only.
_Avoid_: context target, separate context registry

**Adapter**:
A per-target script at `scripts/adapters/<id>.sh` exposing `wire_context` and/or `render_skill` hooks. Referenced by registry `skill.adapter` / `context.adapter` fields.
_Avoid_: in-process render_* in orchestrators, target logic in sync-skills.sh

**Adapter Interface**:
The two optional hooks an adapter script may implement: `wire_context` (Context Wiring) and `render_skill` (Skill Adapter). Orchestrators call only the hooks the registry row declares non-null.
_Avoid_: unified render function, monolithic renderer module

**Agents Contract**:
The required shape of a Reach Context Spine: multi-agent preamble, `## Preflight` (non-empty), `## Test` / `## Lint` / `## Build` (present; may be `N/A`), neutral title. Validated by `bp-read-agents.sh` and `verify-install.sh --matrix`.
_Avoid_: agents file, config template, CLAUDE.md-shaped contract

**Reach Template**:
Canonical contract source at `docs/templates/AGENTS.md`. `seed-conventions` copies it; does not invent structure ad hoc.
_Avoid_: per-project contract invention, CLAUDE.md template as source

**Wiring Tier** (field):
Registry metadata controlling verify scope: `default_on` (always asserted), `opt_in` (asserted when wiring artifacts exist), `optional` (asserted only with `--full`).
_Avoid_: priority, wave number as verify logic

**Compile Pass**:
One of three ordered orchestration steps: **Seed** (author spine), **Bundle** (wire context), **Sync** (render skills). Each pass is independent and idempotent.
_Avoid_: compile, build (when meaning the full chain in one command)

### Relationships

- A project has **exactly one** authored **Context Spine** (`AGENTS.md`).
- Each **Integration Target** has **exactly one** row in the **Integration Registry**.
- Each registry row MAY declare a **Skill Adapter** (`skill` field), **Context Wiring** (`context` field), both, or neither alone — at least one MUST be non-null.
- **Skill Source** files compile to per-target artifacts only when the target's `skill` field is non-null; dispatch sources `scripts/adapters/<id>.sh` and calls `render_skill`.
- **Context Wiring** runs only when the target's `context` field is non-null; dispatch sources the same adapter and calls `wire_context`.
- An **Agents Contract** validates the **Context Spine**; per-target contract assertions live on the same registry row.
- **`verify-install.sh --matrix`** checks a target only when its **Wiring Tier** rules say it is in scope for this project (see invariants 9–11).
- **`seed-conventions`** performs only the **Seed** pass — authors `AGENTS.md`; never calls adapter hooks.
- **`generate-context-bundle.sh`** performs only the **Bundle** pass — calls `wire_context` for in-scope targets.
- **`sync-skills.sh`** performs only the **Sync** pass — calls `render_skill` for registry rows with non-null `skill`.

### Invariants

1. Exactly one authored context file per project: `AGENTS.md`.
2. `CLAUDE.md`, `CURSOR.md`, and similar MUST be symlinks to `AGENTS.md` or content-identical copies when symlinks are unavailable — never independently authored.
3. `SKILL.md` remains the skill source; never merged into the Context Spine.
4. `scripts/targets.yaml` is the sole registry of Integration Targets — no parallel lists in scripts.
5. Every Integration Target has exactly one registry row; `verify-install.sh --matrix` iterates the same `targets[]`.
6. A target with `skill: null` MUST NOT call `render_skill`.
7. A target with `context.mode: native` MUST NOT call `wire_context` and MUST NOT create Context Derivatives.
8. Each registry row MUST have at least one of `skill` or `context` non-null.
9. `tier: default_on` → matrix MUST assert when `AGENTS.md` exists.
10. `tier: opt_in` → matrix asserts only when that target's wiring artifacts exist on disk.
11. `tier: optional` → matrix asserts only with `--full` (or explicit flag) AND wiring artifacts exist.
12. Registry adapter fields MUST resolve to `scripts/adapters/<id>.sh` on disk.
13. `sync-skills.sh` and `generate-context-bundle.sh` MUST NOT contain target-specific render logic after e37s07 — only shared IR, registry load, and hook dispatch.
14. Adapter scripts MUST be idempotent (safe to re-run).
15. Adding a wave target MUST require only a new adapter file + registry row — no orchestrator edit.
16. `seed-conventions` MUST NOT call `wire_context` or `render_skill`.
17. `generate-context-bundle.sh` MUST NOT call `render_skill`.
18. `sync-skills.sh` MUST NOT call `wire_context`.
19. Documented onboarding order: Seed → Bundle → Sync (or `bundle && sync` one-liner).
20. Reach Context Spine MUST include non-empty `## Preflight`.
21. Reach Context Spine MUST include `## Test`, `## Lint`, `## Build` (value may be `N/A` with explanation).
22. Reach Context Spine MUST include a multi-agent preamble naming ≥1 OSS target.
23. Reach Context Spine title MUST use neutral agent wording — not Codex-only.
24. `bp-read-agents.sh` MUST prefer `AGENTS.md` over Context Derivatives once dogfooding completes.
25. `docs/templates/AGENTS.md` is the sole Reach Template source for seed.

### Context Spine lifecycle

```
[no context] --seed--> [AGENTS.md authored]
[AGENTS.md authored] --bundle--> [symlinks/config per opted-in targets]
[bundle done] --sync--> [skill artifacts per registry]
[wiring present] --verify-matrix--> [PASS | FAIL per in-scope target]
[--full flag] --optional targets--> [additional assertions if wired]
```

### Flagged ambiguities

- "CLAUDE.md" was used as the operational doc in CONVENTIONS.md and `sync-skills.sh` — **resolved**: authoring moves to AGENTS.md; CLAUDE.md becomes a Context Derivative (symlink). bigpowers dogfoods this during e37.
- "all targets in registry" vs "all targets wired" — **resolved**: registry lists capability; matrix scope follows Wiring Tier + artifact presence (project opt-in).

### Example dialogue

> **Dev:** "Should Cline get its own context file?"
> **Domain expert:** "No — Cline reads AGENTS.md natively. We only add a symlink when a tool expects a different filename; Cline doesn't need one."

> **Dev:** "User seeded without Aider — should verify-install fail?"
> **Domain expert:** "No — Aider is `tier: opt_in`. No `.aider.conf.yml` means out of scope, not a failure."

> **Dev:** "Can seed-conventions create the CLAUDE.md symlink?"
> **Domain expert:** "No — seed authors AGENTS.md only. Run `generate-context-bundle.sh` after seed to wire context."

> **Dev:** "Solo Cursor dev, no OpenCode — still need the multi-agent preamble?"
> **Domain expert:** "Yes — mention Cursor in the preamble. OpenCode is opt-in at bundle time, not required in the contract."

## Signals / Active Considerations
- **Skills Render Pipeline (SRP) Hybrid Architecture**: The core compilation is migrating to a hybrid model (`scripts/lib/srp-engine.py`). Python handles complex YAML/frontmatter parsing and constructs an immutable JSON `SkillIR`. Bash adapters (`scripts/adapters/*.sh`) are spawned as subprocesses and read this payload via `stdin` using `jq`, honoring ADR-0007 while eliminating leaky global bash state.
- **Python / Bash Versioning**: Python dependencies are loose (`pyyaml>=6.0`). Bash scripts must remain v3.2 compatible for macOS compatibility (no associative arrays `declare -A`).
- **Strict Naming Rules**: Enforces strict `verb-noun` kebab-case naming for all skills under `skills/`, with documented exceptions in `CONVENTIONS.md`.
- **Traceability Verification**: Uses `trace-stories.sh` and Python helper scripts to scan for `story: eNNsNN` tags in implementation and test files, gating the build on complete traceability.

## Migration Engine Domain (e44)

### Language

**Migration Engine**:
The orchestrator component that handles safety, DAG resolution, and dry-run user prompts. Must delegate complex data structures to Python (`scripts/lib/migrate-engine.py`).
_Avoid_: monolithic bash script parsing yaml

**OKF Bundle**:
A YAML file containing `okf_kind: spec-migration` or `okf_kind: migration-registry`, specifying dependencies, heuristics, and transformations.

**Action Adapter**:
A concrete implementation of a domain-specific transformation (e.g., `convert_md_to_yaml`, `rename_file`) exposing `dry_run` and `apply` methods.
_Avoid_: massive switch/case block

**Triple Safety Net**:
The three-stage protection protocol: Backup (copy before mutation) → Dry Run (show diffs with ⚠ markers) → Auto-commit (allows git reset).

### Invariants
1. `migrate-version.sh` wrapper MUST NOT perform complex DAG resolution or YAML parsing in Bash.
2. The Migration Engine MUST treat OKF Bundles as the source of truth.
3. Every Action Adapter MUST be strictly idempotent.
4. If any migration fails during Apply, the Engine MUST rollback the entire batch to the backup and abort the auto-commit.
