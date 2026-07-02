# bigpowers

![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)
![npm version](https://img.shields.io/badge/npm-v2.43.2-blue.svg)
![Skills](https://img.shields.io/badge/skills-72-brightgreen.svg)

> 72 agent skills synthesizing 17 years of software engineering discipline into a prescriptive methodology for solo developers.

`bigpowers` is not a random collection of best practices. It is a highly opinionated, chronological layer cake of ideas, combining classical software craftsmanship with modern AI-native architecture. 

It provides a 6-phase lifecycle with hard gates, a 94% quality threshold, and a YAML cockpit (`specs/state.yaml`) that keeps both human and AI agents perfectly aligned across complex software projects. By enforcing strict boundaries and verifiable outcomes, it allows solo developers to orchestrate multi-agent workflows with predictable, high-quality results.

## Prerequisites

- **Runtime**: Node.js v14+
- **Environment**: Bash (required for all internal scripts)
- **Tooling**: jq (highly recommended for configuration)
- **AI Tools**: Claude Code, Gemini CLI, Cursor, or pi

## Installation

```bash
# One-shot setup: downloads, syncs artifacts, and links skills
npx bigpowers

# Or install globally
npm install -g bigpowers
bigpowers
```

## Usage

```bash
# Update and re-sync your local skills
npm update -g bigpowers
bigpowers
```
For deep usage, integrate the generated skills directly into your favorite AI tool (Claude Code, Gemini CLI, Cursor). Use the provided MCP Server to expose skills dynamically:
```bash
node scripts/mcp-server.js
```

## Features

- **72 Purpose-Built Skills**: From `survey-context` to `develop-tdd`, each skill is a targeted tool for a specific phase of development.
- **Spec-Driven Cockpit**: Uses `specs/state.yaml` and `release-plan.yaml` to maintain state across agent sessions, preventing context drift.
- **Native IDE Support**: Automatically generates configurations for Cursor (`.cursor/rules`), Gemini CLI, and pi.
- **Model Context Protocol (MCP)**: Dynamic tool discovery and invocation via the included MCP server.
- **Built-in Quality Gates**: Strict verification standards (e.g., F.I.R.S.T tests, BCP accounting) enforced before any code is merged.

## 🧠 Philosophical Stack — How These Ideas Concatenate

`bigpowers` is not a flat list of influences. It is a **chronological layer cake** — each wave of thinking builds on and resolves tensions from the previous one. No layer replaces the last; each addresses a problem the prior one created.

![Philosophy Diagram](docs/images/philosophy_diagram.jpg)

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

## Development

```bash
git clone https://github.com/danielvm-git/bigpowers.git
cd bigpowers
npm install
# Sync artifacts from SKILL.md sources
npm run sync
```

## Tests

```bash
# Run compliance verification against Gherkin features
npm run compliance

# Validate YAML specifications and doctrine
npm run doctrine
npm run validate-specs
```

## Contributing

1. Fork the repo.
2. Create a feature branch (`git checkout -b feature/my-thing`).
3. Make your changes using the `bigpowers` methodology.
4. Commit using Conventional Commits (`git commit -am 'feat: add my thing'`).
5. Push to the branch (`git push origin feature/my-thing`).
6. Open a Pull Request.

## Changelog

See [CHANGELOG.md](CHANGELOG.md) or [Releases](https://github.com/danielvm-git/bigpowers/releases).

## Links

- **Repository**: https://github.com/danielvm-git/bigpowers
- **Issue Tracker**: https://github.com/danielvm-git/bigpowers/issues

## Acknowledgements

This project is a synthesis of decades of software engineering thought. It would not be possible without the foundational work of the authors who wrote the inspirational articles and books that shaped this methodology:

- **Robert C. Martin (Uncle Bob)** for establishing the baseline of code hygiene and the F.I.R.S.T principles in *Clean Code*.
- **John Ousterhout** for his paradigm-shifting views on Deep Modules and complexity management in *A Philosophy of Software Design*.
- **Andrej Karpathy** and **Matt Pocock** for their pioneering work on agentic skills and structuring context for LLMs.
- **Jarek Wasowski** for identifying Spec-Driven Development (SDD) as the missing link for AI agents.
- **AkitaOnRails** for adapting classical clean code principles to the reality of the AI token economy.

## License

MIT — see [LICENSE](LICENSE) for details.
