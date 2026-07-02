# bigpowers — Best-in-Class Agentic Skills

![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)
![npm version](https://img.shields.io/npm/v/bigpowers.svg)
![Skills](https://img.shields.io/badge/skills-72-brightgreen.svg)

**72 agent skills synthesizing 17 years of software engineering discipline — from Clean Code to AI-native architecture — into a single, prescriptive methodology for solo developers.**

`bigpowers` is not a random collection of best practices. It is a chronological layer cake of ideas: each wave of thinking (Uncle Bob → Ousterhout → Karpathy → Wasowski → Akita) builds on and resolves tensions from the last, culminating in a 6-phase lifecycle with hard gates, a 94% quality threshold, and a YAML cockpit (`specs/state.yaml`) that keeps both human and agent aligned across sessions.

Published on npm: [bigpowers@2.43.2](https://www.npmjs.com/package/bigpowers)

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
| `bigpowers_list_skills` | List all 72 skills with name, description, phase. Optional `phase` filter. |
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
- `[skill-name]/`: Source files for each of the 72 skills.

---

## 🧠 Philosophical Stack — How These Ideas Concatenate

`bigpowers` is not a flat list of influences. It is a **chronological layer cake** — each wave of thinking builds on and resolves tensions from the previous one. No layer replaces the last; each addresses a problem the prior one created.

| Era | Source | Contribution | Tension Resolved |
|:---|:---|:---|:---|
| **2008** | [Uncle Bob](https://www.amazon.com/Clean-Code-Handbook-Software-Craftsmanship/dp/0132350882) (Clean Code) | SRP, Boy Scout Rule, F.I.R.S.T. tests, intention-revealing names | — (foundation) |
| **2018** | [Ousterhout](https://www.amazon.com/Philosophy-Software-Design-John-Ousterhout/dp/1732102201) (*A Philosophy of Software Design*) | Deep modules, information hiding, define errors out of existence | Small functions alone create shallow modules with bloated interfaces |
| **2023–24** | [Karpathy](https://github.com/multica-ai/andrej-karpathy-skills), [Superpowers](https://github.com/obra/superpowers), [Pocock](https://github.com/mattpocock/skills) | Think-first planning, verb-noun skill architecture, zoom-out strategy | Raw LLMs have no discipline — they need orchestration, not raw prompting |
| **2024** | [Wasowski](https://medium.com/@wasowski.jarek/sdd-writing-specifications-for-ai-bdd-as-the-missing-link-spec-driven-development-ad1b540b7f75) (SDD), [BCP](https://github.com/flow-ciandt/bcp-agent) | Specs as the human-agent interface; business complexity as a pre-build sizing unit | Agents drift without a verifiable spec — BDD Gherkin closes the loop |
| **2026** | [Akita](https://akitaonrails.com/2026/04/20/clean-code-para-agentes-de-ia/) (*Clean Code for AI Agents*) | Grep-ability, structured JSON logging, token economy, remediation hints in errors | Uncle Bob's rules were written for humans — agents need different code hygiene |
| **Synthesis** | BMAD + GSD (self-authored) | 6-phase lifecycle, hard gates, 94% quality threshold, `specs/state.yaml` cockpit | All the above are principles; bigpowers turns them into an executable discipline |

### How to see the concatenation in action

Each philosophical pillar has a corresponding Gherkin `.feature` file in [`specs/verifications/features/`](specs/verifications/features/) that empirically proves compliance:

| Pillar | Verification |
|:---|:---|
| Classical Craftsmanship | `cleancode.feature` |
| Complexity Management | `pocock.feature` |
| Behavioral Integrity | `karpathy.feature` |
| Spec-Driven Development | Implicit in SDD workflow |
| Agentic Standard | `akita.feature` |
| Project Conventions | `conventions.feature` |
| Original Baseline | `superpowers.feature` |

Run `npm run compliance` to audit all features. Score < 94% = hard stop.

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---
*“Simplicity is the ultimate sophistication, but integrity is the ultimate requirement.”*
