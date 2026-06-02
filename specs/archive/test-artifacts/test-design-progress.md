---
workflowStatus: 'completed'
totalSteps: 5
stepsCompleted: ['step-01-detect-mode', 'step-02-load-context', 'step-03-risk-and-testability', 'step-04-coverage-plan', 'step-05-generate-output']
lastStep: 'step-05-generate-output'
nextStep: ''
lastSaved: '2026-05-18'
inputDocuments:
  - 'specs/PLAN-v1.11.0.md'
  - 'CONVENTIONS.md'
  - 'GEMINI.md'
  - 'specs/test-artifacts/traceability-matrix.md'
  - '.agents/skills/bmad-testarch-test-design/resources/knowledge/risk-governance.md'
  - '.agents/skills/bmad-testarch-test-design/resources/knowledge/probability-impact.md'
  - '.agents/skills/bmad-testarch-test-design/resources/knowledge/test-levels-framework.md'
  - '.agents/skills/bmad-testarch-test-design/resources/knowledge/test-priorities-matrix.md'
---

# Step 1: Detect Mode & Prerequisites

## Mode Selection
- **Selected Mode**: Epic-Level Mode
- **Epic Context**: v1.11.0 (Compliance Reference Features)
- **Rationale**: The v1.11.0 epic involves creating Gherkin feature files for behavioral benchmarks (Akita, Karpathy, etc.), which is fundamentally a test-design and compliance task. A dedicated epic-level test plan will ensure the quality and coverage of these reference features.

## Prerequisite Check
- [x] Epic/Story Requirements: Found in `specs/PLAN-v1.11.0.md`.
- [x] Architecture Context: Found in `CONVENTIONS.md` and `GEMINI.md`.
- [x] Acceptance Criteria: Outlined as "verify" steps in `specs/PLAN-v1.11.0.md`.

## HALT Conditions
- None. Required inputs are present.

# Step 2: Load Context & Knowledge Base

## Configuration & Stack Detection
- `tea_use_playwright_utils`: `true`
- `tea_use_pactjs_utils`: `false`
- `tea_browser_automation`: `auto`
- `detected_stack`: `frontend` (Documentation/Node.js project)

## Artifact Analysis
- **Testable requirements**: 
  1. Creation of 6 Gherkin `.feature` files (Akita, Karpathy, Clean Code, Pocock, BMAD, Superpowers).
  2. Baseline audit run using `audit-compliance.sh`.
  3. Session state update (`specs/STATE.md`).
- **Existing Test Patterns**:
  - Gherkin feature files in `specs/audit/features/`.
  - Shell scripts for step verification in `specs/audit/steps/`.
  - `audit-compliance.sh` as the test runner.
- **Integration Points**: 
  - The `audit-compliance.sh` script interacting with the skill definitions (Markdown files).

## Knowledge Fragments Loaded
- Core risk, level, and priority frameworks have been loaded.
- Specialized knowledge for contract testing and microservices is skipped as not relevant to this epic.

# Step 3: Testability & Risk Assessment

## Risk Assessment Matrix (Epic-Level: v1.11.0)

| ID | Category | Risk Description | Prob (1-3) | Imp (1-3) | Score | Mitigation Plan | Owner |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **R1** | BUS | **Inaccurate Gherkin Specs**: Features misinterpret source benchmarks (Clean Code, Karpathy, etc.). | 2 | 3 | **6 (HIGH)** | Peer review against original PDFs/URLs; include source citations in Gherkin comments. | Winston (Architect) |
| **R2** | TECH | **Audit Script Fragility**: `audit-compliance.sh` fails on edge case step names or missing `.sh` scripts. | 2 | 2 | **4 (MED)** | Unit test the parser logic; validate step-to-script mapping before audit runs. | danielvm |
| **R3** | BUS | **Inconsistent Judging**: Agentic judging varies between models or sessions. | 3 | 2 | **6 (HIGH)** | Minimize step ambiguity; provide concrete "PASS/FAIL" examples in Gherkin `Examples` tables. | danielvm |
| **R4** | BUS | **Incomplete Coverage**: Feature files miss critical principles identified in traceability matrix. | 2 | 2 | **4 (MED)** | Cross-reference Gherkin Scenarios with the `traceability-matrix.md` Oracle IDs. | danielvm |

## Summary of Risk Findings
The high-risk areas are the **Accuracy of the Compliance Specs (R1)** and the **Consistency of the Judging Process (R3)**. 

- **R1 Mitigation**: We must ensure that the Gherkin steps are directly derived from the authoritative sources. The presence of `book_Robert_C_Martin_2008_Clean_Code_A_Handbook_of_Agile_Software_Craftsmanship.pdf` in the root is a key resource here.
- **R3 Mitigation**: Since judging is interactive, we will prioritize "Simplicity" and "Determinism" in the step definitions.

# Step 4: Coverage Plan & Execution Strategy

## Coverage Matrix

| Req / Scenario | Atomic Test Scenario | Test Level | Priority | Rationale |
| :--- | :--- | :--- | :--- | :--- |
| **Gherkin Creation** | Akita, Karpathy, Clean Code, Pocock, BMAD, Superpowers features created and valid. | Doc / Spec | P0 | Foundation for compliance audit. |
| **Audit Script** | `audit-compliance.sh` correctly parses a .feature file and maps steps to .sh scripts. | Unit / Int | P0 | Critical harness for verification. |
| **Audit Execution** | Baseline audit runs and reports correctly (detecting FAILs). | E2E (Audit) | P1 | Validates the "Red" state of the project. |
| **Step Definitions** | Each unique step in the feature files has a corresponding `.sh` script in `specs/audit/steps/`. | Integration | P1 | Required for automated/agentic verification. |
| **Session State** | `STATE.md` accurately reflects the v1.11.0 milestone completion. | Doc | P2 | Project management and audit trail. |

## Execution Strategy
- **PR Gate**: Run `bash scripts/audit-compliance.sh [feature] --dry-run` for all changed feature files.
- **Nightly Suite**: Run the full audit loop across all benchmarks to track project compliance maturity.

## Resource Estimates
- **P0 (Critical)**: ~10–15 hours
- **P1 (High)**: ~8–12 hours
- **P2 (Medium)**: ~2–4 hours
- **Total Estimated Effort**: ~20–31 hours

## Quality Gates
- **P0 Pass Rate**: 100%
- **P1 Pass Rate**: ≥ 90% (Audit harness must be stable even if skills fail).
- **High-Risk Mitigations**: Risk R1 (Spec Accuracy) must be reviewed by the Architect before merging.

# Step 5: Generate Outputs & Validate

## Output Generation Summary
- **Mode Used**: Sequential
- **Template**: `test-design-template.md`
- **Output File**: `specs/test-artifacts/test-design-epic-v1.11.0.md`
- **Validation**: Checklist verified. All P0 and P1 coverage defined. Risk mitigations owned.
