# bigpowers — Best-in-Class Agentic Skills

![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)
![npm version](https://img.shields.io/npm/v/bigpowers.svg)
![Skills](https://img.shields.io/badge/skills-59-brightgreen.svg)

**59 agent skills for high-integrity, spec-driven, test-first software development by solo developers.**

`bigpowers` provides a prescriptive, vertical-slice methodology for building software with AI agents (Claude Code, Gemini CLI, Cursor). It bridges the gap between raw LLM capabilities and professional engineering standards.

Published on npm: [bigpowers@1.0.0](https://www.npmjs.com/package/bigpowers)

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

## 🏗 The BMAD Lifecycle

Every task in `bigpowers` follows a prescriptive lifecycle (see `SKILL-INDEX.md`):

1.  **Discover**: survey-context, research-first, elaborate-spec.
2.  **Elaborate / Plan**: scope-work, plan-work, slice-tasks.
3.  **Build**: develop-tdd, execute-plan.
4.  **Verify**: verify-work, run-evals — prove it works before review.
5.  **Review / Release**: audit-code, request-review, release-branch.
6.  **Sustain**: stocktake-skills, evolve-skill (benchmark-gated).

---

## 📖 Hierarchy of Truth

| Level | Document | Responsibility |
| :--- | :--- | :--- |
| **Vision** | `docs/PRINCIPLES.md` | Philosophical foundations and evolution. |
| **Context** | `specs/CONTEXT.md` | Tech stack, architecture, and glossary. |
| **Scope** | `specs/SCOPE.md` | In-scope / out-of-scope and success criteria. |
| **Decisions** | `specs/adr/` | Architectural Decision Records (irreversible choices). |
| **Roadmap** | `specs/RELEASE-PLAN.md` | WSJF-prioritized releases and stories. |
| **Current** | `specs/STATE.md` | Current milestone and session progress. |
| **Index** | `SKILL-INDEX.md` | Canonical list of all active skills. |
| **Style** | `CONVENTIONS.md` | Coding, testing, and naming standards. |

---

## 📁 Project Structure

- `scripts/`: Installation, syncing, and compliance tools.
- `specs/`: The "Brain" of your project — all planning and decisions live here.
- `docs/references/`: Theoretical foundations (Uncle Bob, Ousterhout, Karpathy, etc.).
- `[skill-name]/`: Source files for each of the 59 skills.

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
