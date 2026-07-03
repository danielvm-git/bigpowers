# Agent Configuration Files & OKF Cross-Reference

**Added:** 2026-07-03 | **Source:** session research

---

## 1. Agent Configuration Files by Tool

Every AI coding tool loads one or more markdown files as persistent agent instructions.
The file name, loading strategy, and activation model differ per tool.

| Tool | Config File(s) | Loading Strategy | Activation | Docs |
|------|---------------|------------------|------------|------|
| **Claude Code** | `CLAUDE.md`, `CLAUDE.local.md` | Walks directory tree up from cwd, concatenates all found | Always on | https://code.claude.com/docs/en/memory |
| **Gemini CLI / Agy** | `GEMINI.md` | Hierarchical, configurable via `context.fileName` | Always on | https://github.com/google-gemini/gemini-cli/blob/HEAD/docs/cli/gemini-md.md |
| **pi** | `CLAUDE.md`, `AGENTS.md`, `SYSTEM.md` | Global (`~/.pi/agent/`) → parent dirs → cwd | Always on | https://pi.dev/docs/latest/quickstart |
| **OpenCode** | `AGENTS.md`, `opencode.json` | Project root; config precedence: remote > global > custom > project | Always on | https://opencode.ai/docs/rules/ |
| **Codex CLI** (OpenAI) | `AGENTS.md`, `.codex/config.toml` | Global (`~/.codex/`) → project (`.codex/`) | Always on | https://developers.openai.com/codex/guides/agents-md |
| **GitHub Copilot** | `AGENTS.md`, `.github/copilot-instructions.md` | Nearest `AGENTS.md` in directory tree wins | Always on | https://docs.github.com/copilot/customizing-copilot/adding-custom-instructions-for-github-copilot |
| **Cline** | `.clinerules/` | Also auto-detects `.cursorrules`, Windsurf rules | Always on | https://docs.cline.bot/customization/cline-rules |
| **Roo Code** | `.roo/rules/*.md` | YAML frontmatter: `alwaysApply`, glob patterns, manual; also reads `CLAUDE.md` | Controlled per rule | https://agentconfig.ing/files/roo-rules/ |
| **Aider** | `.aider.conf.yml`, `CONVENTIONS.md` | YAML config: `~/.aider.conf.yml` → repo → cwd (last wins) | Always on | https://aider.chat/docs/config/aider_conf.html |
| **Kiro** | `.kiro/steering/*.md`, agent `.md` profiles | Explicit wiring via `resources` field in JSON config | Opt-in, per-agent | https://kiro.dev/docs/cli/steering/ |
| **Windsurf** | `.windsurf/rules/*.md`, `.windsurfrules` (legacy) | Project-local; 4 activation modes | `always_on`, `model_decision`, `glob`, `manual` | https://agentconfig.ing/files/windsurf-rules-md/ |
| **Lovable** | `AGENTS.md`, Workspace Knowledge | Shared with Copilot/Codex CLI; also `SKILL.md` folders | Always on | https://docs.lovable.dev/features/knowledge |
| **Cursor** | `.cursor/rules/*.mdc` | Project-local with glob patterns | File-pattern matching | https://docs.cursor.com/context/rules-for-ai |
| **Amazon Q Developer** | `.amazonq/cli-agents/*.json` | Workspace (`.amazonq/`) or user-wide (`~/.aws/amazonq/`) | Per-agent name | https://aws.github.io/amazon-q-developer-cli/agent-format.html |
| **Continue** | `.continue/rules/` (via `config.yaml`) | System message injected into Agent, Chat, Edit modes | Always on | https://docs.continue.dev/customize/deep-dives/rules |

### Comparison Matrix

