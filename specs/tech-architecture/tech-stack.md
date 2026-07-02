# Project Context

## Stack
- Node.js (>=14.0.0)
- Bash (for core scripting and artifact generation)
- Key Libraries: No production dependencies. Uses `semantic-release` (and plugins) as devDependencies. Relies on system tools like `jq`, `awk`, and `sed`.

## Architecture
- **Pattern Description:** Documentation-as-Code / Build-time Compilation. The project acts as a source of truth for AI agent skills (`SKILL.md` files) and uses build scripts to compile these into IDE-specific formats (Cursor, Gemini CLI, Pi).
- **Data Flow:**
  - **Input:** `verb-noun` directories containing `SKILL.md` (with YAML frontmatter and Markdown body).
  - **Processing:** `scripts/sync-skills.sh` iterates over skills, parses YAML, concatenates markdown, and runs validation/regression guards.
  - **Output:** Artifacts in `.cursor/rules/`, `.gemini/extensions/bigpowers/`, `.pi/`, and lockfiles (`skills-lock.json`, `SKILL-INDEX.md`).
- **Entry Points:**
  - CLI Wrapper: `bin/bigpowers.js` (delegates to bash scripts).
  - Sync Script: `scripts/sync-skills.sh`.
  - Dashboard: `dashboard/bin/dashboard.js`.

## Conventions (Observed)
- **Error Handling Pattern:** Bash scripts use `set -euo pipefail` for fail-fast behavior. Manual regression guards are placed at the end of scripts (e.g., `sync-skills: FAIL — ...`). Node CLI uses top-level `try/catch` wrapping `child_process.execSync`.
- **API Design:** CLI-first. No HTTP APIs provided by the core engine. Integrates heavily with the filesystem (writing to `.gemini`, `.cursor`, `specs/`).
- **Type System:** Untyped. Pure Bash and Vanilla JavaScript.
- **Workflow & Lifecycle:** Strictly mandated by `CONVENTIONS.md`. Enforces the use of `specs/` for planning (`state.yaml`, `release-plan.yaml`, `execution-status.yaml`), BCP accounting, and step-by-step verification.

## Signals / Active Considerations
- **Debt Hotspot:** `scripts/sync-skills.sh` is a large Bash script (~250 lines) performing complex string manipulation (awk/sed), JSON construction (jq), and cross-platform checks (macOS Bash 3.2 compatibility). It could become difficult to maintain as more IDE formats are added.
- **Type Safety Gap:** The lack of TypeScript or a robust schema validator for the `SKILL.md` frontmatter means errors might only be caught by custom bash/python validation scripts (`validate-skill-yaml.py`).
- **Convention Strictness:** The codebase strictly enforces skill naming (`verb-noun` format with explicit exceptions) and workflow mandates. Any new code must adhere to these highly prescriptive rules.
