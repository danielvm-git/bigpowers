# Release Plan: Gap Closure Strategy (Strict SemVer & Conventional Commits)

This document outlines the sequential release strategy to address gaps identified in `specs/COMPARISON.md`. It strictly adheres to [Conventional Commits 1.0.0](https://www.conventionalcommits.org/en/v1.0.0/) and [Semantic Versioning 2.0.0](https://semver.org/).

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

## Release Sequence

| Release | Gap | Target Commit Message | Bump | Baseline: `v1.0.0` |
| :--- | :--- | :--- | :--- | :--- |
| **v1.1.0** | N/A | `feat(compliance): enforce Conventional Commits and SemVer in CONVENTIONS.md` | Minor | New Version: `v1.1.0` |
| **v1.2.0** | GSD | `feat(survey): introduce map-codebase skill for high-fidelity surveying` | Minor | New Version: `v1.2.0` |
| **v1.3.0** | GSD | `feat(utility): introduce session-state skill to prevent context rot` | Minor | New Version: `v1.3.0` |
| **v1.4.0** | #1 | `feat(develop-tdd): add 'Think Before Coding' assumption-surfacing gate` | Minor | New Version: `v1.4.0` |
| **v1.5.0** | #2 | `feat(skills): implement HARD-GATE callout blocks for critical execution points` | Minor | New Version: `v1.5.0` |
| **v1.6.0** | #3 | `feat(zoom-out): introduce zoom-out utility skill` | Minor | New Version: `v1.6.0` |
| **v1.7.0** | #4 | `feat(develop-tdd): append 'red flags' table for common agent rationalizations` | Minor | New Version: `v1.7.0` |
| **v1.8.0** | #5 | `feat(terse-mode): extend terse-mode with caveman token-reduction rules` | Minor | New Version: `v1.8.0` |
| **v1.9.0** | #6 | `feat(audit-code): add 'Surgical Changes' diff check` | Minor | New Version: `v1.9.0` |
| **v1.10.0** | #7 | `feat(handoff): introduce handoff utility skill` | Minor | New Version: `v1.10.0` |
| **v1.11.0** | #8 | `feat(architecture): introduce improve-codebase-architecture sustain skill` | Minor | New Version: `v1.11.0` |
| **v1.12.0** | #9 | `feat(audit-code): integrate agent-readability lens checklist` | Minor | New Version: `v1.12.0` |
| **v1.13.0** | #12 | `feat(audit-code): add Clean Code heuristics reference catalog` | Minor | New Version: `v1.13.0` |
| **v1.14.0** | #13 | `feat(integrations): introduce to-issues and triage skills for tracker sync` | Minor | New Version: `v1.14.0` |

---

## Detailed Action Items per Release

### v1.1.0: Compliance Infrastructure
- **Target:** `CONVENTIONS.md`, `.releaserc.json` (New)
- **Change:** Formally document the mandate for Conventional Commits and SemVer in `CONVENTIONS.md`. Create a `.releaserc.json` to automate versioning and changelog generation using `semantic-release`.

### v1.2.0: `map-codebase` Skill (GSD-inspired)
- **Target:** `map-codebase/SKILL.md` (New)
- **Change:** Implement a high-fidelity surveying skill that analyzes stack, architecture, and gray areas (error handling, API shapes) and persists them into `specs/CONTEXT.md`. This goes beyond `survey-context` by identifying "signals" for planning.

### v1.3.0: `session-state` Skill (GSD-inspired)
- **Target:** `session-state/SKILL.md` (New), `specs/STATE.md` (New)
- **Change:** Introduce a mechanism to track implementation decisions and progress in a structured `specs/STATE.md` file. This prevents "context rot" by ensuring decisions survive session boundaries and context window flushes.

### v1.4.0: "Think Before Coding" Gate
- **Target:** `develop-tdd/SKILL.md`
- **Change:** Add a mandatory step in the Research/Strategy phase to surface assumptions and interpret the request in 2-3 ways before writing any code.

### v1.5.0: HARD-GATE Callouts
- **Target:** All execution-heavy skills (e.g., `plan-work`, `execute-plan`).
- **Change:** Embed bold, high-visibility blocks: **HARD GATE — Do NOT proceed until [Artifact] exists.**

### v1.6.0: `zoom-out` Utility
- **Target:** `zoom-out/SKILL.md` (New)
- **Change:** Create a skill that requires the agent to explain the target code's purpose and relationships within the broader system *before* modifying it.

### v1.7.0: Red Flags Table
- **Target:** `develop-tdd/SKILL.md`
- **Change:** Add a "Red Flags" table identifying common agent rationalizations ("it's too small for tests", "I'll refactor later").

### v1.8.0: Caveman Terse Mode
- **Target:** `terse-mode/SKILL.md`
- **Change:** Add rules for dropping articles (the, a, an), filler language, and aggressive token compression.

### v1.9.0: Surgical Changes Audit
- **Target:** `audit-code/SKILL.md`
- **Change:** Add a checklist item verifying that the diff is "surgical"—affecting only the necessary files and lines for the task.

### v1.10.0: `handoff` Utility
- **Target:** `handoff/SKILL.md` (New)
- **Change:** Create a skill to compact the current session state into a concise document for a "cold-start" by a subsequent agent.

### v1.11.0: `improve-codebase-architecture` Skill
- **Target:** `improve-codebase-architecture/SKILL.md` (New)
- **Change:** Implement an audit skill based on John Ousterhout's "A Philosophy of Software Design" (module depth vs. interface breadth).

### v1.12.0: Agent-Readability Lens
- **Target:** `audit-code/SKILL.md`
- **Change:** Add checks for "grep-ability", unique naming, and ensuring functions fit within standard context windows.

### v1.13.0: Clean Code Heuristics Catalog
- **Target:** `audit-code/HEURISTICS.md` (New)
- **Change:** A comprehensive reference of Martin's heuristics (G1-G35, etc.) linked from `audit-code/SKILL.md`.

### v1.14.0: Issue Tracker Integration
- **Target:** `to-issues/SKILL.md`, `triage/SKILL.md` (New)
- **Change:** Skills for syncing `specs/*.md` artifacts with GitHub/Linear issue trackers.
