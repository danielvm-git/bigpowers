# story: e46s01

# BMAD TEA (Test Engineering Architect) Reference

## Provenance
This reference document credits the upstream **TEA (BMAD Test Architecture Enterprise)** methodology.
Repository: `github.com/bmad-code-org/bmad-method-test-architecture-enterprise/main`
Credit Culture: We credit early and credit visibly (e36-style precedent).

## What is TEA?
TEA (Test Engineering Architect) is an upstream methodology built around the "Murat" persona and nine core workflows. It provides enterprise-grade test architecture rules and risk-scaled engineering guidance.

## Core Mechanisms Documented

### 1. Risk-Based Test Depth (P0–P3 scaling)
TEA introduces a tiered approach to testing, scaling verification rigor based on business risk:
*   **P0 (Critical):** Full verification multi-phase, security scans, and strict NFR gates.
*   **P1 (High):** Standard verification (build, test, lint, step-by-step UAT).
*   **P2 (Medium):** Smoke tests, typecheck, and lint.
*   **P3 (Low):** Typecheck and lint only.

### 2. Tiered Knowledge Fragments
TEA utilizes a structured knowledge tiering system (e.g., `tea-index.csv`) categorizing fragments into:
*   **Core:** Fundamental testing patterns and rules.
*   **Extended:** Context-specific testing techniques.
*   **Specialized:** Niche, domain-specific or framework-specific test architecture knowledge.

### 3. NFR Evidence Audit
TEA treats non-functional requirements (NFR) as primary gates. The NFR evidence audit evaluates features based on a go/no-go outcome across three dimensions:
*   **Performance:** Response time, throughput.
*   **Reliability:** Error rate, recovery.
*   **Operability:** Logging coverage, health checks.

## Adoption in bigpowers

### What bigpowers IS adopting (e46 e46s02-s04)
*   **Risk scaling (P0-P3):** Integrated into `plan-work` to scale the depth of verification in `verify-work`.
*   **NFR Evidence Gate:** Integrated as an explicit UAT gate in `verify-work` for P0 stories.
*   **Test-Design Artifact:** Producing an upstream `eNN-TEST_PLAN_LATEST.md` with structured `SC-eNNsYY-P*-NN` scenario IDs, enforced by traceability gates (`gate-trace`).

### What bigpowers is NOT adopting
*   **Per-workflow `checklist.md`:** bigpowers already manages discover-phase workflows via `specs/planning-status.yaml`.
*   **Resume frontmatter:** bigpowers orchestrates its sessions effectively using `specs/state.yaml`.
