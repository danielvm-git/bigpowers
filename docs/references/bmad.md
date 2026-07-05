# BMAD Method Reference

**Source:** [BMAD Method](https://github.com/bmad-code-org) — local mirror at `~/.opensrc/repos/github.com/bmad-code-org/`
**Author:** Daniel VM (curated reference)
**Last updated:** 2026-07-05

## Core Concepts

- **Bold, Minimal, Actionable, Durable:** The four criteria for high-integrity documentation.
- **The Lifecycle Arc:** Discover → Elaborate → Plan → Build → Sustain.

## BMAD v6

BMAD v6 introduced structured personas (architect, developer, tester) and workflow-based development. The methodology centers on spec-first engineering where documentation drives all automated processes.

## TEA (Test Architecture Enterprise)

The TEA module adds risk-based test depth to the BMAD methodology:

- **Murat Persona:** A dedicated test-architecture persona that assesses risk per story and assigns test depth (P0 full TDD → P3 smoke-only).
- **9 Workflows:** TEA defines nine structured workflows covering test planning, risk assessment, evidence collection, and NFR audit.
- **Risk-Based Depth:** Test intensity scales with story risk — P0/P1 stories get full TDD + integration + UAT; P2/P3 get lighter verification.
- **NFR Evidence Audit:** TEA mandates collecting objective evidence for non-functional requirements (performance, security, accessibility) rather than relying on checklists.

## Bigpowers Adoption

bigpowers adopted TEA's risk-based model through:
- `security-review` — threat-model epic scope (Step 0 of build-epic)
- `assess-impact` — blast-radius scoring before code (Step 2)
- `enforce-first` — F.I.R.S.T compliance gate (per CONVENTIONS.md §Tests)
- Epic risk classification (P0-P3) in `release-plan.yaml`
- `plan-tests` skill for P0/P1 epic test planning
