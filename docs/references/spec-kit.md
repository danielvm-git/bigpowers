# Spec-Driven Development (SDD) Tool Landscape

**Source:** various (see per-tool links)
**Author:** Daniel VM (curated reference)
**Last updated:** 2026-07-05

## Spec-Kit

**What it does:** Standardizes specification formats for machine-readability, integrates specs with agent toolchains, and enforces validation gates before implementation.

**Key differentiator:** Spec-first gating — no code before spec passes validation.

**Bigpowers relation:** bigpowers adopted the structured-spec pattern (YAML epic capsules, tasks.yaml with `verify:` commands) and the validation-gate concept (golden suite, compliance, traceability). The `elaborate-spec` and `plan-work` skills operationalize spec-kit's core ideas within the bigpowers lifecycle.

## Kiro

**What it does:** Spec-driven code generation — reads specifications and produces implementation code directly, reducing hand-coding for well-specified features.

**Key differentiator:** Code generation from specs rather than spec-guided development.

**Bigpowers relation:** bigpowers takes the opposite approach — specs guide the agent (plan-work → develop-tdd) rather than generate code directly. The human-in-the-loop verification mandate (UAT after every story) is a deliberate divergence from Kiro's automated generation model.

## Tessl

**What it does:** AI-native SDD platform — end-to-end spec-to-deployment pipeline with integrated AI agents that read specs and produce running software.

**Key differentiator:** Full-stack platform with built-in deployment; closed-loop from spec to production.

**Bigpowers relation:** bigpowers shares the spec-first philosophy but is toolchain-agnostic — you bring your own stack, CI, and deployment. bigpowers skills are composable (each skill does one thing) rather than a monolithic platform.

## BMAD (BMAD Method)

**What it does:** Methodology-first SDD approach with structured personas (architect, developer, tester), risk-based test depth (TEA module), and NFR evidence audit.

**Source:** [BMAD Method](https://github.com/bmad-code-org) — local mirror at `~/.opensrc/repos/github.com/bmad-code-org/`

**Key differentiator:** Persona-driven development with dedicated roles for each lifecycle phase; TEA (Test Architecture Enterprise) module for risk-based verification depth.

**Bigpowers relation:** bigpowers adopted BMAD's persona concept (skills act as specialized roles — `design-interface` = architect, `develop-tdd` = developer, `enforce-first` = tester) and the risk-based verification model via `security-review` and `assess-impact`. The `docs/references/bmad.md` file covers the full BMAD v6/TEA intersection.

## GSD (General Spec-Driven Framework)

**What it does:** A general-purpose SDD framework with quality levels for test suites (GSD levels 0-5), structured planning, and agent-driven execution.

**Source:** GSD Core repository

**Key differentiator:** Quality-level progression model — teams advance through test maturity levels rather than a binary pass/fail gate.

**Bigpowers relation:** bigpowers incorporated GSD's quality-level concept into the `audit-code` checklist (tiered gates: --quick, --gate, full) and the golden suite's progressive compliance model. The `enforce-first` skill mirrors GSD's test quality rubric approach.

## Bigpowers

**What it does:** Curated set of 74 skills organized around the PMBOK developer lifecycle — spec-driven, test-first development by solo developers.

**Key differentiator:** Composability over platform — each skill is a standalone markdown file; no vendor lock-in; works with Claude Code, Cursor, and Gemini CLI.

## Comparison Matrix

| Tool | Approach | Open Source | Agent-Native | Spec Format | Deployment |
|------|----------|-------------|--------------|-------------|------------|
| spec-kit | Spec gating | Yes | Yes | YAML/MD | Agnostic |
| Kiro | Code generation | — | Yes | Structured spec | Agnostic |
| Tessl | Full platform | — | Yes | Platform-native | Built-in |
| BMAD | Methodology | Yes | Yes | Markdown | Agnostic |
| GSD | Quality levels | Yes | Yes | Markdown | Agnostic |
| bigpowers | Skill composition | Yes | Yes | YAML (epics) + MD (SKILL.md) | Agnostic |