| | Hierarchical? | Activation control | Multiple files? | Shared standard? |
|---|---|---|---|---|
| Claude Code | Yes (tree walk) | Always on | Yes (`.local.md` variant) | Proprietary |
| Gemini/Agy | Yes (configurable) | Always on | No (single file) | Proprietary |
| pi | Yes (global→parent→cwd) | Always on | Yes (`AGENTS.md` fallback) | Reads both CLAUDE.md & AGENTS.md |
| OpenCode | No (project root) | Always on | Yes (`opencode.json` companion) | AGENTS.md open standard |
| Codex CLI | Yes (global→project) | Always on | Yes (`config.toml` companion) | AGENTS.md open standard |
| GitHub Copilot | Yes (nearest in tree) | Always on | Yes (`copilot-instructions.md`) | AGENTS.md open standard |
| Cline | No (project-local) | Always on | Yes (`.clinerules/` directory) | Reads `.cursorrules`, Windsurf rules |
| Roo Code | No (project-local) | Per-rule (always/glob/manual) | Yes (`.roo/rules/` directory) | Reads CLAUDE.md |
| Aider | Yes (home→repo→cwd) | Always on | Yes (`CONVENTIONS.md`) | Proprietary (YAML config) |
| Kiro | No (explicit wiring) | Opt-in per agent | Yes (steering directory) | Proprietary |
| Windsurf | No | 4 modes (`always_on`, `auto`, `glob`, `manual`) | Yes (rules directory) | Proprietary (`.windsurfrules` legacy) |
| Lovable | No | Always on | Yes (Knowledge + Skills) | AGENTS.md open standard |
| Cursor | No (project-local) | Glob-based auto-inclusion | Yes (`.mdc` directory) | Proprietary |
| Amazon Q Developer | Yes (user→workspace) | Per-agent name | Yes (`.json` agent directory) | Proprietary (JSON, not Markdown) |
| Continue | No (project-local) | Always on | Yes (`.continue/rules/`) | Proprietary (YAML config) |

### Key takeaway

`CLAUDE.md` and `AGENTS.md` are emerging as the two dominant patterns:

- **`CLAUDE.md`** — Anthropic's hierarchical tree-walk model. Also read by pi and Roo Code. Best for monorepos with layered conventions.
- **`AGENTS.md`** — Open standard adopted by Codex, OpenCode, GitHub Copilot, Lovable, and Factory. Simpler, single-file-at-root pattern. Most portable across tools.

**Symlink pattern**: create `AGENTS.md` as the single source, then symlink `CLAUDE.md` → `AGENTS.md` for Claude Code compatibility. Cline, Windsurf, and Cursor can also be pointed at it via their respective rule directories.

### Open-source repos

| Tool | License | Repo |
|------|---------|------|
| Claude Code | Proprietary | https://github.com/anthropics/claude-code |
| Gemini CLI | Apache 2.0 | https://github.com/google-gemini/gemini-cli |
| pi | MIT | https://github.com/earendil-works/pi |
| OpenCode | MIT | https://github.com/anomalyco/opencode |
| Codex CLI | Apache 2.0 | https://github.com/openai/codex |
| Cline | MIT | https://github.com/cline/cline |
| Roo Code | Apache 2.0 | https://github.com/RooCodeInc/Roo-Code |
| Aider | Apache 2.0 | https://github.com/Aider-AI/aider |
| Continue | Apache 2.0 | https://github.com/continuedev/continue |
| Amazon Q Developer CLI | Apache 2.0 | https://github.com/aws/amazon-q-developer-cli |
| Kiro | Proprietary | https://kiro.dev |
| Windsurf | Proprietary | https://codeium.com/windsurf |
| Lovable | Proprietary | https://lovable.dev |
| Cursor | Proprietary | https://cursor.com |

---

## 2. Open Knowledge Format (OKF v0.1)

### Documentation Links

| Resource | URL |
|----------|-----|
| Specification | https://github.com/GoogleCloudPlatform/knowledge-catalog/blob/main/okf/SPEC.md |
| Guide, Examples & Validator | https://www.openknowledgeformat.com/ |
| Validator tool | https://www.openknowledgeformat.com/validator |
| Bundle templates | https://www.openknowledgeformat.com/templates |
| Prompt generator | https://www.openknowledgeformat.com/okf-prompt-generator |
| What is OKF? | https://okfbundle.com/what-is-okf/ |
| Google Cloud announcement | https://cloud.google.com/blog/products/data-analytics/how-the-open-knowledge-format-can-improve-data-sharing |

### How it works

OKF is a **vendor-neutral specification** for representing knowledge as portable Markdown files.
A "knowledge bundle" is a directory tree where each `.md` file is a "concept" with YAML frontmatter.

**Minimal structure:**

```
my_bundle/
├── index.md              # directory listing (progressive disclosure)
├── log.md                # optional update history
├── tables/
│   ├── orders.md         # concept: type: BigQuery Table
│   └── customers.md
└── playbooks/
    └── incident.md       # concept: type: Playbook
```

**Concept file format:**

```markdown
---
type: BigQuery Table          # REQUIRED — concept kind
title: Customer Orders        # Recommended
description: One row per completed order.
resource: https://console.cloud.google.com/bigquery?...  # Optional canonical URI
tags: [sales, orders]          # Optional cross-cutting categories
timestamp: 2026-05-28T14:30:00Z  # Optional last-modified
---

# Schema
| Column | Type | Description |
|--------|------|-------------|
| order_id | STRING | Unique identifier |
```

