# Plan: v1.15.0 — Superpowers Gates

## Context

Fixes 3 failing steps in `superpowers.feature`:
- "automatically bootstrap project context at session start"
- "detect red flag rationalizations in my own thought process"
- "reject PRs that do not meet the 94% quality threshold"

All changes are to Markdown — SKILL.md files and CLAUDE.md. No code is written.

Audit baseline: post-v1.14.0. Expected improvement: +3–4 steps.

## Steps

1. Add mandatory "Session Start" section to `CLAUDE.md` Agent Rules — before any task:
   (1) read CLAUDE.md, (2) read CONVENTIONS.md, (3) check specs/ for active RELEASE-PLAN.md
   and STATE.md. Must be phrased as required, not opt-in.
   → verify: `grep -c "Session Start\|Before any task" CLAUDE.md`

2. Add red-flag self-check to `plan-work/SKILL.md` after Step 2 "Draft steps" — before
   finalizing the plan, name any rationalization caught for skipping a gate, adding
   out-of-scope steps, or omitting a verify command. Write them out; do not suppress.
   → verify: `grep -c "rationalization\|[Rr]ed.flag" plan-work/SKILL.md`

3. Add "### Red Flags" section to `audit-code/SKILL.md` at end of checklist — name any
   rationalization caught for skipping a checklist item; silence is not acceptable.
   → verify: `grep -c "rationalization\|Red Flag" audit-code/SKILL.md`

4. Add 94% quality threshold gate to `request-review/SKILL.md` Step 3 — compute score as
   `100 × (total_items − must_fix − should_fix) / total_items`; report the score; add
   HARD-GATE: if score < 94%, run `respond-review` before merging.
   → verify: `grep -c "94%" request-review/SKILL.md`

5. Run sync-skills.sh to regenerate Cursor and Gemini artifacts.
   → verify: `bash scripts/sync-skills.sh 2>&1 | grep "skills synced"`

6. Run compliance audit to confirm superpowers.feature gains.
   → verify: `npm run compliance 2>&1 | grep -E "PASS|FAIL" | tail -8`

## Out of scope

- Testing mandates (v1.16.0)
- Modifying bmad skills or generated artifacts directly

## Risks

- `plan-work/SKILL.md` will also receive additions from v1.14.0 Step 2 and 5; if total
  exceeds 130 lines, extract red-flag section to `plan-work/REFERENCE.md`.
- The 94% formula applies to review findings (must-fix + should-fix counts), not audit
  checklist items — confirm interpretation before writing Step 4.
