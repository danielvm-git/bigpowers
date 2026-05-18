# Plan: v1.14.0 — Karpathy Behavioral Mandates

## Context

Fixes 3 failing steps in `karpathy.feature`:
- "present multiple interpretations of ambiguous requests"
- "loop until behavioral correctness is verified"
- "push back on unnecessary complexity"

All changes are to Markdown SKILL.md files. No code is written.

Audit baseline: ~84% (~75/89). Expected improvement: +2–3 steps.

## Steps

1. Add multiple interpretations gate to `elaborate-spec/SKILL.md` Step 2 — if the request
   admits ≥2 valid interpretations, list them and ask the user to choose before proceeding.
   → verify: `grep -c "interpretation" elaborate-spec/SKILL.md`

2. Add multiple interpretations gate to `plan-work/SKILL.md` Pre-flight — if the task
   statement admits ≥2 interpretations, present them and get a decision before drafting steps.
   → verify: `grep -c "interpretation" plan-work/SKILL.md`

3. Add loop-until-correct rule to `validate-fix/SKILL.md` Rules section — a mechanical
   verify pass is not enough; behavioral correctness must be confirmed; loop back if wrong.
   → verify: `grep -c "behavioral correctness\|loop" validate-fix/SKILL.md`

4. Add loop-until-correct note to `execute-plan/SKILL.md` Step 2d — mechanical verify
   passing ≠ behavioral correctness; fix and re-verify if behavior is wrong.
   → verify: `grep -c "behavioral" execute-plan/SKILL.md`

5. Add complexity pushback gate to `plan-work/SKILL.md` Step 2 — any step introducing a
   new abstraction must include a one-sentence forcing function: "This abstraction is needed
   because…"; remove the abstraction if the sentence cannot be filled.
   → verify: `grep -c "abstraction\|forcing" plan-work/SKILL.md`

6. Run sync-skills.sh to regenerate Cursor and Gemini artifacts.
   → verify: `bash scripts/sync-skills.sh 2>&1 | grep "skills synced"`

7. Run compliance audit to confirm karpathy.feature gains.
   → verify: `npm run compliance 2>&1 | grep -E "PASS|FAIL" | tail -8`

## Out of scope

- Superpowers and testing mandates (v1.15.0, v1.16.0)
- Modifying bmad skills or generated artifacts directly

## Risks

- `plan-work/SKILL.md` is at 96 lines; Steps 2 and 5 both add to it. If it exceeds
  130 lines after both edits, extract the complexity section to `plan-work/REFERENCE.md`.
