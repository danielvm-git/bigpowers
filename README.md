# bigpowers — Best-in-Class Agentic Skills

![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)
![Version](https://img.shields.io/badge/version-1.14.0-blue.svg)
![Skills](https://img.shields.io/badge/skills-44+-brightgreen.svg)

**44+ agent skills for high-integrity, spec-driven, test-first software development by solo developers.**

`bigpowers` provides a prescriptive, vertical-slice methodology for building software with AI agents (Claude Code, Gemini CLI, Cursor). It bridges the gap between raw LLM capabilities and professional engineering standards.

---

## 🚀 Quick Start

```bash
# 1. Clone the repository
git clone https://github.com/danielvm-git/bigpowers.git && cd bigpowers

# 2. Install globally (links to Claude, Gemini, and Cursor)
bash scripts/install.sh

# 3. Sync artifacts
npm run sync
```

---

## 🛠 Prerequisites

- **Bash**: Required for all scripts.
- **Node.js**: Required for `npm` commands.
- **jq**: (Highly Recommended) Used for robust configuration of tool settings.
- **AI Tools**: One or more of:
  - [Claude Code](https://claude.ai/code)
  - [Gemini CLI](https://github.com/google/gemini-cli)
  - [Cursor](https://cursor.sh/)

---

## 🔄 Maintenance (Update & Uninstall)

### Update
To get the latest skills and performance improvements:
```bash
git pull
npm run sync
```
*Note: Since the installation uses symlinks, syncing automatically updates the tools.*

### Uninstall
To remove all managed symlinks and configuration hooks:
```bash
bash scripts/install.sh --uninstall
```

### Reinstall
If you need a fresh start:
```bash
bash scripts/install.sh --uninstall && bash scripts/install.sh
```

---

## 🏗 The BMAD Lifecycle

Every task in `bigpowers` follows a prescriptive 5-phase arc to ensure integrity:

1.  **Discover**: Investigate context, map unknowns, and survey requirements.
2.  **Elaborate**: Formalize specs and lock design decisions (ADRs).
3.  **Plan**: Write a verifiable, Karpathy-style implementation roadmap.
4.  **Build**: Execute via TDD, vertical slices, and small commits.
5.  **Sustain**: Audit quality, verify compliance, and release.

---

## 📖 Hierarchy of Truth

| Level | Document | Responsibility |
| :--- | :--- | :--- |
| **Vision** | `PRINCIPLES.md` | Philosophical foundations and evolution. |
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
- `references/`: Theoretical foundations (Uncle Bob, Ousterhout, Karpathy, etc.).
- `[skill-name]/`: Source files for each of the 44+ skills.

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
