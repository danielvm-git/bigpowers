# Plan: v1.10.0 (Agentic Gherkin Compliance Harness)

## Context
Implement the foundational infrastructure for auditing bigpowers skills against behavioral requirements defined in Gherkin feature files. This harness allows an agent to "judge" skill compliance by mapping Gherkin steps to markdown content and evaluating them against the benchmarks (Akita, Karpathy, Clean Code, etc.).

## Steps

1. Create audit directory structure → verify: `mkdir -p specs/audit/features specs/audit/reports && ls -d specs/audit/features`

2. Define a "Harness Smoke Test" feature file in `specs/audit/features/harness-smoke.feature` to test the script → verify: `cat specs/audit/features/harness-smoke.feature`

3. Create `scripts/audit-compliance.sh` with basic CLI argument handling and help message → verify: `bash scripts/audit-compliance.sh --help`

4. Implement Gherkin line-parsing (extracting Feature, Scenario, and Steps) in `scripts/audit-compliance.sh` → verify: `bash scripts/audit-compliance.sh specs/audit/features/harness-smoke.feature --dry-run`

5. Implement the "Agentic Judge" loop: the script presents a step and relevant file content (if specified) to the terminal, then waits for a PASS/FAIL input → verify: `bash scripts/audit-compliance.sh specs/audit/features/harness-smoke.feature`

6. Implement Markdown report generation for audit results → verify: `bash scripts/audit-compliance.sh specs/audit/features/harness-smoke.feature && ls specs/audit/reports/*.md`

7. Update `specs/STATE.md` to include "Agentic Gherkin Compliance Harness" in the project capabilities → verify: `grep "Compliance Harness" specs/STATE.md`

## Out of scope
- Automatic API-based LLM judging (initial version is interactive/agent-judged).
- Supporting complex Gherkin features like `Scenario Outline` or `DataTable` in the first pass.
- Creating the full suite of compliance features (scheduled for v1.11.0).

## Risks
- **Brittle Parsing:** Bash is not ideal for complex Gherkin. 
  - *Mitigation:* Use strict line-prefix matching and require a standard format for feature files.
- **Judge Fatigue:** Too many steps could overwhelm the agent.
  - *Mitigation:* Focus on high-signal behavioral steps; support `--scenario` filtering.
