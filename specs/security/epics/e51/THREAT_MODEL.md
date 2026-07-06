# Threat Model — e51 Always Green / Shift Left

**Epic:** e51 | **Date:** 2026-07-06 | **Risk level:** LOW

## Surface area

| Component | Change type | Exposure |
|-----------|-------------|----------|
| `CONVENTIONS.md` | Documentation — agent rules | None (no runtime) |
| `CLAUDE.md` | Documentation — bootstrap | None |
| `skills/seed-conventions/` | Template generation | Indirect — shapes new project configs |
| `skills/kickoff-branch/` | Skill workflow | None — no shell execution of user code |
| `skills/verify-work/` | Skill workflow | None |
| `skills/audit-code/`, `develop-tdd/`, `quick-fix/`, `fix-bug/` | Skill workflow | None |

No new network endpoints, auth boundaries, crypto, deserialization, or user-input sinks.

## Vulnerability categories assessed

| Category | Applicable? | Notes |
|----------|-------------|-------|
| Command injection | No | No new shell hooks or eval paths |
| Secrets exposure | No | No credential handling |
| Auth bypass | No | No auth model changes |
| Path traversal | No | No file I/O beyond existing spec paths |
| SSRF / XSS | No | Documentation-only deliverables |
| IDOR | No | N/A |

## Primary risks (operational, not security)

1. **False sense of green** — Preflight definition too narrow could let agents proceed with red CI. Mitigation: e51s03 mandates CI green via `gh pr checks` in verify-work.
2. **Scope creep on fix-or-log** — Agents may over-fix unrelated code. Mitigation: quick-fix guardrails + fix-bug for guardrail abort; separate commits required.
3. **Seeded project drift** — Existing projects won't auto-update CONVENTIONS. Mitigation: e51s01 "Existing projects" callout documents manual merge path.

## Mitigation guidance

- Keep Preflight verify commands project-specific; never hardcode secrets in templates.
- fix-or-log routing must not bypass `guard-git` push/force-push blocks.
- seed-conventions templates must not inject arbitrary shell from user interview answers without sanitization (pre-existing seed-conventions contract; unchanged by e51).

## Verdict

**LOW risk** — doctrine and workflow documentation. No HIGH-confidence security findings. Proceed with build.
