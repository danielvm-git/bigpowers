# story: e37s04
# verify-install.sh — AGENTS.md spine assertions (OSS P1 + optional Codex)

BCP: 2 | risk: P2

## Summary

Extend `scripts/verify-install.sh` to assert AGENTS.md spine shape, Preflight row,
and Cline/Aider wiring, plus optional Codex assertions when the Codex wave stories
(s14–s16) are present. Mirrors the e47 verify-install pattern for pi/OpenCode.

---

## Acceptance Criteria

Scenario: AGENTS.md spine assertions pass
  Given verify-install.sh after e37 spine stories
  When run on a clean scratch environment
  Then it asserts AGENTS.md template shape and Preflight row
  And it asserts Cline/Aider wiring when opted in
  And optional Codex assertions run only when Codex wave stories are present

---

## Behaviours

### 1. AGENTS.md template shape
- Assert `docs/templates/AGENTS.md` exists and contains a multi-agent preamble
  naming ≥1 OSS target (Cline, Aider, OpenCode).
- Assert `## Preflight` section is present and non-empty.
- Assert `## Test`, `## Lint`, `## Build` are present (value may be `N/A`).
- Assert title uses neutral agent wording (not Codex-only or Claude-only).

### 2. Preflight row integrity
- Assert the Preflight section contains a row with an install/sync command
  (matches the e51 Preflight mandate).

### 3. Cline wiring (e37s02)
- Assert `AGENTS.md` exists at project root after seed-conventions runs.
- Assert the template can be read by Cline (no forbidden patterns).

### 4. Aider wiring (e37s03)
- When Aider is opted in: assert `.aider.conf.yml` exists with `read: AGENTS.md`.
- Assert the Aider section in `using-bigpowers` references Aider-AI/aider.

### 5. Codex assertions (optional, gated on Codex wave)
- Only when Codex wave stories (s14–s16) are present: assert `docs/templates/codex/` exists,
  assert `install.sh --dry-run` mentions Codex CLI, assert secret-free templates.
- When Codex wave is absent: these assertions must be skipped (no false negatives).

---

## Out of scope
- Live Codex CLI binary invocation (covered by e37s15 if opted in).
- Project-level E2E seed test in consumer repo.
- TOML config parsing (covered by e37s14 if opted in).
- Per-target verify-matrix (covered by e37s08).

---

## References
- scripts/verify-install.sh (e47s04 patterns — pi/OpenCode assertions)
- epic.yaml (e37s04: "AGENTS.md spine assertions (OSS P1 + optional Codex)")
