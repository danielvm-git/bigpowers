# Agent instructions

This project uses the bigpowers skills (in `.claude/skills/` and `.agents/skills/`).

- Work through the bigpowers lifecycle for every change: `survey-context` → `plan-work` → `develop-tdd` → `verify-work` → `audit-code`.
- Use `develop-tdd`: write a failing test first, confirm it fails, then make it pass.
- For a defect, use `fix-bug` (investigate the root cause before changing code).
- Never weaken, skip or delete an existing test to make the suite pass.
- Show test evidence before you say the work is done.
