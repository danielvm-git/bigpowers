# story: e74s01
# Wave A — Antigravity CLI adapter research and agy.sh stub

## Acceptance Criteria

```bash
test -f specs/epics/e74-integration-antigravity/RESEARCH-ANTIGRAVITY.md &&
grep -q 'wire_context' scripts/adapters/agy.sh &&
grep -q 'render_skill' scripts/adapters/agy.sh &&
bash scripts/test-adapters.sh agy &&
echo OK
```

## Requirements

### ADDED

- Research document capturing Antigravity CLI config paths, hook events, and skills layout.
- Expanded `agy.sh` adapter stub with documented env defaults and `render_skill` placeholder for Wave B.
- Threat model at `specs/security/epics/e74/THREAT_MODEL.md`.
- Epic capsule `integration_details` updated from research findings.

## Out of scope

- `install.sh`, `install-helpers.js`, `setup.js`, `targets.yaml`, `verify-install.sh`
- `.gemini/**` install wiring and skill symlinks
- Runtime E2E with `agy` binary (proprietary beta)
- Hook script generation or MCP config emission

## Adapter guidance

- Reuse `context-wire.sh` symlink mode (e37 pattern) — `CLAUDE.md` target per existing registry row.
- `render_skill` stub: mkdir under `AGY_SKILLS` env default `.agents/skills` — no file copy until Wave B.
- Constants at top of adapter cite RESEARCH-ANTIGRAVITY.md paths for Wave B implementers.
- Verify: `bash scripts/test-adapters.sh agy` (context contract only; `skill: null` in registry).

## Risks

- External docs may drift — cite URLs and date in research doc.
- `test-adapters.sh` may exit non-zero despite passes (known counter quirk) — use explicit `TA_FAIL` grep in verify.
