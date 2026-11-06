# story: e51s02 e37s01 e37s03 e37s14
# story: e45s21
# Seed Conventions — Reference Templates

## Navigation

| Lines | Section |
|-------|---------|
| 1 | Title |
| 5–29 | Navigation |
| 30–53 | Fenced markers (e45s21) |
| 54–65 | AGENTS.md spine (Reach Template — e37s01) |
| 66–77 | Agent config template (legacy — prefer AGENTS.md spine) |
| 78–81 | Project |
| 82–91 | Commands |
| 92–94 | Architecture |
| 95–98 | Conventions |
| 99–104 | Never |
| 105–114 | Agent Rules |
| 115–123 | opencode.json template |
| 124–133 | Aider — `.aider.conf.yml` bridge (e37s03) |
| 134–146 | Codex CLI — project-local `.codex/config.toml` + AGENTS.md (e37s14) |
| 147–156 | CONVENTIONS.md |
| 157–160 | Stack profile fragments |
| 161–164 | Local tool wiring (optional interview step 8) |
| 165–173 | Cursor — project-local `.cursor/rules` symlink |
| 174–187 | OpenCode — project-local `opencode.json` + `AGENTS.md` |
| 188–190 | When to offer |

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
