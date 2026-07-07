---
name: seed-conventions
model: sonnet
description: "Generate CLAUDE.md and CONVENTIONS.md for a brand-new project through a brief interview, and create the specs/ directory with evolved bigpowers structure (product/, tech-architecture/, verifications/, epics/archive/). Entry point for greenfield projects. Use when starting a new project from scratch, when user asks to set up AI agent conventions, or when there is no CLAUDE.md yet."
---

# story: e10s01
# story: e47s02
# story: e10s02
# story: e51s02
# story: e45s21


# Seed Conventions
> **HARD GATE** — Before any new code lands, confirm the project conventions are understood. Ask: 'What does a good commit message look like in this project?'

Bootstrap a new project with the AI agent conventions it needs. Run this once at the start of a greenfield project.

## What this creates

- `CLAUDE.md` — Claude Code session config (project-specific)
- `CONVENTIONS.md` — shared rules for all AI agents
- `specs/` — the specs directory where all planning output will live
- `AGENTS.md` — for OpenCode and other agents (optional)
- `GEMINI.md` — for Gemini CLI (optional)

## Interview

Ask the user these questions (one at a time, wait for each answer):

1. **Project name and one-sentence description** — "What is this project? One sentence."
2. **Stack** — "What language, framework, and runtime? (e.g. TypeScript / Next.js / Node 22)"
2b. **Stack profile (optional)** — Offer: `swift`, `typescript-vue`, `node-service`, or none. If chosen, merge the matching fragment from `profiles/<name>.md` into generated `CONVENTIONS.md`.
3. **Commands** — "What commands do you use for: run, test, build, lint?"
3b. **Preflight (optional)** — "What single command runs your full local green stack (test + lint + build)? If you don't have one, we'll chain your Test + Lint + Build answers into a **Preflight** row in the Commands table."
4. **Architecture** — "Key modules and relationships in 1–2 sentences."
5. **Conventions** — "Any naming, file organization, or patterns all agents must follow?"
6. **Never-do list** — "What are the hard stops? Things an agent must never touch?"
7. **Defensive code categories** — "Which apply? (Rate limit / Retry / Circuit breaker / Timeout / Graceful degradation)"
8. **Local tool wiring (optional)** — "Wire bigpowers for project-local tools? (Cursor, OpenCode, Cline, Aider, Codex CLI)" If yes, generate AGENTS.md spine artifacts per [REFERENCE.md](REFERENCE.md) §Local tool wiring and §AGENTS.md spine. If no, skip — standard seed output unchanged (no AGENTS.md spine unless opted in).

## Generate files

After the interview, generate each file using the templates in [REFERENCE.md](REFERENCE.md):
- `AGENTS.md` — from `docs/templates/AGENTS.md` Reach Template (canonical spine source)
- `CLAUDE.md` — symlink to `AGENTS.md` (copy fallback on Windows when symlink fails)
- `GEMINI.md` — symlink to `AGENTS.md` when Gemini wiring opted in
- `opencode.json` — with `"instructions": ["AGENTS.md"]` when OpenCode opted in
- `.aider.conf.yml` — with `read: AGENTS.md` when Aider opted in
- `CONVENTIONS.md` — bigpowers standard template + project defensive code categories

### `specs/` directory

```bash
mkdir -p specs/product specs/product/snapshots specs/epics/archive
mkdir -p specs/tech-architecture specs/adr specs/verifications specs/bugs
touch specs/product/SCOPE_LATEST.yaml specs/product/VISION_LATEST.yaml specs/product/GLOSSARY_LATEST.yaml
touch specs/release-plan.yaml specs/execution-status.yaml specs/planning-status.yaml specs/state.yaml
touch specs/tech-architecture/tech-stack.md specs/tech-architecture/SECURITY_PLAN_LATEST.md
touch specs/tech-architecture/TEST_PLAN_LATEST.md specs/tech-architecture/DESIGN_PLAN_LATEST.md
touch specs/tech-architecture/REFACTOR_LATEST.md specs/tech-architecture/IMPACT_LATEST.md
touch specs/bugs/registry.yaml
echo "# Specs\n\nAll planning documents for this project." > specs/README.md
```

**Note:** `specs/state.yaml.lock` is NOT pre-created — acquired/released dynamically.

`specs/state.yaml` carries a top-level `workflow_mode` key (`team-pr` | `solo-git`, default `solo-git`). This is the **canonical integrate-mode signal** for all skills — set it once here and skills such as `release-branch` read it from this file instead of sniffing profile files.