**Key properties:**

- **Only `type` is required** in frontmatter. All other fields are optional.
- **Bundle-relative links** (`/tables/orders.md`) express relationships as traversable graph edges.
- **No tooling required** — `cat`, `grep`, `git diff` are sufficient.
- **Consumers MUST tolerate** unknown types, missing fields, and broken links (graceful degradation).
- **`index.md`** enables progressive disclosure — agents scan the index before opening individual concepts.
- **`log.md`** records chronological updates (ISO 8601 date headings, newest first).

### Conformance rules

A bundle is conformant if:
1. Every non-reserved `.md` file has parseable YAML frontmatter.
2. Every frontmatter contains a non-empty `type` field.
3. Reserved filenames (`index.md`, `log.md`) follow their defined structure.

### Comparison with adjacent standards

| | OKF | Obsidian | Notion | "Metadata as code" |
|---|---|---|---|---|
| Format | Markdown + YAML frontmatter | Markdown + wikilinks | Proprietary blocks | Various |
| Specified? | Yes (written spec) | No | No | No |
| Git-native? | Yes | Yes (with plugins) | No | Yes |
| Agent-friendly? | Yes (typed, linkable) | Partial | Limited | Varies |
| Cross-linking | Markdown links → graph edges | `[[wikilinks]]` | Database relations | Varies |

---

## 3. OKF in bigpowers

bigpowers already uses OKF:

| Bundle | Location | Type |
|--------|----------|------|
| Story metrics | `specs/metrics/e38s09.okf.md` | `story-metrics` |
| Migration registry | `specs/migrations/registry.okf.md` | `migration-registry` |
| Migration bundles | `specs/migrations/m1-*.okf.md` through `m4-*.okf.md` | Migration concepts |
| Codebase wiki | `specs/codebase-wiki/` | Auto-generated story traceability concepts |
| OKF validator | `scripts/validate-okf.sh` | CI gate |

### Planned OKF expansion (v2.7x/v3.0 train)

| Epic | OKF Scope |
|------|-----------|
| e39 (Semantic Context Bridge) | Skill reference graph as OKF bundle, skills-wiki, conventions-wiki, agent-guide |
| e40 (Metrics Integrity) | Per-story metrics as OKF bundles with aggregation tags |
| e44 (Spec Version Migration) | Migration bundles distributed as OKF concepts |
| e45 (OKF Completion) | Epics-wiki, ADR-wiki, verification reports as OKF, bug-registry OKF-ification, viz.html graph |

### Should CLAUDE.md / GEMINI.md use OKF?

**No — the format overhead isn't justified for thin, single-file agent instructions.**

| File | Lines | OKF benefit? | Why |
|------|-------|-------------|-----|
| `CLAUDE.md` | ~220 | Low | Single flat file. OKF's value is in multi-concept bundles with typed frontmatter and cross-links. At 220 lines, splitting into concepts adds ceremony without payoff. |
| `GEMINI.md` | ~85 | Low | Even smaller; mostly redirects to CLAUDE.md. |
| `AGENTS.md` (hypothetical) | N/A | Low | Would be another thin redirect. |
| **`skills/*/SKILL.md`** (73 files) | 50–300 each | **High** | Already structured like OKF concepts — YAML frontmatter (`name`, `description`, `model`, `effort`), markdown body. Adding `type: Skill` and `okf_version: "0.1"` would make them conformant with zero structural change. |
| **`specs/` directory** | Various | **High** | Already migrating. `state.yaml`, `release-plan.yaml`, epics, ADRs, bugs all benefit from typed, linkable structure. |

**If all 73 SKILL.md files add `type: Skill` and `okf_version: "0.1"` to frontmatter**, the entire skill catalog becomes an OKF-compliant knowledge bundle. Benefits:

- `grep 'type: Skill'` → discover all skills (already possible with `search-skills`)
- Traverse skill dependencies as graph edges via markdown links (`[plan-work](/skills/plan-work/SKILL.md)`)
- Validate bundle integrity with `validate-okf.sh` (already exists)
- Render as browsable website (e33 docs site)
- Agents navigate the skill graph instead of reading individual files (e32 MCP server)

---

## 4. Version History

| Date | Change |
|------|--------|
| 2026-07-03 | Initial research — agent config file comparison + OKF assessment |
