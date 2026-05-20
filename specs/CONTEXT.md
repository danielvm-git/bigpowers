# Context: bigpowers

Project constitution read by all agents before planning or implementation.

---

## Vision

**"Maintain senior-grade quality while scaling agentic autonomy."**

bigpowers is a collection of 44+ verb-noun skills for spec-driven, test-first software development
by solo developers. It governs AI agents (Claude Code, Gemini CLI, Cursor) with the same rigorous
standards applied to senior human engineers — Clean Code, Ousterhout's deep-module theory, and
Karpathy's behavioral principles — unified into a single prescriptive lifecycle.

The project is a discipline, not a plugin store. It provides the *how*, not the *what*.

---

## Technology

- **Language**: Markdown + Bash (documentation-first; no runtime)
- **Distribution**: Claude Code (`.claude/`), Cursor (`.cursor/rules/`), Gemini CLI (`.gemini/extensions/`)
- **Sync**: `scripts/sync-skills.sh` auto-generates harness artifacts from `SKILL.md` sources
- **Compliance**: `npm run compliance` runs the Gherkin audit harness (`scripts/audit-compliance.sh`)
- **Install**: `bash scripts/install.sh` (links hooks, generates initial CLAUDE.md + CONVENTIONS.md)

---

## Architecture

One `SKILL.md` per skill directory (verb-noun, kebab-case). Supporting files (`REFERENCE.md`,
`HEURISTICS.md`, scripts) live alongside. The sync script reads every `SKILL.md` and writes:

```
<skill>/SKILL.md  ← single source of truth
    ↓ sync-skills.sh
.cursor/rules/<skill>.mdc
.gemini/extensions/bigpowers/skills/<skill>/SKILL.md
```

All planning and spec output goes to `specs/` at the project root. `specs/` accumulates across
every phase and is the project's persistent long-term memory.

Compliance is measured by a Gherkin harness in `specs/audit/features/` with one `.feature` file
per philosophical pillar. Every scenario maps to a runnable step script.

---

## Philosophical Foundations (chronological)

| Year | Source | Contribution to bigpowers |
|------|--------|--------------------------|
| 2008 | Uncle Bob — *Clean Code* | SRP, Boy Scout Rule, F.I.R.S.T, intention-revealing names |
| 2018 | Ousterhout — *A Philosophy of Software Design* | Deep modules, information hiding, seams |
| 2023 | Karpathy | Think-first, surgical changes, goal-driven execution |
| 2024 | Wasowski — SDD | Spec-driven development; BDD as the missing link |
| 2024 | Superpowers / Pocock | Verb-noun skills, zoom-out, hard gates |
| 2026 | Akita | Agent-era re-rank: grep-ability, structured logging, token economy |
| 2026 | BMAD / GSD | 5-phase lifecycle, prescriptive loop, wave execution |

See `references/` for full source documents. See `PRINCIPLES.md` for the narrative arc.

---

## Glossary

| Term | Definition |
|------|-----------|
| **Skill** | A single `SKILL.md` file encoding one verb-noun capability. The atomic unit of bigpowers. |
| **BMAD lifecycle** | Discover → Elaborate → Plan → Build → Sustain. The 5-phase arc all work follows. |
| **Hard Gate** | An explicit `> **HARD GATE**` blockquote in a skill that stops execution until a condition is met. |
| **verify:** | A runnable shell command at the end of each plan step proving the step succeeded. |
| **Ghost skill** | Listed in SKILL-INDEX.md but has no directory — planned, not yet implemented. |
| **Orphan skill** | Has a directory and SKILL.md but absent from SKILL-INDEX.md — implemented but unindexed. |
| **WSJF** | Weighted Shortest Job First: (Business Value + Time Criticality + Risk Reduction) / Job Size. |
| **Context rot** | Quality degradation when a session's context window fills up across multiple skill invocations. |
| **Deep module** | A module with a simple interface hiding significant internal complexity (Ousterhout). |
| **Spec** | A file in `specs/` — the authoritative source of intent for a phase or decision. |
| **ADR** | Architecture Decision Record: a hard, irreversible decision with context, choice, and consequences. |
