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
  - **Processing**: `scripts/sync-skills.sh` iterates over skills, parses frontmatter and concatenated markdown body, dispatches to target-specific renderers (Cursor `.mdc`, Gemini `.json`/`.toml`, Pi skill folders, OKF markdown wiki concepts).
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

## Signals / Active Considerations
- **Debt Hotspot (sync-skills.sh)**: `scripts/sync-skills.sh` is a large Bash script (693 lines) that has grown significantly to handle multiple rendering pipelines (Cursor, Gemini CLI, Pi, OKF concepts). It performs complex regex matching, file concatenations, and Python subprocess calls.
- **Python / Bash Versioning**: Python dependencies are loose (`pyyaml>=6.0`). Bash scripts must remain v3.2 compatible for macOS compatibility (no associative arrays `declare -A`).
- **Strict Naming Rules**: Enforces strict `verb-noun` kebab-case naming for all skills under `skills/`, with documented exceptions in `CONVENTIONS.md`.
- **Traceability Verification**: Uses `trace-stories.sh` and Python helper scripts to scan for `story: eNNsNN` tags in implementation and test files, gating the build on complete traceability.
