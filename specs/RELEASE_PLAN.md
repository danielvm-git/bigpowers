# Release Plan: Gap Closure Strategy (Strict SemVer & Conventional Commits)

This document outlines the sequential release strategy to address gaps identified in `specs/COMPARISON.md`. It strictly adheres to [Conventional Commits 1.0.0](https://www.conventionalcommits.org/en/v1.0.0/) and [Semantic Versioning 2.0.0](https://semver.org/).

## Cross-Platform Mandate
**All skills must be harness-agnostic.** Every release must be verified to function correctly across:
- **Claude Code** (via `.claude/settings.json` and PreToolUse hooks)
- **Antigravity** (via Google Terminal Deny-lists and native integrations)
- **Cursor / Cursor CLI** (via `.cursor/rules` and `beforeShellExecution` hooks)
- **Gemini CLI** (via `.gemini/settings.json` and BeforeTool hooks)

## Core Versioning Logic
- **PATCH (x.y.Z):** Backwards-compatible bug fixes.
- **MINOR (x.Y.z):** Backwards-compatible new features.
- **MAJOR (X.y.z):** Incompatible API changes or structural breaking changes.
- **Initial Development:** During `v0.x.y`, the public API is not stable.

## Commit Message Specification
- **Mandate:** NEVER include `Co-authored-by` footers in commit messages.
- **Format:** `<type>(<scope>): <description>`
- **Space:** A space MUST be provided after the colon.
- **Types:** `feat` (Minor), `fix` (Patch), `perf` (Patch), `chore`, `docs`, `refactor`, `style`, `test`.
- **Breaking Changes:** Indicated by `!` after the type/scope OR `BREAKING CHANGE:` footer.

---

## Release Sequence (Priority: Git Overhaul)

| Release | Status | Gap | Target Commit Message | Bump |
| :--- | :--- | :--- | :--- | :--- |
| **v1.1.0** | ✅ | N/A | `feat(compliance): enforce Conventional Commits and SemVer in CONVENTIONS.md` | Minor |
| **v1.2.0** | ✅ | GSD | `feat(survey): introduce map-codebase skill for high-fidelity surveying` | Minor |
| **v1.3.0** | ✅ | GSD | `feat(utility): introduce session-state and harden process gates` | Minor |
| **v1.4.0** | ✅ | GSD | `feat(guard): implement PreToolUse hook for Conventional Commits & main-branch protection` | Minor |
| **v1.5.0** | ✅ | #2 | `feat(skills): implement HARD-GATE callout blocks for critical execution points` | Minor |
| **v1.6.0** | ✅ | GSD | `feat(develop-tdd): bake 'Commit-on-Green' requirement into the TDD loop` | Minor |
| **v1.7.0** | ✅ | #4 | `feat(develop-tdd): append 'red flags' table for common agent rationalizations` | Minor |
| **v1.8.0** | ✅ | GSD | `feat(session-state): sync git branch/hash automatically in specs/STATE.md` | Minor |
| **v1.9.0** | ✅ | GSD | `feat(kickoff): harden git-worktree lifecycle and automated cleanup` | Minor |
| **v1.10.0** | ✅ | ALL | `feat(audit): implement agentic gherkin compliance harness` | Minor |
| **v1.11.0** | ✅ | ALL | `test(audit): define reference features (Akita, Karpathy, Clean Code, Pocock, BMAD, Super)` | No Bump |
| **v1.12.0** | ⏳ | #1 | `feat(develop-tdd): add 'Think Before Coding' assumption-surfacing gate` | Minor |
| **v1.13.0** | ⏳ | #3 | `feat(zoom-out): introduce zoom-out utility skill` | Minor |
| **v1.14.0** | ✅ | #9 | `feat(audit-code): integrate agent-readability lens checklist` | Minor |
| **v1.15.0** | ⏳ | #5 | `feat(terse-mode): extend terse-mode with caveman token-reduction rules` | Minor |
| **v1.16.0** | ⏳ | #6 | `feat(audit-code): add 'Surgical Changes' diff check` | Minor |
| **v1.17.0** | ⏳ | #7 | `feat(handoff): introduce handoff utility skill` | Minor |
| **v1.18.0** | ⏳ | #8 | `feat(architecture): introduce improve-codebase-architecture sustain skill` | Minor |
| **v1.19.0** | ⏳ | #12 | `feat(audit-code): add Clean Code heuristics reference catalog` | Minor |
| **v1.20.0** | ⏳ | #13 | `feat(integrations): introduce to-issues and triage skills for tracker sync` | Minor |

---

## Detailed Action Items per Release

### v1.10.0: Agentic Gherkin Compliance Harness
- **Target:** `scripts/audit-compliance.sh`, `specs/audit/steps/`
- **Change:** Build the "Judge" infrastructure that allows LLMs to evaluate Gherkin steps against markdown files. This is the foundational tool for proving compliance.

### v1.11.0: Reference-Based Compliance Features (The "Red" State)
- **Target:** `specs/audit/*.feature`
- **Goal:** Define feature files for Akita, Karpathy, Clean Code, Pocock, BMAD, and Superpowers. Running the audit now should show "FAIL" for all remaining gaps.

### v1.12.0: "Think Before Coding" Gate
- **Target:** `develop-tdd/SKILL.md`
- **Change:** Add a mandatory step in the Research/Strategy phase to surface assumptions and interpret the request in 2-3 ways before writing any code. (Satisfies Karpathy/Akita requirements).

### v1.13.0: `zoom-out` Utility
- **Target:** `zoom-out/SKILL.md` (New)
- **Change:** Create a skill that requires the agent to explain the target code's purpose and relationships within the broader system *before* modifying it. (Satisfies Pocock requirement).

### v1.15.0: Caveman Terse Mode
- **Target:** `terse-mode/SKILL.md`
- **Change:** Add rules for dropping articles (the, a, an), filler language, and aggressive token compression. (Satisfies Pocock/Akita requirements).

### v1.16.0: Surgical Changes Audit
- **Target:** `audit-code/SKILL.md`
- **Change:** Add a checklist item verifying that the diff is "surgical"—affecting only the necessary files and lines for the task. (Satisfies Karpathy requirement).



---

### v1.12.0: "Think Before Coding" Gate
- **Target:** `develop-tdd/SKILL.md`
- **Change:** Add a mandatory step in the Research/Strategy phase to surface assumptions and interpret the request in 2-3 ways before writing any code.

### v1.13.0: `zoom-out` Utility
- **Target:** `zoom-out/SKILL.md` (New)
- **Change:** Create a skill that requires the agent to explain the target code's purpose and relationships within the broader system *before* modifying it.

### v1.15.0: Caveman Terse Mode
- **Target:** `terse-mode/SKILL.md`
- **Change:** Add rules for dropping articles (the, a, an), filler language, and aggressive token compression.

### v1.16.0: Surgical Changes Audit
- **Target:** `audit-code/SKILL.md`
- **Change:** Add a checklist item verifying that the diff is "surgical"—affecting only the necessary files and lines for the task.

### v1.17.0: `handoff` Utility
- **Target:** `handoff/SKILL.md` (New)
- **Change:** Create a skill to compact the current session state into a concise document for a "cold-start" by a subsequent agent.

### v1.18.0: `improve-codebase-architecture` Skill
- **Target:** `improve-codebase-architecture/SKILL.md` (New)
- **Change:** Implement an audit skill based on John Ousterhout's "A Philosophy of Software Design" (module depth vs. interface breadth).

### v1.19.0: Clean Code Heuristics Catalog
- **Target:** `audit-code/HEURISTICS.md` (New)
- **Change:** A comprehensive reference of Martin's heuristics (G1-G35, etc.) linked from `audit-code/SKILL.md`.

### v1.20.0: Issue Tracker Integration
- **Target:** `to-issues/SKILL.md`, `triage/SKILL.md` (New)
- **Change:** Skills for syncing `specs/*.md` artifacts with GitHub/Linear issue trackers.