When generating `CLAUDE.md`, if the user did not name a Preflight command, chain the Test + Lint + Build interview answers into one **Preflight** row (e.g. `npm test && npm run lint && npm run build`).

### Self-installing fenced markers (e45s21)

Skills that write into `CLAUDE.md` or `AGENTS.md` MUST use **fenced HTML comment markers** so handwritten content outside the fence is never clobbered:

```markdown
<!-- BEGIN bigpowers:section-id -->
…agent-managed content only…
<!-- END bigpowers:section-id -->
```

**Merge rule:** On update, replace only the content *between* matching `BEGIN`/`END` pairs. If a marker pair is missing, append a new fenced block at the end of the file — never rewrite the whole file.

**Standard marker IDs** for seeded projects (see [REFERENCE.md](REFERENCE.md) § Fenced markers):

| Marker ID | Owner skill | Purpose |
|-----------|-------------|---------|
| `project` | seed-conventions | Project, Commands, Architecture |
| `context-routing` | seed-conventions | Glob → sub-AGENTS.md routing table |
| `learned-preferences` | session-state | Learned User Preferences + Workspace Facts |
| `tooling` | setup-environment, guard-git | sqz/rtk/hook blocks installed by tooling skills |

Emit these fences in `AGENTS.md` (and therefore `CLAUDE.md` symlink) from `docs/templates/AGENTS.md`. User prose outside fences is sacred.

- [ ] CLAUDE.md exists and is populated
- [ ] CONVENTIONS.md exists and includes specs/ output convention
- [ ] specs/product/ exists with SCOPE_LATEST.yaml, VISION_LATEST.yaml, GLOSSARY_LATEST.yaml
- [ ] specs/tech-architecture/ exists with tech-stack.md, security.md, test.md, design.md
- [ ] specs/verifications/ exists
- [ ] specs/epics/archive/ exists
- [ ] specs/bugs/registry.yaml exists
- [ ] Confirm with user: "Does CLAUDE.md accurately describe your project?"

---

# story: e51s02 e37s01 e37s03 e37s14
# story: e45s21
# Seed Conventions — Reference Templates

## Navigation

| Lines | Section |
|-------|---------|
| 1–4 | Title + story tags |
| 6–22 | Navigation (this table) |
| 24–35 | AGENTS.md spine |
| 37–76 | Agent config template |
| 78–85 | opencode.json template |
| 87–96 | Aider bridge |
| 98–108 | Codex CLI wiring |
| 110–118 | CONVENTIONS.md |
| 120–122 | Stack profile fragments |
| 124–153 | Local tool wiring |

## Fenced markers (e45s21)

Self-installing blocks prevent skills from overwriting user-authored prose. Pattern:

```markdown
<!-- BEGIN bigpowers:section-id -->
…managed content…
<!-- END bigpowers:section-id -->
```

**Merge algorithm:**

1. If `BEGIN bigpowers:<id>` exists → replace inner content only.
2. If missing → append new fenced block at EOF.
3. Never delete content outside fences.

Seed these marker IDs in generated `AGENTS.md`:

| ID | Initial content |
|----|-----------------|
| `project` | Project, Commands, Architecture, Conventions, Never, Agent Rules |
| `context-routing` | Glob → sub-AGENTS.md table (see CLAUDE.md e45s22) |
| `learned-preferences` | Empty Learned User Preferences + Workspace Facts lists |

## AGENTS.md spine (Reach Template — e37s01)

Canonical source: copy from `docs/templates/AGENTS.md` in the bigpowers repo (Reach Template).
Do not invent structure ad hoc — the template includes multi-agent preamble, Preflight, Test/Lint/Build sections.

When local tool wiring is opted in:
1. Copy Reach Template → project root `AGENTS.md`, fill interview placeholders
2. `ln -sf AGENTS.md CLAUDE.md` (or content copy on Windows when symlink fails)
3. Write `opencode.json` with `"instructions": ["AGENTS.md"]`

When user **opts out** of local tool wiring, do not emit AGENTS.md spine artifacts.

## Agent config template (legacy — prefer AGENTS.md spine)

All three files use the same structure — only the header differs:
- `CLAUDE.md` → `# [Project Name] — Claude Code` (or symlink to AGENTS.md)
- `GEMINI.md` → `# [Project Name] — Gemini CLI`
- `AGENTS.md` → `# [Project Name] — AI Agents` (Reach Template header)

