# Spike: Verification-First Workflow

**Goal**: Implement the "plan, tdd, execute, verify" loop for every epic, inspired by the `get-shit-done` (GSD) verification journey.

## GSD Research Findings (`/gsd:verify-work`)

- **Philosophy**: "Show expected, ask if reality matches."
- **Cold-start smoke test**: Automatically checks if the application starts from scratch (kills server, clears caches, boots).
- **User-observable outcomes**: Tests are derived from "Accomplishments" and "User-facing changes" in `SUMMARY.md`.
- **Step-by-step UAT**: One action at a time (Open -> Fill -> Click -> Observe).
- **Gaps-closure loop**: Failed UAT steps are logged as "Gaps" and fed back into `plan-phase --gaps`.
- **Conversational**: Uses simple "yes/next/ok" for passing and descriptive feedback for issues.

## bigpowers Gap Analysis

| Skill | Current State | Gap |
| :--- | :--- | :--- |
| `plan-work` | Produces mechanical `verify: <cmd>` per step. | Missing a structured "Manual Verification Script" for the story/epic as a whole. |
| `develop-tdd` | Focuses on red-green-refactor of logic. | No explicit mandate to provide a manual test script to the user at the end. |
| `execute-plan` | Runs mechanical `verify:` commands. | Lacks a "Verification Checkpoint" that guides the user through the UAT. |
| `survey-context` | Ends at Execute/Review. | Missing an explicit "Verify" phase in the lifecycle map. |

## Proposed Strategy

### 1. Update `plan-work`
- Update the `specs/RELEASE-PLAN.md` template to include a `## Verification Script` section for each story.
- Mandate that this script contains step-by-step instructions for a human to verify the story's outcome.

### 2. Update `develop-tdd` & `execute-plan`
- Add a final "Verification" step to the workflow of both skills.
- The agent MUST present the `## Verification Script` from the plan and wait for user confirmation.

### 3. Update `CONVENTIONS.md`
- Add a "Verification Mandate": "Every story implementation must end with a step-by-step manual verification script provided to the user."

### 4. Update `survey-context`
- Add "Verify" as a distinct phase between "Execute" and "Review".

## Next Steps

1. [ ] Update `plan-work/SKILL.md` template.
2. [ ] Update `develop-tdd/SKILL.md` with verification handover.
3. [ ] Update `execute-plan/SKILL.md` with interactive verification checkpoint.
4. [ ] Update `survey-context/SKILL.md` lifecycle map.
5. [ ] Update `CONVENTIONS.md` with the mandate.
6. [ ] Sync skills (`bash scripts/sync-skills.sh`).
