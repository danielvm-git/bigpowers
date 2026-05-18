# Plan: v1.11.0 (Compliance Reference Features)

## Context
Define the behavioral requirements (Gherkin features) for the project's key external benchmarks: Akita, Karpathy, Clean Code, Pocock, BMAD, and Superpowers. These feature files will be used by the `audit-compliance.sh` harness to identify remaining gaps in the `bigpowers` skills.

## Steps

1. Create `specs/audit/features/akita.feature` containing the 13 rules for agent-friendly code → verify: `ls specs/audit/features/akita.feature`

2. Create `specs/audit/features/karpathy.feature` containing the 4 behavioral principles (Think Before Coding, Simplicity, Surgical Changes, Goal-Driven) → verify: `ls specs/audit/features/karpathy.feature`

3. Create `specs/audit/features/cleancode.feature` covering key Martin heuristics (SRP, Small Functions, DRY, etc.) → verify: `ls specs/audit/features/cleancode.feature`

4. Create `specs/audit/features/pocock.feature` covering Ousterhout/Deep Module concepts and token consciousness → verify: `ls specs/audit/features/pocock.feature`

5. Create `specs/audit/features/bmad.feature` covering full-SDLC consistency and artifact tracking → verify: `ls specs/audit/features/bmad.feature`

6. Create `specs/audit/features/superpowers.feature` covering HARD-GATEs and red-flag detection → verify: `ls specs/audit/features/superpowers.feature`

7. Run a baseline audit using all new features to confirm "FAIL" states (the Red state) → verify: `for f in specs/audit/features/*.feature; do bash scripts/audit-compliance.sh "$f" --dry-run; done`

8. Update `specs/STATE.md` to reflect the defining of reference features → verify: `grep "v1.11.0" specs/STATE.md`

## Out of scope
- Fixing the gaps identified by the audit (these are for future releases).
- Automated judging (remains agentic/interactive).

## Risks
- **Over-specification:** Features might be too granular for a quick audit.
  - *Mitigation:* Focus on the most distinctive behavioral requirements from each source.
- **Ambiguity:** Vague Gherkin steps are hard to judge.
  - *Mitigation:* Use clear, outcome-based language in steps (e.g., "Then functions should be under 20 lines").
