---
name: request-review
model: opus
description: "Dispatch a fresh reviewer agent with a clean context to critique the code after audit-code passes. The reviewer has no shared state with the coding agent and gives a genuine second opinion. Use after audit-code passes, before committing, or when user wants an independent code review."
disable-model-invocation: true
---

# story: e45s28

# Request Review

Dispatch fresh reviewer agents with clean contexts. Reviewers have no shared state — they find what the coding agent missed.

**Distinct from `audit-code`:** `audit-code` is self-review (internal). This skill dispatches external agents.

**Solo developer note:** Reviewer agents replace the human reviewer.

**Run `audit-code` first.** Don't waste reviewer attention on hygiene issues you could have caught yourself.

## Santa Method — Dual-Blind AND Gate (e45s07)

Use **two independent reviewers** (Reviewer A and Reviewer B) with **no shared context** between them or the coding agent.

| Parameter | Value |
|-----------|-------|
| Reviewers | 2 (mandatory) |
| `MAX_REVIEW_ITERATIONS` | **5** (hard cap — e45s28; iteration 6 forbidden) |
| Pass rule | **AND-gate** — both reviewers must pass independently |
| Blindness | Neither reviewer sees the other's report until both complete |

**Iteration loop (max `MAX_REVIEW_ITERATIONS`):**

1. Dispatch Reviewer A and Reviewer B in parallel with identical briefs but separate contexts.
2. Collect both reports. Each categorizes findings: must-fix / should-fix / consider.
3. **AND-gate:** If **either** reviewer has must-fix findings → FAIL round. Run `respond-review`, fix, re-dispatch both reviewers.
4. If both pass (zero must-fix, score ≥ 94% each) → review complete.
5. After **5** iterations without dual pass → **stop**; report "Review cap exhausted (5/5). Human decision required." Do not merge.

> **HARD GATE** — Single-reviewer pass is insufficient. Partial agreement does not satisfy the AND-gate.

## Process

### 1. Prepare the review brief

Write a self-contained brief for each reviewer. Include:

- What was built (feature description, not implementation)
- Which files changed (the diff context)
- What `specs/` artifacts are relevant (active `epics/eNN-*.yaml`, `requirements/SCOPE_LATEST.yaml`, `bugs/BUG-*.md`)
- What CONVENTIONS.md requires
- What the verify command is
- What you're most uncertain about (where you want fresh eyes)
- **Security focus** — If the epic has a `specs/security/epics/<id>/THREAT_MODEL.md`, include the relevant vulnerability categories as reviewer focal points. Also include the false-positive exclusion rules so the reviewer avoids known-safe patterns. Tag the review as `security-sensitive: true` if THREAT_MODEL risk is HIGH+.

### 2. Fan-out parallel reviewers (e45s17)

Beyond the mandatory dual-blind pair (e45s07), optionally dispatch **N dimension-specific subagents in one message** — one check per agent for broader coverage (OpenAI Codex `code-review-*` pattern):

| Agent | Focus |
|-------|-------|
| R-correctness | Logic, edge cases, verify command result |
| R-conventions | CONVENTIONS.md, test quality (F.I.R.S.T) |
| R-security | Injection, auth, secrets (when `security-sensitive`) |
| R-design | Simpler alternatives, API shape |

Santa Method still applies: each agent is blind; AND-gate uses Reviewer A + B scores. Fan-out agents feed findings into `respond-review` but do not replace the dual-blind pair.

### 2b. Dispatch both reviewer agents (parallel)

Use the Agent tool twice with completely fresh contexts. Each prompt must be self-contained — no references to "our conversation" or "what we discussed."

```
You are code reviewer [A|B]. Review the following code changes independently.

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
7. Refactoring smells — explicitly name any detected Fowler smells: Mysterious Name, Duplicated Code, Feature Envy, Data Clumps, Primitive Obsession, Message Chains, Middle Man

For each finding, categorize as: must-fix / should-fix / consider.
Run the verify command and report the result.
```

### 3. Collect both reports

When reviewers return:
- Read every finding from **both** reports before acting on any
- Note each verify command result
- Compute quality score per reviewer: `100 × (total_items − must_fix − should_fix) / total_items`
- **AND-gate check:** both scores ≥ 94% and zero must-fix from **both**?

> **HARD GATE** — If either score < 94% or either has must-fix → FAIL round. Run `respond-review` first. The 94% threshold also applies to `npm run compliance` (scripts/audit-compliance.sh).

### 4. Hand off to respond-review

Pass combined findings to `respond-review` to categorize and apply fixes. Increment iteration counter. Re-dispatch both reviewers until AND-gate passes or iteration 3 exhausted.

Report to user: "Review round [N/3]. Reviewer A: [score], Reviewer B: [score]. AND-gate: [PASS|FAIL]."

## Verify

→ verify: `grep -q 'AND-gate' skills/request-review/SKILL.md && grep -q 'max 3' skills/request-review/SKILL.md && echo OK`
