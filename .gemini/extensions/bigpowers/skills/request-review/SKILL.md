---
name: request-review
description: "Dispatch a fresh reviewer agent with a clean context to critique the code after audit-code passes. The reviewer has no shared state with the coding agent and gives a genuine second opinion. Use after audit-code passes, before committing, or when user wants an independent code review."
---


# Request Review

Dispatch a fresh reviewer agent with a clean context. The reviewer has no shared state — it can give a genuine second opinion because it hasn't been involved in writing the code.

**Distinct from `audit-code`:** `audit-code` is the coding agent checking its own work (internal). This skill dispatches an external agent whose job is to find what the coding agent missed.

**Solo developer note:** This replaces the human reviewer. The reviewer agent IS the reviewer.

**Run `audit-code` first.** This skill assumes `audit-code` has already passed. Don't waste a reviewer's attention on hygiene issues you could have caught yourself.

## Process

### 1. Prepare the review brief

Write a self-contained brief for the reviewer agent. Include:

- What was built (feature description, not implementation)
- Which files changed (the diff context)
- What `specs/` artifacts are relevant (active `epics/eNN-*.yaml`, `requirements/SCOPE_LATEST.yaml`, `bugs/BUG-*.md`)
- What CONVENTIONS.md requires
- What the verify command is
- What you're most uncertain about (where you want fresh eyes)

### 2. Dispatch the reviewer agent

Use the Agent tool with a completely fresh context. The agent prompt must be self-contained — no references to "our conversation" or "what we discussed."

```
You are a code reviewer. Review the following code changes.

Context: [feature description]
CONVENTIONS.md rules: [paste relevant sections]
Active epic shard: [paste or summarize from specs/epics/]

Diff: [paste git diff or describe changed files]

Verify command: [runnable command]

Review for:
1. Correctness — does the code do what was intended?
2. CONVENTIONS.md compliance — are all rules followed?
3. Test quality — do tests verify behavior (not implementation)?
4. Design — are there simpler or more robust approaches?
5. Edge cases — what inputs or states could cause failures?
6. Security — any injection, auth, or data exposure risks?

For each finding, categorize as: must-fix / should-fix / consider.
Run the verify command and report the result.
```

### 3. Collect the report

When the reviewer returns:
- Read every finding before acting on any
- Note the verify command result
- Compute the quality score: `100 × (total_items − must_fix − should_fix) / total_items`
- Report the score to the user

> **HARD GATE** — If score < 94%, do NOT merge. Run `respond-review` to resolve must-fix and should-fix findings first. The 94% threshold also applies to the compliance SCORE computed by `npm run compliance` (scripts/audit-compliance.sh): SCORE = passing Gherkin scenarios / total × 100.

### 4. Hand off to respond-review

Pass the reviewer's report to `respond-review` to categorize findings and apply fixes.

Report to user: "Review complete. [N] findings: [X] must-fix, [Y] should-fix, [Z] consider. Running respond-review."
