# story: e37s15
# bigpowers — Codex CLI starter context

Read CONVENTIONS.md before any GitHub or git operation.

## Project

**bigpowers** — agent skills for spec-driven, test-first software development.
This is the global Codex CLI starter; for project-specific context run `seed-conventions` in your repo.

## Commands

| Action | Command |
|--------|---------|
| Install | `npm install -g bigpowers && bigpowers setup` |
| Preflight | `npm run compliance && bash scripts/run-verification-gates.sh` |

## Notes

- Codex is **instruction-file-only** — no slash skills.
- Project wiring: opt in during `seed-conventions` for `.codex/config.toml` + root `AGENTS.md`.
- Docs: `skills/using-bigpowers/SKILL.md` § Codex CLI.
