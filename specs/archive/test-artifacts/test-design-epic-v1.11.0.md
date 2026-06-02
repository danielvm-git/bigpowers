---
workflowStatus: 'completed'
totalSteps: 5
stepsCompleted: ['step-01-detect-mode', 'step-02-load-context', 'step-03-risk-and-testability', 'step-04-coverage-plan', 'step-05-generate-output']
lastStep: 'step-05-generate-output'
nextStep: ''
lastSaved: '2026-05-18'
---

# Test Design: Epic v1.11.0 - Compliance Reference Features

**Date:** 2026-05-18
**Author:** danielvm
**Status:** Approved

---

## Executive Summary

**Scope:** Epic-level test design for Epic v1.11.0

**Risk Summary:**

- Total risks identified: 4
- High-priority risks (≥6): 2 (Accuracy, Judging Consistency)
- Critical categories: BUS, TECH

**Coverage Summary:**

- P0 scenarios: 2 (~10–15 hours)
- P1 scenarios: 2 (~8–12 hours)
- P2/P3 scenarios: 1 (~2–4 hours)
- **Total effort**: ~20–31 hours (~3–4 days)

---

## Not in Scope

| Item | Reasoning | Mitigation |
| :--- | :--- | :--- |
| **Fixing Audit Gaps** | v1.11.0 is for defining requirements, not fixing the skills themselves. | Gaps are documented in `STATE.md` and future epics. |
| **Automated Judging** | Remains agentic/interactive as per plan. | Use clear Gherkin steps to minimize agent ambiguity. |

---

## Risk Assessment

### High-Priority Risks (Score ≥6)

| Risk ID | Category | Description | Probability | Impact | Score | Mitigation | Owner | Timeline |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **R-001** | BUS | **Inaccurate Gherkin Specs**: Features misinterpret source benchmarks (Clean Code, Karpathy, etc.). | 2 | 3 | 6 | Peer review against original PDFs/URLs; include source citations in Gherkin comments. | Winston (Architect) | 2026-05-18 |
| **R-003** | BUS | **Inconsistent Judging**: Agentic judging varies between models or sessions. | 3 | 2 | 6 | Minimize step ambiguity; provide concrete "PASS/FAIL" examples in Gherkin `Examples` tables. | danielvm | 2026-05-18 |

### Medium-Priority Risks (Score 3-4)

| Risk ID | Category | Description | Probability | Impact | Score | Mitigation | Owner |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **R-002** | TECH | **Audit Script Fragility**: `audit-compliance.sh` fails on edge case step names or missing scripts. | 2 | 2 | 4 | Unit test parser logic; validate step-to-script mapping before runs. | danielvm |
| **R-004** | BUS | **Incomplete Coverage**: Feature files miss critical principles identified in traceability matrix. | 2 | 2 | 4 | Cross-reference Gherkin Scenarios with the `traceability-matrix.md` Oracle IDs. | danielvm |

---

## Entry Criteria

- [x] v1.11.0 Plan approved and baseline traceability matrix exists.
- [x] Access to benchmark source materials (Clean Code PDF, Superpowers URL).
- [x] `audit-compliance.sh` harness is provisioned in `scripts/`.

## Exit Criteria

- [x] All 6 compliance feature files created and valid.
- [x] `audit-compliance.sh` dry-run passes for all feature files.
- [x] Baseline audit report generated showing "FAIL" states for gaps.
- [x] `STATE.md` updated and reviewed.

---

## Test Coverage Plan

### P0 (Critical) - Run on every commit

**Criteria**: Blocks core journey + High risk (≥6) + No workaround

| Requirement | Test Level | Risk Link | Test Count | Owner | Notes |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Gherkin Creation** | Doc / Spec | R-001 | 6 | Winston | Features for Akita, Karpathy, etc. |
| **Audit Script Harness** | Unit / Int | R-002 | 1 | danielvm | Parser and script mapping verification. |

**Total P0**: 7 tests, ~15 hours

### P1 (High) - Run on PR to main

**Criteria**: Important features + Medium risk (3-4) + Common workflows

| Requirement | Test Level | Risk Link | Test Count | Owner | Notes |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Audit Execution** | E2E (Audit) | R-003 | 1 | danielvm | Full baseline run. |
| **Step Definitions** | Integration | R-002 | ~15 | danielvm | Shell scripts in `specs/audit/steps/`. |

**Total P1**: ~16 tests, ~12 hours

### P2 (Medium) - Run nightly/weekly

**Criteria**: Secondary features + Low risk (1-2) + Edge cases

| Requirement | Test Level | Risk Link | Test Count | Owner | Notes |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Session State** | Doc | - | 1 | danielvm | Update `STATE.md`. |

**Total P2**: 1 test, ~4 hours

---

## Execution Order

### Smoke Tests (<5 min)

- [x] `audit-compliance.sh --help` (Check script exists)
- [x] `ls specs/audit/features/*.feature` (Verify feature files exist)

### P0 Tests (<10 min)

- [ ] `audit-compliance.sh [feature] --dry-run` for each benchmark.

### P1 Tests (<30 min)

- [ ] Full baseline audit execution.

---

## Resource Estimates

### Test Development Effort

| Priority | Count | Hours/Test | Total Hours | Notes |
| :--- | :--- | :--- | :--- | :--- |
| P0 | 7 | 2.0 | 14 | Specs and harness |
| P1 | 16 | 0.75 | 12 | Step scripts and baseline |
| P2 | 1 | 4.0 | 4 | Documentation/State |
| **Total** | **24** | **-** | **~30** | **~4 days** |

---

## Quality Gate Criteria

### Pass/Fail Thresholds

- **P0 pass rate**: 100% (Features created and parser works)
- **P1 pass rate**: ≥ 90% (Audit harness stable even if skills fail)
- **High-risk mitigations**: 100% Accuracy review (R1) complete

---

## Mitigation Plans

### R-001: Inaccurate Gherkin Specs (Score: 6)

**Mitigation Strategy:** Peer review Gherkin files against source documents. Use Gherkin comments (`# Source: ...`) to link steps to specific book pages or sections.
**Owner:** Winston (Architect)
**Timeline:** End of v1.11.0 implementation.
**Status:** Planned
**Verification:** Manual review of Gherkin files against `book_Robert_C_Martin_2008_Clean_Code_A_Handbook_of_Agile_Software_Craftsmanship.pdf`.

### R-003: Inconsistent Judging (Score: 6)

**Mitigation Strategy:** Use the Gherkin `Examples` tables to provide concrete "Pass" and "Fail" evidence examples for agents to follow. Keep steps outcome-based.
**Owner:** danielvm
**Status:** In Progress
**Verification:** Comparative audit runs across different sessions to ensure consistent reporting.

---

## Assumptions and Dependencies

### Assumptions

1. Agentic judging remains the primary verification method for v1.11.0.
2. Source materials provided in the root are authoritative.

### Dependencies

1. `audit-compliance.sh` remains compatible with basic Gherkin syntax.

---

## Appendix

### Knowledge Base References

- `risk-governance.md` - Risk classification framework
- `probability-impact.md` - Risk scoring methodology
- `test-levels-framework.md` - Test level selection
- `test-priorities-matrix.md` - P0-P3 prioritization

**Generated by**: BMad TEA Agent - Test Architect Module
**Workflow**: `bmad-testarch-test-design`
**Version**: 4.0 (BMad v6)
