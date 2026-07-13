---
name: generate-allure-report
model: sonnet
effort: standard
description: "Generate Allure-ready reports from bigpowers YAML metadata. Reads execution-status.yaml, release-plan.yaml, epic capsules, task YAMLs, cycle-times.yaml, and bug registry to produce allure-results/junit-results.xml, categories.json, and executor.json. Use when preparing progress dashboards, integrating with Allure TestOps, or generating CI reports."
---

# Generate Allure Report

Generate Allure TestOps-compatible reports from bigpowers project metadata. Produces JUnit XML for story-level test results, custom categories for filtering, and executor metadata — all in the `allure-results/` directory.

## Quick Start

```bash
bash scripts/generate-allure-report.sh
```

## What It Produces

Three files in `allure-results/`:

| File | Description |
|------|-------------|
| `junit-results.xml` | One `<testcase>` per story with `<properties>` for risk, security, WSJF, tier, wave, and status. Incomplete stories get a `<failure>` element. |
| `categories.json` | Custom Allure categories for filtering by epic, risk level (P0), and security reviews. |
| `executor.json` | Build metadata — name, type, version from release-plan.yaml, build order. |

## Data Sources

See [REFERENCE.md](REFERENCE.md)

## Verify

```bash
test -f allure-results/junit-results.xml && test -f allure-results/categories.json && test -f allure-results/executor.json
```

## Handoff

- next_skill: null (terminal skill — no downstream workflow step)
