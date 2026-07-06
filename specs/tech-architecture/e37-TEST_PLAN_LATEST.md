# e37 Test Plan — Reach: Universal Agent Portability

**Date:** 2026-07-06 · **Risk:** P0/P1/P2 mix
**Status:** Draft (pre-build)

---

## Risk-scaled verification strategy

| Risk tier | Stories | Verification depth |
|-----------|---------|-------------------|
| P0 | s07 (adapter dispatch) | Full preflight + matrix + manual UAT |
| P1 | s01, s04, s05, s06, s08 | Scripted verify commands + manual UAT |
| P2 | s02, s03, s09–s12, s14, s15 | Scripted verify commands |
| P3 | s13, s16 | Light (grep / presence check) |

**Note:** bigpowers is a documentation/shell project — there is no traditional test harness.
All verification is via `verify:` commands in tasks.yaml files and manual UAT steps.
This test plan documents the coverage surface, not a test framework.

---

## Per-story verification matrix

### Spine phase (s01–s04)

| Story | verify command | What it proves | Gaps |
|-------|---------------|----------------|------|
| s01 — AGENTS.md template | `grep -q 'Preflight' docs/templates/AGENTS.md && grep -qi 'cline\|opencode\|aider' docs/templates/AGENTS.md` | Template has Preflight + multi-agent preamble | Does not prove seed-conventions emits it correctly |
| s02 — Cline verification | `grep -qi 'cline' scripts/verify-install.sh && grep -qi 'cline' skills/using-bigpowers/SKILL.md` | Cline is documented and verified | Does not prove runtime Cline reads AGENTS.md |
| s03 — Aider bridge | `grep -qi 'aider' skills/seed-conventions/SKILL.md && grep -qi 'Aider-AI' skills/using-bigpowers/SKILL.md` | Aider wiring is in seed + docs | Does not prove .aider.conf.yml is valid YAML |
| s04 — Verify-install spine | `bash scripts/verify-install.sh && echo OK` | Full harness exit 0 | Depends on s01–s03 being implemented first |

### Registry phase (s05–s08)

| Story | verify command | What it proves | Gaps |
|-------|---------------|----------------|------|
| s05 — targets.yaml | `bash scripts/validate-targets-yaml.sh && bash scripts/test-adapters.sh` | Schema + adapter smoke tests pass | Does not prove generated artifacts match registry |
| s06 — Context bundle | `bash scripts/generate-context-bundle.sh --dry-run \| grep -qi 'AGENTS.md'` | Script runs and references AGENTS.md | Dry-run only; no content integrity check |
| s07 — Adapter dispatch | `bash scripts/sync-skills.sh && bash scripts/run-verification-gates.sh` | Full preflight after sync | Does not prove all adapters rendered correctly |
| s08 — Verify matrix | `bash scripts/verify-install.sh --matrix \| grep -q 'PASS'` | Matrix assertions pass | Does not prove all contracts are implemented |

### Wave phase (s09–s13)

| Story | verify command | What it proves | Gaps |
|-------|---------------|----------------|------|
| s09 — Wave A | `grep -q 'goose' + verify-install --matrix goose.*PASS` | Goose + Agy in registry + matrix pass | Does not prove adapter works with real Goose |
| s10 — Wave B | `grep -q 'zed/omp/hermes'` | Three targets in registry | No matrix assertion; grep-only |
| s11 — Wave C | `grep -q 'qwen/kilocode'` | Two targets in registry | No matrix assertion; grep-only |
| s12 — Wave D | `grep -q 'continue' + verify-install --matrix continue` | Continue in registry + matrix pass | |
| s13 — Wave E | `grep -q 'iflow/vibe/shai'` | Three optional targets in registry | Grep-only; optional story |

### Codex wave (s14–s16, optional)

| Story | verify command | What it proves | Gaps |
|-------|---------------|----------------|------|
| s14 — Codex seed | `grep -qi 'codex' seed-conventions/SKILL.md + config.toml` | Codex wiring in seed-conventions | Does not prove TOML is valid |
| s15 — Codex install | `bash scripts/install.sh --dry-run \| grep -qi 'codex'` | Install mentions Codex | Dry-run only |
| s16 — Codex docs | `grep -qi 'codex' using-bigpowers/SKILL.md` | Docs reference Codex | Presence check only |

---

## Manual UAT steps (required for P0 and P1 stories)

After machine verification, the implementor must run:

1. **s01**: Run `seed-conventions` in a temp directory; verify AGENTS.md has Preflight + multi-agent header
2. **s04**: Run `bash scripts/verify-install.sh` in clean scratch; confirm exit 0
3. **s05**: Run `bash scripts/validate-targets-yaml.sh` and `bash scripts/test-adapters.sh`; confirm PASS
4. **s06**: Run `bash scripts/generate-context-bundle.sh`; confirm CLAUDE.md exists as symlink to AGENTS.md
5. **s07**: Run `bash scripts/sync-skills.sh`; confirm .cursor/rules/ and .gemini/ are populated
6. **s08**: Run `bash scripts/verify-install.sh --matrix`; confirm each target row shows PASS

---

## Verification gates by epic phase

| Phase | Gate | Command | Hard block? |
|-------|------|---------|-------------|
| Pre-ship (any branch) | Preflight | `npm run compliance && bash scripts/run-verification-gates.sh && bash scripts/sync-skills.sh && bash scripts/trace-stories.sh --strict` | Yes |
| s01 | Template correctness | `grep -q 'Preflight' docs/templates/AGENTS.md` | Yes |
| s05 | Registry schema | `bash scripts/validate-targets-yaml.sh` | Yes |
| s05 | Adapter smoke | `bash scripts/test-adapters.sh` | Yes |
| s07 | Full sync | `bash scripts/sync-skills.sh && bash scripts/run-verification-gates.sh` | Yes |
| s08 | Matrix coverage | `bash scripts/verify-install.sh --matrix \| grep -q 'PASS'` | Yes |

---

## Traceability mandate

Every implementing file MUST contain a `story: e37sNN` tag.
`bash scripts/trace-stories.sh --strict` enforces this in CI.

---

## References
- specs/execution-status.yaml (story status tracking)
- specs/epics/e37-reach/epic.yaml (story metadata)
- specs/epics/e37-reach/*.md (per-story specs)
- specs/tech-architecture/tech-stack.md § Reach Domain (invariants)
