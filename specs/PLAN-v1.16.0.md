# Plan: v1.16.0 — Testing Mandates

## Context

Fixes 3 failing steps in `cleancode.feature` "Professional Testing" scenario:
- "no Ignored Tests without an explicit ambiguity note (T4)"
- "boundary conditions exhaustively tested (T5)" — needs explicit develop-tdd checklist entry
- "Background: pre-conditions" — none of the 8 feature files have a Background: block yet

All changes are to Markdown — CONVENTIONS.md, SKILL.md files, and Gherkin feature files.
No code is written.

Audit baseline: post-v1.15.0. Expected improvement: +2–3 steps.

## Steps

1. Add T4 prohibition to `CONVENTIONS.md` testing section — never skip or @ignore a test
   without an ambiguity note explaining exactly what is unresolved; silently ignored tests
   are prohibited (T4).
   → verify: `grep -c "T4\|ambiguity note" CONVENTIONS.md`

2. Add T4/T5/T8 explicit checklist items to `develop-tdd/SKILL.md` Checklist Per Cycle:
   - `[ ] No test is ignored without an explicit ambiguity note (T4)`
   - `[ ] Boundary conditions tested: empty, max, min, off-by-one (T5)`
   - `[ ] Tests verify behavior through public interface only (T8)`
   → verify: `grep -c "T4\|T5\|T8" develop-tdd/SKILL.md`

3. Add `Background:` block to `specs/audit/features/cleancode.feature` — extract the
   repeated `Given the codebase exists` from all 4 scenarios into a shared Background.
   → verify: `grep -c "Background:" specs/audit/features/cleancode.feature`

4. Add `Background:` block to `specs/audit/features/akita.feature` — extract the repeated
   `Given a project with bigpowers conventions` from both scenarios.
   → verify: `grep -c "Background:" specs/audit/features/akita.feature`

5. Run sync-skills.sh to regenerate Cursor and Gemini artifacts.
   → verify: `bash scripts/sync-skills.sh 2>&1 | grep "skills synced"`

6. Run compliance audit to confirm cleancode.feature gains.
   → verify: `npm run compliance 2>&1 | grep -E "PASS|FAIL" | tail -8`

## Out of scope

- v1.17.0+ (guardrails, BMAD lifecycle, taxonomy)
- Modifying bmad skills or generated artifacts directly
- Adding Background: to feature files that do not repeat a Given clause

## Risks

- `develop-tdd/SKILL.md` is already 137 lines; additions must be terse (1 line each).
- Extracting Given into Background: changes Gherkin structure — verify the harness still
  parses the files correctly after the edit (Step 6 compliance run will surface any failure).
