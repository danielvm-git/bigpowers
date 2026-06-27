# bigpowers — Best-in-Class Agentic Skills

![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)
![npm version](https://img.shields.io/npm/v/bigpowers.svg)
![Skills](https://img.shields.io/badge/skills-70-brightgreen.svg)

**70 agent skills for high-integrity, spec-driven, test-first software development by solo developers.**

`bigpowers` provides a prescriptive, vertical-slice methodology for building software with AI agents (Claude Code, Gemini CLI, Cursor, pi). It bridges the gap between raw LLM capabilities and professional engineering standards.

Published on npm: [bigpowers@2.0.0](https://www.npmjs.com/package/bigpowers)

---

## 🚀 Quick Start

### npm (recommended)

```bash
# One-shot setup — downloads, syncs artifacts, and links skills to your tools
npx bigpowers

# Or install globally and run the setup command anytime
npm install -g bigpowers
bigpowers
```

Both commands sync skill artifacts and link them to Claude Code, Gemini CLI, and Cursor (see [Prerequisites](#-prerequisites)).

### From source (contributors)

```bash
git clone https://github.com/danielvm-git/bigpowers.git && cd bigpowers
npm install          # runs postinstall: sync + link
# or manually:
bash scripts/install.sh
npm run sync
```

---

## 🛠 Prerequisites

- **Bash**: Required for all scripts.
- **Node.js**: v14+ (required for npm/npx).
- **jq**: (Highly Recommended) Used for robust configuration of tool settings.
- **AI Tools**: One or more of:
  - [Claude Code](https://claude.ai/code)
  - [Gemini CLI](https://github.com/google/gemini-cli)
  - [Cursor](https://cursor.sh/)
  - [pi](https://pi.dev/) — coding agent harness

---

## 🔄 Maintenance (Update & Uninstall)

### Update

**npm install:**

```bash
npm update -g bigpowers
bigpowers    # re-sync and refresh symlinks
```

**git clone:**

```bash
git pull
npm run sync
```

*Install uses symlinks — re-running setup refreshes links without duplicating files.*

### Uninstall

**npm install:**

```bash
bash "$(npm root -g)/bigpowers/scripts/install.sh" --uninstall
npm uninstall -g bigpowers
```

**git clone:**

```bash
bash scripts/install.sh --uninstall
```

### Reinstall

```bash
npx bigpowers
# or, if installed globally:
bigpowers
```

---

## 🔌 pi Support

bigpowers generates pi Agent Skills and prompt templates alongside Cursor and Gemini artifacts via `sync-skills.sh`.

### Install as a pi package

```bash
# Clone and sync to generate pi artifacts
cd bigpowers
bash scripts/sync-skills.sh

# Install from local path as a pi package
pi install .

# Or install as a pi npm package (once published with pi-package keyword)
pi install npm:bigpowers
```

**What you get:**
- **62 pi skills** in `.pi/skills/` — loaded automatically into pi's system prompt as `<available_skills>`
- **62 pi prompt templates** in `.pi/prompts/` — slash commands like `/survey-context`, `/plan-work`
- **pi package manifest** in `.pi/package.json` — enables `pi install` with auto-discovery

Skills are loaded on-demand via progressive disclosure: only descriptions are always in context; the full SKILL.md loads when the agent reads it. Prompt templates expand in pi's editor with autocomplete.

## 🔧 MCP Server (Model Context Protocol)

bigpowers ships an MCP server that exposes all skills as callable MCP tools. Agents can discover and invoke skills dynamically instead of relying on a static system prompt.

### Start the server

```bash
node scripts/mcp-server.js
```

### Add to Claude Code

```bash
claude mcp add bigpowers node /path/to/bigpowers/scripts/mcp-server.js
```

Or add manually to `.claude/settings.json`:

```json
{
  "mcpServers": {
    "bigpowers": {
      "command": "node",
      "args": ["/path/to/bigpowers/scripts/mcp-server.js"]
    }
  }
}
```

### Available MCP tools

| Tool | Description |
|------|-------------|
| `bigpowers_list_skills` | List all 70 skills with name, description, phase. Optional `phase` filter. |
| `bigpowers_get_skill` | Get full SKILL.md content for any skill by name. |
| `bigpowers_search_skills` | Keyword/semantic search — returns ranked matches for a query. |
| `bigpowers_get_state` | Get current `specs/state.yaml` (active flow, epic, step). |
| `bigpowers_invoke_skill` | Get skill instructions with optional context for agent invocation. |

---

## 🏗 The v2.0.0 Lifecycle

Every project follows the **orchestrate-project 6-phase model** (full SOP: [`docs/WORKFLOW-SOP-v2.md`](docs/WORKFLOW-SOP-v2.md)):

```
ONE TIME    seed-conventions  (CLAUDE.md, .claude/, .gemini/, agents/, skill sync)
              ↓
ONCE/PROJECT orchestrate-project
              │
              ├─ Ph1 DISCOVER   survey-context, research-first, elaborate-spec
              ├─ Ph2 ELABORATE  model-domain, grill-me, define-language, deepen-architecture
              ├─ Ph3 PLAN       scope-work, slice-tasks, plan-work → release-plan.yaml (BCP baseline)
              ├─ Ph4 BUILD      build-epic × N stories
              │
              │  Per story — 8-step build-epic cycle:
              │   1. survey-context   ← stamps story_start in state.yaml
              │   2. plan-work        ← [BCP N] tasks + verify: commands
              │   3. kickoff-branch   ← worktree + feature branch
              │   4. develop-tdd      ← RED → GREEN → REFACTOR
              │   5. verify-work      ← UAT gate
              │   6. audit-code       ← quality gate ≥ 94%
              │   7. commit-message   ← Conventional Commits + semver
              │   8. release-branch   ← land to main; writes story_end + cycle-times.yaml
              │
              ├─ Ph5 VERIFY     run-evals, verify-work (project-level)
              └─ Ph6 RELEASE    semantic-release → v1.0.0 MVP tag
```

**Semver:** projects start at `0.0.0-β`; each `feat:` story → minor bump; developer declares MVP → `1.0.0`.

**BCP accounting:** every task labeled `[BCP N]`; story total in `state.yaml`; BCP/hr logged to `specs/metrics/cycle-times.yaml`.

**next_skill signaling:** each critical-path skill writes `handoff.next_skill` to `state.yaml`. Call `survey-context` after any interruption to resume exactly where you left off.

---

## 📖 Hierarchy of Truth

| Level | Document | Responsibility |
| :--- | :--- | :--- |
| **Vision** | `docs/PRINCIPLES.md` | Philosophical foundations and evolution. |
| **Context** | `specs/tech-architecture/TECH_STACK_LATEST.md` | Tech stack, architecture, and domain notes. |
| **Scope** | `specs/product/SCOPE_LATEST.yaml` | In-scope / out-of-scope and success criteria. |
| **Vision** | `specs/product/VISION_LATEST.yaml` | North star and initiative success criteria. |
| **Decisions** | `specs/adr/` | Architectural Decision Records (irreversible choices). |
| **Roadmap** | `specs/release-plan.yaml` + `specs/epics/` | WSJF-prioritized epics and stories with BCP baseline. |
| **Current** | `specs/state.yaml` | Session flow, active epic, `handoff.next_skill`, timestamps. |
| **Metrics** | `specs/metrics/cycle-times.yaml` | Per-story BCPs, cycle minutes, BCP/hr (v2.0.0). |
| **Index** | `SKILL-INDEX.md` | Canonical list of all active skills. |
| **Style** | `CONVENTIONS.md` | Coding, testing, and naming standards. |

---

## 📁 Project Structure

- `scripts/`: Installation, syncing, and compliance tools.
- `specs/`: YAML cockpit — `state.yaml`, `release-plan.yaml`, `epics/`, `execution-status.yaml`, `requirements/`.
- `specs/metrics/`: Cycle-time ledger (`cycle-times.yaml`) — per-story BCPs, timestamps, BCP/hr (v2.0.0).
- `dashboard/`: Live monitoring tool — TUI (`npm run dashboard`) and web (`npm run dashboard:web`, port 7742).
- `docs/`: Guides including `WORKFLOW-SOP-v2.md` (full SDLC SOP) and `using-bigpowers.md`.
- `docs/references/`: Theoretical foundations (Uncle Bob, Ousterhout, Karpathy, etc.).
- `[skill-name]/`: Source files for each of the 70 skills.

---

## 🤝 References & Credits

`bigpowers` stands on the shoulders of giants. It integrates patterns from:
- **Akita**: Architectural patterns.
- **BMAD**: Bold, Minimal, Actionable, Durable documentation.
- **Clean Code**: Robert C. Martin (Uncle Bob).
- **A Philosophy of Software Design**: John Ousterhout.
- **GSD (Get Stuff Done)**: Pragmatic workflow frameworks.

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---
*“Simplicity is the ultimate sophistication, but integrity is the ultimate requirement.”*