```markdown
# [Project Name] — [Agent]

Read CONVENTIONS.md before any GitHub or git operation.

## Project
[One sentence description]
Stack: [language, framework, runtime]

## Commands
| Action | Command |
|--------|---------|
| Run    | `[cmd]` |
| Test   | `[cmd]` |
| Build  | `[cmd]` |
| Lint   | `[cmd]` |
| Preflight | `[test && lint && build chain — or user-named full-green cmd]` |
| CI     | `gh pr checks` (when a PR is open) |

## Architecture
[1–2 sentences. Key modules and their relationships.]

## Conventions
- [convention 1]
- [convention 2]

## Never
- Never dismiss reproducible gate failures as pre-existing or out of scope
- Never proceed on red Preflight or red CI — invoke quick-fix or fix-bug first
- [hard stop 1]
- [hard stop 2]

## Agent Rules
- **Workflow Mandate:** You MUST use the bigpowers skills (e.g. `plan-work`, `develop-tdd`, `orchestrate-project`) to perform tasks. DO NOT write code directly in response to a user prompt like "build this feature".
- **Always Green:** Preflight and CI must be green before forward work. Reproducible gate failures require **fix-or-log** (quick-fix → fix-bug) per CONVENTIONS § Discovered Defects.
- Read specs/ before writing code.
- All planning and specifications MUST be written to `specs/` (`product/SCOPE_LATEST.yaml`, `release-plan.yaml`, `epics/`) before any code is generated.
- Write the minimum code that solves the stated problem. Nothing extra.
- Run tests after every change. Show evidence before declaring done.
- One clarifying question beats a wrong assumption baked into 200 lines.
```

## opencode.json template

```json
{
  "$schema": "https://opencode.ai/config.json",
  "instructions": ["AGENTS.md"]
}
```

## Aider — `.aider.conf.yml` bridge (e37s03)

When Aider wiring is opted in:

```yaml
read: AGENTS.md
```

Upstream: [Aider-AI/aider](https://github.com/Aider-AI/aider) (not paul-gauthier/aider).

## Codex CLI — project-local `.codex/config.toml` + AGENTS.md (e37s14)

Source: https://developers.openai.com/codex/guides/agents-md

Codex is instruction-file-only — no slash skills. When Codex wiring is opted in:

```toml
# .codex/config.toml
instructions = ["AGENTS.md"]
```

Use AGENTS.md header `# [Project Name] — AI Agents` (shared with OpenCode/Cline). Single AGENTS.md serves dual-tool projects.

## CONVENTIONS.md

Use the standard bigpowers CONVENTIONS.md as the base. Fill in the project-specific defensive code categories from the interview answers.

**Always embed** these doctrine sections from bigpowers (adapt commands only):

- **§ Always Green / Shift Left** — 1-10-100 rationale, Preflight + CI green definitions
- **§ Discovered Defects** — fix-or-log ladder (quick-fix → fix-bug), separate commits for discovered fixes
- **Banned dismissive phrases** table — pre-existing, unrelated to session, not introduced by my changes, out of scope (ignoring a red gate)

## Stack profile fragments

If the user selected a stack profile, merge the matching `profiles/<name>.md` fragment into the generated `CONVENTIONS.md` under a `## Stack Conventions` section. Profiles supply language-specific commands, architecture patterns, and never-do additions.

## Local tool wiring (optional interview step 8)

Offered after the standard interview. Covers the two tools that global install (`scripts/install.sh`) structurally cannot reach because they read project-root config, not global paths.

### Cursor — project-local `.cursor/rules` symlink

```bash
# From the project root:
ln -sfn <bigpowers-install-path>/.cursor/rules .cursor/rules
```

Cursor reads `.cursor/rules/` from the project root. This symlink gives every project access to bigpowers skills as Cursor rules without duplicating the files. Run once per project.

### OpenCode — project-local `opencode.json` + `AGENTS.md`

`opencode.json` (project root):
```json
{
  "$schema": "https://opencode.ai/config.json",
  "instructions": [".cursor/rules/*.mdc", "AGENTS.md"]
}
```

OpenCode reads `opencode.json` from the project root, NOT from a global path. The `instructions` array points to the local `.cursor/rules` symlink (from the Cursor step above) and the project's `AGENTS.md`. Both must exist in the project for OpenCode to see bigpowers skills.

`AGENTS.md` is already generated by the standard interview (step 2 of Generate Files). When local tool wiring is opted in, ensure `AGENTS.md` includes the standard agent-config template header `# [Project Name] — OpenCode`.

### When to offer

Only offer local tool wiring when the user's project will be opened in Cursor or OpenCode. These tools are project-root scoped by design — no global installer can solve them. Global install (`install.sh`) already handles Claude Code, Gemini CLI, and pi globally. Do not offer for tools that read global config.
